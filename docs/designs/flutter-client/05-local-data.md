# 05. Local Data

Status: design phase.

## Files on Disk (native targets)

```
<appSupport>/                                   # getApplicationSupportDirectory()
├── app.db                                      # AppDatabase: profiles, app settings
├── logs/app.0.log … app.4.log
└── profiles/<profileId>/
    ├── state.db                                # StateDatabase: durable user state
    ├── media/<sha1(playbackId)[0:2]>/<sha1(playbackId)>.<ext>
    ├── media/<…>.part                          # Transfer in progress
    └── art/<sha1(ref)>.img                     # Artwork pinned for downloaded items and OS media controls

<appCache>/                                     # getApplicationCacheDirectory(); the OS may purge it
└── profiles/<profileId>/
    ├── cache.db                                # CacheDatabase: disposable server data
    └── images/                                 # flutter_cache_manager store
```

- File names are derived from a hash because a `playbackId` is opaque and must never be interpreted, even as a file name. The extension comes from the response `Content-Type` (`audio/mpeg` → `mp3`, `audio/flac` → `flac`, `audio/mp4` → `m4a`, `audio/ogg` → `ogg`, `audio/webm` → `webm`, otherwise `bin`); engines sniff content, so the extension is a convenience for debugging.
- The two-character fan-out keeps directories small on large libraries.
- `media/` is excluded from cloud backup: iOS and macOS set `NSURLIsExcludedFromBackupKey` on the directory; Android lists it under `<exclude>` in `data_extraction_rules.xml`.
- On web there are no files. `app.db` and both profile databases are drift WASM databases named `app`, `p_<profileId>_state`, `p_<profileId>_cache`.

## Why Two Databases per Profile

| | `cache.db` | `state.db` |
|---|---|---|
| Contents | Copies of server data | Things that exist only on this device, or that the server has not received yet |
| If deleted | Refetched | Downloads orphaned, pending writes lost |
| Location | OS cache directory | App support directory |
| Migration failure | Delete and recreate | Must migrate; tested per version |
| Size bound | Yes, pruned | Small |

Separating them lets the cache schema change freely and makes "Clear cache" a file delete.

## `AppDatabase` (`app.db`)

```dart
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get baseUrl => text()();
  TextColumn get displayName => text()();
  TextColumn get userId => text()();
  TextColumn get username => text()();
  TextColumn get userDisplayName => text().nullable()();
  TextColumn get role => text()();
  TextColumn get authKind => textEnum<AuthKind>()();
  TextColumn get deviceId => text()();
  DateTimeColumn get credentialCreatedAt => dateTime()();
  DateTimeColumn get credentialExpiresAt => dateTime().nullable()();
  TextColumn get serverVersion => text().nullable()();
  TextColumn get features => text().nullable()();          // JSON
  DateTimeColumn get featuresFetchedAt => dateTime().nullable()();
  TextColumn get state => textEnum<ProfileState>()();
  DateTimeColumn get lastUsedAt => dateTime()();
  @override Set<Column> get primaryKey => {id};
  @override List<Set<Column>> get uniqueKeys => [{baseUrl, userId}];
}

class AppSettings extends Table {            // key/value
  TextColumn get key => text()();
  TextColumn get value => text()();          // JSON-encoded
  @override Set<Column> get primaryKey => {key};
}
```

App settings keys: `activeProfileId`, `themeMode` (`system|dark|light`), `locale`, `window.bounds`, `window.maximized`, `closeToTray`.

## `StateDatabase` (`state.db`)

| Table | Purpose | Key columns |
|---|---|---|
| `device_settings` | Per-profile, per-device settings (key/value) | `key` |
| `queue_snapshot` | The persisted queue, one row per item | `position` |
| `queue_meta` | Single row: current item id, position ms, shuffle, repeat, context, updatedAt | `id = 1` |
| `download_collections` | What the user asked to keep offline | `(kind, refId)` |
| `download_items` | One row per track or episode file | `itemKey` |
| `download_membership` | Which collections need which items | `(kind, refId, itemKey)` |
| `outbox` | Pending writes | `seq` autoincrement |
| `play_sessions` | The play in progress (`playbackId`, metadata, `playedAt`, `listenedMs`), kept so a kill does not lose it | `sessionId` |
| `search_history` | Recent searches | `query` |

```dart
class DownloadItems extends Table {
  TextColumn get itemKey => text()();              // "t:<playbackId>" or "e:<podcastId>:<episodeId>"
  TextColumn get mediaType => textEnum<MediaType>()();
  TextColumn get metaJson => text()();             // TrackMeta / episode meta: enough to render and play offline
  TextColumn get quality => text().nullable()();   // As resolved by the server
  TextColumn get status => textEnum<DownloadStatus>()();
  TextColumn get taskId => text().nullable()();    // background_downloader task id
  TextColumn get downloadUrl => text().nullable()();
  TextColumn get etag => text().nullable()();
  IntColumn get expectedBytes => integer().nullable()();
  IntColumn get receivedBytes => integer().withDefault(const Constant(0))();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get relativePath => text().nullable()();   // Under profiles/<id>/media
  TextColumn get failureCode => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  BoolColumn get serverConfirmed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get requestedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  @override Set<Column> get primaryKey => {itemKey};
}

class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get opType => text()();               // See 07, Outbox
  TextColumn get entityKey => text()();            // Coalescing key, e.g. "pref:<playbackId>"
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
}
```

`device_settings` keys: `quality.wifi`, `quality.cellular`, `quality.download` (each `serverDefault|original|high|medium|low`), `downloads.wifiOnly`, `downloads.quotaBytes`, `downloads.autoCacheBytes`, `playback.volume`, `playback.speed.podcast`, `playback.skipSeconds`, `offline.forced`.

Metadata needed to render and play a downloaded item offline is stored on the `download_items` row itself (`metaJson`), so offline playback never depends on `cache.db`.

## `CacheDatabase` (`cache.db`)

Normalized entity tables plus an ordered-list table for pages.

| Table | Key | Columns of note |
|---|---|---|
| `tracks` | `key` | `playbackId` (nullable), `json` (domain `Track` serialized), `albumId`, `artistId`, `title` (for local search), `fetchedAt` |
| `albums` | `id` | `json`, `title`, `artistName`, `year`, `fetchedAt`, `detailFetchedAt` |
| `artists` | `id` | `json`, `name`, `fetchedAt`, `detailFetchedAt` |
| `playlists` | `id` | `json`, `name`, `fetchedAt`, `detailFetchedAt` |
| `podcasts`, `episodes` | `id` | `json`, `fetchedAt` |
| `lists` | `listKey` | `total`, `fetchedAt`, `complete` |
| `list_entries` | `(listKey, position)` | `entityKind`, `entityKey` |
| `blobs` | `key` | `json`, `fetchedAt` — for one-off payloads: home shelves, lyrics, artist detail extras |

- `tracks.key` is the `playbackId` when present, else `"x:" + sha1(title|artist|album|duration)` so non-playable rows still have identity.
- `listKey` encodes endpoint and parameters: `albums?filter=owned&sort=name&origin=all`, `playlist:<id>`, `album:<id>:tracks`, `search:<q>:<type>`. A page fetch upserts entities and replaces the `list_entries` range it covers in one transaction.
- Entities are stored as a JSON blob plus the few columns that are queried or sorted locally. This keeps the cache schema stable while domain types evolve; a decoding failure of a cached blob is treated as a cache miss.

### Read Policy: Stale-While-Revalidate

Every repository read method returns a `Stream<Cached<T>>`:

```dart
class Cached<T> {
  final T value;
  final DateTime fetchedAt;
  final bool refreshing;
  final ApiException? refreshError;   // Non-null when the cache is shown but the refresh failed
}
```

1. Emit the cached value immediately if present.
2. If it is older than the TTL and the server is reachable, fetch.
3. On success, write to the cache; the drift watch query emits the new value.
4. On failure, re-emit the cached value with `refreshError`. If there was no cached value, the stream errors.

| Data | TTL | Notes |
|---|---|---|
| Library list pages | 5 min | Also refreshed on pull-to-refresh and after a local mutation |
| Album, artist, playlist detail | 10 min | Playlist detail is invalidated by any local edit to it |
| Home shelves | 5 min | |
| Search results | 2 min | Not shown offline unless the query matches the cache exactly |
| Lyrics | 30 days | |
| Podcast detail | 10 min | |

Offline, every cached value is shown regardless of age.

### Pruning

Runs at start-up after the first frame and when `cache.db` exceeds 64 MB: delete `lists` not read for 30 days with their entries, then entities referenced by no list and no `blobs` row. The image store is capped at 500 MB and 30 days by the cache manager configuration.

## Image Cache

`cached_network_image` with a per-profile `CacheManager`:

- Store directory `…/profiles/<id>/images`. Cache key = `sha1(ref) + ":" + size`, independent of the URL, so a rotated `?token=` on web does not miss.
- Requests carry `authHeaders` on native targets. On web the URL carries `?token=`.
- `memCacheWidth` is set to the same snapped pixel size requested from the server. `PaintingBinding.instance.imageCache` is capped at 100 MB and 300 images on desktop, 60 MB and 200 images on mobile.
- Artwork for downloaded items and for the current track's OS media controls is copied to `profiles/<id>/art/`, which is not purgeable.

## Migrations

- Each database class has its own `schemaVersion`. `drift_dev schema dump` writes a JSON schema per version to `client/drift_schemas/<db>/`; `drift_dev schema generate` produces the helpers used by migration tests.
- `AppDatabase` and `StateDatabase`: stepwise `MigrationStrategy.onUpgrade` using drift's `stepByStep`. Every version bump adds a test that opens a database at each earlier version with representative rows, migrates, and validates the schema and the data.
- `CacheDatabase`: `onUpgrade` drops all tables and recreates them. A failure to open deletes the file and retries once.
- Downgrade (an older app opening a newer `state.db`): refuse to open, show "This data was written by a newer version of the app", and offer to reset the profile's local state. Never silently delete downloads.
- All databases run with `PRAGMA journal_mode = WAL`, `foreign_keys = ON`, `synchronous = NORMAL`, opened on a background isolate through `drift_flutter` (`driftDatabase(name:, native: DriftNativeOptions(databaseDirectory: …))`).

## Web Storage

- drift WASM: `web/sqlite3.wasm` and `web/drift_worker.js` are shipped with the build. drift chooses the best storage the browser offers. Without cross-origin isolation headers (which the design rules out because they break third-party artwork), that is the OPFS dedicated-worker mode where available and IndexedDB otherwise. Both satisfy the client's needs; verify in spike S6.
- `state.db` on web holds the queue snapshot, outbox, and settings. Download tables exist but stay empty.
- Private browsing can make storage unavailable. `DatabaseOpener` falls back to an in-memory database and shows a one-time notice that nothing will be remembered.
