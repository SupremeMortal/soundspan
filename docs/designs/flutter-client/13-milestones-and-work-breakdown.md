# 13. Milestones and Work Breakdown

Status: design phase.

Each task is one reviewable PR unless marked "(series)". Every task follows the repository's Definition of Done: tests first, verification evidence, changelog entry under `### Client` when user-visible. Dependencies name task ids. Milestone order follows the design document; the content of each is refined by the documents in this directory.

## Dependency Overview

```
S1-P9a, S1-P9b (typed spec) ─┐   S1-P7, P8, P9c ─┐   S1-P6, P9d ─┐   S1-P9e ─┐   S1-P9f ─┐
                             ▼                   ▼               ▼           ▼           ▼
Spikes S1–S6, S8 ─▶ M0 Foundations ─▶ M1 Playback ─▶ M2 Mobile polish ─▶ M3 Offline ─▶ M4 Social & discovery ─▶ M5 Release ─▶ M6 Extended
```

The server work stream S1 feeds each milestone the part of the typed spec it needs. M0's scaffold, theme, storage, and shell tasks do not wait for it; M0's API tasks start when S1-P9b has merged. The other spikes run in parallel with M0. M4 does not depend on M3 and can be reordered or run alongside it.

## Spikes

Throwaway code in a branch; the output is a short written finding appended to the relevant plan document; where a spike changes a design choice, that document is rewritten to match. A spike is done when its questions have yes/no answers with evidence.

| Id | Question | Method | If the answer is no |
|---|---|---|---|
| S1 | Does `just_audio` play gaplessly through a two-item playlist with authenticated header requests on Android, iOS, and macOS, and does replacing item 1 while item 0 plays leave playback undisturbed? | Minimal app, two FLAC files cut from one continuous tone, local server that checks headers | Use `ConcatenatingAudioSource`-style full-playlist loading in the adapter; `PlayerEngine` contract unchanged |
| S2 | Does `media_kit` give gapless transitions with `gapless-audio` and `prefetch-playlist`, accept per-item HTTP headers, and report playlist index changes reliably on Windows and Linux? | Same harness | Call libmpv through `media_kit`'s `NativePlayer` command interface (`loadfile … append`) directly |
| S3 | Does `audio_service` on Android keep playing with the screen off for one hour with the engine owned outside the handler, and restart correctly from the notification after the process is killed? | Minimal app on a physical device | Move engine ownership into the handler isolate boundary as `audio_service` documents |
| S4 | Does `smtc_windows` build with the pinned Flutter, need no extra toolchain on CI, and deliver button events, metadata, timeline, and thumbnail? | Minimal Windows app | Write `client/packages/soundspan_smtc` (C++/WinRT, about 300 lines) |
| S5 | Does `background_downloader` resume with `Range` + `If-Range`, append on `206`, and restart cleanly on `200`? Does it re-attach after process death on Android and iOS? | Against a real server with P4, killing the app mid-transfer | Apply the fallback rule in [07](07-offline-and-downloads.md) |
| S6 | Does drift WASM open three databases in one tab without cross-origin isolation in Chrome, Firefox, and Safari? Can the same-origin web build reuse the web UI's OIDC session? | Minimal web build behind the dev reverse proxy | IndexedDB-only mode; web stays password-only |
| S8 | Does `swagger_parser` generate correct `freezed` models and `retrofit` clients from the S1-P9b spec: optional versus nullable fields, `oneOf` responses (login with and without 2FA), unknown enum values, one client per tag, method names from `operationId`? | Generate from the emitted spec; decode captured real responses | Use `openapi-generator` `dart-dio` (adds a JDK to CI); only `lib/src/generated/` differs |
| S7 (after signing) | Does `auto_updater` work with the pinned Flutter and signed builds on Windows and macOS? | Signed test builds and a test appcast | Keep the in-app "new version available" notice that opens the release page (M5-03) |

## S1. Server Prerequisites P6–P9

Defined in [12](12-server-prerequisites-p6-p9.md).

| Id | Task | Acceptance |
|---|---|---|
| S1-P7 | `report=0` on `/api/playback/stream`; `downloadUrl` carries it | Tests in [12](12-server-prerequisites-p6-p9.md); smoke job extended |
| S1-P8 | `playedAt` and `listenedMs` on `POST /api/plays`: validation, the `Play.listenedMs` column and migration, idempotency | Same |
| S1-P6 | `DELETE /api/api-keys/current` | Same |
| S1-P9a | Typed-spec infrastructure: `defineOperation`, registry merge, `ApiError`, response-validation middleware, emitter and its CI check | Tests in [12](12-server-prerequisites-p6-p9.md); emitted file is deterministic |
| S1-P9b | Schemas and registry entries: connection and session, library and browse, playlists (read), search, home shelves | Existing route tests pass with validation on |
| S1-P9c | Playback, plays, playback state, lyrics, settings, preferences, playlist mutations, podcasts | Same |
| S1-P9d | Device link and API keys | Same |
| S1-P9e | Offline | Same |
| S1-P9f | Mixes, discovery, radio, vibe, Listen Together REST, presence | Same |
| S1-REL | Server release containing P1–P9; `BuildConfig.minServer` set to it | Tag exists; contract suite pinned to it |

## M0. Foundations

Exit: a debug build on all six targets signs in with a password to a real server, browses the library from cache and network in both themes, and switches between two profiles. CI is green on every job in `client-quality.yml`.

| Id | Task | Depends | Acceptance |
|---|---|---|---|
| M0-01 | Scaffold `client/`: `flutter create` for six platforms with org `io.soundspan`, `.fvmrc`, `pubspec.yaml`, `analysis_options.yaml`, licence file and SPDX headers, `tool/gen.sh`, empty `soundspan_api` package; repo-contract edits ([01](01-toolchain-and-repository.md)) | — | `flutter analyze` and an empty `flutter test` pass; file-size gate covers Dart |
| M0-02 | `client-quality.yml` with analyze, test, and the five build jobs; `verify:client` | M0-01 | Workflow green; server-only PR does not trigger it |
| M0-03 | `tool/check_imports.dart`, `check_l10n.dart`, `license_audit.dart` with their own tests | M0-01 | Each rule has a failing-fixture test |
| M0-04 | Logging: `AppLogger`, redaction, rolling file sink | M0-01 | Redaction table tested; no secret patterns in output |
| M0-05 | Theme: tokens, `SoundspanColors`, `ColorScheme` mapping, typography, contrast test, Montserrat asset, Turret Road asset and `Wordmark` widget, both fonts' licence texts in `assets/licenses/` | M0-01 | Contrast test passes for both themes |
| M0-06 | `soundspan_api` transport: config, guard, credential, refresh, retry, error mapper, log interceptor | M0-01 | Unit tests for every row of the interceptor tables in [03](03-api-layer.md) |
| M0-07 | `soundspan_api` generation: `swagger_parser.yaml`, `tool/gen.sh` step, `SoundspanApi` facade, decode smoke test, `tool/spec_compat.dart`, `client-spec` job; first clients (session) in use | M0-06, S1-P9b, spike S8 | Generated code compiles and decodes captured responses; spec gate green |
| M0-08 | Contract harness: compose file with response validation on, fixture library, seed script, first contract group (connection and session); `client-contract` job | M0-07 | Job green against the PR's backend |
| M0-09 | Storage: `AppDatabase`, `SecretStore` seam, `AppPaths`, `DatabaseOpener` (native and web) | M0-01 | Migration test scaffold; web opens in Chrome |
| M0-10 | Profiles: `ProfileRepository`, `ProfileRuntime`, `ProfileScope`, `SessionController` | M0-06, M0-09 | Switching profiles disposes every profile-scoped provider (test asserts `onDispose` calls) |
| M0-11 | Connect flow: `ServerAddress`, `ProbeController`, classification, probe UI | M0-07, M0-10 | Table-driven normalization tests; widget tests for each failure class |
| M0-12 | Password sign-in with 2FA; capability refresh and version gate | M0-11 | Widget tests for each response in [04](04-auth-and-server-profiles.md); gate tests for below, in, above, unknown |
| M0-13 | App shell: router, `WindowClass`, bottom bar / rail / sidebar, top bar, empty player slots, settings skeleton with theme mode and servers | M0-05, M0-10 | Goldens at 390, 800, 1440 in both themes |
| M0-14 | Library, playlist, and search repositories over the generated clients; `ImageUrls`; `OffsetPage` and `KeysetPage` | M0-07 | Mapping tests (wire to domain); contract group "Library and browse" |
| M0-15 | `CacheDatabase`, `Cached<T>` SWR repositories, `PagedSource` | M0-09, M0-14 | SWR sequence tests (cache hit, stale, refresh failure, offline) |
| M0-16 | Shared widgets: `Artwork`, `MediaCard`, `Shelf`, `TrackRow` (no playback actions), `EmptyState`, `ErrorView`, `Banner`; image cache manager | M0-05, M0-14 | Goldens; semantics guideline tests |
| M0-17 | Library screens: Playlists, Artists, Albums, Songs tabs with paging | M0-15, M0-16 | Scroll test over a 10,000-row fake source keeps extent stable |
| M0-18 | Album, Artist, Playlist detail (read-only) | M0-15, M0-16 | Widget tests; goldens |
| M0-19 | Home shelves and Search (library + discover, recent searches) | M0-15, M0-16 | Widget tests |
| M0-20 | Localization scaffold: ARB, pseudo-locale generator, RTL goldens for the shell | M0-13 | `check_l10n` green over all UI |
| M0-21 | Desktop shell basics: `window_manager` bounds persistence, minimum size, single instance on Windows and Linux | M0-13 | Desktop integration smoke test |
| M0-22 | Icons and launch screens: copy the vector masters ([`assets/`](assets/)) into `client/assets/brand/`, `tool/gen_icons.dart`, generated icon sets for every target | M0-01 | All targets show the icon; generator output is committed and reproducible |

## M1. Playback

Exit: on all six targets, an album plays gaplessly from the server with OS media controls, likes and playlist edits work, plays are reported once per listen, the queue survives a restart, and a podcast episode resumes where it stopped. Engine conformance passes on every native target.

| Id | Task | Depends | Acceptance |
|---|---|---|---|
| M1-01 | Queue model: `QueueState`, `QueueReducer`, shuffle order | M0-01 | Unit tests for every rule in [06](06-playback.md) |
| M1-02 | `PlayerEngine` interface, `FakeEngine`, conformance suite | M1-01 | Suite passes on `FakeEngine` |
| M1-03 | `JustAudioEngine` | M1-02, spike S1 | Conformance on Android emulator, iOS simulator, macOS, Chrome |
| M1-04 | `MediaKitEngine` | M1-02, spike S2 | Conformance on Windows and Linux |
| M1-05 | Playback, plays, playback-state, settings, preferences, and playlist-mutation repositories over the generated clients; `StreamUrls` | M0-07, S1-P7, S1-P8, S1-P9c | Contract groups for each |
| M1-06 | `SourceResolver` (stream only) and `PlaybackController` with failure policy | M1-02, M1-05 | Controller tests with `FakeEngine`: advance, skip on failure, stop after three failures, unauthorized retry |
| M1-07 | Queue persistence in `state.db`; restore on start | M1-06, M0-09 | Kill-and-restore test |
| M1-08 | Loudness gain | M1-06 | Table tests for each mode and clamp |
| M1-09 | Audio focus and interruptions | M1-06 | Unit tests with a fake session; manual matrix rows |
| M1-10 | `MediaControls`: `audio_service` adapter (Android, iOS, macOS, web, Linux MPRIS) and `ArtworkPinner` | M1-06, spike S3 | Desktop integration smoke; manual rows |
| M1-11 | `MediaControls`: Windows SMTC | M1-06, spike S4 | Manual rows; smoke test that the adapter initialises |
| M1-12 | Player UI: `PlayerBar`, `MiniPlayer`, `SeekBar`, now playing, queue panel and sheet, quality badge, lyrics with LRC parser | M1-06, M0-16 | Goldens; widget tests; LRC parser tests |
| M1-13 | Outbox (store, worker, coalescing) | M0-09, M1-05 | Tests for every row of the operation and outcome tables in [07](07-offline-and-downloads.md) |
| M1-14 | Likes, playlist create / rename / delete / add / remove / reorder through the outbox with optimistic overlay; track context menu and `ActionBar` | M1-13, M0-18 | Repository tests with `FakeApi`; widget tests |
| M1-15 | `PlayReporter` and `play_sessions` | M1-06, M1-13 | Tests for every rule in [06](06-playback.md): accumulation across pauses and seeks, the 5-second minimum on the total (4.9 s dropped, 3 s + 3 s reported), one report per play, recovery after a kill |
| M1-16 | `PlaybackStateSync` | M1-06, M1-05 | Cadence and windowing tests |
| M1-17 | Podcasts: API, repositories, screens, episode playback, progress, speed and skip | M1-06, M1-13 | Widget and controller tests; contract group |
| M1-18 | Reachability controller and offline banner (no downloads yet) | M0-15 | State-transition tests |
| M1-19 | Desktop interaction: shortcuts, selection, context menus, drag to playlist and queue, tray, macOS menu bar | M1-12, M1-14 | Desktop integration tests for shortcuts; manual drag tests |
| M1-20 | Playback settings: per-network quality, levelling mode | M1-06 | Widget tests |
| M1-21 | `client-nightly.yml`: engine conformance on four runners, desktop integration | M1-03, M1-04 | Nightly green three nights running |

## M2. Mobile Polish

Exit: a phone links to an SSO-only server with a code or QR, plays for an hour with the screen off, is controllable from the lock screen, a headset, and Android Auto, and an installable unsigned build exists for testers on Android.

| Id | Task | Depends | Acceptance |
|---|---|---|---|
| M2-01 | Device-link sign-in: `CodeCells`, verify, device naming, expiry lookup | M0-12, S1-P9d | Widget tests for each error; contract group |
| M2-02 | Deep links on all native targets; `DeepLinkRouter` | M0-21 | Unit tests for URI validation; manual per-OS rows |
| M2-03 | QR scanner (Android, iOS, macOS, web) | M2-01 | Widget test with a fake scanner; camera permission denied path |
| M2-04 | Pasted API key sign-in | M2-01 | Widget tests |
| M2-05 | `KeyExpiryMonitor`, banner, local notification, re-link with self-revoke | M2-01, S1-P6 | Clock-driven tests at 15, 14, 3, 1, 0 days |
| M2-06 | Sign-out and remove-server sequences | M2-05, M1-13 | Sequence tests including failures of each best-effort step |
| M2-07 | Android: foreground service configuration, notification actions (Like), media button receiver, backup exclusions, permissions flow | M1-10 | Manual rows on a physical device |
| M2-08 | Android Auto browse tree, `playFromMediaId`, voice search | M2-07 | Desktop Head Unit checklist |
| M2-09 | iOS: background audio, route picker, interruptions, privacy manifest, launch screen | M1-10 | Manual rows on a physical device |
| M2-10 | Patrol suite on Android emulator: sign in, play, background, notification pause, resume | M2-07 | In nightly |
| M2-11 | Compact and medium layout polish: gestures (swipe mini player, drag-down now playing), fast scroll, tablet two-pane | M1-12 | Goldens at 390 and 800 |
| M2-12 | `client-release.yml` first version: unsigned artifacts, draft pre-release, checksums | M0-02 | A `client-v0.x` pre-release exists with every artifact except iOS |

## M3. Offline

Exit: an album and a playlist download in the background, survive an app kill, play in airplane mode, sync likes and plays made offline with correct timestamps, and are removed when the server revokes them.

| Id | Task | Depends | Acceptance |
|---|---|---|---|
| M3-01 | Offline repositories over the generated client | S1-P7, S1-P9e | Contract group |
| M3-02 | Download tables, `DownloadStore`, state machine (pure) | M0-09 | Transition tests for every row |
| M3-03 | `Downloader` seam over `background_downloader`; scheduler | M3-02, spike S5 | Tests with `FakeDownloader`; integration test against the contract server |
| M3-04 | `DownloadController`: pin, unpin, membership, quota, verification, server confirmation | M3-01, M3-03, M1-13 | Scenario tests: mixed downloadable/unavailable album, cache-limit error, disk full |
| M3-05 | `SourceResolver` local-file path; offline skip rule; "Downloaded" badge | M3-04, M1-06 | Controller tests |
| M3-06 | Reconciliation and start-up scan | M3-04 | Tests for each rule |
| M3-07 | Offline mode UI: Downloads tab, download glyphs and actions, "Downloaded only" filter, local search | M3-04, M1-18 | Widget tests; goldens |
| M3-08 | Collection upkeep: playlist diff, daily album re-resolve | M3-04 | Tests |
| M3-09 | Episode downloads | M3-03, M1-17 | Tests |
| M3-10 | Storage settings and usage breakdown | M3-04 | Widget tests |
| M3-11 | Android download notifications and foreground handling; iOS background session wiring; inactive-profile completion handler | M3-03 | Manual rows; Patrol test: download, kill, relaunch, play offline |
| M3-12 | Android Auto "Downloads" root with `FileProvider` artwork | M3-07, M2-08 | Head Unit checklist in airplane mode |

## M4. Social and Discovery

Exit: two devices stay in audible sync in a Listen Together group, presence shows who is listening, and servers with discovery, mixes, and vibe enabled show those sections.

| Id | Task | Depends | Acceptance |
|---|---|---|---|
| M4-01 | `SocketClient` with typed events and both credential kinds | M0-10 | Tests against a local socket.io server; contract group |
| M4-02 | `ListenTogetherController`: clock sync, state application, drift correction, `RemoteDriver` | M4-01, M1-06 | Scripted-event tests for every row in [08](08-realtime.md) |
| M4-03 | Listen Together UI: lobby, create, join, group view, queue header, follower state | M4-02 | Widget tests |
| M4-04 | Presence: heartbeat, activity panel and sheet | M4-01 | Tests |
| M4-05 | Mixes and Made For You detail; save mix as playlist | M0-19, S1-P9f | Feature-gated widget tests |
| M4-06 | Explore: recommendations, popular artists, radio stations (genres, decades) | M0-19 | Feature-gated tests |
| M4-07 | Vibe: similar tracks from a track, text search; "Start radio" action | M1-14 | Feature-gated tests |
| M4-08 | Lyrics polish: tap to seek, auto-scroll pause on manual scroll, large-screen layout | M1-12 | Widget tests |

## M5. Release

Exit: accessibility script passes on every platform, resource budgets are met and recorded, every target has an installable package, and the software is ready for v1. Signing and store submission follow ("Deferred Until the Software Is Ready for v1").

| Id | Task | Depends | Acceptance |
|---|---|---|---|
| M5-01 | Accessibility pass: labels, traversal, announcements, text scale, high contrast; fixes | all UI | Scripted screen-reader pass recorded per platform |
| M5-02 | Performance pass against the resource budget; fixes | all | Measurements recorded in the release checklist |
| M5-03 | Desktop update notice: a version check that opens the release page; `auto_updater` is evaluated once builds are signed (spike S7) | — | A build older than the latest release shows the notice |
| M5-05 | Packaging: MSIX and Inno Setup, `.dmg`, Flatpak manifest, AppImage, `.deb`, web container image (all unsigned) | M2-12 | Each installs and runs on a clean machine or container |
| M5-07 | User documentation: `docs/` page for the client (install, connect, link a device, offline), reverse-proxy notes for the web build, `docs/SUBSONIC_CLIENTS.md` cross-link | — | Docs are timeless-rule compliant |
| M5-08 | Licence review: exception wording approved by copyright holders; in-app licences screen complete, including fonts; LGPL notices for libmpv | — | Sign-off recorded |

## M6. Extended Surfaces

As in the design document, each independently releasable: CarPlay (needs Apple's CarPlay audio entitlement, so it follows the Apple account setup), Android TV layout, Wear OS and watchOS controllers, home-screen widgets. Audiobooks, which are not in v1, are planned here as a separate track: API resources, a third `QueueItem` kind with chapters, a sleep timer, and screens. Each gets its own short plan document in this directory before work starts.

## Deferred Until the Software Is Ready for v1

Not tracked as tasks and not part of any milestone's exit. Listed so nothing is forgotten when the time comes.

- **Accounts:** Apple Developer Program (App ID `io.soundspan.app`, distribution certificate, App Store Connect key, a demo server for review); Google Play Console (app record, upload key, Play App Signing); Windows code signing (Azure Trusted Signing or a certificate); Flathub, winget, and Homebrew submissions.
- **Signing in `client-release.yml`:** a permanent Android signing key, notarised macOS builds, Authenticode-signed Windows installers, an iOS archive. Testers uninstall a debug-signed Android pre-release once before the first properly signed build.
- **Store delivery:** TestFlight and Play internal track jobs, then store submissions.
- **Desktop auto-update:** `auto_updater` with Sparkle and WinSparkle (spike S7), which requires signed builds.
- **Crash reporting:** an opt-in reporter and its endpoint, if wanted after v1.
- **Cross-device handoff:** [`../cross-device-playback-handoff.md`](../cross-device-playback-handoff.md).

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Trigger to act |
|---|---|---|---|---|---|
| K1 | A playback package cannot deliver gapless or header auth on some platform | Medium | High | Spikes S1 and S2 before M1; `PlayerEngine` isolates the fix to one adapter | Spike answers "no" |
| K2 | `background_downloader` resume semantics differ from the server contract | Medium | Medium | Spike S5; fallback rule already designed | Spike answers "no" |
| K3 | Generated models do not match what the server sends | Low | Medium | P9 validates server responses against the spec in the backend's tests and in the contract server; the spec gate keeps the committed spec and generated code current | A `RESPONSE_SCHEMA_MISMATCH` in any suite |
| K4 | The typed spec (P9) lands later than M0 needs it | Medium | High | S1-P9a and S1-P9b are the first server PRs; M0's non-API tasks proceed meanwhile; P9 groups are split by milestone | M0-06 done and S1-P9b not merged |
| K5 | iOS suspends the app during long background downloads | Medium | Low | Background `URLSession`; state machine tolerates arbitrary delays | Manual matrix |
| K6 | Linux desktop variety (no Secret Service, no tray, Wayland quirks) | High | Low | Capability checks with clear messages; Flatpak as the primary tested path | Bug reports |
| K7 | Windows SMTC plugin unmaintained | Medium | Medium | Spike S4; in-repo plugin fallback sized at about 300 lines | Spike answers "no" |
| K8 | Web build size and start-up time are poor | Medium | Low (secondary target) | Deferred loading for M4 features; bundle-size report in CI | Initial load above 5 MB compressed |
| K9 | Light theme looks unlike the product | Medium | Low | Tokens only; mockups reviewed before M0-05 merges | Design review |
| K10 | Server `main` changes a shape between `minServer` and release | Medium | Medium | Version matrix in nightly contract runs; `maxTestedServer` banner | Nightly failure on `main` |
| K11 | macOS CI minutes cost | Medium | Low | Apple job path-filtered on PRs | Budget alert |
| K12 | A bundled font or brand asset lacks a redistribution licence | Low | Medium | Font-licence gate in `license_audit`: every file under `assets/fonts/` needs its licence text beside it | Gate failure |
