# 04. Auth and Server Profiles

Status: design phase.

Code lives in `lib/core/auth/`, `lib/core/profile/`, and `lib/features/connect/`.

## Server Behaviour This Relies On

Checked in the backend source; the contract suite ([11](11-testing-and-ci.md)) keeps these true.

- Access JWT lifetime is 24 hours and refresh JWT lifetime is 30 days (`backend/src/middleware/auth.ts`). Refresh rotates both tokens. Tokens are stateless; a rotated-out refresh token stays valid until it expires or the user's `tokenVersion` changes.
- Credential precedence is `X-API-Key`, then `?token=` (only on `requireAuthOrToken` routes, and only an access JWT), then `Authorization: Bearer`. There is no cookie auth.
- `/api/offline/*` uses `requireAuth`, so `?token=` is not accepted there.
- Login with 2FA: the first `POST /api/auth/login` returns HTTP 200 `{ requires2FA: true }` with no tokens. The client resubmits username, password, and `token` (6-digit TOTP or 8-hex recovery code).
- Device link: the signed-in web UI generates a 6-character code (alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, 5-minute lifetime). The device submits it to `POST /api/device-link/verify` and receives `{ success, apiKey, userId, username }`. `apiKey` is 64 hex characters.
- API keys expire 90 days after creation and cannot be renewed.
- `DELETE /api/api-keys/:id` and `DELETE /api/device-link/devices/:id` reject API-key sessions (`requireInteractiveSession`). A device-linked client cannot revoke its own key (closed by P6).

## Profile Record

Stored in `AppDatabase.profiles` ([05](05-local-data.md)). Secrets are never in this row.

| Field | Type | Notes |
|---|---|---|
| `id` | UUID v4 | Generated on creation. Names the profile's directories and secret keys. |
| `baseUrl` | text | Normalized, final (after redirects), no trailing slash, may include a path prefix |
| `displayName` | text | User-editable; defaults to the host |
| `userId`, `username`, `userDisplayName`, `role` | text | From the sign-in response or `GET /auth/me` |
| `authKind` | `password` \| `deviceLink` \| `apiKey` | |
| `deviceId` | UUID v4 | Generated on creation. Sent as offline `deviceId` and `X-Playback-Device-Id`. Not a secret. |
| `credentialCreatedAt` | UTC timestamp | For API keys: when the key was issued, to compute expiry |
| `credentialExpiresAt` | UTC timestamp, nullable | From `GET /api-keys` when the key can be identified; else `credentialCreatedAt + 90 days` |
| `serverVersion` | text | Last seen `info.version` |
| `features` | JSON | Last `GET /system/features` body, subset used by the client |
| `featuresFetchedAt` | UTC timestamp | |
| `state` | `active` \| `signedOut` | `signedOut` keeps cache and downloads |
| `lastUsedAt` | UTC timestamp | Orders the server switcher |

Uniqueness: `(baseUrl, userId)`. Adding the same pair again updates the existing profile's credential.

### Secret Storage

`SecretStore` keys, all namespaced by profile id:

| Key | Value |
|---|---|
| `p/<profileId>/refresh` | Refresh JWT |
| `p/<profileId>/access` | Access JWT (stored so a cold start does not need a refresh round-trip) |
| `p/<profileId>/apikey` | API key |

`flutter_secure_storage` options: Android uses the plugin's default storage (AES-GCM with an RSA-OAEP key wrapped in the Android Keystore; the plugin removed `encryptedSharedPreferences` in its version 11 and migrates any data stored that way); iOS and macOS `accessibility: first_unlock_this_device` (background playback after a reboot needs the key before the first foreground, and it must not migrate to another device); Linux libsecret; Windows Credential Manager. A `PlatformException` from the plugin surfaces as `SecretStoreUnavailable`. On web the implementation keeps tokens in memory and mirrors them to `sessionStorage` so a reload keeps the session; nothing is written to `localStorage`. A new web store loads the `sessionStorage` entries whose key starts with `p/`, and when `sessionStorage` throws the store keeps working from memory.

Deleting a profile deletes its three keys, its directory tree, and its row, in that order.

## Address Normalization

`ServerAddress.parse(String input)` is a pure function with table-driven tests.

```text
1. Trim whitespace. Reject empty input.
2. If the input parses as soundspan://link?... → extract `server` and `code`; continue with `server`.
3. If there is no "://", prepend a scheme:
     - host is an IP literal in a private, loopback, or link-local range, or ends in .local / .lan /
       .home.arpa / .internal, or has no dot (single-label host)  → candidates [http, https]
     - otherwise                                                   → candidates [https]
   An explicit scheme gives exactly one candidate. Schemes other than http and https are rejected.
4. Lower-case the scheme and host. Keep the port unless it is the scheme default.
5. Keep the path. Remove a trailing "/api", "/api/", and any trailing slashes. Drop query and fragment.
6. Result: ordered list of candidate base URLs.
```

Private ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`, `169.254.0.0/16`, `100.64.0.0/10` (carrier-grade NAT, used by mesh VPNs), `fc00::/7`, `fe80::/10`, `::1`.

Explicit `http://` to a public host is allowed only after the user confirms a warning dialog. This is the design's "plain http only for LAN hosts, with a warning" made concrete: LAN hosts get a passive warning chip, public hosts get a blocking confirmation.

## Probe

`ProbeController` (an `AsyncNotifier<ProbeState>`) tries each candidate in order and stops at the first that reaches `ready`.

```text
           ┌──────────┐  GET /api/health   ┌───────────────┐  GET /api/auth/config       ┌────────┐
 input ──▶ │ resolving│ ─────────────────▶ │ health checked│ ──────────────────────────▶ │ config │
           └──────────┘                    └───────────────┘  GET /api/onboarding/status  └────────┘
                │ failure                         │ 503 draining/starting                    │
                ▼                                 ▼                                          ▼
          classified error                 "server is starting" + auto-retry         ready | needsSetup
```

Rules:

- Redirects are **not** followed automatically by the probe's dio (`followRedirects: false`). A 301, 302, 307, or 308 from `/api/health` is followed manually, at most 3 hops, and only when the target is `http(s)`. The final base is recomputed from the final URL by stripping `/api/health`. If it differs from what the user typed, the result screen shows "Using `<final>`" before continuing. A downgrade from `https` to `http` is refused.
- `/api/health` is accepted when the body is JSON with a string `status`. Anything else is `NotSoundspan`.
- 503 with a valid health body means starting or draining: show that, retry every 3 s up to 30 s.
- `onboarding/status.hasAccount == false` → `needsSetup`: the screen explains that the server must be set up in its web UI and offers "Open in browser" (`url_launcher`).
- All three requests share a 10 s connect and 10 s receive timeout.

### Failure Classification

| Signal | Class | Message key |
|---|---|---|
| `SocketException` with OS error "host lookup failed" | `dns` | Address not found |
| `SocketException` connection refused | `refused` | Nothing is listening at that address and port |
| Timeout | `timeout` | The server did not answer |
| `HandshakeException`, `TlsException`, certificate verify failed | `tls` | The server's certificate is not trusted by this device |
| HTTP 401 or 403 on `/api/health` | `blockedByProxy` | Something in front of the server requires its own login |
| HTTP 404 or non-JSON 200 | `notSoundspan` | That address is not a soundspan server (check the path) |
| HTTP 5xx without a health body | `serverError` | |
| Web only: `DioExceptionType.connectionError` with no response | `corsOrNetwork` | Shows `ALLOWED_ORIGINS` instructions with this app's origin |

On web a CORS rejection is indistinguishable from a network failure in the Fetch API, so the web message covers both and puts the origin string in a copyable field.

When the input came from a QR code (`server` is an origin without a path) and the class is `notSoundspan`, the screen asks for the path and re-probes, keeping the code.

## Sign-In

The sign-in screen renders only what `auth/config` allows:

| `localLoginEnabled` | `oidcEnabled` | Screen |
|---|---|---|
| true | false | Password form; "Link with a code" and "Use an API key" as secondary actions |
| true | true | Same, plus a note that single sign-on users should link with a code |
| false | true | Device-link panel, titled "Sign in with `<oidcProviderName>`", with the steps to get a code from the web UI; API key as secondary |
| false | false | API key only (cannot occur on a configured server; handled for completeness) |

On web, API-key and device-link options are hidden: API keys cannot be used in `?token=` stream URLs (`PlatformCapabilities.supportsApiKeyStreaming == false`).

### Password

```text
POST /api/auth/login { username, password }
  200 { token, refreshToken, user }         → signed in
  200 { requires2FA: true }                 → show the code step, keep username/password in memory
  401 { error: "Invalid credentials" }      → inline error
  403 { error: "Local login is disabled" }  → re-run the probe (config changed)
  429                                       → "Too many attempts", countdown from Retry-After

POST /api/auth/login { username, password, token }
  200 { token, refreshToken, user }         → signed in
  401 "Invalid 2FA token" | "Invalid recovery code" → inline error, stay on the code step
```

The code step accepts 6 digits (authenticator) or 8 hexadecimal characters (recovery), with a toggle between them, matching the web UI. The password is held in the notifier's memory only, cleared on success, on leaving the screen, and after 5 minutes.

### Device Link

The app never generates a code. The user gets one from the web UI's device page.

- **Manual entry:** six cells, upper-cased as typed, restricted to `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`. Pasting a full code fills all cells. Characters outside the alphabet are rejected with a hint that the code has no `I`, `O`, `0`, or `1`.
- **QR scan:** `/connect/scan` (`mobile_scanner`). Accepts `soundspan://link?code=&server=` and plain `http(s)://` URLs. Camera permission is requested only when the scanner opens.
- **Deep link:** the OS delivers `soundspan://link?...` through `app_links`; the router goes to `/connect/probe` with the code.
- **Submit:** `POST /api/device-link/verify { code, deviceName }` → `{ apiKey, userId, username }`.
- `deviceName` is built locally: `"<model or hostname> (soundspan <os>)"`, at most 64 characters, from `device_info`-free sources (`Platform.localHostname` on desktop; a generic "Android phone"/"iPhone" on mobile, editable before submit). No hardware identifiers.
- Errors: 400 `Code already used` / `Code expired`, 404 `Invalid code` → inline, with "Generate a new code in the web UI". 429 → countdown.

After success the client calls `GET /api/auth/me` (role, display name) and `GET /api/api-keys` to find its own key's `expiresAt` by matching `name == deviceName` and the newest `createdAt`. If no unique match exists, it uses `now + 90 days`.

### Pasted API Key

A single field; the key is validated with `GET /api/auth/me`. Expiry is looked up as above when the key's name can be matched (it usually cannot; the user is told the key's expiry is unknown and that the app will prompt when the server rejects it).

## Session Lifecycle

`SessionController` (profile scope) implements `CredentialProvider` and owns the profile's `state`.

| Event | Action |
|---|---|
| Tokens rotated | Write `refresh` then `access` to `SecretStore`; update in-memory credential |
| `onUnauthenticated(sessionExpired)` (refresh rejected) | Profile → `signedOut`; stop playback; keep cache, downloads, outbox; router redirects to sign-in with the server and username prefilled |
| `onUnauthenticated(keyRejected)` (API key 401) | Same, with the "Link again" flow |
| User signs out | See below |
| User deletes profile | Sign out, then delete data |

### API-Key Expiry

- `KeyExpiryMonitor` computes days remaining from `credentialExpiresAt` on start and once a day.
- From 14 days before expiry: a persistent banner on Home ("This device's link expires in N days · Link again") and one local notification (re-shown at 3 days and 1 day).
- "Link again" runs the device-link flow for the same server. On success the new key replaces the old one in `SecretStore`, and the old key is revoked with `DELETE /api/api-keys/current` sent **with the old key** before it is discarded (P6). If that call fails, the old key is simply dropped; it expires on its own.

### Sign-Out

1. Stop playback and close the socket.
2. Cancel running downloads (files already complete are kept unless the user ticked "Also remove downloads").
3. Try the outbox once (5 s budget) so pending likes and plays are not lost.
4. Revoke: JWT session → `POST /api/auth/logout` (a server no-op, kept for forward compatibility); API-key session → `DELETE /api/api-keys/current` (P6).
5. Delete secrets. Set `state = signedOut`.
6. If "Remove this server" was chosen: delete `cache.db`, `state.db`, images, media, and the profile row. With downloads present, `DELETE /api/offline/items` for this device is attempted in step 3.

Steps 3 and 4 are best-effort with short timeouts; sign-out always completes locally.

## Capability Discovery and Version Gate

Runs after sign-in, on every app start, and on resume after more than one hour in the background. Implemented by `CapabilityRefresher`.

```dart
class ServerCapabilities {
  final Version serverVersion;
  final bool audioAnalysis, discovery, autoPlaylists, federation, vibe;
  final double loudnessTargetLufs;
  final bool hasP6SelfRevoke, hasP7PlayMarker, hasP8PlayedAt;   // derived from version
}
```

- `GET /api/docs.json` is requested with `Accept: application/json` and decoded with a streaming JSON reader that stops after `info.version`, because the document is large. A 401/403/404 here (docs disabled by a proxy) falls back to `GET /api/health` → `version`, and if that is `unknown` the client proceeds as "version unknown" with a dismissible warning.
- `Version` is parsed as semver; pre-release tags compare lower than the release.
- Gate:

| Server version | Behaviour |
|---|---|
| `< minServer` | Sign-in is blocked on the probe result screen: "This app needs soundspan `<minServer>` or newer. This server runs `<v>`." An existing profile becomes read-only-offline (downloads still play). |
| `minServer … maxTestedServer` | Normal |
| `> maxTestedServer` | Dismissible banner once per server version |
| unknown | Dismissible banner; behave as in range |

- Feature flags drive navigation: destinations and actions are built from `ServerCapabilities`, so a disabled feature has no entry point. `FeatureDisabled` responses trigger an immediate refresh.
- The result is cached on the profile row, so the correct navigation is shown offline and on cold start before the refresh returns.

## Multiple Profiles

- `Settings → Servers` lists profiles ordered by `lastUsedAt`, with state, server version, and storage used.
- Switching: `ProfileRuntime.switchTo(id)` pauses playback, awaits disposal of the old profile container (databases closed, socket closed, downloader tasks of the old profile left running in the OS and re-attached when that profile is active again), then creates the new container. The UI shows a 150 ms cross-fade; nothing from the old profile is readable during or after it.
- Downloads of an inactive profile continue in the OS scheduler on mobile; their completion callbacks are queued in `state.db` of that profile by a small root-scope handler that opens the database only long enough to record the result.
- Deep links that name a server (`soundspan://link?server=`) match an existing profile by normalized base URL before offering to add a new one.
