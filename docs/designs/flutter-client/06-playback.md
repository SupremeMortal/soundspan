# 06. Playback

Status: design phase.

Code lives in `lib/core/playback/`.

```
core/playback/
├── playback_controller.dart        # The one object UI and OS controls talk to
├── queue/                          # Pure Dart: QueueState, QueueReducer, ShuffleOrder
├── engines/
│   ├── player_engine.dart          # Interface
│   ├── just_audio_engine.dart      # Android, iOS, macOS, web
│   ├── media_kit_engine.dart       # Windows, Linux
│   └── fake_engine.dart            # Deterministic, for tests
├── source_resolver.dart            # QueueItem → EngineSource (local file or stream URL)
├── loudness.dart                   # Gain computation
├── media_controls/
│   ├── media_controls.dart         # Interface
│   ├── audio_service_controls.dart # Android, iOS, macOS, web, Linux (MPRIS)
│   └── smtc_controls.dart          # Windows
├── audio_focus.dart                # audio_session wiring
└── persistence.dart                # Queue snapshot to state.db
```

## Server Behaviour This Relies On

Checked in the backend source; the contract suite ([11](11-testing-and-ci.md)) keeps these true.

- Requesting `/api/playback/stream/<id>` for a library track records a play before bytes are served, deduplicated per user and track within 30 seconds (`backend/src/services/playback/streamLibraryTrack.ts`). Downloads and gapless preloads therefore count as plays (closed by P7).
- `POST /api/plays` stamps the current time, and the `Play` row has no duration column (closed by P8).
- `quality` accepts `original | high | medium | low`. Absent means the user's saved quality, else `medium`.
- Playback state is stored per user and per device, selected by the `X-Playback-Device-Id` header. The stored queue is capped at 100 items. There is no endpoint that lists other devices' states.

## Component Responsibilities

```
 UI widgets ─┐                                   ┌─▶ PlayReporter ─▶ Outbox ─▶ POST /api/plays
 OS controls ┼─▶ PlaybackController ─▶ PlayerEngine    PlaybackStateSync ─▶ POST /api/playback-state
 Listen Tog. ┘        │    ▲                     └─▶ MediaControls (metadata, state)
                      ▼    │ events
                 QueueReducer (pure)      SourceResolver ─▶ DownloadStore / StreamUrls
```

- **`PlaybackController`** owns the queue and the engine. It exposes `Stream<PlaybackSnapshot>` and command methods. Nothing else calls the engine.
- **`QueueReducer`** is a pure function `(QueueState, QueueCommand) → QueueTransition` (the next `QueueState` and a `QueueEffect`). All queue rules are tested here with no player.
- **`PlayerEngine`** plays at most two things: the current source and a preloaded next source. It knows nothing about queues, shuffle, or the server.
- **`MediaControls`** mirrors the snapshot to the OS and turns OS button presses into controller commands.

## `PlayerEngine`

```dart
/// A playable thing handed to the engine. Built by SourceResolver.
class EngineSource {
  final String queueItemId;
  final Uri uri;                         // file:// or http(s)://
  final Map<String, String> headers;     // Empty for files and on web
  final Duration? knownDuration;
  final Duration startAt;                // Resume position; zero normally
}

enum EngineStatus { idle, loading, ready, buffering, ended, error }

class EngineState {
  final EngineStatus status;
  final bool playing;                    // Play intent; true while buffering after play()
  final String? currentQueueItemId;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;
  final EngineError? error;
}

sealed class EngineEvent {}
/// The engine moved from current to the preloaded next source by itself.
class AdvancedToNext extends EngineEvent { final String queueItemId; }
/// The current source finished and no next source was set.
class Completed extends EngineEvent { final String queueItemId; }
class Failed extends EngineEvent { final String queueItemId; final EngineError error; }

abstract interface class PlayerEngine {
  Stream<EngineState> get state;         // Replay-latest; position updates at ≥ 4 Hz while playing
  Stream<EngineEvent> get events;

  /// Replace everything. Completes when the source is ready or failed.
  Future<void> load(EngineSource current, {EngineSource? next, bool autoPlay = true});
  /// Set, replace, or clear the preloaded next source without disturbing current.
  Future<void> setNext(EngineSource? next);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();                   // Releases the source; keeps the engine alive
  /// Linear gain 0.0–1.0 for user volume × loudness gain.
  Future<void> setVolume(double linear);
  Future<void> setSpeed(double speed);   // Podcasts only; 0.5–3.0
  Future<void> dispose();
}

class EngineError {
  final EngineErrorKind kind;            // network, http, decode, notFound, unauthorized, unknown
  final int? httpStatus;
  final String detail;                   // For logs only
}
```

Contract details every engine keeps (doc comments on `PlayerEngine`, pinned by the conformance suite):

- `state` replays the latest value to a new listener; the initial state is `idle`, not playing, position zero.
- `load` never throws for a bad source: it completes, emits `Failed` for that `queueItemId`, and the state is `error` with the `EngineError`.
- A next source that fails to load emits `Failed` with the next item's id; the current item is undisturbed and the next slot is empty.
- After `AdvancedToNext`, `currentQueueItemId` is the new item, position restarts from zero, and the next slot is empty until `setNext` is called again.
- After `Completed`, status is `ended`, `playing` is false, and position equals the duration.
- `seek` clamps to `[0, duration]`. `play` with nothing loaded is a no-op. `setVolume` clamps to 0.0–1.0, `setSpeed` to 0.5–3.0.
- After `dispose`, both streams are closed and any further call throws `StateError`.

The engine for the platform comes from the root-scope `playerEngineBuilderProvider` (`engines/player_engine_provider.dart`). Its default throws `UnsupportedError` when called; each platform's engine replaces it and tests override it with `FakeEngine.new`.

`FakeEngine` runs on virtual time: `advance(d)` moves playback forward and emits state (every 200 ms while playing, and at every transition) and events in order, with no real timers. Each source is scripted by URI with a `FakeSource` (duration, an optional failure, how far ahead it buffers, and headers it requires, answering 401 without them); a URI with no script fails with `notFound`, and `requested` records every source opened with its headers.

The two-slot contract is the smallest surface that still gives gapless playback. It maps cleanly onto both backends and keeps queue edits (reorder, remove, shuffle toggle) out of engine code: an edit that changes what comes next is one `setNext` call.

### `JustAudioEngine` (Android, iOS, macOS, web)

- One `AudioPlayer`. `load` calls `setAudioSources([current, next?], initialIndex: 0, initialPosition: startAt)`.
- `setNext` on Android, iOS and web removes index 1 if present and adds the new source, using the player's playlist mutation calls. The current item is never touched.
- `setNext` on macOS reloads the playlist instead: one `setAudioSources([current, next?], initialIndex: 0, initialPosition: <current position>)` call that keeps the play intent (full-playlist loading, see Spike S1 finding). The `PlayerEngine` interface is the same on every platform.
- Sources: `AudioSource.uri(uri, headers: headers, tag: queueItemId)` for streams and `AudioSource.file(path, tag: …)` for downloads.
- Events: a `currentIndexStream` change from 0 to 1 with `ProcessingState.ready` is `AdvancedToNext`. The engine then removes the played item so the new current is index 0 again and waits for the controller's next `setNext`. `ProcessingState.completed` is `Completed`. `playbackEventStream` errors and `errorStream` map to `Failed`; `PlayerException.code` and the HTTP status (when available) set `kind`.
- Gapless: ExoPlayer (Android) and AVQueuePlayer (iOS) transition between adjacent playlist items without a gap when the next item is buffered. On macOS the transition between the two loaded items is not reliably gapless (Spike S1 finding), so the adapter keeps both items in one full-playlist load and gapless playback on a Mac is confirmed on real hardware. Web is best-effort.
- Headers are delivered by `just_audio` through a loopback proxy inside the app (`useProxyForRequestHeaders` left at its default). Every request the player makes, range requests included, carries them (Spike S1 finding). The iOS and macOS `Info.plist` therefore allow local networking (`NSAllowsLocalNetworking`), which does not weaken transport security for remote hosts, and the macOS sandbox has `network.client` and `network.server` ([10](10-platform-integration.md)).
- Android: `AndroidLoadControl` buffer of 30 s min, 120 s max; `androidApplyAudioAttributes: true`; `handleInterruptions: false` (the controller handles focus itself, see Audio Focus).

### `MediaKitEngine` (Windows, Linux)

- One `Player` from `media_kit` (libmpv), created with `PlayerConfiguration(title: 'soundspan', ready: …)` and video output disabled (`vid=no`).
- mpv properties set once through `NativePlayer.setProperty`: `gapless-audio=yes`, `prefetch-playlist=yes`, `audio-client-name=soundspan`, `cache=yes`, `demuxer-max-bytes=64MiB`, `network-timeout=30`, `volume-max=100`.
- `load` opens `Playlist([Media(uri, httpHeaders: headers), Media(next…)])` with `play: autoPlay`; `setNext` uses `player.remove(1)` and `player.add(media)`.
- Headers: with `prefetch-playlist=yes`, mpv opens the next item while the current one plays using the current item's header set, so the next item's requests carry the current item's headers (Spike S2 finding). Every item of a session carries the same credential, so authentication is unaffected; whether the engine keeps prefetch on or turns it off to send each item's own headers is settled with the Spike S2 evidence when the engine is built.
- Events: `stream.playlist` index change 0 → 1 is `AdvancedToNext`; `stream.completed` true on the last item is `Completed` (media_kit also reports `completed` true for a moment at the end of every item before mpv advances); `stream.error` is `Failed`.
- Position comes from `stream.position` (already throttled by media_kit).
- `MediaKit.ensureInitialized()` is called from the engine factory only on Windows and Linux, so the native library is never loaded elsewhere.

### Engine Conformance Suite

`test/core/playback/engine_conformance.dart` is one parameterized suite run against `FakeEngine` in unit tests and against the real engine for the current platform in `integration_test/engine_conformance_test.dart` (tag `engine`), using short tone files served by a local `shelf` server that checks headers and Range.

Required behaviours: load and play; pause and resume keep position; seek within buffered and unbuffered ranges; `setNext` then natural end produces exactly one `AdvancedToNext` and no audible gap larger than 20 ms (measured from the position streams, verified by ear in the manual matrix); `setNext(null)` then natural end produces `Completed`; replacing next twice before the transition plays only the last one; a 404 source produces `Failed(notFound)`; a 401 produces `Failed(unauthorized)`; headers reach the server; a local file plays with the network disabled; `stop` then `load` works; `dispose` releases the device.

The suite is `runEngineConformance(name, createHarness)`. An `EngineHarness` supplies engines and sources (a tone, a slowly buffering tone, a 404, a 401, a local file), the headers the server saw, a way to disable the network, `elapse` (virtual for the fake, real time for devices), the clock `now` that stamps state samples (the sum of `elapse` for the fake, a stopwatch for devices), the gap tolerance (20 ms) and the cases the platform skips. Besides the required behaviours it pins the interface: state replays the latest value to a late listener, position updates at least four times a second while playing, `load` with `startAt` starts there, and `load` with `autoPlay: false` is ready and not playing. The gap at a transition is measured from the position stream only: with `(tA, pA)` the last sample of the ending item and `(tB, pB)` the first of the new one, the gap is `|(tB − tA) − ((durationA − pA) + pB)|`.

## Queue Model

v1 plays music and podcasts, so a queue item is either a track or an episode. Audiobooks are not in v1.

```dart
class QueueState {
  final List<QueueItem> items;          // Canonical (unshuffled) order
  final List<int>? shuffleOrder;        // Permutation of indices when shuffle is on
  final int? cursor;                    // Index into play order (shuffleOrder ?? identity)
  final RepeatMode repeat;              // off | all | one
  final QueueContext? context;          // What "Play" was pressed on
  final int revision;                   // Incremented on every change
}

sealed class QueueCommand {}            // ReplaceAll, PlayNext, Append, RemoveAt, Move, JumpTo,
                                        // Next, Previous, SetShuffle, SetRepeat, Clear, ItemFinished
```

`QueueReducer.reduce` returns a `QueueTransition`: the next state plus a `QueueEffect` (`none`, `loadCurrent`, `restartCurrent` or `stop`), so the controller applies the engine change the queue rules imply without re-deriving them; a command that changes nothing returns the identical state, and `revision` grows by one exactly when the state changes.

Rules, each with unit tests:

- **Play order** is `shuffleOrder` if set, else the identity. `current = items[playOrder[cursor]]`. `upNext = items[playOrder[cursor + 1]]`, wrapping when `repeat == all`, and equal to `current` when `repeat == one`.
- **Shuffle on:** keep the current item at the cursor, shuffle the remaining indices with Fisher–Yates using a seeded `Random` (the seed is injected, so tests are deterministic). Already-played items keep their order behind the cursor. Replacing the queue while shuffled starts at the chosen item and shuffles all the others; clearing it keeps shuffle on. Moving an entry while shuffled changes only the permutation. Wrapping with `repeat == all` does not reshuffle.
- **Shuffle off:** drop `shuffleOrder`; the cursor becomes the current item's canonical index.
- **Play next:** insert after the current item in canonical order and, when shuffled, at `cursor + 1` in the permutation.
- **Append:** add at the end of the canonical list and, when shuffled, at a random position after the cursor.
- **Remove current:** advance to the next item first, then remove. Removing the last item in play order wraps to the first with `repeat == all` and otherwise stops on the new last item.
- **Previous:** if position > 3 s, seek to zero; otherwise (3 s exactly included) move the cursor back (wrapping only with `repeat == all`). At the first item without wrapping, seek to zero.
- **Item finished:** `repeat one` → replay; end of queue with `repeat all` → the first item in play order (a single item replays); end of queue with `repeat off` → stop, cursor stays on the last item, position zero. `Next` follows the same wrap with `repeat all`; with `repeat one` it is a user skip and behaves as with `repeat off`.
- **Maximum size:** 5,000 items. "Play" on a larger collection queues the first 5,000 and says so; when the chosen start item lies beyond them, the 5,000-item window slides forward just far enough to end on it. Shuffle, when on, applies to the window. Play next and Append queue the leading items that fit. `QueueTransition.dropped` reports how many were left out, for the message.
- Every `QueueItem` has a client-generated `queueItemId`, so the same track can appear twice and edits address entries, not tracks.

After every reducer step the controller compares the new `upNext` with what the engine has preloaded and calls `setNext` if they differ.

## Source Resolution

`SourceResolver.resolve(QueueItem) → Future<EngineSource>`:

1. `DownloadStore.completedFile(itemKey)` → the absolute path of a `completed` item's file (a path, because `dart:io` stays under `lib/platform/`), played as a `file://` URI with no headers. The file's existence is checked; a missing file marks the download `missing` and falls through.
2. Offline (forced or unreachable) and no file → throws `NotAvailableOffline`; the controller skips the item.
3. Otherwise a stream URL:
   - Track: `StreamUrls.track(playbackId, quality: q, reportPlay: false)` where `q` is `quality.wifi` or `quality.cellular` from device settings according to the current connection type, or null for "server default".
   - Episode: `StreamUrls.episode(podcastId, episodeId)`.
   - Native: `headers = authHeaders(credentials)`.
   - Web: `withQueryToken(uri, jwt)`.

**Credential freshness.** A source's credential is fixed when it is created. Before building a stream source with a JWT, the resolver asks `SessionController.ensureFresh(minRemaining: 2 h)`, which refreshes if the access token has less than two hours left. The next source is resolved only when it becomes "up next", so a token is at most one track old plus two hours of margin. On `Failed(unauthorized)` the controller refreshes, rebuilds the source, and retries once at the same position.

## Controller Behaviour

```dart
class PlaybackSnapshot {
  final QueueState queue;
  final QueueItem? current;
  final EngineStatus status;
  final bool playing;
  final Duration position, buffered;
  final Duration? duration;
  final StreamQualityInfo? quality;     // From stream-info, for the quality badge
  final PlaybackError? error;
  final bool isLocalFile;
}
```

- `position` in the snapshot is throttled to 4 Hz for general listeners. The seek bar interpolates locally between updates with a `Ticker`.
- **Failure policy:** on `Failed` for the current item, retry once after 1 s (network and HTTP 5xx kinds only). If it fails again, mark the item failed in the snapshot, show a snackbar, and advance. Three consecutive failed items stop playback with "Can't reach the server" instead of skipping through the whole queue.
- **`SourceUnavailable` / `notFound`:** no retry; skip with a per-item message.
- **Connection type change** (Wi-Fi → mobile data) does not interrupt the current item; the quality setting applies from the next resolved source.
- **Quality badge:** when an item becomes current and is streamed, `GET /playback/stream-info/:id` is fetched once (cached per `playbackId` + quality for the session) and shown as e.g. "FLAC · 24/96 kHz". For a downloaded file the badge shows "Downloaded" plus the stored quality. The badge has one neutral style; it does not vary by source.

## Loudness

`loudness.dart`, pure and unit tested. Inputs: the track's `loudnessLufs` and `truePeakDb`, the album's `albumLoudnessLufs` and `albumTruePeakDb`, the server's `loudnessTargetLufs` (default −18), the user's `loudnessMode` from `GET /api/settings`, and the queue context.

```text
mode off                          → gainDb = 0
mode track                        → use track values
mode album                        → use album values, fall back to track values
mode auto                         → album values when QueueContext.kind == album, else track values

measured missing                  → gainDb = 0
gainDb   = target − measuredLufs
if gainDb > 0:
    headroomDb = (truePeakDb != null) ? max(0, −truePeakDb) : 0
    gainDb = min(gainDb, 3.0, headroomDb)
linear   = 10 ^ (gainDb / 20)
engineVolume = clamp(userVolume × linear, 0, 1)
```

- The engine volume range ends at 1.0 on ExoPlayer, AVPlayer, and HTML audio, so a positive gain is audible only when the user volume is below 1.0. This matches the web player, which also composites gain into element volume. mpv is held to the same range (`volume-max=100`) so every platform behaves alike.
- Gain is applied when an item becomes current: on `AdvancedToNext` the controller sets the new volume immediately. A gapless transition between tracks with different gains therefore has a volume step at the boundary, the same as on the web.
- Episodes get `gainDb = 0`.

## OS Media Controls

```dart
abstract interface class MediaControls {
  Future<void> init(MediaCommandHandler handler);
  void update(MediaSessionState state);     // Metadata, playing, position, speed, enabled actions
  Future<void> dispose();
}
```

`MediaSessionState` carries title, artist, album, duration, artwork as a **local file URI**, position, playing flag, and the available actions (play, pause, next, previous, seek, stop, skip ±N for episodes, like).

Artwork must be a file because OS media surfaces cannot send auth headers: when an item becomes current, `ArtworkPinner` fetches the 512-pixel cover through the authenticated image cache, writes it to `profiles/<id>/art/now-playing.img`, and passes its URI. Until it is ready the previous artwork is cleared.

| Target | Implementation | Notes |
|---|---|---|
| Android | `audio_service` | `SoundspanAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler` forwards to the controller. Runs in a foreground `MediaBrowserService` (`androidStopForegroundOnPause: true`, notification channel "Playback"). Custom "like" action in the notification. Android Auto browse tree in M2. |
| iOS | `audio_service` | Now Playing info and remote command centre; `AVAudioSession` category playback. |
| macOS | `audio_service` | Now Playing widget and media keys. |
| Web | `audio_service` | Media Session API. |
| Linux | `audio_service` with `audio_service_mpris` | MPRIS on the session bus as `org.mpris.MediaPlayer2.soundspan`. |
| Windows | `client/packages/soundspan_smtc` behind `SmtcControls` | System Media Transport Controls through an in-repo C++/WinRT plugin of about 300 lines: buttons, metadata, timeline, thumbnail. The calls it exposes are listed under Spike S4 finding. |

The handler holds no state of its own; it renders the controller's snapshot. This keeps one source of truth on every platform, including Windows where `audio_service` is absent.

## Audio Focus and Interruptions

`audio_focus.dart` configures `audio_session` with `AudioSessionConfiguration.music()` for tracks and `.speech()` for episodes, and handles:

| Event | Action |
|---|---|
| Interruption begins (call, other app takes focus) | Pause; remember "was playing" |
| Interruption ends with `shouldResume` | Resume if it was playing and the pause was not the user's |
| Transient duck request | Android lowers volume itself; elsewhere multiply volume by 0.3 until it ends |
| Becoming noisy (headphones unplugged, Bluetooth disconnected) | Pause; never auto-resume |
| Output device change on desktop | No action |

## Play Reporting

`PlayReporter` in `core/sync` listens to the controller. A play is reported with the total time the track was heard. A play heard for less than 5 seconds in total is not recorded.

**A play** belongs to one queue entry.

- It **starts** at the first instant that entry produces audible output. An entry that is preloaded, or current but never started, has no play.
- `listenedMs` **accumulates** while the engine is `ready` and `playing`, measured as wall-clock time between state changes. Pauses, buffering, and the seek itself add nothing.
- **Seeking does not end or reset the play.** Skipping forward leaves out the skipped part; seeking back and hearing a passage again adds it again. `listenedMs` can therefore be smaller or larger than the track's length.
- It **ends** when the entry stops being the current one: next, previous, a jump in the queue, the queue being replaced or cleared, stop, the natural end of the track, sign-out, or a profile switch. Pausing does not end it, however long the pause.
- Repeat-one, and playing the same entry again after it ended, start a new play.

**Reporting.** When a play ends with `listenedMs` of at least 5,000 it is enqueued to the outbox exactly once as `play` with `{ playbackId, metadata, playedAt, listenedMs }`, where `playedAt` is the instant the play started (P8). A play that ends below 5,000 ms is discarded and nothing is sent: a track skipped after two seconds leaves no trace, and one skipped after twenty is reported with `listenedMs: 20000`. The total decides, not any single stretch, so three seconds heard, a seek, and three more seconds is a 6-second play. The rule does not depend on the track's length. The limit is the constant `PlayReporter.minListened`, mirroring the server's.

**Surviving a kill.** The open play (`sessionId`, `playbackId`, metadata, `playedAt`, `listenedMs`) is written to `play_sessions` every 10 s while playing, on pause, and when the app is backgrounded. At start-up any row left by a previous process is closed with its stored total and, if that reaches 5 seconds, enqueued, so a kill loses at most the last 10 seconds of listening and never the play.

**Consequences.**

- The server learns of a play when it ends, not when it starts, so "recently played" on other devices gains a track after it finishes or is skipped.
- Stream requests always carry the P7 marker, so the server records nothing on its own. Downloads carry it through the server-built `downloadUrl`.
- Offline plays are reported the same way and keep their real `playedAt`.
- A follower in a Listen Together group reports its own plays like any listener.
- Episodes are not reported to `/api/plays`; they use the podcast progress endpoint below.

## Playback-State Sync

`PlaybackStateSync` posts to `POST /api/playback-state` with header `X-Playback-Device-Id: <deviceId>`.

- Triggers: every 15 s while playing (the web cadence), on pause, on track change, on queue edit (debounced 2 s), and on app background. At most one request in flight; a newer state replaces a queued one.
- Body: `playbackType` (`track` or `podcast`), `playbackId` or `podcastId`, `currentIndex`, `currentTime` (seconds), `isShuffle`, `isPlaying`, and `queue`.
- The server keeps 100 queue items. The client sends a window of the play order: up to 20 items before the cursor and 79 after, with `currentIndex` relative to the window. Track items are `{ playbackId, metadata }`; episode items use the server's episode item shape.
- Not sent while offline and not queued in the outbox: only the latest state matters, and it is sent on reconnect.
- **Restore:** the local `queue_snapshot` is authoritative for this device. `GET /api/playback-state` is consulted only when there is no local snapshot (fresh install or cleared data), which also restores the queue after a reinstall. Restored playback is always paused.
- **This device only.** Resume restores the state this device wrote. Continuing the queue another device is playing is not part of this plan; its design is [`../cross-device-playback-handoff.md`](../cross-device-playback-handoff.md).

## Local Queue Persistence

`persistence.dart` writes `queue_snapshot` and `queue_meta` to `state.db`: the full queue on structural change (debounced 500 ms, in one transaction) and the position every 5 s while playing and on pause. On start the controller rebuilds `QueueState`, resolves the current item, and calls `engine.load(current, autoPlay: false)` lazily on the first play press, so start-up costs no network.

## Podcasts

- `EpisodeQueueItem` plays through the same controller and engine.
- Controls differ by item kind: skip back/forward by `playback.skipSeconds` (default 15) and a speed control (0.5×–3×, remembered in `playback.speed.podcast`) are shown for episodes; shuffle and repeat are hidden. OS controls advertise skip intervals instead of previous/next when the queue holds a single episode.
- Resume: an episode starts at `progress.currentTime` from the podcast detail payload unless `isFinished`.
- Progress: `POST /podcasts/:podcastId/episodes/:episodeId/progress { currentTime, duration, isFinished }` every 15 s while playing, on pause, and on finish (`isFinished` when within 30 s of the end). Offline, the latest progress per episode is kept as one coalesced outbox operation.
- Speed changes the engine speed only for episodes; switching to a track resets it to 1.0.

## Background Behaviour by Platform

| Target | Mechanism | Keep-alive rule |
|---|---|---|
| Android | Foreground service while playing | Leaves foreground on pause; the notification stays dismissible for 10 min, then the service stops |
| iOS | `audio` background mode | The OS suspends the app shortly after audio stops; state is persisted on pause |
| macOS, Windows, Linux | Process keeps running | "Close to tray" (default on Windows and Linux, off on macOS where closing the window keeps the app in the Dock) |
| Web | Tab must stay open | A `beforeunload` prompt is not used; state is persisted continuously |

## Listen Together Hook

`PlaybackController` exposes a `RemoteDriver` attachment point used by [08](08-realtime.md). While a driver is attached, queue and transport commands from the UI are routed to the driver (which sends them to the server) instead of mutating local state, and the controller applies server state as it arrives. Play reporting and playback-state sync continue unchanged.

## Spike S1 finding

A minimal Flutter app played a two-item playlist `[A, B]` through one `AudioPlayer` configured as above (`setAudioSources`, `AudioSource.uri` with an `X-API-Key` header). A and B are 3-second FLAC files (44.1 kHz) cut at a sample boundary from one continuous 440 Hz tone; C is a 3-second 880 Hz tone. An `HttpServer` inside the test process on `127.0.0.1` served them with Range support, rejected requests without the right key with 401 and recorded every request. Position and index were polled every 5 ms against a `Stopwatch`; the timeline is `index × duration(A) + position`, and the gap is the largest `wallClockDelta − timelineDelta` between consecutive samples within 500 ms of the index change. Each question ran five times per platform.

| Platform (CI device) | 1. Gapless `[A, B]` | 2. Header on every request; wrong key fails | 3. Replace item 1 while item 0 plays |
|---|---|---|---|
| Android (emulator, API 34, x86_64, `google_apis`) | Yes, 5/5: gap 0.0, 5.1, 4.7, 5.1, 6.7 ms | Yes, 5/5: 2 of 2 requests per run carried the key; wrong key fails with `PlayerException` code 0 ("Source error") | Yes, 5/5: gap at the replacement ≤ 0.02 ms, no state change, C played next, one index change |
| iOS (simulator, iPhone 16e, macOS 26 arm64 runner) | Yes, 5/5: gap 8.7, 6.7, 6.8, 6.4, 7.6 ms | Yes, 5/5: 4 of 4 requests per run (all range requests) carried the key; wrong key fails with `PlayerException` code −1013 (`NSURLErrorUserAuthenticationRequired`) | Yes, 5/5: gap at the replacement ≤ 0.08 ms, no state change, C played next, one index change |
| macOS (macOS 26 arm64 runner) | **No**, 3/5: gap 7.8, 6.7, 113.5, 21.4, 6.4 ms | Yes, 5/5: 4 of 4 requests per run (all range requests) carried the key; wrong key fails with `PlayerException` code −1013 | Yes, 5/5: gap at the replacement ≤ 0.04 ms, no state change, C played next, one index change |

In every run on every platform the processing state stayed `ready` across the transition and there was exactly one index change, 0 → 1.

- The darwin implementation can deliver the index change before the position reset: the first sample with index 1 still reports the end position of A. The harness skips such a sample when measuring the gap (one sample in macOS run 4; the consecutive-sample value including it is 2871 ms). An engine reading `currentIndexStream` together with `position` must expect this ordering.
- AVPlayer reports the duration of the 3.000-second FLAC files as 3.030 s on iOS and macOS; ExoPlayer reports 3.000 s.
- On Android the HTTP status of a failed request is not in the `PlayerException` (code 0); on iOS and macOS the `NSURLError` code is.
- Package versions: Flutter 3.50.0 (Dart 3.14.0), `just_audio` 0.10.6, `just_audio_platform_interface` 4.6.0, `audio_session` 0.2.4.
- Native settings required: Android `usesCleartextTraffic` for the loopback proxy (covered by the global cleartext policy of [10](10-platform-integration.md)); iOS and macOS `NSAllowsLocalNetworking`; macOS `com.apple.security.network.client` and `com.apple.security.network.server`.
- Whether playback is audibly gapless on a real Android device, iPhone and Mac cannot be measured on CI and is a human checklist row.

Because question 1 is answered no on macOS, macOS takes the full-playlist fallback for `setNext` in `JustAudioEngine`; Android and iOS keep the playlist mutation calls.

## Spike S2 finding

A minimal Flutter desktop app played the same files as Spike S1 (A and B: 3-second 44.1 kHz FLAC cut at a sample boundary from one continuous 440 Hz tone; C: a 3-second 880 Hz tone) from an `HttpServer` inside the test process on `127.0.0.1` with Range support, which rejected requests without `X-API-Key: spike` with 401 and recorded every request. One media_kit `Player` was configured with the mpv properties listed under `MediaKitEngine`, plus `ao=null` because CI runners have no sound card (playback runs in real time against the null output). Media were opened as `Playlist([Media(uri, httpHeaders: …), …])`; the next item was replaced with `player.remove(1)` and `player.add(media)`. Every 5 ms the harness sampled `player.state` and mpv's `playlist-playing-pos`, `audio-pts` and `paused-for-cache`; the gap is the largest `wallClockDelta − timelineDelta` between consecutive samples within 500 ms of the index change, with the timeline `index × 3 s + position`. Each two-item case ran five times per platform.

| Platform (CI runner) | 1. Gapless `[A, B]` | 2. Per-item headers; wrong key fails | 3. Index events; replace next |
|---|---|---|---|
| Linux (`ubuntu-latest`, system libmpv 0.41.0, FFmpeg 8.0.1) | Yes, 5/5: position gap 6.1, 6.0, 6.0, 6.0, 6.0 ms; `audio-pts` gap ≤ 0.1 ms; never `paused-for-cache` | **No**: the key reached the server on every request (5/5), but item B's requests carried item A's headers in 5/5 runs; a wrong key fails with `stream.error` "Failed to open …" and no playback (5/5) | Yes: 20 natural transitions reported indices 1 to 20 once each, in order; after `remove(1)` and `add(C)` during item 0, C played next and B was not requested again (5/5) |
| Windows (`windows-latest`, libmpv v0.36.0-403-g652a1dd907 from `media_kit_libs_windows_audio`, FFmpeg n6.0) | Yes, 5/5: position gap 6.3, 6.1, 7.1, 6.5, 6.1 ms; `audio-pts` gap ≤ 0.4 ms; never `paused-for-cache` | **No**: same result as Linux (key on every request 5/5, B carried A's headers 5/5, wrong key fails 5/5) | Yes: same result as Linux |

The position gap across the 20 natural transitions was at most 6.7 ms on Linux and 7.0 ms on Windows.

- Question 2 fails because mpv's playlist prefetch opens the next file with the options in force at that moment: media_kit sets `http-header-fields` from the current item's `Media` in its `on_load` hook, so the prefetch of item 1 uses item 0's headers, and mpv reuses the prefetched stream when item 1 starts.
- The doc 13 fallback does not change this. Appending each file with `loadfile <url> append` and its headers as the per-file option `http-header-fields` gave the same result on both platforms (B carried A's headers in 5/5 runs). mpv 0.38 added an index argument before the options argument of `loadfile`, so the fallback has to choose the argument layout by libmpv version: Linux took `<url> append -1 <options>` and Windows took `<url> append <options>`.
- With `prefetch-playlist=no` and the media_kit `Playlist` path otherwise unchanged, each item carried its own headers (5/5) and the transition stayed gapless on both platforms (position gap ≤ 6.6 ms, `audio-pts` gap ≤ 0.14 ms). Against a loopback server the next file opens within the audio still buffered from the current one. A remote server's latency is not covered by this measurement.
- Measurement notes for the engine: `player.state.position` follows mpv's `time-pos`, which mpv updates about every 100 ms. media_kit sets the position to zero when a file starts, before the new file's first real position arrives. That first position is negative: mpv subtracts the previous item's audio that is still buffered, about −0.46 s. The index change can also arrive before the previous item's last position update. media_kit sets `stream.buffering` true on every file start, so it cannot detect a stall at a transition; mpv's `paused-for-cache` can. `stream.completed` turns true for a moment at the end of each item.
- Package versions: Flutter 3.50.0, `media_kit` 1.2.6, `media_kit_libs_linux` 1.2.1, `media_kit_libs_windows_audio` 1.0.9. No mpv property had to differ from the list under `MediaKitEngine`; `ao=null` was set only for the runners.
- Whether playback is audibly gapless through a real sound device on Windows and Linux cannot be measured on CI and is a human checklist row.

Because question 2 is answered no on both platforms and the fallback also fails it, the `MediaKitEngine` design is not rewritten to the fallback. The choice between keeping prefetch on (shared credential headers, which the transport already guarantees) and turning it off (own headers per item) is made when `MediaKitEngine` is built, using this evidence.

## Spike S3 finding

A minimal Android app was built with the structure this document and [02](02-architecture.md) describe: `main()` creates one `AudioPlayer` and a controller object in the main isolate, then `AudioService.init` registers a `BaseAudioHandler` that holds no state, forwards `play`, `pause`, `stop` and `seek` to the controller and mirrors the player's state to `playbackState` and `mediaItem`. The manifest and `AudioServiceConfig` were those of [10](10-platform-integration.md) (Android, Playback service): `MainActivity` extends `AudioServiceActivity` with `launchMode="singleTask"`, the `AudioService` service with `foregroundServiceType="mediaPlayback"`, the `MediaButtonReceiver`, channel `io.soundspan.app.playback` named "Playback", `androidNotificationOngoing: true`, `androidStopForegroundOnPause: true`, icon `drawable/ic_stat_soundspan`. A bundled 5-second tone played on a loop (no network). Once a second the app logged its process id, a start counter persisted in a file, the playing flag, the accumulated played time and whether the engine was created under an activity or by the playback service; an `adb` driver read those lines. Every question ran on two emulator images.

| Question | Android 14 (API 34, x86_64, `google_apis`) | Android 13 (API 33, x86_64, `google_apis`) |
|---|---|---|
| 1. Playback continues with the screen off, battery unplugged and the device forced into deep idle, engine owned outside the handler | Yes: deep idle state `IDLE` throughout; same process; foreground service still listed; 600.002 s played in 600.000 s; longest stall 9 ms | Yes: deep idle state `IDLE` throughout; same process; foreground service still listed; 600.001 s played in 599.999 s; longest stall 1 ms |
| 2. After a pause (the service leaves the foreground) and a kill of the process (`kill -9`), a media button (`cmd media_session dispatch play`) restarts playback | Yes, 3/3: each time a new process created the engine with no activity, the handler received `play` 17–27 ms after the engine was created, and the position advanced | Yes, 3/3: each time a new process created the engine with no activity, the handler received `play` 8–9 ms after the engine was created, and the position advanced |
| 3. Playback continues when the task is removed while playing (`am stack remove`) | Yes: same process, 59.996 s played in a 60 s window | Yes: same process, 58.986 s played in a 60 s window |

- The media button reached the killed app through the media session service's last media-button receiver on the first try every time; the key-event fallback was never needed. The app never restarted on its own after a kill.
- In a process started by the media button, `main()` runs with no activity and no view. The harness called `AudioService.init` from `main()` before `runApp`, so the handler was registered before any frame; bootstrap step 8 runs it after the first frame, which a process with no view does not produce.
- Package versions: Flutter 3.50.0 (Dart 3.14.0), `audio_service` 0.18.19, `just_audio` 0.10.6, `audio_session` 0.2.4. The debug APK ran without the Flutter tool attached.
- One hour of playback with the screen off on real hardware (vendor battery managers) and a restart by tapping play in the media notification itself cannot be measured on CI and are human checklist rows.

Because questions 1 to 3 are answered yes on both images, the design stands: the engine and `PlaybackController` stay outside the handler, and the handler holds no state.

## Spike S4 finding

A minimal Flutter Windows app (app user model id `io.soundspan.app` set in `main.cpp` as [10](10-platform-integration.md) describes) ran an integration test against `smtc_windows` on a `windows-latest` runner (Visual Studio 18 Build Tools). The test initialised the plugin, enabled play, pause, next and previous, set the playback status to playing, updated metadata (title, artist, album, album artist), the timeline (start 0, end 215 s, position 42 s, seek range 0–215 s, then a position update to 43 s) and a thumbnail given as a `file:///` URI of a local PNG, and subscribed to the button-event stream. A Windows PowerShell 5.1 script then read every session back through `Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager`.

| Question | Answer | Evidence |
|---|---|---|
| 1. Builds with the pinned Flutter | Yes, with Rust present | `flutter build windows --release` exits 0 when the image's Rust toolchain is on `PATH`; the Rust crate compiles in about 37 s |
| 2. No extra toolchain on CI | **No** | With `%USERPROFILE%\.cargo\bin` hidden the build fails: cargokit reports "Precompiled binaries are disabled" and then "rustup not found in PATH". The package ships no precompiled binaries, so every build compiles its Rust crate |
| 3. Initialises and accepts metadata, timeline and thumbnail | **No** as the client resolves it; yes with `flutter_rust_bridge` pinned to 2.11.1 | With the client's resolution (`flutter_rust_bridge` 2.13.0) initialisation throws "smtc_windows's codegen version (2.11.1) should be the same as runtime version (2.13.0)". With `flutter_rust_bridge` 2.11.1 every call completes (initialise 328 ms, each update ≤ 4 ms) and the system reads back the session `io.soundspan.app` as current, with the title, artist and album that were set, status `Playing`, position 43 000 ms and end time 215 000 ms. The read-back reported no thumbnail for the `file:///` URI |
| 4. Button events (media keys, flyout buttons) | Not answerable on CI | No hosted runner can press a system media button; the stream was subscribed and received nothing. Human checklist row |

- Package versions: Flutter 3.50.0, `smtc_windows` 1.1.0 (`flutter_rust_bridge` codegen 2.11.1, cargokit build, no precompiled binaries).
- The system session read-back works on a hosted Windows runner, so a smoke test of the adapter can compare what it set with what `GlobalSystemMediaTransportControlsSessionManager` reports.

Because questions 2 and 3 are answered no, the fallback of [13](13-milestones-and-work-breakdown.md) applies: `smtc_windows` is not a dependency, and the Windows adapter is the in-repo C++/WinRT plugin `client/packages/soundspan_smtc`. It exposes the calls the harness exercised:

- initialise for the process's app user model id, and dispose;
- enable or disable the play, pause, next and previous buttons;
- set the playback status (closed, changing, stopped, playing, paused);
- update metadata as a music item: title, artist, album, album artist;
- update the timeline: start, end, position, minimum and maximum seek time;
- set the thumbnail from a local file (`StorageFile` through `RandomAccessStreamReference.CreateFromFile`, since the URI form left no thumbnail in the read-back);
- a stream of button presses (play, pause, next, previous).
