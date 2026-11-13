# 12. Server Prerequisites P6–P9

Status: design phase.

Four additive server changes the client needs beyond the Unified Playback API (P1–P5, `docs/designs/unified-playback-api.md`). They follow that document's rules: no existing route, field, or behaviour changes; each is its own PR (P9 is a series) with tests against real PostgreSQL where data is involved, OpenAPI annotations, and a `CHANGELOG.md` entry. Work stream **S1**. The release that contains P1–P9 is the client's `minServer`.

Parameter and path names below are proposals; the server PR fixes them and this document and the client follow.

## P6. A Credential Can Revoke Itself

### Problem

`DELETE /api/api-keys/:id` and `DELETE /api/device-link/devices/:id` use `requireInteractiveSession`, which rejects any request carrying `X-API-Key` (`backend/src/middleware/auth.ts`). That is correct for managing *other* keys, but it means a device-linked app cannot clean up after itself: sign-out and re-link leave live keys behind until they expire after 90 days.

### Change

`DELETE /api/api-keys/current`

- Auth: `requireAuth`. Must be authenticated **with an API key**; a JWT session gets 400 `{ error, code: "NOT_API_KEY_SESSION" }`.
- Effect: deletes the API key that authenticated this request, and disconnects sockets authenticated with it (`revokeApiKeySockets`, already used by the other delete paths).
- Response: `200 { message: "API key revoked successfully" }`.
- The authenticating key's id is already resolved by the auth middleware; the handler needs it exposed on the request (it is recorded for sockets as `socket.data` today).
- Route order: registered before `/:id` so `current` is not read as an id.

No new capability is granted: possession of a key already allows everything the key can do, and destroying it only reduces access.

### Tests

- Key deletes itself; a second request with it is 401.
- JWT session → 400.
- Another user's keys are untouched.
- A socket authenticated with the key is disconnected.

## P7. Stream Requests Can Opt Out of Implicit Play Logging

### Problem

`streamLibraryTrack` records a play for every request to a library track's stream, before sending bytes, deduplicated per user and track within 30 seconds (`backend/src/services/playback/streamLibraryTrack.ts`). For a client that is not the web player this produces wrong history:

- An offline download of an album records a play for every track.
- Preloading the next track for gapless playback records a play even if the user skips before it starts.
- Remote-source tracks are *not* logged on stream, so the same action is counted differently depending on a source the client is not allowed to know about.

### Change

`GET /api/playback/stream/:playbackId` accepts `report=0`.

- `report=0`: the handler streams exactly as it does today but does not record a play for any source.
- Absent or any other value: today's behaviour. The web UI and third-party clients are unaffected.
- `POST /api/offline/items` builds each `downloadUrl` with `report=0` appended (`/api/playback/stream/<id>?quality=<q>&report=0`), so downloads never count as plays regardless of client.
- The parameter is threaded from the route through `resolvePlayback` to the library stream service as an option; the legacy per-source route `/api/library/tracks/:id/stream` is not changed.
- The `ETag` and `If-Range` behaviour is unaffected (the tag derives from playbackId, variant, and size).

The client then reports every play explicitly with `POST /api/plays`, which already accepts a `playbackId` for library and remote tracks alike.

### Tests

- Stream with `report=0` creates no `Play` row; without it, one row (existing behaviour).
- `downloadUrl` values contain `report=0`.
- Range and `If-Range` requests behave identically with and without the parameter.
- `POST /api/plays { playbackId }` for a library track creates a play when no stream was requested in the previous 30 seconds, and its interaction with the dedupe window is specified: an explicit `POST /api/plays` is never dropped by the stream dedupe.

## P8. Plays Accept a Client Timestamp and a Listened Duration

### Problem

`POST /api/plays` stamps `playedAt` with the server's current time, and a `Play` row records that a track was played but not for how long (`backend/src/routes/plays.ts`, `backend/prisma/schema.prisma`).

- Plays made while offline are sent later from the client's outbox and would all be recorded at reconnect time, in the wrong order relative to other devices, and scrobbled to Last.fm and ListenBrainz with the wrong time.
- The client reports every play together with the total time the track was heard. The server has nowhere to keep that.

### Change

`POST /api/plays` accepts two optional fields on both the `playbackId` form and the legacy forms.

**`playedAt`** (ISO-8601 UTC string): the instant the play began.

- Validation: must parse; must not be more than 5 minutes in the future (clock skew allowance); must not be older than 14 days. Outside the window → 400 `{ error, code: "INVALID_PLAYED_AT" }`.
- Absent: current time, as today.
- The stored `Play.playedAt` and the scrobble `listenedAt` both use the accepted value.

**`listenedMs`** (integer): the total time the track was audibly playing during this play, in milliseconds. Every heard stretch counts, whatever seeking happened between them, so the value can be smaller than the track's length (skipped) or larger (a passage was replayed).

- Validation: an integer from 0 to 86,400,000 (24 hours). Otherwise 400 `{ error, code: "INVALID_LISTENED_MS" }`.
- **Minimum listen.** A request whose `listenedMs` is below 5,000 is not recorded as listened: no `Play` row is created, nothing is forwarded to scrobblers, and the answer is 200 `{ recorded: false }`. The limit is one server constant (`MIN_LISTENED_MS`). First-party clients do not send such plays; the server rule makes the behaviour the same for every client. Requests without `listenedMs` are not affected.
- Stored in a new nullable column `Play.listenedMs Int?` (one Prisma migration, no backfill). Rows created without the field, including the stream handler's implicit plays and the web player's, keep `null`, which means "not measured".
- Returned on the play row in the response and wherever play rows are already returned.
- No existing consumer of `Play` rows changes behaviour.

**Idempotency.** A repeat of the same `(userId, track, playedAt)` returns the existing row instead of inserting a duplicate, so an outbox retry after a lost response cannot double-count. This applies only when `playedAt` is supplied.

### Tests

- Supplied timestamp is stored and forwarded to scrobblers.
- Future and too-old timestamps are rejected.
- `listenedMs` is stored and returned; negative, fractional, and over-limit values are rejected; a value larger than the track's duration is accepted.
- `listenedMs` of 4,999 creates no row, forwards no scrobble, and answers `{ recorded: false }`; 5,000 is recorded.
- A repeated request returns the same row; history shows one play.
- Absent fields behave as before, including for the legacy identifier forms; the row's `listenedMs` is `null`.
- The migration applies to a database with existing `Play` rows.

## P9. A Typed OpenAPI Description of the Client Surface

### Problem

The client's API models and endpoint methods are generated from the server's OpenAPI document. Today that document cannot drive a generator:

- It is assembled by `swagger-jsdoc` from `@openapi` comments. Of 480 operations, 366 declare no JSON response schema, 104 declare an inline one, 7 reference a named component, and none has an `operationId`.
- Nothing compares a comment with what its handler sends. Handlers call `res.json(...)` with Prisma results and ad hoc objects, so there is no response type to derive a schema from.

No tool produces correct response types from this code without the shapes being declared somewhere. P9 declares them once, on the server, in a form that is both the OpenAPI source and a runtime check.

### Scope

The **client surface**: the operations in the endpoint inventory of [03](03-api-layer.md), about 75 of the 480. Every other operation keeps its current comment-based description untouched. The surface grows only when a client needs another operation.

### Change

**1. Schemas are zod objects.** `backend/src/openapi/schemas/` holds one module per resource (`album.ts`, `track.ts`, `playlist.ts`, …). Each exported schema carries a component name:

```ts
export const AlbumSummary = z.object({
    id: z.string(),
    title: z.string(),
    year: z.number().int().nullable(),
    coverArt: z.string().nullable(),
    playbackId: z.string().optional(),
    addedAt: z.iso.datetime(),
}).meta({ id: "AlbumSummary" });
```

`zod` 4 is already a backend dependency and converts schemas to OpenAPI 3.0 itself (`z.toJSONSchema(schema, { target: "openapi-3.0" })`), so no new runtime dependency is needed. Where a route already validates its input with a zod schema, that schema object is exported and registered; it is not rewritten. Rules that JSON Schema cannot express (`superRefine` cross-field checks) are stated in the operation's description.

**2. Operations are declared in a registry.** `backend/src/openapi/clientSurface.ts`:

```ts
defineOperation({
    method: "get",
    path: "/api/library/albums/{id}",
    operationId: "getAlbum",
    tag: "library",
    params: z.object({ id: z.string() }),
    query: AlbumDetailQuery,
    responses: { 200: AlbumDetail, 404: ApiError },
});
```

- `operationId` is unique, camelCase, and becomes the generated method name. `tag` is exactly one of a fixed list (`session`, `library`, `playlists`, `search`, `playback`, `offline`, `podcasts`, `discovery`, `listenTogether`, `social`) and becomes the generated client class.
- `ApiError` is the shared `{ error: string, code?: string }` component. Every operation lists the error statuses it can return.
- Binary responses (streams, cover art) are declared with their media type and no schema; the client does not generate code for them.
- `swagger.ts` converts the registry into path items and component schemas and merges them over the comment-derived document. The `@openapi` comment of a registered operation is deleted, so each operation has one description.

**3. Responses are checked against the schemas.** A middleware, `validateClientSurfaceResponses`, wraps `res.json` for registered operations and parses the body with the schema for the status being sent.

- It is active only when `OPENAPI_VALIDATE_RESPONSES=1`: in the backend's route and integration tests, in the Unified Playback Smoke job, and in the client's contract server ([11](11-testing-and-ci.md)). In production it is not installed.
- A mismatch throws in tests and answers 500 `{ code: "RESPONSE_SCHEMA_MISMATCH" }` with the failing path in the contract server, so a drifting shape fails a test instead of reaching a client.
- Object schemas are non-strict: a handler may send extra fields. A field becomes part of the contract when it is added to the schema.

**4. The surface is emitted as a file.** `npm --prefix backend run openapi:emit-client` writes the surface subset (its paths, the components they reference, `info.version`) to `client/packages/soundspan_api/openapi/soundspan-client.json`, with stable key order. CI runs it and fails when the committed file differs, so a server PR that changes a surface shape shows the spec diff and the regenerated Dart in the same review.

### Serialisation Rules the Schemas Follow

| Server value | Schema |
|---|---|
| `Date` | `z.iso.datetime()` (string, `format: date-time`) |
| Prisma nullable column | `.nullable()`; the key is always present |
| Key the handler omits in some cases (`playbackId` on a track with no external id) | `.optional()` |
| Enum columns | `z.enum([...])`; clients must tolerate values added later |
| Integers that are counts, sizes, or durations | `z.number().int()` |
| Fields added after the `minServer` release | `.optional()` in responses, so one generated client decodes both server versions |

### What Does Not Change

- No route path, parameter, status code, or response body changes. P9 describes behaviour; it does not alter it. Where writing a schema exposes an inconsistency (a field that is sometimes a string and sometimes a number), the schema states the union and a follow-up issue is opened; the handler is not "fixed" inside a P9 PR.
- `openapiRouteSync.test.ts` and the existing documentation UI keep working; they read the merged document.

### Tests

- `clientSurface.test.ts`: every registered operation resolves to a mounted route; `operationId`s are unique; each has one known tag and a schema for every declared JSON status; no schema contains an untyped object.
- The middleware: a conforming body passes; a missing required key, a wrong type, and an undeclared status each fail; unregistered routes are untouched; with the variable unset nothing is wrapped.
- Existing route tests for surface operations run with validation on. Their fixtures become the proof that each schema matches its handler.
- The emitted file is deterministic (two runs are byte-identical).

### Delivery

A series, ordered by when the client needs each group:

| Step | Contents | Needed by |
|---|---|---|
| S1-P9a | `defineOperation`, registry merge in `swagger.ts`, `ApiError`, the middleware, the emitter and its CI check, `clientSurface.test.ts` | Everything below |
| S1-P9b | Connection and session; library and browse; playlists (read); search; home shelves | Client M0 |
| S1-P9c | Playback, plays, playback state, lyrics, settings, preferences, playlist mutations, podcasts | Client M1 |
| S1-P9d | Device link and API keys | Client M2 |
| S1-P9e | Offline | Client M3 |
| S1-P9f | Mixes, discovery, radio, vibe, Listen Together REST, presence | Client M4 |

## Rollout

| Step | Depends on | Needed by |
|---|---|---|
| S1-P7 (`report=0` and `downloadUrl`) | P2, P4 | Client M1 (play reporting), M3 (downloads) |
| S1-P8 (`playedAt`, `listenedMs`) | P3 | Client M1 (play reporting); essential for M3 (offline plays) |
| S1-P6 (self-revoke) | — | Client M2 (device link) |
| S1-P9a to S1-P9f (typed client surface) | — | Client M0 onward, group by group (see P9, Delivery) |

P6, P7, and P8 are independent and releasable alone; each also adds its operation to the P9 registry once S1-P9a exists. The client's contract suite gains a group per item when it lands, and `ServerCapabilities` derives `hasP6SelfRevoke`, `hasP7PlayMarker`, and `hasP8PlayedAt` from the server version so development builds can run against a server that has only some of them:

| Missing | Client behaviour in development builds |
|---|---|
| P6 | Skip the revoke call |
| P7 | Do not send explicit plays for streamed items (avoid double counting); downloads inflate history |
| P8 | Send plays without `playedAt` and `listenedMs`; offline plays are recorded at reconnect time |

P9 has no such branch: the client is generated from the spec file in the repository, not from the running server.

Release builds require `minServer`, which has P6–P8, so these branches are compiled out of release behaviour by the version gate.

## Documentation

- OpenAPI annotations for the new route and parameters.
- `CHANGELOG.md` entries.
- `docs/designs/unified-playback-api.md` gains a pointer to this document under Follow-Up; `docs/designs/flutter-client.md` lists P6–P9 in Server Prerequisites.
- The Unified Playback Smoke job (`smoke:unified-playback`) gains assertions for `report=0`, `playedAt`, `listenedMs`, and self-revoke, and runs with response validation on.
