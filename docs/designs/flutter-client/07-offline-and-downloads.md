# 07. Offline and Downloads

Status: design phase.

Native targets only. On web `PlatformCapabilities.canDownload` is false and every entry point is hidden. Code lives in `lib/core/downloads/`, `lib/core/sync/`, and `lib/core/connectivity/`.

## Vocabulary

- **Collection:** something the user asked to keep offline: a track, an album, a playlist, or a podcast episode. Row in `download_collections`.
- **Item:** one audio file. Row in `download_items`. An item can belong to several collections (`download_membership`); it is deleted when its last membership is removed.
- **Pinned:** an item with at least one membership. Pinned items are never evicted automatically.

## Requesting a Download

`DownloadController.pin(kind, refId)`:

1. Insert the collection row with status `resolving`. The UI shows it immediately.
2. `POST /api/offline/items { kind, id, deviceId, quality? }`. `quality` is the `quality.download` device setting, omitted for "server default".
3. On 409 `CACHE_LIMIT_EXCEEDED`: collection → `blocked(serverQuota)`; the sheet shows the three byte values from the response and links to the server's storage setting.
4. On 409 `SOURCE_DOWNLOADS_DISABLED` (admin switch off): collection → `blocked(disabledByServer)`.
5. Otherwise, for each returned item:
   - `downloadable: false` → membership recorded with the item in status `unavailable` and the server's `reason`. Shown greyed out, without source wording: `SOURCE_DOWNLOADS_DISABLED` → "Downloads are turned off on this server", `TRACK_UNAVAILABLE` → "No longer available", `SOURCE_UNAVAILABLE` → "Not available for your account".
   - `downloadable: true` and the item is already `completed` at the same quality → add the membership only.
   - Otherwise upsert the item as `queued` with `downloadUrl`, `expectedBytes`, `quality`, and a metadata snapshot.
6. Check the local quota (below). Items that do not fit stay `queued` with `waitingFor: space`.
7. Hand queued items to the scheduler.

Offline at step 2: the collection stays `resolving(pendingNetwork)` and is retried when the server is reachable. Nothing is added to the outbox; the collection row is the pending work.

Podcast episodes do not use `/api/offline/items` (the unified offline API covers tracks only). An episode download uses the episode stream URL directly, with no server-side accounting; everything else below applies.

## Item State Machine

```
              ┌────────────── retry (attempts < 5) ──────────────┐
              ▼                                                  │
 queued ──▶ running ──▶ verifying ──▶ completed ──▶ (confirmed)  │
   ▲          │  │           │                                   │
   │          │  └─ paused ◀─┘ (user, no Wi-Fi, no space)        │
   │          ▼                                                  │
   └────── failed(retryable) ────────────────────────────────────┘
              │
              ▼
        failed(permanent)        unavailable        missing (file vanished)      revoked ─▶ deleted
```

| Transition | Trigger | Action |
|---|---|---|
| `queued → running` | Scheduler slot free, constraints met | Enqueue a `DownloadTask`; store `taskId` |
| `running → verifying` | Transfer reports complete | See Verification |
| `verifying → completed` | Size check passes | Atomic rename `.part` → final path; set `sizeBytes`, `completedAt` |
| `completed → confirmed` | `POST /api/offline/items/complete` succeeds | `serverConfirmed = true` (a flag on the completed row, not a separate status) |
| `running → paused` | User pause, Wi-Fi-only and not on Wi-Fi, disk full | Cancel the task; the item restarts from byte zero when it runs again (Resume Rule) |
| `running → failed(retryable)` | Network error, 5xx, 429, 401 | Backoff 5 s × 3^attempts, cap 1 h; 401 refreshes credentials first |
| `running → failed(permanent)` | 400, 404, 409 | No retry. 404/409 re-resolve the collection once (the server may now say `downloadable: false`) |
| `completed → missing` | File absent at play time or at the start-up scan | Re-queue |
| any `→ revoked` | Reconciliation says `revoked: true` | Delete the file and the row |

`attempts` resets when the user presses Retry.

## Transfers: `background_downloader`

`Downloader` (platform seam) wraps `FileDownloader()`.

```dart
DownloadTask(
  taskId: item.itemKeyHash,                    // Stable, so re-enqueueing is idempotent
  url: streamUrls.resolve(item.downloadUrl).toString(),
  headers: streamUrls.authHeaders(credentials),
  baseDirectory: BaseDirectory.applicationSupport,
  directory: 'profiles/$profileId/media/${hash.substring(0, 2)}',
  filename: '$hash.part',
  group: 'p:$profileId',
  updates: Updates.statusAndProgress,
  requiresWiFi: settings.downloadsWifiOnly,
  retries: 0,                                  // The state machine owns retries
  allowPause: false,                           // Resume Rule: transfers restart from zero
  metaData: item.itemKey,
);
```

- **Concurrency:** 2 active transfers per profile. The controller's scheduler releases the next `queued` item when a slot frees; it does not hand the whole queue to the OS, so priorities and pausing stay under app control. Order: user-initiated single tracks first, then collections in request order, then items inside a collection in track order.
- **Android:** transfers run in WorkManager. Batches estimated above 50 MB run as a foreground service with a progress notification (channel "Downloads"), because long expedited work is otherwise deferred. `POST_NOTIFICATIONS` is requested the first time a download starts.
- **iOS:** background `URLSession`. The OS decides when to run discretionary transfers; user-initiated downloads are marked high priority. After the app is killed and relaunched by the OS for session events, the root-scope handler records results in the right profile's `state.db` ([04](04-auth-and-server-profiles.md), Multiple Profiles).
- **Desktop:** in-process transfers; they stop when the app quits and resume on next start.
- **Start-up:** `FileDownloader().start()` re-attaches to OS tasks; `resumeFromBackground()` delivers events that arrived while the app was dead. Then the controller reconciles `download_items` in `running` with the plugin's task records: a `running` row with no live task goes back to `queued`.
- **Credentials in queued tasks:** headers are fixed at enqueue time. JWT sessions call `ensureFresh(minRemaining: 12 h)` before each enqueue. A transfer that still gets 401 is retried with fresh headers.

### Resume Rule

The server contract (`unified-playback-api.md`, P4) is: resume with `Range` and `If-Range: <ETag>`; `206` continues the file; `200` means restart from byte zero.

- The plugin's own resume sends `Range` without `If-Range` (Spike S5 finding), so it does not follow that contract and is not used.
- A paused or interrupted transfer is always cancelled and restarted from byte zero: tasks are created with `allowPause: false`, and an item that runs again gets a new transfer of the whole file.
- The item row stores `etag` from the first response for diagnostics.

### Verification

- If `expectedBytes` is non-null and the file size differs → `failed(retryable)`, file deleted.
- If `expectedBytes` is null, compare with the response `Content-Length` when present; otherwise accept.
- A zero-byte file is always a failure.
- No checksum: the server offers none.
- After the rename, `POST /api/offline/items/complete { deviceId, playbackId, quality, sizeBytes }` is sent directly when online, or as an outbox operation otherwise.

## Storage Accounting and Quota

Two independent limits apply.

| Limit | Source | Enforced |
|---|---|---|
| Server per-user limit | `cacheLimitBytes` / `cacheUsedBytes` in the `POST /items` response; `GET /offline/stats` | By the server (409) |
| Device limit | `downloads.quotaBytes` device setting; default is the smaller of 20 GB and 25 % of free disk space at first use | By the client |

- Before queuing, the client sums `sizeBytes` of completed items, `expectedBytes` of queued ones (unknown sizes estimated at 8 MB), and compares with the device limit and with free disk space minus a 500 MB reserve.
- When pinned content would exceed the device limit, the sheet says how much is needed and offers "Raise limit" or "Download what fits".
- **Auto-cache (non-pinned)** is off in v1. The table and eviction order (`lastPlayedAt` ascending) are in place so that "keep recently played tracks" can be added without a migration; `downloads.autoCacheBytes` defaults to 0.
- `Settings → Storage` shows per-profile totals for downloads, image cache, and database, with "Remove all downloads" and "Clear cache".

## Removing Downloads

`unpin(kind, refId)`: delete the membership rows; for each item left with no membership, delete the file, delete the row, and add its `playbackId` to a batched `DELETE /api/offline/items { deviceId, playbackIds }` (≤ 500 per request; outbox operation when offline). Removing an item that is currently playing lets playback finish from the open file handle on POSIX systems; on Windows the delete is deferred until the engine releases the file.

## Keeping Collections Current

- **Playlists:** when a pinned playlist's detail is refreshed and its track list differs from the membership set, the controller re-runs `POST /offline/items { kind: playlist }` and diffs: new items are queued, removed ones are unpinned. A local edit to a pinned playlist triggers the same pass.
- **Albums:** re-resolved at most once a day and on manual refresh.
- **Podcasts:** no auto-download in v1; episodes are pinned individually.

## Reconciliation

Runs at start-up when online, after sign-in, and at most every 6 hours.

1. `GET /api/offline/items?deviceId=`.
2. Server item with `revoked: true` → delete the local file and row, then include it in `DELETE /offline/items`.
3. Local `completed` item unknown to the server → re-send `complete` (this happens after a failed confirmation or a server restore).
4. Server item unknown locally (reinstall with the same `deviceId` is impossible because `deviceId` is regenerated; this occurs after "Clear local state") → `DELETE /offline/items` for it.
5. Local scan: every `completed` row's file must exist with the recorded size; otherwise `missing`. Files in `media/` with no row (and `.part` files with no live task) are deleted.

## Reachability and Offline Mode

`ReachabilityController` (root scope, per active profile) produces one of `online`, `serverUnreachable`, `noNetwork`, `forcedOffline`.

- Inputs: `connectivity_plus` (interface up/down and type), the outcome of real API calls (any `Offline` exception counts as a failure, any response as a success), and the `offline.forced` setting.
- After 2 consecutive failures within 30 s the state becomes `serverUnreachable`. A probe of `GET /api/health/live` then runs with backoff 5 s, 15 s, 30 s, 60 s (cap) and on every connectivity change; one success returns to `online`.
- `connectivity_plus` alone is never trusted to mean "online": a captive portal or a VPN-only server looks connected.
- In any non-online state:
  - Repositories serve the cache and skip refreshes.
  - Library gains an "Offline" banner and a "Downloaded only" filter that is on by default; rows without a local file are disabled.
  - Search queries the local cache and downloads (`title`/`name` `LIKE`), labelled "Results from this device".
  - Writes go to the outbox.
- Returning to `online` triggers: outbox replay, playback-state post, capability refresh if due, reconciliation if due, and resolution of `resolving(pendingNetwork)` collections.

## Outbox

A durable, ordered queue of writes in `state.db`. Every user-visible write goes through it, online or not; online it simply drains immediately. That gives one code path and one set of tests.

### Operations

| `opType` | Endpoint | `entityKey` | Coalescing |
|---|---|---|---|
| `preference` | `POST /library/preferences` | `pref:<playbackId>` | Last write wins; a pending op for the same key is replaced |
| `albumPreference` | `POST /library/albums/:id/preference` | `apref:<albumId>` | Last write wins |
| `play` | `POST /plays` (with `playedAt` and `listenedMs`, P8) | `play:<sessionId>` | Never coalesced |
| `playlistCreate` | `POST /playlists` | `pl:<tempId>` | |
| `playlistRename` | `PUT /playlists/:id` | `plname:<id>` | Last write wins |
| `playlistDelete` | `DELETE /playlists/:id` | `pl:<id>` | Removes pending ops for the same playlist |
| `playlistAdd` | `POST /playlists/:id/items` | `plitem:<id>:<opUuid>` | An add followed by a remove of the same pending item cancels both |
| `playlistRemove` | `DELETE /playlists/:id/items/:playbackId` | `plitem:<id>:<opUuid>` | |
| `playlistReorder` | `PUT /playlists/:id/items/reorder` | `plorder:<id>` | Last write wins (the payload is the full order) |
| `episodeProgress` | `POST /podcasts/…/progress` | `ep:<episodeId>` | Last write wins |
| `offlineComplete` | `POST /offline/items/complete` | `oc:<playbackId>` | Last write wins |
| `offlineDelete` | `DELETE /offline/items` | `od:<batchUuid>` | Batches merge up to 500 ids |

Coalescing happens when an op is enqueued, in the same transaction as the insert (`OutboxStore`, `lib/core/sync/outbox/`):

- A last-write-wins op deletes the pending ops with the same `opType` and `entityKey` and is inserted with a new `seq` at the tail and no attempts, so a reorder enqueued after an add stays after it.
- `playlistDelete` deletes every pending rename, add, remove, reorder and delete of the playlist. If a `playlistCreate` with that temporary id is still pending, it is deleted too and nothing is stored: the playlist never reached the server.
- A `playlistRemove` whose `opUuid` matches a pending `playlistAdd` of the same playlist deletes the add and is not stored. The caller passes the add's `opUuid` when removing an item that has not been sent, and a fresh uuid otherwise.
- `offlineDelete` merges into the device's newest pending batch while it holds fewer than 500 ids and no `offlineComplete` of the device follows it, so a removal never moves ahead of a completion. Ids are deduplicated; the merged batch keeps its `batchUuid` and moves to the tail with a new `seq`, so a send already in flight never loses the added ids. Ids beyond 500 go into new batches with new `batchUuid`s.
- Ops are compared and stored by value; `metadata` holds the JSON form of `TrackMeta`. A row that does not decode is logged at `severe` and deleted when read.

A playlist created offline has a temporary id (`tmp_<uuid>`). When `playlistCreate` succeeds, the worker rewrites the id in later pending operations and in `cache.db` in the same transaction.

### Worker

- One worker per profile; strictly sequential in `seq` order, so a playlist add never overtakes its create.
- Runs when an operation is enqueued, when reachability becomes `online`, and on a 60 s timer while operations are pending.
- Outcome handling:

| Result | Action |
|---|---|
| 2xx | Delete the op; update the cache from the response |
| `Offline`, 5xx, `Upstream` | Stop the pass; `nextAttemptAt` = backoff 5 s × 2^attempts, cap 15 min |
| `RateLimited` | Stop the pass; retry after the given delay |
| `Unauthenticated` | Stop; ops are kept across re-sign-in to the same `(baseUrl, userId)` |
| 404 on the target (playlist or track gone) | Drop the op; one grouped snackbar: "Some changes couldn't be saved because the item no longer exists" |
| 409 | Drop the op; refetch the entity; snackbar |
| 400 | Drop the op; log at `severe` (a client bug) |

- Optimistic state: repositories overlay pending ops on cached data when reading (a liked track shows liked before the server confirms). Dropping an op removes the overlay, which is the rollback.
- Plays older than 14 days are dropped unsent: scrobbling services reject old timestamps.
- `Settings → About` shows the pending count; a non-empty outbox blocks "Remove this server" behind a confirmation.

## Android Auto and Offline

The Android Auto browse tree (M2) includes a "Downloads" root backed by `download_collections`, so the car UI works with no network. Artwork there comes from the pinned `art/` directory through a `content://` URI served by a small `FileProvider`.

## Spike S5 finding

A minimal Flutter app created download tasks like the `DownloadTask` sketch above, but with `allowPause: true` (`retries: 0`, `updates: Updates.statusAndProgress`, a `.part` file name, an `Authorization` header). A `dart:io` pass-through proxy inside the test process trickled every response body over about 10 seconds and recorded each request's `Range` and `If-Range` and each response's status, `ETag` and `Content-Range`. Reference bytes were fetched with `dart:io` `HttpClient`, without the plugin. Questions 1 to 3 ran on Linux (`ubuntu-latest`, under Xvfb), where the plugin transfers in a Dart isolate; question 4 ran on an Android emulator (API 34, x86_64, `google_apis`), where it transfers in WorkManager.

| Question | Answer | Evidence |
|---|---|---|
| 1. Resume sends `Range` and `If-Range: <ETag>` | **No** | Real server (the contract server and seed), 30-second fixture track from `GET /api/playback/stream/<playbackId>?quality=original&report=0` through the proxy, paused at 49 %. First request: no `Range`; `200`, `ETag: "cc435de536b8dc26cf7208a107349e58"`, `Content-Length: 370783`. Resume request: `Range: bytes=180224-` (the paused offset) and no `If-Range`. |
| 2. Appends on `206` | Yes | The resume answered `206`, `Content-Range: bytes 180224-370782/370783`, the same `ETag`; the task completed and the file is byte-identical to the reference (370783 bytes, SHA-256 `3bfcb3c5…6c237106`). |
| 3. Restarts cleanly on `200` to a ranged request | Yes | Local server that answers every request with `200` and a fixed 2 MB body (2097152 bytes) and `Accept-Ranges: bytes`, paused at 43 %. With `ETag: "s5-fixed-body"` and without an `ETag`: the resume sent `Range: bytes=901120-` and no `If-Range`, got `200`, and the finished file is the 2097152-byte body, byte-identical (SHA-256 `018d7874…7673d75db`), not partial-plus-full. |
| 4. Re-attaches after process death on Android | Yes, 3/3 | Slow 2 MB download (40 s) from the CI host at `10.0.2.2`; the process was killed with `kill -9` (after `adb root`) at 20–21 % and relaunched; the app called `FileDownloader().start()` and `resumeFromBackground()`. On relaunch the plugin's record said `running` and `allTasks` listed `s5-q4`; 14 to 17 seconds after the relaunch WorkManager ran the task again under its original id `s5-q4`, from byte 0 (a new request without `Range`), and it completed with the reference SHA-256 in each run. |
| 5. Re-attaches after process death on iOS | Not answerable on CI | A simulator does not relaunch an app for background `URLSession` events. The design (background `URLSession`, Start-up reconciliation) stands; it is a human checklist row. |

- The plugin protects a resume in the client instead of with `If-Range`: when the resume answer is `206`, it compares the answer's `ETag` with the one stored at pause and fails the task with "Cannot resume: ETag is not identical, or is weak" when they differ or the stored one is weak. The Android implementation has the same check. The contract of `unified-playback-api.md` P4 is stated in terms of `If-Range`, so the Resume Rule does not rely on this check.
- On Linux the plugin listens to connectivity through NetworkManager on the system bus. Where NetworkManager is absent (the CI runners), that listener fails asynchronously with `org.freedesktop.DBus.Error.ServiceUnknown` and the plugin does not handle the error; it then keeps its default "connected". Code that creates the plugin on Linux has to expect this error.
- The plugin's task store on Linux lives under the XDG documents directory, resolved with `xdg-user-dir`.
- Package versions: Flutter 3.50.0, `background_downloader` 9.6.6.
