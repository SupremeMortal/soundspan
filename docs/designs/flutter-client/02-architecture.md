# 02. Architecture

Status: design phase.

## Layers and Allowed Dependencies

```
features/<f>/ui        widgets, screens, view models (Riverpod notifiers)
        │  reads providers only
features/<f>/domain    entities, value types, use cases, repository interfaces   (pure Dart)
        ▲  implemented by
features/<f>/data      repositories: soundspan_api + drift DAOs → domain entities
        │
core/*                 cross-feature services: playback, downloads, sync, realtime, auth, storage
        │
platform/*             interfaces with io and web implementations
packages/soundspan_api transport and wire models (pure Dart)
```

Rules (enforced by `tool/check_imports.dart`, see [01](01-toolchain-and-repository.md)):

- `ui` depends on `domain` and on providers. It never sees a wire model, a drift row, or dio.
- `domain` depends on nothing but Dart and `collection`.
- `data` maps wire models and drift rows to domain entities. Mapping functions live next to the repository and are unit tested.
- `core` services may depend on each other only in this direction: `storage` ← `auth` ← `profile` ← (`sync`, `downloads`, `realtime`) ← `playback`. `playback` may call `downloads` (to resolve a local file) and `sync` (to report plays); nothing in `core` imports `features`.

## Domain Model (shared)

Defined in `lib/shared/domain/`. All are `freezed` value types.

```dart
/// Opaque server identifier of a playable track. Never parsed.
extension type const PlaybackId(String value) {}

/// What the client shows and sends back as `metadata` on every write.
class TrackMeta {
  final String title;
  final String artist;
  final String album;
  final int durationSec;
  final String? artworkRef;   // value to pass to the cover-art endpoint
  final String? isrc;
}

class Track {
  final PlaybackId? playbackId;   // null means "not playable"; row is shown disabled
  final TrackMeta meta;
  final String? albumId;
  final String? artistId;
  final Loudness? loudness;       // loudnessLufs, truePeakDb, albumLoudnessLufs, albumTruePeakDb
  final Preference preference;    // liked | disliked | neutral
  final int? discNumber;
  final int? trackNumber;
}

sealed class QueueItem {
  String get queueItemId;         // client-generated UUID, unique per queue entry
}
class TrackQueueItem extends QueueItem { final Track track; final QueueContext context; }
class EpisodeQueueItem extends QueueItem { final Episode episode; final Podcast podcast; }

/// Where the item was queued from. Drives loudness "auto" mode and playlist radio.
enum QueueContextKind { album, playlist, artist, mix, radio, search, library, single }
```

The domain `Track` has no source field. Server fields `streamSource`, `tidalTrackId`, `youtubeVideoId`, `provider`, and `mediaSource` are not declared on the wire models either, so they cannot leak in.

## Riverpod Structure

Two provider scopes.

**Root scope** (lives for the whole process):

| Provider | Type | Notes |
|---|---|---|
| `appDatabaseProvider` | `AppDatabase` | Profiles and app settings |
| `secretStoreProvider` | `SecretStore` | `flutter_secure_storage` or the web implementation |
| `profileRepositoryProvider` | `ProfileRepository` | CRUD over profiles + secrets |
| `activeProfileIdProvider` | `Notifier<String?>` | Persisted in app settings |
| `appSettingsProvider` | `AppSettings` | Theme mode, locale |
| `reachabilityProvider` | `ReachabilityController` | See [07](07-offline-and-downloads.md) |
| `appLoggerProvider` | `AppLogger` | |

**Profile scope** (one per signed-in profile; rebuilt when the active profile changes):

```dart
/// Throws if read outside a ProfileScope.
@Riverpod(keepAlive: true, dependencies: [])
ProfileContext profileContext(Ref ref) => throw UnimplementedError();

class ProfileScope extends ConsumerWidget {
  const ProfileScope({required this.profile, required this.child, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ProviderScope(
        key: ValueKey(profile.id),               // new key ⇒ old container disposed
        overrides: [profileContextProvider.overrideWithValue(ProfileContext(profile))],
        child: child,
      );
}
```

Everything that touches a server depends, directly or transitively, on `profileContextProvider`: the API client, both per-profile databases, the image cache manager, repositories, `PlaybackController`, `DownloadController`, `Outbox`, `SocketClient`. Changing the `ValueKey` disposes the whole graph, and each provider's `ref.onDispose` closes its resource (stop playback, close databases, disconnect the socket, cancel timers). This is what makes "switching servers swaps the whole data layer" true by construction instead of by discipline.

Riverpod's scoped-provider rule applies: every provider that depends on a scoped provider declares it in `dependencies:`. The generator lint enforces this.

`ProfileContext` carries `profile` (id, base URL, user id, auth kind, device id), `paths` (the profile's directories), and nothing mutable.

### Background Entry Points

`audio_service` callbacks, `background_downloader` callbacks, and deep links can arrive when no widget tree exists (Android service restarted by the OS). `bootstrap.dart` therefore owns a top-level `ProviderContainer`; the widget tree attaches to it with `UncontrolledProviderScope`. Profile-scoped services needed in the background (`PlaybackController`, `DownloadController`) are obtained through `ProfileRuntime`, a root-scope object that holds the active profile's nested `ProviderContainer` and recreates it when the active profile changes. `ProfileScope` in the widget tree attaches to that same nested container, so UI and background code share one instance of every service.

## Bootstrap Sequence

`bootstrap()` runs these steps in order. Steps 1–6 complete before the first frame; the budget is 300 ms on a mid-range Android device.

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Install error hooks: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and a guarded zone. All route to `AppLogger`. Nothing is sent off the device.
3. Resolve `AppPaths` (`getApplicationSupportDirectory`, `getApplicationCacheDirectory`); on web this is a no-op.
4. Open `AppDatabase` and read `AppSettings` and the active profile id.
5. Desktop only: `windowManager.ensureInitialized()`, restore window bounds, register the tray.
6. Create the root `ProviderContainer` with the opened database and paths as overrides.
7. `runApp`. The router's redirect sends the user to `/connect` if there is no active profile, otherwise to the shell.
8. After the first frame, in parallel and without blocking UI:
   - `AudioService.init` (or the platform's media-controls adapter) and audio-session configuration.
   - `FileDownloader` start-up: re-attach to tasks that ran while the app was dead.
   - `Reachability.start()`.
   - Capability refresh for the active profile ([04](04-auth-and-server-profiles.md)).
   - Outbox replay and download reconciliation.
   - Deep-link listener (`app_links`), including the link that launched the app.

Playback restore (showing the last queue, paused) reads only `state.db`, so the mini player appears on the first frame without network.

## Routing

`go_router` with one `StatefulShellRoute.indexedStack` for the four top-level destinations, so each tab keeps its own navigation stack and scroll position.

```
/connect                         Add server: address entry
/connect/probe                   Probe progress and result
/connect/sign-in                 Password, device-link code, API key
/connect/scan                    QR scanner (Android, iOS, macOS, web)
/                                Shell
├── /home
├── /search?q=
├── /library/:tab                tab ∈ playlists | artists | albums | songs | downloads
├── /podcasts
│   └── /podcasts/:podcastId
├── /album/:albumId              Pushed inside the current branch
├── /artist/:artistId
├── /playlist/:playlistId        `liked` is a reserved id for Liked Songs
├── /mix/:mixId                  M4
└── /listen-together             M4
/now-playing                     Root navigator, full-screen (compact and medium only)
/settings                        Root navigator
├── /settings/servers
├── /settings/playback
├── /settings/storage
├── /settings/appearance
└── /settings/about
```

- Detail routes (`/album/…`) are declared once and attached to every branch, so opening an album from Search keeps the Search tab selected.
- Guards (`redirect`): no active profile → `/connect`; profile in `signedOut` state → `/connect/sign-in` with the server prefilled; server below `minServer` → `/connect/probe` showing the update message.
- Deep links: `soundspan://link?code=…&server=…` maps to `/connect/probe` with the code carried as an extra. `soundspan://album/<id>`, `artist/<id>`, `playlist/<id>` open the matching route in the active profile.
- On desktop and web the route is reflected in the window title and, on web, the URL (path strategy).

## Adaptive Layout

One enum decides the shell; screens read it from an `InheritedWidget`, never from `MediaQuery` width directly.

```dart
enum WindowClass { compact, medium, expanded }   // < 600, 600–1023, ≥ 1024 logical px

WindowClass windowClassOf(Size size) => switch (size.width) {
  < 600 => WindowClass.compact,
  < 1024 => WindowClass.medium,
  _ => WindowClass.expanded,
};
```

| | compact | medium | expanded |
|---|---|---|---|
| Navigation | Bottom bar (4 destinations) | Navigation rail | Sidebar, 256 px, with playlist list |
| Player | Mini player above the bottom bar; `/now-playing` full screen | Mini player at the bottom; `/now-playing` full screen | Persistent player bar, 96 px; now-playing opens as an overlay over the content area |
| Queue and lyrics | Tabs inside now-playing | Tabs inside now-playing | Right-hand panel, 360 px, toggled from the player bar |
| Detail navigation | Push | List–detail two-pane where it helps (Library → Album) | Push inside the content area |
| Input | Touch | Touch, optional keyboard | Pointer, keyboard shortcuts, context menus, drag and drop |

Input mode is independent of window class: a desktop window resized to 500 px wide gets the compact layout but keeps hover states, context menus, and shortcuts. Pointer features key off `defaultTargetPlatform` being desktop or a mouse being connected, not off width.

## Error Model

- `soundspan_api` throws only subclasses of the sealed `ApiException` ([03](03-api-layer.md)).
- Repositories let `ApiException` propagate. They do not catch and return null.
- View models are Riverpod `AsyncNotifier`s; errors surface as `AsyncError` and screens render them through one shared `ErrorView` that switches on the exception type:

| Exception | Screen shows |
|---|---|
| `Unauthenticated` | Nothing; the session controller moves the profile to `signedOut` and the router redirects |
| `Offline` | Cached content if any, with an "Offline" banner; else the offline empty state |
| `FeatureDisabled` | The screen is removed from navigation at the next capability refresh; meanwhile a neutral "Not available on this server" |
| `RateLimited` | Automatic retry after the delay; a message only if the retry also fails |
| `ServerError`, `Upstream` | Message + Retry |
| `NotFound` | "This item is no longer available" |

- User-triggered writes (like, add to playlist) are optimistic: the view model updates local state, enqueues the operation in the outbox, and rolls back with a snackbar only on a permanent failure ([07](07-offline-and-downloads.md)).
- No `catch (e)` without rethrow outside `bootstrap.dart`, the outbox worker, and engine adapters; each of those logs and converts to a typed state.

## Logging

`lib/core/logging/app_logger.dart` wraps `package:logging`. It is the only logging entry point (`avoid_print` is an error).

```dart
final _log = AppLogger.scope('Downloads');      // scope is a structured field, not a message prefix
_log.info('task finished', {'bytes': size});
```

- Sinks: debug console in debug builds; a rolling file (`<appSupport>/logs/app.<n>.log`, 5 files × 1 MB) on native targets; an in-memory ring (500 entries) on web.
- Redaction happens in the logger, before any sink: values of keys named `token`, `refreshToken`, `apiKey`, `password`, `authorization`, `x-api-key`; any `?token=` query value; the host and path prefix of the active profile's base URL (replaced with `<server>`).
- `Settings → About → Export logs` zips the rolling files through the platform share or save dialog.
- Levels: `fine` for per-request detail (off in release), `info` for lifecycle, `warning` for recovered failures, `severe` for unrecovered ones.

## Platform Seams

Each seam is an abstract class in `lib/platform/<name>/<name>.dart` with `_io.dart` and `_web.dart` implementations selected by a conditional import, plus per-OS branches inside `_io` where needed. Features and `core` import only the interface.

| Seam | Interface | Native implementation | Web implementation |
|---|---|---|---|
| Paths | `AppPaths` | `path_provider` | None (no files) |
| Secrets | `SecretStore` | `flutter_secure_storage` | Memory + `sessionStorage` |
| Database opener | `DatabaseOpener` | `drift_flutter` native | drift WASM worker |
| Player engine factory | `PlayerEngineFactory` | `JustAudioEngine` or `MediaKitEngine` by OS | `JustAudioEngine` |
| Media controls | `MediaControls` | `audio_service` (Android, iOS, macOS, Linux via MPRIS), SMTC adapter (Windows) | `audio_service` (Media Session API) |
| Downloader | `Downloader` | `background_downloader` | `UnsupportedDownloader` (feature hidden) |
| Stream credentials | `StreamAuth` | Header | `?token=` query |
| Window and tray | `DesktopShell` | `window_manager`, `tray_manager` | No-op |
| QR scanner | `QrScanner` | `mobile_scanner` (Android, iOS, macOS); unavailable on Windows and Linux | `mobile_scanner` |
| Deep links | `DeepLinks` | `app_links` | URL on load |
| Notifications | `LocalNotifications` | `flutter_local_notifications` | No-op |
| Capabilities | `PlatformCapabilities` | Constants per OS | Constants |

`PlatformCapabilities` is the only place UI asks "can this platform do X": `canDownload`, `canScanQr`, `hasTray`, `hasBackgroundPlayback`, `supportsApiKeyStreaming`. Screens hide features by capability, never by `Platform.isX`.
