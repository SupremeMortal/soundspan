# soundspan Client (Flutter)

Status: design phase.

A first-party soundspan client built with Flutter that ships from one Dart codebase to **Android, iOS, Windows, macOS, Linux, and the web**. Every native target renders with Flutter's own engine — **no webview on any native platform**. It is a pure API consumer of the soundspan REST, streaming, and socket.io surfaces. It requires **one server prerequisite**: a source-agnostic playback and offline API (see Server Prerequisites), so the client never needs to know where a track comes from. Beyond that, it uses the existing API as is.

## Goals and Non-Goals

### Goals

- One Flutter/Dart codebase for all six targets, with layouts adapted to phone, tablet, and desktop.
- Native-quality playback: background audio, lock-screen / OS media controls, gapless queue, Android Auto, offline downloads on native targets.
- **Connects to any self-hosted soundspan instance.** No server URL, account, or feature set is baked into the app; everything about a server is discovered at runtime (see Connecting to Any Self-Hosted Server).
- Multi-server: a client can store and switch between several soundspan servers.
- Works against any soundspan server at or above the version that ships the Server Prerequisites; the only operator-side knob that may be needed is `ALLOWED_ORIGINS` for the web target.

### Non-Goals

- Replacing the existing Next.js web frontend. It remains the primary web UI; the Flutter web build is a secondary target (see Platform Matrix).
- Admin surfaces (system settings, backup/restore, federation admin, queue dashboard). They stay in the existing web UI; the client links out to them.
- Backend changes beyond the Server Prerequisites. Any other feature that cannot be built on the current API is deferred and listed in Open Questions.
- Client-side knowledge of track sources. The client never branches on whether a track is local, federated, TIDAL, YouTube Music, or YouTube.
- Subsonic `/rest` as the primary protocol. It loses soundspan-specific features (vibe, mixes, Listen Together, TIDAL/YT Music sources).

## Technology Choice

Flutter is chosen because it is the most mature toolkit that covers all five native platforms without a webview:

| Option | Native targets without webview | Rejected because |
|---|---|---|
| **Flutter** | Android, iOS, Windows, macOS, Linux | — (chosen) |
| Tauri v2 + React | None (webview everywhere) | Webview feel and startup on mobile |
| Expo + Tauri | Android, iOS | Desktop still a webview; uncommon combination |
| React Native + RN Windows/macOS | Android, iOS, Windows, macOS | No Linux |
| Compose Multiplatform | All five | Desktop on JVM (memory), web in beta, thinner audio ecosystem |
| .NET MAUI | Android, iOS, Windows, macOS | No Linux, no web |

Accepted trade-offs: Dart instead of TypeScript (no code reuse with the Next.js frontend); a canvas-rendered web build; Flutter's own widgets rather than platform-default look.

### Language for Core Logic: Dart, Not Rust

All app logic (HTTP, auth, queue, downloads, offline outbox, caching) is written in **Dart**. Rust via `flutter_rust_bridge` was considered and rejected for v1:

- Dart already has mature, cross-platform packages for every core concern (listed below), so Rust would add a second toolchain to six build pipelines without replacing much code.
- Rust on the web target requires a WASM build and cross-origin isolation headers (COOP/COEP), which would break cross-origin artwork from CDNs that do not send CORP headers. Dart works on all six targets with one implementation.
- Playback, the one performance-sensitive area, is handled by native engines (ExoPlayer, AVPlayer, libmpv) through plugins, not by app code.

Rust remains an option for a future, isolated need (e.g. client-side DSP) behind an FFI package; nothing in this design blocks it.

## Platform Matrix

| Capability | Android | iOS | Windows | macOS | Linux | Web |
|---|---|---|---|---|---|---|
| Rendering | Impeller | Impeller | Skia/Impeller | Impeller | Skia | CanvasKit / skwasm |
| Audio backend | ExoPlayer (`just_audio`) | AVPlayer (`just_audio`) | libmpv (`just_audio_media_kit`) | AVPlayer (`just_audio`) | libmpv (`just_audio_media_kit`) | HTML audio (`just_audio`) |
| OS media controls | `audio_service` (MediaSession, notification) | `audio_service` (Now Playing, Control Center) | `smtc_windows` (SMTC) | `audio_service` (Now Playing) | `audio_service_mpris` (MPRIS) | `audio_service` (Media Session API) |
| Background playback | Foreground service | `audio` background mode | Yes | Yes | Yes | Tab must stay open |
| Car integration | Android Auto (`audio_service` browse tree) | CarPlay (M6) | — | — | — | — |
| Offline downloads | Yes | Yes | Yes | Yes | Yes | No |
| Credential storage | Keystore | Keychain | Credential Manager (DPAPI) | Keychain | libsecret | Memory / `sessionStorage` |
| CORS applies | No | No | No | No | No | Yes |
| Updates | Play Store / F-Droid | App Store | In-app updater (WinSparkle) | In-app updater (Sparkle) | Flatpak / package manager | Redeploy |
| Minimum version | Android 8 (API 26) | iOS 15 | Windows 10 1809 | macOS 11 | GTK 3.24 (Ubuntu 22.04-class) | Current Chrome, Firefox, Safari, Edge |
| App identifier | `io.soundspan.app` (applicationId) | `io.soundspan.app` (bundle ID) | `io.soundspan.app` (MSIX identity) | `io.soundspan.app` (bundle ID) | `io.soundspan.app` (Flatpak / desktop file) | — |

The web build is supported but secondary: canvas rendering gives weaker text selection and accessibility than the Next.js UI, and it cannot play in the background or download. It ships only as its own optional container image / static bundle; it is not bundled into the server image, and the Next.js UI stays the default web experience. Operators who deploy it either put it behind the same origin as the server or add its origin to `ALLOWED_ORIGINS`.

## Architecture

### Repository Layout

The client lives in this monorepo under `client/`, so a server API change and the matching client change can land in one PR. It still talks to the server only through the HTTP API and the OpenAPI spec, never by importing backend code. Monorepo implications:

- CI jobs for the client are path-filtered to `client/**` (plus `backend/src/routes/**` for the API contract tests), so server-only PRs do not pay for six-platform builds.
- Client releases use their own tag prefix (`client-v*`) and version, independent of server releases; signing secrets are scoped to the client release workflow.
- `AGENTS.md` gains a Dart section (handbook baseline, `flutter analyze` + `dart format` gates, logging and file-size rules extended to `client/lib`) when the scaffold lands.
- `CHANGELOG.md` entries for client changes go under a separate "Client" heading.

```
client/
├── lib/
│   ├── app/                 # App shell, router, theming, adaptive scaffold
│   ├── features/            # One folder per domain: library, search, player, downloads, social, settings…
│   │   └── <feature>/{data,domain,ui}/
│   ├── core/
│   │   ├── api/             # Generated OpenAPI client + transport, auth interceptor, errors
│   │   ├── auth/            # Server profiles, sign-in flows, token refresh
│   │   ├── playback/        # Queue model, audio handler, platform media-control adapters
│   │   ├── downloads/       # Download manager over background_downloader
│   │   ├── storage/         # drift database, secure storage, file layout
│   │   └── sync/            # Offline outbox, playback-state sync, play reporting
│   └── platform/            # Conditional imports: io vs web implementations
├── packages/
│   └── soundspan_api/       # Generated Dart client (openapi-generator, dart-dio)
├── android/ ios/ windows/ macos/ linux/ web/
├── integration_test/
└── tool/                    # Codegen, release, and signing scripts
```

### Layering

```
┌────────────── UI (widgets, go_router, adaptive layouts) ──────────────┐
│               Riverpod providers (state, async data)                    │
├────────────── Domain (queue, library models, use cases) ──────────────┤
├────────────── Data (repositories) ────────────────────────────────────┤
│  soundspan_api (dio)   drift DB   secure storage   background_downloader│
├────────────── Platform plugins ───────────────────────────────────────┤
│  just_audio · audio_service · media_kit · smtc_windows · mpris          │
└──────────── ExoPlayer · AVPlayer · libmpv · HTML audio ────────────────┘
```

Platform differences are isolated in `lib/platform/` with Dart conditional imports (`dart.library.io` vs `dart.library.js_interop`), so features never branch on platform directly.

### Key Packages

| Concern | Package |
|---|---|
| State / DI | `flutter_riverpod` |
| Routing | `go_router` |
| HTTP | `dio` (via the generated client) |
| API client | `openapi-generator` (`dart-dio`) from `/api/docs.json` |
| Local DB / cache | `drift` (SQLite; WASM build on web) |
| Secrets | `flutter_secure_storage` |
| Playback | `just_audio`, `just_audio_media_kit` (Windows/Linux) |
| Media controls | `audio_service`, `audio_service_mpris`, `smtc_windows` |
| Downloads | `background_downloader` |
| Images | `cached_network_image` |
| Realtime | `socket_io_client` |
| Desktop window / tray | `window_manager`, `tray_manager` |
| Desktop updates | `auto_updater` (Sparkle / WinSparkle) |

Package choices are pinned in `pubspec.lock`; each is re-evaluated in M0 against its current maintenance status before being adopted.

## Server Connection and Authentication

### Server Profiles

A profile is `{ id, baseUrl, displayName, userId, username, authKind, serverVersion, features }`. Profiles live in the drift DB; secrets live in secure storage keyed by profile id. Adding a profile runs the connection flow below.

### Connecting to Any Self-Hosted Server

The app ships with no default or hard-coded server. Each user points it at their own instance, whatever its hostname, reverse proxy, version, or configuration. Instances differ widely, so the client discovers everything at runtime using existing endpoints.

**1. Address entry and normalization**

- The user types an address in any reasonable form: `music.example.com`, `https://music.example.com`, `https://example.com/soundspan`, `192.168.1.20:3030`. A scheme is added if missing (`https://` first; `http://` only for LAN/private-range hosts), trailing slashes are trimmed, and a **path prefix is preserved** so instances published under a sub-path behind a reverse proxy work. Every API, stream, and socket URL is built from this base (`<base>/api/...`, `<base>/socket.io/...`), never from the host alone.
- Redirects returned by the probe (e.g. `http` → `https`, or a canonical hostname) are followed and the final URL is what gets saved, after showing the user the change.
- **QR code / deep link entry.** The web UI's device page (`frontend/app/device/page.tsx`) already renders a QR code of the form `soundspan://link?code=<CODE>&server=<url-encoded origin>`. The app registers the `soundspan://` scheme on every native target (Android intent filter, iOS/macOS `CFBundleURLTypes`, Windows protocol registration, Linux `.desktop` `MimeType=x-scheme-handler/soundspan`) and has an in-app scanner, so scanning the code or tapping the link adds the server and completes device link in one step. A plain `https://` URL QR is also accepted and starts the normal flow.
- The QR's `server` value is `window.location.origin`, which drops any sub-path. The app therefore treats it as a starting point: it probes it, and if that is not a soundspan server it asks the user to confirm or add the path before submitting the code.

**2. Probe** (unauthenticated, all existing):

| Call | Purpose |
|---|---|
| `GET <base>/api/health` | Confirms a soundspan backend is reachable and ready. A non-JSON response or a missing `status` field means "not a soundspan server" (wrong URL, or the reverse proxy is routing elsewhere), shown as a specific error. A 503 means the server is starting or draining. |
| `GET <base>/api/auth/config` | Which sign-in methods this instance offers: `localLoginEnabled`, `oidcEnabled`, `oidcProviderName`. The sign-in screen shows only what is available; SSO-only instances go straight to device link, labelled with the provider name. |
| `GET <base>/api/onboarding/status` | `needsOnboarding: true` means the instance has no accounts yet. The app explains that the server must be set up in its web UI first and offers to open it, rather than offering a sign-in that cannot succeed. |

Probe failures are classified and explained individually: DNS failure, connection refused, timeout, TLS failure (untrusted or expired certificate — the server needs a certificate the device trusts), HTTP 4xx/5xx, not-a-soundspan-server, and (web build only) CORS rejection with `ALLOWED_ORIGINS` instructions.

**3. Sign-in**, using only the methods the probe reported (see Sign-In Methods).

**4. Capability discovery** (authenticated, after sign-in, refreshed on every app start and when returning from background after more than an hour):

| Call | Purpose |
|---|---|
| `GET <base>/api/docs.json` → `info.version` | Server version for compatibility gating. |
| `GET <base>/api/system/features` | Which optional features this instance has enabled (audio analysis, discovery, auto playlists, federation, loudness target, and the detected integrations). |

**Feature gating rules**

- Screens, menu items, and actions for an optional feature appear only when the instance reports it as enabled; the app never shows a feature that will fail on this server. A feature that disappears (the operator disables it) is hidden on the next refresh, and its cached data is kept but not shown.
- Endpoints that are absent on an older or differently configured server (404) degrade the related UI quietly instead of failing the screen; this is a fallback, not the primary detection mechanism.
- Out-of-range versions: older than `minServer` blocks sign-in with an "update your server" message; newer than `maxTestedServer` shows a dismissible warning and continues.
- Nothing in the client assumes a particular provider, integration, or deployment mode (single container, AIO, Helm, HA). Provider-specific behaviour is the server's job (see Source-Agnostic Tracks).

**Multiple instances**

- Each profile is fully isolated: its own credentials, drift cache tables, download directory (`media/<serverId>/`), outbox, and feature set. Switching servers stops playback and swaps the whole data layer; nothing leaks between instances.
- The same user may add the same server twice with different accounts; profiles are keyed by `(normalized baseUrl, userId)`.
- The server's display name comes from the user (defaulting to the hostname), since instances have no public name field.

### Sign-In Methods (all existing endpoints)

1. **Username + password**: `POST /api/auth/login` returns an access token and refresh token; 2FA is handled through the existing `2FA token required` response. Refresh with `POST /api/auth/refresh` `{ refreshToken }`. All targets.
2. **Device link** (preferred on mobile, and for SSO-only servers): the user, signed in on the web UI, generates a code (`POST /api/device-link/generate`). The client submits it to `POST /api/device-link/verify` `{ code, deviceName }` and receives an **API key**. No browser redirect is involved.
3. **Pasted API key**: created under Settings → API keys in the web UI.

OIDC is not driven from inside native apps: the server's OIDC callback redirects to the configured web frontend, not an app-registered URI scheme. Native targets offer device link instead. The Flutter web build, when hosted on the server's origin, can reuse the browser OIDC flow.

### Credential Use

| Credential | JSON calls | Streaming | Refresh |
|---|---|---|---|
| JWT access token | `Authorization: Bearer` | Header (native) or `?token=` (web) | `/api/auth/refresh`, proactive at 80% of lifetime and on 401 |
| API key | `X-API-Key` | Header only | None; fixed 90-day lifetime from creation |

API keys cannot be passed as `?token=`, so the web build uses JWT sessions only. Native players set headers themselves (`just_audio` `headers`, media_kit `httpHeaders`).

A dio interceptor injects credentials and performs single-flight refresh: concurrent 401s wait on one refresh future, then replay.

### Device-Link Key Lifetime

API keys expire a fixed 90 days after creation (`API_KEY_LIFETIME_MS` in `backend/src/utils/apiKeyHash.ts`). The client stores the link date with the profile and:

- shows a persistent banner and a local notification from 14 days before expiry, with a "Link again" action that walks through a new device-link code;
- on a 401 from an expired key, switches the profile to a signed-out state that keeps its cache and downloads, so re-linking restores it without re-downloading;
- revokes the previous key (`/api/api-keys`) after a successful re-link.

### CORS and the Web Target

- **Native targets** use `dart:io` HTTP, which sends no `Origin` header, so the server's CORS policy (`backend/src/utils/cors.ts`) does not apply.
- **Web target**: serve the build behind the same origin as the server (`/app/*`), or have the operator add its origin to `ALLOWED_ORIGINS`. The connection probe detects a CORS failure and shows operator instructions.

## API Client

- **Codegen.** `openapi-generator` (`dart-dio`) generates `packages/soundspan_api` from `GET /api/docs.json`. The spec is pinned per server release in `tool/specs/<version>.json` and committed; CI regenerates and fails on drift. Where the OpenAPI schema is loose, hand-written `freezed` models wrap the generated ones.
- **Compatibility.** After sign-in the client reads the server version from `info.version` of `GET /api/docs.json` (resolved from the backend `package.json`; auth-gated in production unless `DOCS_PUBLIC=true`, so it is fetched with the session's credentials). `/api/health` is not used for this: its `version` comes from `npm_package_version`, which is `unknown` when the container starts `node dist/index.js` directly. The client compares the version to a supported range (`minServer`, `maxTestedServer`). Out-of-range servers show a warning; features are gated by version, not by probing for 404s.
- **Errors.** Server `{ error, code }` bodies map to a sealed `ApiError` hierarchy (`AuthBackendUnavailable`, `RateLimited(retryAfter)`, `NotFound`, …). 429 honours `Retry-After` with jittered backoff.
- **Caching.** Repositories read through the drift cache (stale-while-revalidate), giving fast cold start and offline browsing of previously loaded pages.

## Playback

### Model

- One `SoundspanAudioHandler` (an `audio_service` `BaseAudioHandler`) owns the queue, shuffle, repeat, and the `just_audio` `AudioPlayer`. The UI talks only to the handler, on every platform.
- Platform media controls are adapters around the handler: `audio_service` natively on Android/iOS/macOS/web, `audio_service_mpris` on Linux, and an `smtc_windows` bridge on Windows.
- Queue logic is pure Dart with unit tests independent of any player.

### Engines

- **Android:** `just_audio` → ExoPlayer, running inside `audio_service`'s foreground `MediaBrowserService`; notification controls, Bluetooth/headset buttons, and the Android Auto browse tree (Recent, Playlists, Albums, Downloads).
- **iOS / macOS:** `just_audio` → AVQueuePlayer with `AVAudioSession` category `.playback` and the `audio` `UIBackgroundModes` entry on iOS.
- **Windows / Linux:** `just_audio_media_kit` → libmpv. libmpv is bundled by `media_kit`'s native library packages, so users install nothing extra.
- **Web:** `just_audio` → HTML audio with `?token=` stream URLs.

### Gapless and Transitions

- The queue is loaded into the player as a playlist (`setAudioSources`) so the engine pre-buffers the next item: gapless on ExoPlayer, AVQueuePlayer, and mpv (`gapless-audio`). Web is best-effort.
- Server-provided loudness metadata is applied as per-track volume where present (see `loudness-and-transitions.md`). Crossfade is out of scope for v1.

### Source-Agnostic Tracks

The client never distinguishes where a song comes from (local library, federated peer, TIDAL, YouTube Music, YouTube, or any future provider). Every track is identified by its opaque `playbackId` (see Server Prerequisites) and is played, queued, liked, added to playlists, reported, and downloaded through the same code path. Provider-specific rules (which upstream to use, availability, quality, whether a track can be downloaded) are the server's responsibility; the client only renders the server's responses and errors. No `if provider == …` branches are allowed in client code, the client never parses a `playbackId`, and the domain model ignores `streamSource`, `tidalTrackId`, and `youtubeVideoId` even where the API still returns them.

### Server Integration

- Stream: `GET /api/playback/stream/:playbackId` for every track (and the podcast/audiobook equivalents) with the same quality parameters the web UI uses.
- Play reporting / scrobbling: `/api/plays` with `playbackId`, at the same thresholds as the web UI; queued in the outbox while offline.
- Cross-device resume: `GET/POST /api/playback-state`, debounced (every 15 s while playing, on pause, on track change, on app background).

## Offline and Downloads (native only)

- Use the server's source-agnostic offline workflow (see Server Prerequisites): request a track, album, or playlist; download each item from its `downloadUrl`; confirm completion. The server's per-device view of what is downloaded stays correct for every source.
- `background_downloader` runs transfers through WorkManager (Android) and background `URLSession` (iOS), surviving app suspension; on desktop it runs in-process. Auth headers are attached per task. Resumable, size-verified, Wi-Fi-only option, default concurrency 2.
- Files live in the app support directory (`<appSupport>/media/<serverId>/<trackId>.<ext>`), not user-visible folders. Per-server quota with LRU eviction for auto-cached (non-pinned) items.
- The audio handler resolves each queue item to a local file first (`AudioSource.file`), falling back to the stream URL.
- **Offline mode:** UI renders from the drift cache plus the downloads table. Mutations (likes, playlist edits, plays) go to an ordered outbox replayed on reconnect; 409/404 conflicts are surfaced as a toast, last-writer-wins otherwise.

## Realtime

- `socket_io_client` for Listen Together (`/socket.io/listen-together`) and social presence. Password sessions authenticate with `handshake.auth.token` (JWT), as the web frontend does; device-linked sessions use `handshake.auth.apiKey` (Server Prerequisite P5). Social features are available on every session type.
- When an API key is revoked, the server disconnects its sockets; the client treats that like an expired key (see Device-Link Key Lifetime).
- On mobile, sockets disconnect when backgrounded; on resume the client reconnects and re-syncs from REST.

## UI

- Material 3 with a custom soundspan theme whose colour and type tokens are derived from the web frontend's design tokens, so both clients look related. Light and dark themes.
- **Adaptive layouts:**
  - Compact (< 600 dp): bottom navigation bar, mini player, full-screen now-playing sheet.
  - Medium (600–1024 dp): navigation rail, side-by-side detail panes on tablets.
  - Expanded (> 1024 dp, desktop): sidebar, persistent player bar, queue side panel, keyboard shortcuts, hover states, right-click menus, drag-and-drop to playlists.
- Long lists use `ListView.builder` / slivers with fixed extents; library pages follow the server's paginated endpoints (including the merged Library Songs page).
- Artwork is requested at display size and decoded with `cacheWidth`/`memCacheWidth`; the image memory cache is capped.
- v1 screens: Home, Search (respecting the server's admin-ordered providers), Library (artists, albums, songs, playlists), Album/Artist/Playlist detail, Now Playing + queue, Lyrics, Podcasts, Downloads, Settings (servers, playback, storage). Discovery/vibe/mixes in M4. Admin features link out to the web UI.
- Localization: all user-visible strings live in ARB files through `flutter_localizations` / `gen-l10n` from M0; dates, numbers, and durations use `intl`. English ships first; adding a language is a new ARB file with no code changes. Layouts are tested with a pseudo-locale (longer strings) and RTL.
- Accessibility: `Semantics` labels on all controls, text scaling respected, full keyboard navigation and focus traversal on desktop, screen-reader passes on TalkBack, VoiceOver, Narrator, and Orca.

## Resource Budget

| Scenario | Target |
|---|---|
| Desktop, window open, browsing library | ≤ 200 MB RSS |
| Desktop, minimised to tray, playing | ≤ 120 MB RSS |
| Mobile, foreground | ≤ 250 MB |
| Cold start to interactive (mid-range Android) | ≤ 2 s |
| Library list scroll | 60 fps on a 10,000-track library |

Budgets are measured in CI-adjacent manual runs each release and regressions block the release.

## Security

- Refresh tokens and API keys only in `flutter_secure_storage` (Keystore, Keychain, Credential Manager, libsecret). Never in shared preferences or plain files. On web, only a JWT session is kept (memory plus `sessionStorage`).
- TLS through the platform stack only. Servers must present a certificate trusted by the OS (e.g. Let's Encrypt or a CA the user has installed system-wide); self-signed or untrusted certificates are not supported, since the audio engines (ExoPlayer, AVPlayer, libmpv) use their own HTTP stacks and could not honour an app-level exception. Plain `http://` is allowed only for LAN/private-range hosts, with a warning.
- Android `network_security_config` and iOS ATS exceptions are limited to user-added LAN hosts.
- No arbitrary URL loading: the HTTP layer only accepts paths relative to the active profile's base URL.
- Sign-out revokes the API key (`/api/api-keys`) or calls `/api/auth/logout`, then wipes secrets, the profile's cache, and optionally its downloads.

## Crash Reporting and Telemetry

- **Off by default.** No data leaves the device unless the user enables "Send crash reports" in Settings (asked once, non-blocking, after the first successful sign-in).
- When enabled, crashes and unhandled errors go to a Sentry-protocol endpoint (`sentry_flutter`), which can be Sentry or a self-hosted GlitchTip. The DSN is a build-time setting for official builds and can be overridden in Settings.
- Reports are scrubbed before sending: no server URLs, usernames, tokens, API keys, track/artist names, or file paths; breadcrumbs are limited to screen names and error codes.
- **No usage analytics** of any kind.
- Independently of crash reporting, Settings → About offers "Export logs", which writes a redacted rolling log file for users to attach to bug reports.

## Licensing

- The client in `client/` is licensed **GPL-3.0 with an additional permission under GPL section 7** that allows distributing the app through app stores (Apple App Store, Google Play, Microsoft Store, and similar) whose terms add usage restrictions. Corresponding source remains available under GPL-3.0.
- The exception applies **only to code under `client/`**. It is stated in `client/LICENSE` (GPL-3.0 text plus the exception) and an SPDX header on client source files (`GPL-3.0-or-later WITH <exception-id>` or a `LicenseRef-` identifier). The rest of the repository stays plain GPL-3.0, and the client must not copy or link server/frontend code, which would not carry the exception.
- Contributions to `client/` are accepted under the same license + exception; `CONTRIBUTING.md` gains a note saying so, and PRs touching the client confirm it.
- Third-party dependencies must allow app store distribution. A license audit runs in M0 and in CI (`flutter pub deps` + license report): permissive licenses (MIT, BSD, Apache-2.0, MPL-2.0) are fine; LGPL components (e.g. libmpv bundled by `media_kit`) are shipped as dynamically linked libraries with their notices; GPL-only dependencies are not allowed in the client.
- An in-app "Open-source licenses" screen (Flutter `LicenseRegistry`) lists every bundled component.
- The exact exception wording should be reviewed by the project's copyright holders before the first store release.

## Build, CI, and Distribution

| Target | Artifact | Signing | Channel |
|---|---|---|---|
| Android | AAB + universal APK | Upload key / Play App Signing | Play Store, GitHub APK, F-Droid |
| iOS | IPA | Apple Distribution | TestFlight → App Store |
| Windows | MSIX + Inno Setup `.exe` | Authenticode (Azure Trusted Signing) | GitHub Releases, winget, Microsoft Store (optional) |
| macOS | Universal `.app` in `.dmg` | Developer ID + notarization | GitHub Releases, Homebrew cask |
| Linux | Flatpak, AppImage, `.deb` | Flatpak repo signing | Flathub, GitHub Releases |
| Web | Static bundle + container image | — | GHCR image; drop-in folder for reverse-proxy hosting |

- Flutter version pinned with FVM (`.fvmrc`); CI uses the same version.
- GitHub Actions matrix: `ubuntu-latest` (Android, Linux, Web), `windows-latest`, `macos-latest` (iOS, macOS).
- Release flow: tag → build all targets → sign/notarize → upload to a draft release → publish appcast for desktop updaters → publish. Store submissions (Play, App Store, Flathub) are a manual promotion step.
- Versioning: semver independent of the server, with the supported server range in release notes and in the app's compatibility table.

## Testing

- **Unit tests** (`flutter test`): queue logic, token refresh single-flight, outbox replay, download state machine, URL allowlisting, error mapping.
- **Widget and golden tests:** each screen at compact, medium, and expanded widths, light and dark.
- **API contract tests:** run the generated client against a disposable soundspan server (the server repo's `docker-compose.yml`, seeded) in CI: login/refresh, device link, library paging, stream range requests, offline endpoints, playback state.
- **Integration tests:** `integration_test` with Patrol on Android and iOS simulators (sign-in, play, background, notification controls, offline playback); `integration_test` on Windows, macOS, and Linux desktop runners.
- **Manual playback matrix** each release: Bluetooth and headset buttons, Android Auto, interruptions/phone calls, sleep/wake, network handoff, tray playback, following the pattern in `docs/NATIVE_AUDIO_ENGINE.md`.

## Server Prerequisites

Verified against the current backend: every track source already shares one auth model (`requireAuthOrToken`: `X-API-Key`, Bearer, or `?token=`) and Range support, but **not** one endpoint or one identifier.

| Gap today | Where |
|---|---|
| Five stream endpoints chosen by a `streamSource` field: `/api/library/tracks/:id/stream` (local and `peer`), `/api/tidal-streaming/stream/:trackId` (`tidal`), `/api/ytmusic/stream/:videoId` or `/stream-public/:videoId` (`youtube`, depending on whether the user linked YT Music), `/api/youtube/stream/:videoId` (`youtube-direct`) | web player: `frontend/components/player/AudioPlaybackOrchestrator.tsx` |
| Track inputs take source-specific fields (`tidalTrackId`, `youtubeVideoId`, provider-prefixed ids) | `backend/src/routes/plays.ts`, `playlists.ts`, `library/remoteTracks.ts` |
| Offline downloads cover whole local albums only (`LOCAL_TRACK_WHERE`, `origin: "LOCAL"`); `CachedTrack` has a foreign key to `Track` only | `backend/src/routes/offline.ts`, `schema.prisma` |

These ship in the server before client M1, each as its own reviewed PR with a backend design doc (`docs/designs/unified-playback-api.md`) and OpenAPI annotations. They are additive: existing endpoints and the Next.js frontend keep working unchanged, and the frontend can adopt them later.

The full design, including endpoint shapes, data model, and tests, is in `docs/designs/unified-playback-api.md`; that document is the source of truth. In summary:

- **P1:** an opaque `playbackId` on every playable track in every response. The client stores and sends only this id and never parses it.
- **P2:** `GET /api/playback/stream/:playbackId` and `/stream-info/:playbackId` for every source, with the same auth, Range, and quality behaviour as today and one error shape.
- **P3:** plays, playlists, likes, playback state, and Listen Together accept `{ playbackId, metadata? }`. The client always sends the display metadata it received with the track; the server uses it only when it must create a row.
- **P4:** offline requests for a track, album, or playlist of any source (`/api/offline/items`), per-device accounting keyed by a client-generated `deviceId`, resumable downloads with pinned variants and `ETag`/`If-Range`, and per-source admin toggles that surface to the client only as `downloadable: false` with a reason. All sources are downloadable by default.
- **P5:** the `/listen-together` socket handshake accepts `handshake.auth.apiKey` as well as `token`, so device-linked sessions get Listen Together and presence.

### Client Compatibility

`minServer` is the release that ships the Unified Playback API (P1–P5). Older servers are refused at sign-in with an "update your server" message (see Connecting to Any Self-Hosted Server). The client contains no fallback to the per-source endpoints.

## Milestones

0. **S0, Server prerequisites** (server repo, before client M1): `unified-playback-api.md` design doc, then P1–P5 with backend tests against real PostgreSQL, OpenAPI annotations, and a server release that becomes the client's `minServer`. Client M0 can proceed in parallel.
1. **M0, Foundations:** repository scaffold, FVM, codegen pipeline, server profiles, password login + refresh, library browse, adaptive shell. Runs on all six targets. Package maintenance review.
2. **M1, Playback:** audio handler, `just_audio` on all targets, gapless queue, media controls (audio_service, MPRIS, SMTC), play reporting, playback-state sync.
3. **M2, Mobile polish:** device-link sign-in, Android foreground service and Android Auto, iOS background audio, TestFlight and Play internal track.
4. **M3, Offline:** download manager, offline mode and outbox, storage management.
5. **M4, Social & discovery:** Listen Together, presence, vibe/mixes/discovery, lyrics polish.
6. **M5, Release:** accessibility pass, resource-budget verification, desktop updaters, App Store / Play / Flathub / winget submissions.
7. **M6, Extended surfaces** (after the core app ships, each independently releasable):
   - **CarPlay:** audio-app template (Recent, Playlists, Albums, Downloads) via a community plugin or a small native module; requires Apple's CarPlay audio entitlement.
   - **Android TV:** leanback launcher entry and a D-pad-first layout set (focus traversal, 10-foot type scale) in the same APK.
   - **Wear OS / watchOS:** control-only companions (play/pause, skip, volume, now-playing art) driving the phone's session; Wear OS through the Media3 session, watchOS through a native SwiftUI target using WatchConnectivity. No offline on watches.
   - **Home-screen widgets:** Now Playing widgets on Android (Glance) and iOS (WidgetKit) via `home_widget`, fed from the audio handler's state.

## Open Questions

None at present.
