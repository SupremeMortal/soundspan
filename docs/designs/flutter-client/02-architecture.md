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
  final String? libraryTrackId;   // the track id the server sent; for lyrics and vibe lookups only
}

sealed class QueueItem {
  String get queueItemId;         // client-generated UUID, unique per queue entry
}
class TrackQueueItem extends QueueItem { final Track track; final QueueContext context; }
class EpisodeQueueItem extends QueueItem { final Episode episode; final Podcast podcast; }

/// Where the item was queued from. Drives loudness "auto" mode and playlist radio.
enum QueueContextKind { album, playlist, artist, mix, radio, search, library, single }
class QueueContext { final QueueContextKind kind; final String? id; final String? title; }
```

`libraryTrackId` is the `id` the server sent on the track payload. It is passed to `GET /lyrics/:trackId` and the vibe lookups, says nothing about where the track comes from, and is never used to decide playability or to branch.

Browse entities carry only the fields the screens of [09](09-ui-and-design-system.md) show: `Album` (id, title, artist name and id, year, artwork ref, track count, release type, preference), `AlbumDetail` (album, tracks, owned), `Artist` (id, name, artwork ref), `ArtistDetail` (artist, albums, top tracks, similar artists, biography, genres) and `SimilarArtist` (name, artwork ref, library id when the library holds the artist). `Album.trackCount` is set only when the server sent the tracks, `Album.releaseType` stays empty while the library endpoints send none, and `Album.preference` comes from the `preference` field of `GET /library/albums` and `GET /library/albums/:id` (the requesting user's state, read from the track preferences that `POST /library/albums/:id/preference` writes: `liked` or `disliked` when every library track of the album is, otherwise `neutral`); an absent or unknown value is `neutral`, and an artist's discography albums, whose payload carries no preference, stay `neutral` until a like sent from this client is confirmed. Query values (`LibraryOrigin`, and the sort and filter enums of the artists, albums and tracks lists) carry exactly the server's parameter values. The network half of the library repositories, `lib/shared/data/library/library_remote_source.dart`, maps the generated models to these types with the mappers beside it: a wire track without `playbackId` becomes a `Track` with `playbackId == null`, a missing or unknown preference is `neutral` (tracks of the liked list are `liked`), and timestamps are UTC.

The remaining browse sources have the same shape (generated client in the constructor, domain values out, `ApiException` propagates, no providers): `PlaylistRemoteSource`, `SearchRemoteSource` and `HomeRemoteSource` under `lib/shared/data/{playlist,search,home}/`. Their types are `PlaylistSummary` (id, name, track count, owner and public flags, up to four cover refs from the server's cover seeds), `PlaylistItem` (item id, sort, track, `isPlayable`, the server's message), `PlaylistDetail` (summary, items in ascending sort; an item the server sends without a track is left out), `MixSummary` (id, name, description, cover refs), `PodcastSummary` (id, title, author, artwork ref, and the feed URL and iTunes id a subscribe request names it by), `RecentItem` (an artist or a podcast; audiobook entries are dropped because audiobooks are not in v1), `SearchHit` (a track, album, artist or podcast), `LibrarySearchResults` (artists, albums, tracks, podcasts; the server's `remoteTracks` and `remoteAlbums` follow the library tracks and albums in server order) and `DiscoverResults` (hits in server order across kinds, and `AliasInfo`). The playlists list has no total, so its page's `total` is null. No mapped value carries a source or provider; a remote result is an ordinary `Track` or `Album`, and a result without `playbackId` is a non-playable `Track`.

Podcasts have their own feature data layer under `lib/features/podcasts/`: `PodcastRepository` (`domain/`) serves the subscribed podcasts and a `PodcastDetail` (the podcast and its episodes, newest first as the server orders them) as `Stream<Cached<T>>` over the generated `PodcastsClient`, and makes the direct calls `subscribe` (a `PodcastRef`: a feed URL or an iTunes id; `PodcastRef.fromSummary` maps a top-list or search `PodcastSummary`; it returns the server's id of the podcast, so the caller can open it), `unsubscribe` and `postProgress`. `Podcast` adds the description, the episode count and, on a detail, the feed URL it can be subscribed to again by, and `Episode` the description and the user's `EpisodeProgress` (position in seconds, finished). Subscribing and unsubscribing are not outbox operations; while the server is not reachable they throw `Offline`.

The writes M1 needs outside playback are thin typed calls of the same shape, one request each, with no caching, queuing or optimistic state (the outbox of [07](07-offline-and-downloads.md) adds those): `SettingsRepository` (`lib/core/profile/settings/`, `fetch` and `update` of `UserSettings`: `playbackQuality` verbatim, `loudnessMode` as `LoudnessMode { off, track, album, auto, unknown }`, `maxCacheSizeMb`; `update` sends only the fields given and never sends `unknown`), `PreferenceRemoteSource` (`lib/core/sync/data/`, track preferences by `playbackId` with `metadata` from `TrackMeta`, album preferences by album id; `liked`, `disliked` and `neutral` map to the `signal` values `thumbs_up`, `thumbs_down` and `clear`, and the answer is the `state` the server returns; only the outbox handlers call it, and features like through `PreferenceRepository` beside it, which enqueues `thumbs_up` or `clear`), and the playlist writes of `PlaylistRemoteSource` (`create` answers an owned, empty `PlaylistSummary`; `update`, `delete`, `addItem`, which answers the new or already-present `PlaylistItem`, `removeItem`, which sends the `playbackId` as one percent-encoded path segment, and `reorder`, which sends the complete order as `playbackIds`). `LibraryRemoteSource.shuffledTracks` reads `GET /library/tracks/shuffle`. The settings and preference repositories have profile-scoped providers.

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
| `appLoggerProvider` | `AppLogger` | `Provider.family` keyed by scope: `ref.read(appLoggerProvider('Downloads'))` |

**Profile scope** (one per signed-in profile; rebuilt when the active profile changes):

```dart
/// Throws if read outside a profile scope. ProfileRuntime overrides it in
/// each profile container.
final profileContextProvider = Provider<ProfileContext>(
  (ref) => throw StateError('read outside a profile scope'),
  dependencies: const [],
);

class ProfileScope extends ConsumerWidget {
  const ProfileScope({required this.child, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(profileRuntimeProvider);
    return ValueListenableBuilder(
      valueListenable: runtime.state,
      builder: (context, state, _) => AnimatedSwitcher(   // 150 ms fade-in; none with reduced motion
        child: state is ProfileRuntimeActive
            ? UncontrolledProviderScope(
                key: ValueKey(state.profileId),
                container: runtime.container!,          // the runtime's nested container
                child: child,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
```

Everything that touches a server depends, directly or transitively, on `profileContextProvider`: the API client, both per-profile databases, the image cache manager, repositories, `PlaybackController`, `DownloadController`, `Outbox`, `SocketClient`. `ProfileRuntime` owns one nested `ProviderContainer` per active profile (see Background Entry Points); switching profiles runs the old container's asynchronous closers, disposes it, and creates the next one, and each provider's `ref.onDispose` closes its resource (stop playback, close databases, disconnect the socket, cancel timers). This is what makes "switching servers swaps the whole data layer" true by construction instead of by discipline.

`ref.onDispose` is synchronous, so a resource that closes asynchronously (a database, the socket, the engine, the downloader) also registers its close with the profile-scoped `ProfileDisposer`. `ProfileRuntime` awaits the registered closers in reverse registration order before it disposes the container; a closer that fails is logged and the others still run.

`ProfileScope` shows only the active profile's subtree: when a switch starts, the old subtree is removed at once (nothing of it builds again), and the new one fades in.

Riverpod's scoped-provider rule applies: every provider that depends on a scoped provider declares it in `dependencies:`. Profile-scoped providers are declared by hand with `dependencies:` listing every scoped provider they read.

The UI reads repositories through the profile-scoped providers in `lib/shared/providers/repositories.dart` (`libraryRepositoryProvider`, `playlistRepositoryProvider`, `homeRepositoryProvider`, `searchRepositoryProvider`), typed by the repository interface. They are `FutureProvider`s because the profile's `cache.db` opens asynchronously.

`ProfileContext` carries `profile` (id, base URL, user id, auth kind, device id), `paths` (the profile's directories), and nothing mutable.

### Background Entry Points

`audio_service` callbacks, `background_downloader` callbacks, and deep links can arrive when no widget tree exists (Android service restarted by the OS). `bootstrap.dart` therefore owns a top-level `ProviderContainer`; the widget tree attaches to it with `UncontrolledProviderScope`. Profile-scoped services needed in the background (`PlaybackController`, `DownloadController`) are obtained through `ProfileRuntime`, a root-scope object that holds the active profile's nested `ProviderContainer` and recreates it when the active profile changes. `ProfileScope` in the widget tree attaches to that same nested container, so UI and background code share one instance of every service.

## Bootstrap Sequence

`bootstrap()` runs these steps in order. Steps 1–6 complete before the first frame; the budget is 300 ms on a mid-range Android device.

1. `WidgetsFlutterBinding.ensureInitialized()`, then cap the decoded-image memory cache (`configureImageMemoryCache`, [05](05-local-data.md#image-cache)).
2. Install error hooks: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and a guarded zone. All route to `AppLogger`. Nothing is sent off the device.
3. Resolve `AppPaths` (`getApplicationSupportDirectory`, `getApplicationCacheDirectory`); on web this is a no-op.
4. Open `AppDatabase` and read `AppSettings` and the active profile id.
5. Desktop only: `WindowStateController.start()` attaches `DesktopShell` to the window, sets the minimum size, restores the window bounds and maximized state, and shows the window; register the tray.
6. Create the root `ProviderContainer` with the opened database and paths as overrides.
7. `runApp`. The router's redirect sends the user to `/connect` if there is no active profile, otherwise to the shell.
8. After the first frame, in parallel and without blocking UI:
   - `AudioService.init` (or the platform's media-controls adapter) and audio-session configuration.
   - `FileDownloader` start-up: re-attach to tasks that ran while the app was dead.
   - `Reachability.start()`.
   - Capability refresh for the active profile ([04](04-auth-and-server-profiles.md)).
   - Outbox replay and download reconciliation; `startDownloads` starts the active profile's `DownloadScheduler` where `canDownload` is true.
   - Cache pruning of the active profile's `cache.db` ([05](05-local-data.md#pruning)).
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
├── /explore                     M4, `discovery`: pushed inside the current branch like a detail
└── /listen-together             M4
/now-playing                     Root navigator, full-screen (compact and medium only)
/settings                        Root navigator
├── /settings/servers
├── /settings/playback
├── /settings/storage
├── /settings/appearance
├── /settings/desktop            Listed on desktop platforms and the web
└── /settings/about
```

- Detail routes (`album/:albumId`, `artist/:artistId`, `playlist/:playlistId`) are declared once, in a function, and attached as children of every branch root, so opening an album from Search keeps the Search tab selected. go_router cannot match one path in four branches, so their real locations are `/<branch root>/album/:albumId` and so on: `/home/album/42`, `/search/album/42?q=…`, `/library/<tab>/album/42`, `/podcasts/album/42`. The top-level `/album/:albumId`, `/artist/:artistId` and `/playlist/:playlistId` (the form deep links use) redirect into the currently selected branch, or Home when none was shown yet. Screens open details through `DetailNavigation` (`openAlbum(context, id)`, `openArtist`, `openPlaylist`) and never build these paths themselves. A branch holds a stack of details: from a branch root, `DetailNavigation` goes to `/<branch root>/<kind>/<id>`; from a detail, it pushes the top-level path, which the same redirect sends into the selected branch, so the new detail lands on that branch's navigator above the previous one (album → artist → album) and Back walks the stack in reverse. The selected destination stays the same, switching branches and back shows the top of the stack, and selecting the current destination again pops the whole stack. `DetailNavigation.openLocation(router, '/album/42')` applies the same rule to a top-level path, for callers without a `BuildContext` such as the deep-link router; a top-level path given to `GoRouter.go` (a URL typed into the browser) replaces the branch's location. The router sets `GoRouter.optionURLReflectsImperativeAPIs`, so the browser URL, like the window title, shows the top detail.
- `explore` is attached beside the detail routes under every branch root, and the top-level `/explore` redirects into the selected branch in the same way (`/home/explore`, `/podcasts/explore`); screens open it with `DetailNavigation.openExplore(context)`. While the server has `discovery` off the route renders "Not available on this server".
- `/` redirects to `/home`; `/library` and an unknown tab redirect to `/library/playlists`. Selecting the current destination again pops its branch to the root.
- Guards (`redirect`): no active profile → `/connect`; profile in `signedOut` state → `/connect/sign-in?profile=<id>` with the server prefilled; server below `minServer` → `/connect/probe` showing the update message. `/connect/**` is always reachable, so a second server can be added. The router re-runs the guards when `ProfileRuntime.state` changes and when the active profile's `SessionController` signs out.
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
| Queue and lyrics | Sheets over now-playing | Sheets over now-playing; beside the controls in landscape | Right-hand panel, 360 px, toggled from the player bar |
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
- `Settings → About → Export logs` goes through the `LogExporter` seam (`lib/platform/log_export/`). On native targets it flushes the file sink, zips every `app.<n>.log` into a temporary `soundspan-logs-<yyyyMMdd-HHmmss>.zip` (time from the `Clock`), and hands it to the share sheet on Android and iOS or copies it to the path a save dialog answers on Windows, macOS and Linux; the temporary zip is then deleted. On web it downloads the ring's entries as `soundspan-logs-<yyyyMMdd-HHmmss>.txt`, one JSON object per line, as the file sink writes them. Entries were redacted when logged, and the bundle holds nothing but log entries.
- A sink that throws does not reach the caller: the logger reports the first failure of each sink through `dart:developer` and keeps delivering to the other sinks.
- Levels: `fine` for per-request detail (off in release), `info` for lifecycle, `warning` for recovered failures, `severe` for unrecovered ones.

## Platform Seams

Each seam is an abstract class in `lib/platform/<name>/<name>.dart` with `_io.dart` and `_web.dart` implementations selected by a conditional import, plus per-OS branches inside `_io` where needed. Features and `core` import only the interface.

| Seam | Interface | Native implementation | Web implementation |
|---|---|---|---|
| Paths | `AppPaths` | `path_provider` | None (no files) |
| Secrets | `SecretStore` | `flutter_secure_storage` | Memory + `sessionStorage` |
| Database opener | `DatabaseOpener` | `drift_flutter` native | drift WASM worker |
| Player engine factory | `createPlayerEngine()` (`lib/platform/player_engine/`) | `JustAudioEngine` or `MediaKitEngine` by OS | `JustAudioEngine` |
| Audio session | `AudioSessionGateway` (`lib/platform/audio_session/audio_session_gateway.dart`) | `audio_session` (Android, iOS, macOS); no-op on Windows and Linux | No-op (focus always granted, no events) |
| Media controls | `createMediaControls()` (`lib/platform/media_controls/`) returning a `MediaControls` | `audio_service` (Android, iOS, macOS, Linux via MPRIS), SMTC adapter (Windows) | `audio_service` (Media Session API) |
| Downloader | `Downloader` | `background_downloader` | `UnsupportedDownloader` (feature hidden) |
| Disk space | `DiskSpace` (`freeBytes(path)`, null when unknown) | `disk_space_2` (Android, iOS, Windows, Linux); null on macOS, which it does not cover | `UnknownDiskSpace` (null) |
| Media files | `MediaFiles` (`delete(path)`; a missing file is not an error) | `dart:io` | No-op (no files) |
| Stream credentials | `StreamAuth` | Header | `?token=` query |
| Window and tray | `DesktopShell` | `window_manager`, `tray_manager` | No-op |
| QR scanner | `QrScanner` | `mobile_scanner` (Android, iOS, macOS); unavailable on Windows and Linux | `mobile_scanner` |
| Deep links | `DeepLinks` | `app_links` (Android, iOS, macOS); launch arguments and single-instance forwarding (Windows, Linux) | `?link=&server=` on load |
| Notifications | `LocalNotifications` | `flutter_local_notifications` | No-op |
| Connectivity | `ConnectivitySource` | `connectivity_plus` | `connectivity_plus` |
| Capabilities | `PlatformCapabilities` | Constants per OS | Constants |
| Persistent log sink | `createPersistentLogSink` (returns a `LogSink`) | `RollingFileLogSink` | `RingLogSink` |
| Log export | `LogExporter` | Zip through `share_plus` (Android, iOS) or a `file_selector` save dialog (desktop) | Download of the ring as text |

`PlatformCapabilities` is the only place UI asks "can this platform do X": `canDownload`, `canScanQr`, `hasTray`, `hasBackgroundPlayback`, `supportsApiKeyStreaming`, `isDesktop`, `allowsPublicCleartextHttp` (false on iOS and macOS, where App Transport Security blocks a public `http://` server), and `hasMobileData` (the device can be on a mobile data connection, so `Settings → Playback` shows a separate quality for it). Screens hide features by capability, never by `Platform.isX`.

| | Android | iOS | macOS | Windows, Linux | Web |
|---|---|---|---|---|---|
| `canDownload` | yes | yes | yes | yes | no |
| `canScanQr` | yes | yes | yes | no | yes |
| `hasTray` | no | no | no (the Dock keeps the app) | yes | no |
| `hasBackgroundPlayback` | yes | yes | yes | yes | no |
| `supportsApiKeyStreaming` | yes | yes | yes | yes | no |
| `isDesktop` | no | no | yes | yes | no |
| `allowsPublicCleartextHttp` | yes | no | no | yes | yes |
| `hasMobileData` | yes | yes | no | no | no |
