# Unified Playback API

Status: shipped.

Server prerequisite for the Flutter client (`docs/designs/flutter-client.md`, "Server Prerequisites"). It gives every playable track one opaque identifier and one way to stream, report, organize, and download it, regardless of where the audio comes from. The change is additive: existing endpoints, payload fields, and the Next.js frontend keep working unchanged.

## Problem

A track can come from five places, and today each is exposed differently. Clients must branch on `streamSource` and carry source-specific identifiers through every interaction.

| `streamSource` in payloads | Backing row | Stream endpoint | Identifier the client must keep |
|---|---|---|---|
| absent / `local` | `Track` (`origin: LOCAL`) | `GET /api/library/tracks/:id/stream` | `id` (cuid) |
| `peer` | `Track` (`origin: FEDERATED`) | same, with peer fallback ladder | `id` |
| `tidal` | `TrackTidal` (may not exist yet) | `GET /api/tidal-streaming/stream/:trackId` | `tidalTrackId` (TIDAL int) |
| `youtube` | `TrackYtMusic` (may not exist yet) | `GET /api/ytmusic/stream/:videoId`, or `/stream-public/:videoId` when the user has not linked YT Music | `youtubeVideoId` |
| `youtube-direct` | none | `GET /api/youtube/stream/:videoId` | `youtubeVideoId` |

The selection logic lives in the web player (`frontend/components/player/AudioPlaybackOrchestrator.tsx`, `frontend/components/player/hooks/useNextTrackPreload.ts`) and the identifier juggling in `frontend/lib/trackRef.ts`. Any second client would have to copy both.

Writes have the same split:

- `POST /api/plays` requires exactly one of `trackId`, `tidalTrackId`, `youtubeVideoId`, and for remote ids also `title`, `artist`, `album`, `duration` so the server can upsert a `TrackTidal`/`TrackYtMusic` row (`backend/src/routes/plays.ts`).
- Playlist adds take the same trio plus metadata (`backend/src/routes/playlists.ts`, `AddToPlaylistRef` in `frontend/lib/trackRef.ts`).
- Likes are split between `LikedTrack` (local) and `LikedRemoteTrack` via provider-prefixed ids (`backend/src/routes/library/remoteTracks.ts`).
- Playback state and Listen Together queue items persist `streamSource` plus provider ids.

Offline downloads are local-only:

- `POST /api/offline/albums/:id/download` filters to `TRACK_VISIBLE_WHERE` + `LOCAL_TRACK_WHERE` and returns `/library/tracks/:id/stream` URLs (`backend/src/routes/offline.ts`).
- `CachedTrack` has a required foreign key to `Track`, is unique on `(userId, trackId, quality)`, and has no device dimension, so two devices of one user overwrite each other's accounting.
- There is no track- or playlist-level offline request.

## Goals

- **One identifier.** Every payload that contains a playable track carries an opaque `playbackId`; a client can do everything with that id alone.
- **One stream surface.** `GET /api/playback/stream/:playbackId` and `GET /api/playback/stream-info/:playbackId` serve any source, with today's auth, Range, and quality behaviour.
- **One input shape.** Every endpoint that takes a track accepts `playbackId`.
- **Offline for every source.** Track, album, and playlist downloads for any source, with per-device accounting and a per-item, server-decided `downloadable` flag. Anything a user can stream by `playbackId`, they can download by `playbackId`, under one admin switch.
- **Same credentials everywhere.** Realtime sockets accept API keys as well as JWTs, so device-linked clients get Listen Together and presence.
- **Additive.** No existing route, field, or behaviour is removed or changed; the frontend needs no changes.

## Non-Goals

- Changing how any provider is fetched, authenticated, transcoded, or rate-limited. The new routes call the same code as the existing ones. An offline download is the same stream a client plays.
- Per-source offline policy or per-source download quality. Offline is one surface: the client never learns which source backs an item, and the admin controls it with one switch.
- Migrating the Next.js frontend. It moves to `playbackId` in a planned follow-up (see Follow-Up), not in this project.
- Deprecating per-source endpoints in this project. They are deprecated only after the frontend follow-up lands.
- Unifying the `Track`, `TrackTidal`, and `TrackYtMusic` tables, or changing `TrackMapping` matching.
- Podcasts and audiobooks. They keep their own stream routes; the client treats them as a separate media type already.

## Design

### P1. `playbackId`

#### Format

```
playbackId := <kind> "." <key>
kind       := "t" | "td" | "ym" | "yt"
```

| kind | Meaning | key |
|---|---|---|
| `t` | `Track` row (local or federated) | `Track.id` (cuid) |
| `td` | TIDAL track | TIDAL numeric id (`TrackTidal.tidalId`) |
| `ym` | YouTube Music track | video id (`TrackYtMusic.videoId`) |
| `yt` | Plain YouTube video | video id |

- Keys use natural/external ids, not `TrackTidal.id`/`TrackYtMusic.id`, because search and browse results for remote tracks are emitted before any row exists. A row is upserted only when a write needs one (as today).
- The format is URL-safe (cuids are alphanumeric; YouTube ids are `[A-Za-z0-9_-]`; none contain `.`), so it can be used as a path segment without encoding.
- Validation: `^(t|td|ym|yt)\.[A-Za-z0-9_-]{1,64}$`, plus per-kind checks (`td` key is a positive integer).
- **Clients must treat it as opaque.** The OpenAPI schema documents it as `string` with no format; the encoding is an internal detail and may gain kinds (e.g. a future provider) without a client change. Only the server parses it.
- Stability: a `playbackId` is stable for as long as its underlying track exists. `t.<cuid>` survives file moves and retags (durable track identity, `docs/designs/durable-track-identity.md`).

#### Semantics: the logical track

A `playbackId` names the logical track the user saw, not a fixed upstream. Which upstream serves it is decided per request by the same rules that apply today:

- `t.*` resolves through the existing library stream handler, including the federated peer fallback ladder and deduplication.
- `ym.*` uses the authenticated YT Music route when the user has linked YT Music, otherwise the public route. This decision moves from the web player into the server.
- `td.*` and `yt.*` map to their existing handlers.

#### Module

`backend/src/services/playback/playbackId.ts`:

```ts
export type PlaybackKind = "t" | "td" | "ym" | "yt";
export type ParsedPlaybackId =
  | { kind: "t"; trackId: string }
  | { kind: "td"; tidalId: number }
  | { kind: "ym"; videoId: string }
  | { kind: "yt"; videoId: string };

export function encodePlaybackId(ref: ParsedPlaybackId): string;
export function parsePlaybackId(value: string): ParsedPlaybackId | null;
export const playbackIdSchema: z.ZodType<ParsedPlaybackId>; // for route validation
```

`@soundspan/media-metadata-contract` gains `playbackId: string` on the shared track types so backend payload builders and any TS consumer agree on the field.

#### Emission

`playbackId` is added wherever a playable track is serialized. The central builders cover most surfaces:

- `backend/src/services/unifiedTrackResponse.ts`: `normalizeLocalTrack`, `normalizeTidalTrack`, `normalizeYtMusicTrack`, `formatPlaylistDetailTrack`, `formatUnifiedTrackItem`.
- `backend/src/services/federatedTrackPayload.ts`, `backend/src/services/libraryTrackPreferences.ts`, `backend/src/services/libraryRadioTrackResponse.ts`.

Remaining direct builders, found by the existing `streamSource` emitters: `routes/library/albums.ts`, `routes/library/tracks.ts`, `routes/plays.ts`, `routes/playbackState.ts`, `routes/social.ts`, `routes/search.ts` (plus its OpenAPI schema), `services/listenTogether.ts`, and the YouTube routes that produce `youtube-direct` items.

A behavioural test enumerates the track-returning routes in the OpenAPI spec and asserts that each sampled response item has a parseable `playbackId` consistent with its existing identifier fields. New track-returning routes are added to that list.

### P2. Unified Stream Endpoints

New route module `backend/src/routes/playback.ts`, mounted at `/api/playback` (indexed in `backend/src/routes/README.md`).

#### `GET /api/playback/stream/:playbackId`

- Auth: `requireAuthOrToken` (`X-API-Key`, Bearer, or `?token=`), identical to the per-source routes.
- Query: `quality` (`original | high | medium | low`, the library vocabulary). Absent means the user's saved playback quality. The resolver maps it to provider-native qualities, so clients never see provider quality names.
- Range requests and response headers (`Accept-Ranges`, `Content-Range`, `Content-Length`, `Content-Type`) behave as the per-source routes do today.
- Implementation: each existing per-source handler is refactored into a service function (`streamLibraryTrack`, `streamTidalTrack`, `streamYtMusicTrack`, `streamYouTubeVideo`) called by both its existing route and the new one. No streaming logic is duplicated.
- Middleware parity: the YT Music limiter (`ytMusicStreamLimiter`) and enablement check apply when a request resolves to `ym`. `/api/playback/stream` is added to the compression exclusion list (`isCompressionExcludedPath`) and to any stream-specific rate-limit path lists, matching the existing stream routes.

#### `GET /api/playback/stream-info/:playbackId`

Returns one shape for every source:

```json
{
  "playbackId": "td.123456",
  "contentType": "audio/flac",
  "codec": "flac",
  "bitrate": null,
  "sampleRate": 44100,
  "bitDepth": 16,
  "durationMs": 241000,
  "contentLength": 28734112,
  "quality": "original"
}
```

Fields a source cannot know are `null`. It reuses the existing `stream-info` handlers for TIDAL and YT Music and local file metadata for `t`.

#### Errors

One shape across sources, via the existing `sendRouteError`:

| Status | `code` | When |
|---|---|---|
| 400 | `INVALID_PLAYBACK_ID` | Fails validation |
| 404 | `TRACK_NOT_FOUND` | No such track, removed track, or upstream says gone |
| 409 | `SOURCE_UNAVAILABLE` | Provider disabled on this server, or requires a link the user has not made and no public path exists |
| 429 | `RATE_LIMITED` | With `Retry-After` |
| 502 | `UPSTREAM_FAILED` | Provider or federated peer error after the fallback ladder |

### P3. `playbackId` on Every Track Input

Each endpoint below accepts `{ playbackId, metadata? }` as an alternative to its current identifier fields. When `playbackId` is present it wins and the legacy fields are ignored.

| Endpoint | Today |
|---|---|
| `POST /api/plays` | `trackId` / `tidalTrackId` / `youtubeVideoId` + metadata |
| Playlist add / remove / reorder (`routes/playlists.ts`) | same trio + metadata |
| Like / unlike: new `POST /api/library/preferences` (`routes/library/playbackPreferences.ts`), body `{ playbackId, signal, metadata? }`, runs the matching legacy handler in `routes/library/tracks.ts` (`t`) or `routes/library/remoteTracks.ts` (`td`, `ym`); `yt` answers 409 `SOURCE_UNAVAILABLE` | local id or provider-prefixed id |
| `POST /api/playback-state` queue items | `streamSource` + provider ids |
| Listen Together queue add / replace / reorder (socket events and REST) | `streamSource` + provider ids |

`metadata` is `{ title, artist, album, durationSec, artworkUrl?, isrc? }`. A client sends the display metadata it already received with the track, for every track, without knowing the source. The server uses it only when it must create a `TrackTidal`/`TrackYtMusic` row that does not exist yet, exactly as the current remote-play and remote-playlist paths do, and ignores it otherwise. Missing metadata when a row must be created returns 400 `METADATA_REQUIRED`.

Responses from these endpoints, `GET /api/playback-state`, and Listen Together state broadcasts include `playbackId` on every queue item.

### P4. Source-Agnostic Offline

#### Endpoints

All under `/api/offline`, `requireAuth`. Existing album routes stay as they are.

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/items` | Request downloads. Body `{ kind: "track" \| "album" \| "playlist", id, deviceId, quality? }`. For `track`, `id` is a `playbackId`; for `album`/`playlist`, the album/playlist id. Returns the resolved items. |
| `POST` | `/items/complete` | Body `{ deviceId, playbackId, quality, sizeBytes }` after a file is fully written. |
| `DELETE` | `/items` | Body `{ deviceId, playbackIds[] }` when the client removes files. |
| `GET` | `/items?deviceId=` | What the server believes this device holds (for reconciliation after reinstall). |
| `GET` | `/stats?deviceId=` | Existing stats, extended with per-device totals. |

`POST /items` response:

```json
{
  "items": [
    {
      "playbackId": "t.ckz0…",
      "downloadable": true,
      "downloadUrl": "/api/playback/stream/t.ckz0…?quality=high",
      "expectedSize": 3561234,
      "quality": "high",
      "contentType": "audio/mpeg"
    },
    {
      "playbackId": "t.ckz1…",
      "downloadable": false,
      "reason": "SOURCE_DOWNLOADS_DISABLED"
    }
  ],
  "estimatedTotalBytes": 3561234,
  "cacheLimitBytes": 10737418240,
  "cacheUsedBytes": 5123456789
}
```

- Album and playlist requests include every visible track of the album/playlist, of any source, in order. Tracks the server will not allow offline are returned with `downloadable: false` and a reason (`SOURCE_DOWNLOADS_DISABLED` when the admin switch is off, `TRACK_UNAVAILABLE` when the track is gone, `SOURCE_UNAVAILABLE` when this user cannot stream it, e.g. TIDAL without a session), so the client can show them greyed out without knowing why in source terms.
- The cache-limit check uses `UserSettings.maxCacheSizeMb` as today, but against reported sizes plus the new request's estimate, and returns 409 `CACHE_LIMIT_EXCEEDED` with the numbers rather than a 400.

#### Download quality

Download quality is decided when `POST /items` resolves an item and is carried in its `downloadUrl`.

- **Effective quality** is the quality requested in `POST /items` (default: the user's saved playback quality), in the library vocabulary (`original | high | medium | low`). The item reports it as `quality`, and `downloadUrl` is `/api/playback/stream/:playbackId?quality=<quality>`.
- `resolvePlayback` maps it to each source the same way it does for streaming: library tracks use the transcode cache (`TranscodedFile`, keyed by `(trackId, quality)`), and remote sources use their provider tiers.

#### Consistent, resumable downloads

Resumable downloads require that every byte range of one download comes from the same encoding. The client follows one rule for every source: resume with `Range` + `If-Range` set to the `ETag` it was given; a `206` continues the file, and a `200` means restart.

- Library files and the transcode cache (`TranscodedFile`) are one fixed file per `(trackId, quality)`, so their stream responses carry a strong `ETag` derived from `(playbackId, variant, contentLength)` and honour `If-Range`.
- Proxied sources can change encoding between requests (e.g. a different YouTube itag), so they carry no strong `ETag`. When a request for one has `If-Range`, the stream route drops the `Range` and sends the full body (RFC 9110), so a resumed file never splices two encodings.
- `expectedSize` is `null` when a source cannot report a length in advance.

#### Data Model

Generalize `CachedTrack` rather than adding a parallel table:

```prisma
model CachedTrack {
  id             String   @id @default(cuid())
  userId         String
  deviceId       String?  // client-generated per-installation UUID; null for legacy rows
  playbackId     String   // backfilled as "t.<trackId>" for existing rows
  trackId        String?  // was required; still set for kind "t"
  localPath      String
  quality        String
  fileSizeMb     Float
  cachedAt       DateTime @default(now())
  lastAccessedAt DateTime @default(now())
  track          Track?   @relation(fields: [trackId], references: [id], onDelete: Cascade)
  user           User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, deviceId, playbackId, quality])
  @@index([userId])
  @@index([lastAccessedAt])
}
```

- Migration: add `deviceId` and `playbackId`, backfill `playbackId = 't.' || "trackId"`, relax `trackId` to nullable, replace the unique constraint. Existing album routes keep writing `trackId` and also set `playbackId`.
- `deviceId` is generated by the client on first launch and stored with the server profile. It is not an authentication factor.
- Rows written by the legacy album and track routes have a NULL `deviceId`. PostgreSQL treats NULLs as distinct in unique indexes, so the composite unique cannot dedupe them and Prisma cannot upsert on a null key; those routes find the row, then update or create it.
- Rows for remote kinds have a null `trackId` and no foreign key; they are cleaned up by `DELETE /items` and by the existing user-deletion cascade.

#### Download Policy

Whether a track can be downloaded is server policy, evaluated in one function (`resolveOfflinePolicy(userId, parsedId)`) and surfaced to clients only as `downloadable` + `reason`.

- **Default: downloads are allowed.**
- Admins get one switch, `SystemSettings.offlineDownloadsEnabled` (default `true`; DB-backed, no env var, so no deployment-surface changes). It applies to every source alike, and appears as "Allow offline downloads" in the admin "Offline downloads" section.
- The policy does not re-check provider availability. Whether this user can stream a remote source is decided by `resolvePlayback`, exactly as for playback, and reported as `SOURCE_UNAVAILABLE`.
- With the switch off, new requests yield `downloadable: false, reason: "SOURCE_DOWNLOADS_DISABLED"`. Files already on devices are not remotely deleted; on the next `GET /items` reconciliation the server reports them as `revoked: true`, and the client removes them. A track that no longer exists is reported `revoked` too.
- The existing album route (`POST /api/offline/albums/:id/download`) honours the switch too, so the policy has one source of truth. When it is off the route answers 409 with code `SOURCE_DOWNLOADS_DISABLED`.

### P5. API-Key Authentication for Realtime Sockets

Listen Together and social presence share the `/listen-together` namespace (path `/socket.io/listen-together`). Its handshake middleware, `configureSocketAuthentication` in `backend/src/services/listenTogetherSocket.ts`, accepts only `handshake.auth.token` verified as a JWT access token.

- The handshake also accepts `handshake.auth.apiKey`. It is resolved with the same helpers HTTP auth uses (`findApiKeyRecord`, `isApiKeyExpired` in `backend/src/utils/apiKeyHash.ts`), with the same pending-deletion check, and updates the key's last-used time like `X-API-Key` requests do. `socket.data` is populated identically, so downstream handlers do not change.
- Exactly one of `token` / `apiKey` must be present; both is rejected, matching the HTTP rule for Subsonic auth.
- Revocation: deleting an API key (`/api/api-keys`, device-link device removal) disconnects sockets authenticated with that key. Sockets record the authenticating key id in `socket.data`, and the delete paths call a new `revokeApiKeySockets(apiKeyId)` alongside the existing `revokeUserSockets`. Key expiry is checked at handshake; a socket that outlives its key's expiry is disconnected on its next mutation-eligibility check.
- Rate limiting and connection limits are unchanged and apply per user, not per credential type.

## Testing

Per `AGENTS.md`: TDD, behavioural assertions, no source-text contract tests.

- `playbackId` unit tests: round-trip, validation, rejection of malformed and unknown kinds.
- Resolver tests: each kind routes to the right stream service; `ym` chooses authenticated vs public from the user's link state; disabled providers give 409 `SOURCE_UNAVAILABLE`.
- Route tests for `/api/playback/stream` and `/stream-info`: auth via each credential type, Range passthrough, error codes, rate-limit and compression parity with the per-source routes.
- Emission test: every track-returning route's sampled payload has a valid `playbackId` consistent with its legacy fields.
- Write-path tests: each P3 endpoint gives identical results via legacy fields and via `playbackId` (+ metadata for not-yet-persisted remote tracks).
- Offline: mixed-source album and playlist resolution with every source downloadable, policy reasons, cache-limit math, per-device isolation, ETag/If-Range behaviour for library downloads, `If-Range` yielding a full body for remote sources, and the `CachedTrack` and `offlineDownloadsEnabled` migrations against real PostgreSQL.
- Offline policy: the switch off yields `SOURCE_DOWNLOADS_DISABLED` for every source; reconciliation marks previously completed items `revoked`; the legacy album route honours the switch.
- Sockets: handshake with a valid, expired, revoked, or malformed API key; both credentials rejected; deleting a key disconnects its sockets and not the user's JWT sockets.
- Regression: existing per-source route suites and frontend tests stay green untouched.

## Documentation

- OpenAPI annotations for every new route and the `playbackId` field (documented as an opaque string).
- `backend/src/routes/README.md` gains `playback.ts`.
- `CHANGELOG.md` entry per PR.
- `docs/designs/flutter-client.md` states that `minServer` is the release that ships this API (P1–P5).

## Rollout

Each step is its own PR, mergeable and releasable alone:

1. `playbackId` module, contract-package field, and emission in all builders (P1).
2. Stream service extraction + `/api/playback/stream` and `/stream-info` (P2).
3. `playbackId` on write endpoints, playback state, and Listen Together (P3).
4. `CachedTrack` migration, offline item endpoints, download ETags and `If-Range` handling, the offline switch and admin UI (P4).
5. API-key socket handshake and key-scoped socket revocation (P5). Independent of steps 1–4; can land in any order.

The release containing steps 1–5 is the Flutter client's `minServer`.

## Follow-Up: Frontend Adoption and Deprecation

Planned as a separate project after this one ships:

1. Move the Next.js frontend to `playbackId`: the player uses `/api/playback/stream`, preload and Listen Together use `playbackId`, and `frontend/lib/trackRef.ts` plus the `streamSource` branches in `AudioPlaybackOrchestrator.tsx` / `useNextTrackPreload.ts` are deleted.
2. Once no first-party client uses them, mark the per-source stream routes and the legacy identifier fields deprecated in OpenAPI and `docs/UPGRADING.md`, keeping them for third-party consumers for at least one minor release.
3. Removal is a separate, later decision.
