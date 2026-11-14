# 03. API Layer

Status: design phase.

`client/packages/soundspan_api` is a pure Dart package and the only code that builds HTTP requests to a soundspan server (the downloader, which hands URLs to the OS, is the one exception and gets its URLs and headers from this package).

## Server Behaviour This Relies On

Checked in the backend source; the contract suite ([11](11-testing-and-ci.md)) keeps these true.

**API description**

- The OpenAPI document is assembled by `swagger-jsdoc` from `@openapi` comments (`backend/src/config/swagger.ts`). Nothing checks those comments against the responses the handlers send.
- Handlers send responses with untyped `res.json(...)` calls; there is no response type to derive a schema from automatically.
- `zod` 4 is already a backend dependency, validates request input in 41 of the 65 route files, and can emit OpenAPI 3.0 schemas itself (`z.toJSONSchema` with the `openapi-3.0` target). P9 builds on this.

**Transport**

- Most 429 responses have a **plain-text** body. `Retry-After` (seconds) is always set.
- Error bodies are `{ error, code? }`. `code` exists only where a route sets it; there is no central catalogue.
- Disabled optional features answer 404 `{ error: "feature disabled", code: "FEATURE_DISABLED" }`.
- The socket.io server accepts **websocket transport only** unless the operator enables polling.
- Cover art `size` snaps to 64, 128, 192, 320, 512, or 768 pixels and requires authentication.
- Search-provider ordering is applied on the server in `GET /api/search/discover`. The client has nothing to do.

## Generated From the Server Specification

The models and endpoint methods are generated from the server's OpenAPI document. The server makes that possible with P9 ([12](12-server-prerequisites-p6-p9.md)): every operation the client uses has an `operationId`, one tag, and named request and response schemas, and the server checks its real responses against those schemas in its own tests.

| Step | What happens |
|---|---|
| Input | `packages/soundspan_api/openapi/soundspan-client.json`, the client-surface subset the backend emits (`npm --prefix backend run openapi:emit-client`). It is committed; CI re-emits it and fails on a difference. |
| Generator | `swagger_parser` (a pure Dart dev dependency; no Java). It reads OpenAPI 3.0 and writes `freezed` + `json_serializable` models and `retrofit` clients over `dio`. |
| Output | `lib/src/generated/`, committed like all generated code and excluded from analysis and the file-size gate. |
| Naming | One client class per tag (`LibraryClient`, `PlaybackClient`, …), each a getter of the root `SoundspanRestClient` named after the tag (`library` becomes `library2`, because `library` is a Dart built-in identifier); one method per `operationId`; one model per named component, plus one per inline enum or union, named after its operation or property (`LoginResponse200`, `ListAlbumsSortBy`). |

`packages/soundspan_api/swagger_parser.yaml`:

```yaml
swagger_parser:
  schema_path: openapi/soundspan-client.json
  output_directory: lib/src/generated
  generation:
    root_api_class_name: SoundspanRestClient
    http_client: retrofit
    serializer: freezed
    unknown_enum_values: preserve   # a value added by a newer server decodes to `<Enum>Unknown`
```

The generator follows the spec exactly, so two spec constructs decide how tolerant the generated code is: a closed object (`additionalProperties: false`) becomes a decoder that rejects unknown keys, so response objects in the client surface are open ([12](12-server-prerequisites-p6-p9.md), Serialisation Rules); and a value outside an `enum` decodes to the enum's `Unknown` subtype only because of `unknown_enum_values: preserve`. The answers for each generator behaviour the plan relies on are under [Spike S8 Finding](#spike-s8-finding).

**Hand-written, around the generated code:**

- transport: the `dio` instance, interceptors, platform adapters;
- `ApiException` and error mapping;
- `StreamUrls` and `ImageUrls`. Audio streams, downloads, and images are never requested through generated methods: players, the downloader, and the image cache take URLs and headers;
- pagination helpers;
- `SoundspanApi`, the facade that owns `dio` and exposes the generated clients.

**Server versions.** One generated client serves every server from `minServer` to the newest. P9 requires response fields added after `minServer` to be optional, so they decode as `null` from an older server. `tool/spec_compat.dart` compares the committed spec with the snapshot of the `minServer` release in `tool/specs/` and fails when an operation was removed or a response field became required; that is the signal to raise `minServer`.

## Package Layout

```
packages/soundspan_api/
├── openapi/soundspan-client.json    # Emitted by the backend (P9); committed
├── swagger_parser.yaml
└── lib/
    ├── soundspan_api.dart           # Public barrel
    └── src/
        ├── client.dart              # SoundspanApi: owns dio, exposes the generated clients
        ├── config.dart              # ApiConfig, Credentials, CredentialProvider
        ├── transport/
        │   ├── base_url_guard.dart
        │   ├── credential_interceptor.dart
        │   ├── refresh_interceptor.dart
        │   ├── retry_interceptor.dart
        │   ├── error_mapper.dart
        │   └── log_interceptor.dart
        ├── errors.dart              # sealed ApiException
        ├── urls.dart                # StreamUrls, ImageUrls
        ├── paging.dart              # OffsetPage, KeysetPage
        └── generated/               # swagger_parser output; never edited
            ├── soundspan_rest_client.dart   # Root client: one getter per tag
            ├── exports.dart
            └── <tag>/                       # One folder per tag (session, library, playlists, …)
                ├── <tag>_client.dart        # SessionClient, LibraryClient, PlaylistsClient, …
                └── models/                  # One freezed class per schema the tag's operations use
```

## Configuration and Credentials

```dart
class ApiConfig {
  final Uri baseUrl;                 // Normalized; may contain a path prefix; no trailing slash
  final String userAgent;            // "soundspan-client/<version> (<os>)"
  final String? playbackDeviceId;    // Sent as X-Playback-Device-Id
  final Duration connectTimeout;     // 10 s
  final Duration receiveTimeout;     // 30 s (JSON calls)
}

sealed class Credentials {}
class JwtCredentials extends Credentials { final String accessToken; final String refreshToken; }
class ApiKeyCredentials extends Credentials { final String apiKey; }

/// Implemented by the app (SessionController). The package never stores secrets.
abstract interface class CredentialProvider {
  Credentials? get current;
  /// Persist rotated tokens. Must complete before the returned future resolves.
  Future<void> onTokensRotated(JwtCredentials next);
  /// Called once when the server rejects the credential permanently.
  void onUnauthenticated(UnauthenticatedReason reason);
}
```

A `SoundspanApi.anonymous(baseUrl)` constructor exists for the probe calls made before sign-in.

## Transport

One `Dio` per `SoundspanApi`. Interceptors run in this order.

### 1. `BaseUrlGuard`

Every resource method passes a path relative to the API root (`/library/albums`). The guard resolves it against `<baseUrl>/api` and rejects, with an `ArgumentError` at development time, any request whose resolved origin or path prefix differs from the configured base. This implements "no arbitrary URL loading" (design doc, Security) and preserves reverse-proxy sub-paths. Server-provided relative URLs (`downloadUrl`: `/api/playback/stream/…`) are resolved by `urls.dart` against the base including its prefix: `https://example.com/soundspan` + `/api/playback/…`.

### 2. `CredentialInterceptor`

- `ApiKeyCredentials` → `X-API-Key: <key>`.
- `JwtCredentials` → `Authorization: Bearer <accessToken>`.
- Requests marked `extra: {anonymous: true}` (probe, login, refresh, device-link verify) get no credential.
- Adds `X-Playback-Device-Id` when configured, and `User-Agent` on native targets.

### 3. `RefreshInterceptor` (JWT sessions only)

```dart
class RefreshInterceptor extends QueuedInterceptor {
  Future<JwtCredentials>? _inFlight;

  Future<JwtCredentials> _refresh(JwtCredentials stale) =>
      _inFlight ??= _doRefresh(stale).whenComplete(() => _inFlight = null);
}
```

- **Proactive:** before sending, decode the access token's `exp` and `iat` claims (no signature check). If more than 80 % of the lifetime has elapsed, refresh first. With 24-hour tokens that is a refresh after about 19 hours of age.
- **Reactive:** on 401 `AUTH_REQUIRED`, refresh once and replay the original request with the new token. A second 401 on the replay is final.
- **Single flight:** all concurrent callers await the same `_inFlight` future. A request that was built with the stale token and fails with 401 after another request already refreshed compares its token with `current` and simply replays.
- **Persistence order:** `onTokensRotated` is awaited before any request uses the new access token. Because server tokens are stateless, a crash between the server's response and the write leaves the old refresh token usable; nothing is lost.
- **Failure:** refresh answers 401 (`Invalid refresh token`, `User not found`, `Token invalidated`) → `onUnauthenticated(sessionExpired)` and every waiter fails with `Unauthenticated`. Refresh answers 503 `AUTH_BACKEND_UNAVAILABLE` or fails on the network → waiters fail with `ServerError`/`Offline`; the session stays signed in and the next request tries again.
- API-key sessions never refresh. A 401 with an API key → `onUnauthenticated(keyRejected)`.

### 4. `RetryInterceptor`

| Condition | Policy |
|---|---|
| 429 | Wait `Retry-After` seconds (cap 60 s) plus 0–20 % jitter, then retry. Up to 2 retries for idempotent methods, 1 for others. Longer waits surface `RateLimited(retryAfter)` to the caller. |
| 502, 503, 504 on `GET` | Exponential backoff 0.5 s, 1 s, 2 s with jitter, 3 attempts |
| Connection error or timeout on `GET` | Same backoff, 2 attempts, then `Offline` |
| Any failure on a non-idempotent method | No automatic retry; the outbox owns retries for writes |

### 5. `ErrorMapper`

Converts every non-2xx response and every `DioException` to an `ApiException`. It must tolerate three body kinds: JSON `{ error, code?, … }`, plain text (most 429s), and HTML (a reverse proxy's error page).

```dart
sealed class ApiException implements Exception {
  final int? status;
  final String? code;          // Server `code`, verbatim, when present
  final String? serverMessage; // Server `error`, for logs; UI uses localized text
}
class Offline extends ApiException {}               // DNS, refused, timeout, TLS
class Unauthenticated extends ApiException {}       // 401
class Forbidden extends ApiException {}             // 403
class NotFound extends ApiException {}              // 404 without FEATURE_DISABLED
class FeatureDisabled extends ApiException {}       // 404 + code FEATURE_DISABLED
class Conflict extends ApiException {}              // 409; subclasses below
class SourceUnavailable extends Conflict {}         // code SOURCE_UNAVAILABLE
class CacheLimitExceeded extends Conflict { final int limitBytes, usedBytes, estimatedBytes; }
class DownloadsDisabled extends Conflict {}         // code SOURCE_DOWNLOADS_DISABLED
class InvalidRequest extends ApiException {}        // 400; `code` distinguishes METADATA_REQUIRED etc.
class RateLimited extends ApiException { final Duration retryAfter; }
class InvalidResponse extends ApiException {}       // 2xx JSON body that failed to decode into its model
class Upstream extends ApiException {}              // 502/503/504 with code UPSTREAM_FAILED
class ServerError extends ApiException {}           // other 5xx
class NotSoundspan extends ApiException {}          // 2xx body not JSON; 4xx (not 429) body not `{ error }`
class Unexpected extends ApiException {}            // fits no other class: unclassifiable failure, 3xx
```

Mapping is by status first, then `code`. Unknown `code` values keep the status-level class and carry the code through, so a newer server never crashes the mapper.

Where the list above leaves a choice, the mapper decides:

- `InvalidResponse` and `Unexpected` are not interchangeable. `InvalidResponse` is a 2xx JSON body that fails to decode into its generated model; the facade wraps each generated call in `guardDecode`, which turns the decoder's failure into it. `Unexpected` is anything no other class fits: a cancelled or otherwise unclassifiable `DioException`, or an unexpected status such as a 3xx.
- `NotSoundspan` is a 2xx whose body is not JSON where JSON is expected (including a body that claims JSON and does not parse), or a 4xx whose body is HTML, plain text, or JSON without a string `error`. A plain-text 429 is `RateLimited`, not `NotSoundspan`.
- A 4xx without a class of its own (405, 413, 422, …) with a JSON error body is `InvalidRequest` with its real `status`.
- 502, 503 and 504 with code `UPSTREAM_FAILED` are `Upstream`; every other 5xx, including one with an HTML body, is `ServerError`.
- `RateLimited.retryAfter` is the `Retry-After` header in seconds; a missing or unparseable header gives 60 s.
- `Offline` is a connection error, a connect, send or receive timeout, or a bad certificate. A response-transform timeout is `Unexpected`.
- `CacheLimitExceeded` reads `cacheLimitBytes`, `cacheUsedBytes` and `estimatedTotalBytes` from the body; a missing number reads as 0.
- An `Error` (the guard's `ArgumentError`) is a programming error, not a server failure, and reaches the caller unchanged.

The `Dio` built by `createDio` rethrows the `ApiException` a failed request carries, so callers, including the generated clients, never see a `DioException`.

### 6. `LogInterceptor`

Logs method, path template, status, and duration at `fine`. Never logs headers, query values, or bodies.

The package has no logging dependency: it reports one `ApiLogEntry` per finished request to an `ApiLogSink` callback the app forwards to its logger. The path template is the path relative to the API root with every segment that is not made only of lower-case letters and hyphens replaced by `:id` (`/library/albums/:id`).

### Platform HTTP Adapters

| Target | Adapter | Notes |
|---|---|---|
| Android, iOS, macOS, Windows, Linux | `IOHttpClientAdapter` | HTTP/1.1 keep-alive, `maxConnectionsPerHost = 6`. Sends no `Origin`, so CORS does not apply. Trusts the OS store only; no `badCertificateCallback`. |
| Web | `BrowserHttpClientAdapter` | `withCredentials = false` (auth is a header). Subject to `ALLOWED_ORIGINS`. |

## Wire Models

Wire models are the generated classes. The app never passes them to UI code: repositories map them to domain types ([02](02-architecture.md)).

- **Nullability comes from the spec.** A nullable column is a nullable Dart field; a key the server may omit is an optional one. The client adds no guesses of its own.
- **`playbackId` is optional.** The server omits it when a row has no external id. The repository maps a track without it to a non-playable domain `Track`.
- **Unknown keys are ignored**, so a newer server's extra fields do not break decoding. This holds because response objects in the spec are open; the generated decoder keeps extra keys in the model's `additionalProperties` map. Unknown enum values decode to the enum's `Unknown` subtype (`TrackSourceUnknown`), which keeps the raw value.
- **A decode failure is a contract bug.** It surfaces as `ApiException` of kind `InvalidResponse`, is logged at `severe` with the operation id and the failing key (no payload), and the screen shows the generic error view. It is not papered over, because P9's response validation is meant to make it impossible.
- Timestamps are `date-time` strings decoded to UTC `DateTime`.
- Request bodies are generated too. The `metadata` object sent with a `playbackId` is always built from the `TrackMeta` the client already holds.

## URL Builders

```dart
class StreamUrls {
  /// Track stream. `quality` null means "server default" (no parameter).
  Uri track(String playbackId, {String? quality, bool reportPlay = false});
  Uri episode(String podcastId, String episodeId);
  /// Resolves a server-provided relative URL such as an offline `downloadUrl`.
  Uri resolve(String serverRelative);
  /// Headers for native players and the downloader; empty on web.
  Map<String, String> authHeaders(Credentials c);
  /// Adds `?token=<accessJwt>` for web playback and images. Throws for API keys.
  Uri withQueryToken(Uri uri, JwtCredentials c);
}

class ImageUrls {
  /// `ref` is the server's cover value (id, hash, absolute URL, or `/podcasts/...` path).
  /// `logicalPx * devicePixelRatio` is rounded up to 64, 128, 192, 320, 512, or 768.
  Uri cover(String ref, {required double logicalPx, required double devicePixelRatio});
}
```

`reportPlay: false` adds the P7 marker ([12](12-server-prerequisites-p6-p9.md)). The client always passes `false`.

`ImageUrls.cover` reproduces the three cases of the web builder (`frontend/lib/api/media.ts`): an id or hash → `/library/cover-art/<encoded>?size=`; an `http(s)://` value → `/library/cover-art?url=<encoded>&size=`; a value starting with `/podcasts/` or `/audiobooks/` → `/api<path>`.

## Endpoint Inventory

The complete set of server operations the client calls. This list is the **client surface**: P9's registry on the server contains exactly these operations, and the generated clients expose exactly these methods. Adding a row here means adding the operation to the registry in the same PR. "MS" is the milestone that first needs it.

### Connection and session

| Method and path | Auth | Request | Response (fields used) | MS |
|---|---|---|---|---|
| `GET /health` | none | | `status`, `draining`, `startupComplete` | M0 |
| `GET /auth/config` | none | | `localLoginEnabled`, `oidcEnabled`, `oidcProviderName` | M0 |
| `GET /onboarding/status` | none | | `needsOnboarding`, `hasAccount` | M0 |
| `POST /auth/login` | none | `username`, `password`, `token?` | `token`, `refreshToken`, `user{id,username,displayName,role}` or `requires2FA` | M0 |
| `POST /auth/refresh` | none | `refreshToken` | `token`, `refreshToken` | M0 |
| `POST /auth/logout` | JWT | | | M0 |
| `GET /auth/me` | any | | `id`, `username`, `displayName`, `role` | M0 |
| `POST /device-link/verify` | none | `code`, `deviceName` | `apiKey`, `userId`, `username` | M2 |
| `GET /api-keys` | any | | `apiKeys[{id,name,createdAt,expiresAt}]` | M2 |
| `DELETE /api-keys/current` | API key | | | M2 (P6) |
| `GET /docs.json` | any | | `info.version` | M0 |
| `GET /system/features` | any | | `audioAnalysis`, `discovery`, `autoPlaylists`, `federation`, `vibeEmbeddings`, `loudnessTargetLufs` | M0 |
| `GET /settings`, `POST /settings` | any | | `playbackQuality`, `loudnessMode`, `maxCacheSizeMb` | M1 |

### Library and browse

| Method and path | Request | Response (top-level keys) | MS |
|---|---|---|---|
| `GET /library/artists` | `limit`, `offset`, `cursor`, `filter`, `sortBy`, `origin`, `query` | `artists`, `total`, `offset`, `limit`, `nextCursor` | M0 |
| `GET /library/artists/:id` | `includeDiscography`, `includeTopTracks`, `includeSimilarArtists` | artist + `albums`, `topTracks`, `similarArtists`, `bio`, `genres` | M0 |
| `GET /library/albums` | `artistId`, `limit`, `offset`, `filter`, `sortBy`, `origin` | `albums`, `total`, `offset`, `limit` | M0 |
| `GET /library/albums/:id` | `includeTracks` | album + `artist`, `tracks`, `coverArt`, `owned` | M0 |
| `GET /library/tracks` | `albumId`, `limit`, `offset`, `sortBy`, `origin` | `tracks`, `total`, `offset`, `limit` | M0 |
| `GET /library/tracks/shuffle` | `limit` | `tracks`, `total` | M1 |
| `GET /library/liked` | `limit`, `cursorLikedAt`, `cursorTrackId` | `playlist`, `tracks`, `total`, `pagination{hasMore,nextCursor}` | M0 |
| `POST /library/preferences` | `playbackId`, `signal`, `metadata?` | `state`, `likedAt` | M1 |
| `POST /library/albums/:id/preference` | `signal` | `state` | M1 |
| `GET /library/recently-listened` | `limit` | `items` | M0 |
| `GET /library/recently-added` | `limit` | `artists` | M0 |
| `GET /library/cover-art[/:id]` | `size`, `url` | image bytes | M0 |
| `GET /playlists` | `limit`, `offset` | array of playlists with `trackCount`, `isOwner`, `items` (cover seeds) | M0 |
| `GET /playlists/:id` | | `items[{id,sort,track,playback{isPlayable,reason}}]`, `isOwner`, `isPublic` | M0 |
| `POST /playlists` | `name`, `isPublic?` | playlist | M1 |
| `PUT /playlists/:id` | `name?`, `isPublic?` | playlist | M1 |
| `DELETE /playlists/:id` | | | M1 |
| `POST /playlists/:id/items` | `playbackId`, `metadata?` | item | M1 |
| `DELETE /playlists/:id/items/:playbackId` | | | M1 |
| `PUT /playlists/:id/items/reorder` | `playbackIds` (full order) | | M1 |
| `GET /search` | `q`, `type`, `limit`, `offset`, `source` | `artists`, `albums`, `tracks`, `podcasts`, `episodes`, `remoteTracks`, `remoteAlbums` | M0 |
| `GET /search/discover` | `q`, `type`, `limit` | `results`, `aliasInfo` | M0 |

### Playback, plays, state, lyrics

| Method and path | Request | Response | MS |
|---|---|---|---|
| `GET /playback/stream/:playbackId` | `quality?`, P7 marker, `Range`, `If-Range` | audio bytes; `ETag` for library files | M1 |
| `GET /playback/stream-info/:playbackId` | `quality?` | `contentType`, `codec`, `bitrate`, `sampleRate`, `bitDepth`, `durationMs`, `contentLength`, `quality` | M1 |
| `POST /plays` | `playbackId`, `metadata?`, `playedAt`, `listenedMs` (P8) | play row | M1 |
| `GET /playback-state` | header `X-Playback-Device-Id` | state row or `null` | M1 |
| `POST /playback-state` | `playbackType`, `playbackId?`, `podcastId?`, `queue?`, `currentIndex?`, `isShuffle?`, `isPlaying?`, `currentTime?` | state row | M1 |
| `DELETE /playback-state` | | | M1 |
| `GET /lyrics/:trackId` | `artist`, `title`, `album`, `duration` | `syncedLyrics`, `plainLyrics`, `synced`, `source` | M1 |

`GET /lyrics/:trackId` takes a library track id, not a `playbackId`. The client passes the track's library id when the server returned one on the track payload, together with the metadata parameters, and otherwise calls it with the `playbackId` value in the path and relies on the metadata parameters. Whether the server accepts a non-library value there is verified when the operation is added to the P9 registry (S1-P9c); if it does not, lyrics for non-library tracks become a P-item appended to [12](12-server-prerequisites-p6-p9.md).

### Offline

| Method and path | Request | Response | MS |
|---|---|---|---|
| `POST /offline/items` | `kind`, `id`, `deviceId`, `quality?` | `items[{playbackId,downloadable,downloadUrl,expectedSize,quality,contentType,reason?}]`, `estimatedTotalBytes`, `cacheLimitBytes`, `cacheUsedBytes` | M3 |
| `POST /offline/items/complete` | `deviceId`, `playbackId`, `quality`, `sizeBytes` | echo | M3 |
| `DELETE /offline/items` | `deviceId`, `playbackIds[]` (≤ 500) | `deletedCount` | M3 |
| `GET /offline/items` | `deviceId` | `items[{playbackId,quality,sizeBytes,revoked}]` | M3 |
| `GET /offline/stats` | `deviceId` | `usedMb`, `maxMb`, `device{usedMb,trackCount}` | M3 |

### Podcasts

| Method and path | Request | Response | MS |
|---|---|---|---|
| `GET /podcasts` | | array of subscribed podcasts | M1 |
| `GET /podcasts/:id` | | podcast + `episodes[{id,title,duration,publishedAt,progress}]` | M1 |
| `GET /podcasts/:podcastId/episodes/:episodeId/stream` | `Range` | audio bytes | M1 |
| `POST /podcasts/:podcastId/episodes/:episodeId/progress` | `currentTime`, `duration`, `isFinished` | | M1 |
| `GET /podcasts/discover/top` | `limit` | array | M1 |
| `POST /podcasts/subscribe`, `POST /podcasts/:id/unsubscribe` | | | M1 |

### Home, discovery, social (M4 unless noted)

| Method and path | Feature gate | MS |
|---|---|---|
| `GET /mixes`, `GET /mixes/:id` | `autoPlaylists` | M0 (home shelf), M4 (detail) |
| `GET /recommendations/for-you` | `discovery` | M4 |
| `GET /discover/current`, `GET /discover/popular-artists` | `discovery` | M4 |
| `GET /library/radio`, `/library/radio/genres`, `/library/radio/decades` | none | M4 |
| `GET /vibe/similar/:trackId`, `POST /vibe/search` | `audioAnalysis` | M4 |
| `POST /listen-together`, `POST /listen-together/join`, `GET /listen-together/discover`, `GET /listen-together/mine`, `POST /listen-together/:id/leave`, `POST /listen-together/:id/end` | none | M4 |
| `POST /social/presence/heartbeat`, `GET /social/online` | none | M4 |

## Pagination

Three server styles exist; each gets one reusable Dart type.

| Style | Endpoints | Client type |
|---|---|---|
| Offset (`limit`, `offset`, `total`) | Albums, tracks, playlists list, search | `OffsetPage<T>` |
| Offset with optional cursor (`nextCursor`) | Artists | `OffsetPage<T>`; the cursor is passed back when present |
| Keyset (`cursorLikedAt`, `cursorTrackId`, `hasMore`) | Liked tracks | `KeysetPage<T, C>` |

Page size is 100 for lists and 60 for grids. The repository exposes a `PagedSource<T>` that the UI drives from scroll position ([09](09-ui-and-design-system.md)); cached pages are served first ([05](05-local-data.md)).

## Testing the Package

- **Unit** (`dart test`, `http_mock_adapter`): one test file per interceptor, for error mapping, and for the URL builders. Generated code is not unit-tested in the client; its shapes are proven on the server by P9's response validation.
- **Decode smoke:** `tool/capture_fixtures.dart` records one real response per operation from the contract server; a single table-driven test decodes each with its generated model. This catches generator defects (as opposed to spec defects).
- **Contract** (`client/contract_test`, tag `contract`): behaviour against a seeded server that runs with response validation on. See [11](11-testing-and-ci.md).
- **Spec gates:** the committed spec equals the backend's emitted spec; generated Dart is current; `tool/spec_compat.dart` passes against the `minServer` snapshot.

## Spike S8 Finding

Spike S8 ([13](13-milestones-and-work-breakdown.md)) generated the client from the committed `soundspan-client.json` (S1-P9b surface) and decoded hand-written bodies built from its schemas. The answer is **yes, with a spec constraint**: `swagger_parser` is the generator.

**Versions.** Dart 3.14.0 (Flutter 3.50.0); `swagger_parser` 2.1.1 (`swagger_parser_core` 1.0.2), `freezed` 4.0.3, `freezed_annotation` 3.1.0, `json_serializable` 6.15.2, `json_annotation` 4.12.0, `retrofit` 4.10.0, `retrofit_generator` 10.3.3, `dio` 5.11.1, `build_runner` 2.17.1.

**Configuration.** The block under [Generated From the Server Specification](#generated-from-the-server-specification). `swagger_parser` 2 replaced the flat 1.x options: `language`, `json_serializer`, `root_client`, `root_client_name`, `put_clients_in_folder`, `unknown_enum_value` and `mark_files_as_generated` are rejected as unknown keys. Their equivalents are `generation.serializer`, `generation.http_client`, `generation.root_api_class_name` and `generation.unknown_enum_values`; the root client, the per-tag folders and the generated-file marker are always produced.

| # | Question | Answer |
|---|---|---|
| 1 | Generation runs and the output compiles | Yes. `dart run swagger_parser`, `build_runner build` and `dart analyze --fatal-infos` (default lints) exit 0 with no findings. The output uses Dart primary constructors (`class const Foo({...})`), so it needs the Dart of `client/.fvmrc`. |
| 2 | Optional versus nullable fields | Yes. A key in `required` that is `nullable` becomes `required final T? field` and must be present (as `null` or a value); a key outside `required` becomes `final T? field` and may be absent; an absent `required` key throws. |
| 3 | `oneOf` responses | Yes. `login` returns a sealed `LoginResponse200` with the subtypes `LoginTokenResponse` and `LoginTwoFactorChallenge`; the decoder matches the body against each branch's required keys and types, and the caller tells them apart with a `switch` on the type. |
| 4 | Unknown enum values | Yes, with `unknown_enum_values: preserve`. Each enum becomes a sealed type with `<Enum>Known` (wrapping a Dart `enum`) and `<Enum>Unknown` (holding the raw value, which `toJson` writes back unchanged). |
| 5 | One client per tag | Yes. One `<Tag>Client` per operation tag, each a getter of `SoundspanRestClient`; the getter for `library` is `library2`. |
| 6 | Method names from `operationId` | Yes. Every operation has a method named after its `operationId` that sends the spec's method and path; query parameters, path parameters and JSON bodies serialise as declared (enum query values as their wire strings). |
| 7 | Unknown keys are ignored | Yes, with a spec constraint. The committed spec closes every object (`additionalProperties: false`), and the generator turns that into `disallowUnrecognizedKeys` and a branch matcher that rejects extra keys, so a body with an extra key fails to decode. The same spec with `additionalProperties: false` removed decodes it and keeps the extra key in `additionalProperties`. Response objects in the client surface are therefore emitted open ([12](12-server-prerequisites-p6-p9.md), Serialisation Rules). |
| 8 | `date-time` strings decode to UTC `DateTime` | Yes. `DateTime.parse(value).toUtc()`; the decoded values have `isUtc` set. |

