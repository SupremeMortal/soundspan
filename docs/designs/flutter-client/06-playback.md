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
- **`QueueReducer`** is a pure function `(QueueState, QueueCommand) → QueueState`. All queue rules are tested here with no player.
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
  Future<void> load(EngineSource current, {EngineSource? next, bool autoPlay});
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

The two-slot contract is the smallest surface that still gives gapless playback. It maps cleanly onto both backends and keeps queue edits (reorder, remove, shuffle toggle) out of engine code: an edit that changes what comes next is one `setNext` call.

### `JustAudioEngine` (Android, iOS, macOS, web)

- One `AudioPlayer`. `load` calls `setAudioSources([current, next?], initialIndex: 0, initialPosition: startAt)`.
- `setNext` removes index 1 if present and adds the new source, using the player's playlist mutation calls. The current item is never touched.
- Sources: `AudioSource.uri(uri, headers: headers, tag: queueItemId)` for streams and `AudioSource.file(path, tag: …)` for downloads.
- Events: a `currentIndexStream` change from 0 to 1 with `ProcessingState.ready` is `AdvancedToNext`. The engine then removes the played item so the new current is index 0 again and waits for the controller's next `setNext`. `ProcessingState.completed` is `Completed`. `playbackEventStream` errors and `errorStream` map to `Failed`; `PlayerException.code` and the HTTP status (when available) set `kind`.
- Gapless: ExoPlayer and AVQueuePlayer both transition between adjacent playlist items without a gap when the next item is buffered. Web is best-effort.
- Headers on iOS and macOS are delivered by `just_audio` through a loopback proxy inside the app. The iOS `Info.plist` therefore allows local networking (`NSAllowsLocalNetworking`), which does not weaken transport security for remote hosts. Verify in spike S1.
- Android: `AndroidLoadControl` buffer of 30 s min, 120 s max; `androidApplyAudioAttributes: true`; `handleInterruptions: false` (the controller handles focus itself, see Audio Focus).

### `MediaKitEngine` (Windows, Linux)

- One `Player` from `media_kit` (libmpv), created with `PlayerConfiguration(title: 'soundspan', ready: …)` and video output disabled (`vid=no`).
- mpv properties set once through `NativePlayer.setProperty`: `gapless-audio=yes`, `prefetch-playlist=yes`, `audio-client-name=soundspan`, `cache=yes`, `demuxer-max-bytes=64MiB`, `network-timeout=30`, `volume-max=100`.
- `load` opens `Playlist([Media(uri, httpHeaders: headers), Media(next…)])` with `play: autoPlay`; `setNext` uses `player.remove(1)` and `player.add(media)`.
- Events: `stream.playlist` index change 0 → 1 is `AdvancedToNext`; `stream.completed` true with no next is `Completed`; `stream.error` is `Failed`.
- Position comes from `stream.position` (already throttled by media_kit).
- `MediaKit.ensureInitialized()` is called from the engine factory only on Windows and Linux, so the native library is never loaded elsewhere.

### Engine Conformance Suite

`test/core/playback/engine_conformance.dart` is one parameterized suite run against `FakeEngine` in unit tests and against the real engine for the current platform in `integration_test/engine_conformance_test.dart` (tag `engine`), using short tone files served by a local `shelf` server that checks headers and Range.

Required behaviours: load and play; pause and resume keep position; seek within buffered and unbuffered ranges; `setNext` then natural end produces exactly one `AdvancedToNext` and no audible gap larger than 20 ms (measured from the position streams, verified by ear in the manual matrix); `setNext(null)` then natural end produces `Completed`; replacing next twice before the transition plays only the last one; a 404 source produces `Failed(notFound)`; a 401 produces `Failed(unauthorized)`; headers reach the server; a local file plays with the network disabled; `stop` then `load` works; `dispose` releases the device.

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

Rules, each with unit tests:

- **Play order** is `shuffleOrder` if set, else the identity. `current = items[playOrder[cursor]]`. `upNext = items[playOrder[cursor + 1]]`, wrapping when `repeat == all`, and equal to `current` when `repeat == one`.
- **Shuffle on:** keep the current item at the cursor, shuffle the remaining indices with Fisher–Yates using a seeded `Random` (the seed is injected, so tests are deterministic). Already-played items keep their order behind the cursor.
- **Shuffle off:** drop `shuffleOrder`; the cursor becomes the current item's canonical index.
- **Play next:** insert after the current item in canonical order and, when shuffled, at `cursor + 1` in the permutation.
- **Append:** add at the end of the canonical list and, when shuffled, at a random position after the cursor.
- **Remove current:** advance to the next item first, then remove.
- **Previous:** if position > 3 s, seek to zero; otherwise move the cursor back (wrapping only with `repeat == all`).
- **Item finished:** `repeat one` → replay; end of queue with `repeat off` → stop, cursor stays on the last item, position zero.
- **Maximum size:** 5,000 items. "Play" on a larger collection queues the first 5,000 in play order and says so.
- Every `QueueItem` has a client-generated `queueItemId`, so the same track can appear twice and edits address entries, not tracks.

After every reducer step the controller compares the new `upNext` with what the engine has preloaded and calls `setNext` if they differ.

## Source Resolution

`SourceResolver.resolve(QueueItem) → Future<EngineSource>`:

1. `DownloadStore.completedFile(itemKey)` → `file://` URI, no headers. The file's existence is checked; a missing file marks the download `missing` and falls through.
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
| Windows | `smtc_windows` behind `SmtcControls` | System Media Transport Controls: buttons, metadata, timeline, thumbnail. Subject to spike S4. |

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
