# 11. Testing and CI

Status: design phase.

`AGENTS.md` rules apply to the client: test first for executable changes, assert on behaviour, no source-text tests, evidence with the `verify:` prefix.

## Test Layers

| Layer | Location | Runner | What it proves | Runs on |
|---|---|---|---|---|
| Unit: API package | `packages/soundspan_api/test` | `dart test` | Interceptors, error mapping, URL builders, decode smoke of every generated model from captured fixtures | Every PR |
| Unit: app | `client/test/**` (not `goldens/`) | `flutter test` | Queue reducer, loudness, play reporter, outbox, download state machine, address normalization, probe classification, LRC parser, Listen Together sync maths | Every PR |
| Widget | `client/test/**/ui` | `flutter test` | Screens with fake repositories: states, navigation, semantics guidelines | Every PR |
| Golden | `client/test/goldens` | `flutter test --tags golden` (`alchemist`) | Pixel layout of components and screens | Every PR, Linux only |
| Contract | `client/contract_test` | `dart test --tags contract` | Behaviour against a real server that validates its own responses against the spec | PRs touching `client/packages/soundspan_api/**`, `backend/src/routes/**`, or `backend/src/openapi/**`; nightly |
| Engine conformance | `client/integration_test/engine_conformance_test.dart` | `flutter test integration_test -d <device>` | `PlayerEngine` contract on the real backend | PRs touching `core/playback/engines/**`; nightly on all desktop OSes and an Android emulator |
| Integration (mobile) | `client/integration_test/patrol` | Patrol | Sign-in → play → background → notification controls → offline playback | Nightly (Android emulator); iOS simulator weekly and before release |
| Integration (desktop) | `client/integration_test/desktop` | `flutter test integration_test -d linux|windows|macos` | Shell, shortcuts, window state, media-control adapter smoke | Nightly |
| Manual matrix | `docs/designs/flutter-client/` release checklist issue template | People | Bluetooth, Android Auto, calls, sleep/wake, network handoff, screen readers, resource budgets | Each release |

Coverage: `flutter test --coverage` merged with the API package's; floor 80 % lines for `lib/core/**` and `packages/soundspan_api/lib/**`, 60 % overall, excluding `*.g.dart`, `*.freezed.dart`, and `generated/` directories. `tool/coverage_floor.dart` checks the floors in `tool/coverage_floor.json`. `tool/coverage_exclusions.txt` lists plugin-bound adapters that `flutter test` cannot run, one glob per line with a ` # reason`; an entry without a reason or one that matches no file fails the check. The floor is a ratchet: it is raised when exceeded by 5 points, never lowered. The check is advisory about the ratchet: it prints the new floor to commit and does not fail for it.

## Test Doubles

| Double | Replaces | Notes |
|---|---|---|
| `FakeEngine` | `PlayerEngine` | Virtual clock; scripted durations and failures; passes the conformance suite |
| `FakeApi` | `SoundspanApi` resource classes | In-memory server model (tracks, playlists, likes) so repository and outbox tests exercise real request sequences |
| `FakeDownloader` | `Downloader` | Emits progress and completion on demand; can inject 401, 404, and truncated files |
| `FakeReachability` | `ReachabilityController` | |
| `FakeClock` | `Clock` (injected everywhere time is read; `DateTime.now()` is banned by lint outside `lib/platform/`) | |
| In-memory drift | Databases | `NativeDatabase.memory()`; migrations tested with generated schema helpers |
| `InMemorySecretStore` | `SecretStore` | |

`test/helpers/pump_app.dart` builds a `ProviderContainer` with these overrides and pumps a screen at a given window class, theme, locale, and text scale.

## Golden Tests

- Matrix per component or screen: widths 390, 800, 1440 × themes dark, light. Selected ones also at text scale 2.0, pseudo-locale, and RTL.
- Rendered with the bundled Montserrat (loaded in `flutter_test_config.dart`) so text is real; goldens are generated and compared **only on the Linux CI image** (`alchemist` CI mode) to avoid cross-platform anti-aliasing diffs. Developers on other OSes run the platform-independent "blocked text" variant locally.
- Updating: commit the images from the `client-golden-rendered` artifact of a failing `client-golden` run, or run `flutter test --tags golden --update-goldens` on Linux with the pinned Flutter (`tool/goldens.sh` runs it through Docker or Podman).
- Network images are replaced by a deterministic placeholder provider.

## Contract Suite

Shapes are proven on the server: P9 validates every client-surface response against its schema ([12](12-server-prerequisites-p6-p9.md)). The contract suite proves what a schema cannot: sequences, headers, status codes, and that the generated client and the hand-written transport work against a real server together.

**Server under test.** `client/contract_test/compose.yaml` extends the repository's `docker-compose.yml` services needed for the API (backend, PostgreSQL with pgvector, Redis), built from the PR's own backend source and started with `OPENAPI_VALIDATE_RESPONSES=1`, so a response that does not match its schema answers 500 and fails the test that caused it. With:

- a fixture music directory of short generated tones with tags (3 artists, 6 albums, 40 tracks, one multi-disc album, one track with embedded lyrics);
- a seed script (`contract_test/seed.ts`, run with the backend's own tooling) that completes onboarding, creates a user and an admin, runs a scan, creates a playlist, subscribes a podcast from a local RSS fixture, and writes the credentials to a JSON file the tests read;
- optional providers (TIDAL, YouTube) disabled. Remote-source behaviour is covered on the server side by the Unified Playback Smoke job; the client suite asserts only that a disabled source yields `SOURCE_UNAVAILABLE` in the expected shape.

**Tests.** One group per table in the endpoint inventory ([03](03-api-layer.md)). Each calls every operation in its table through the generated client at least once, which exercises decoding and the server's response validation in one step. Behavioural cases:

- Login, refresh rotation, refresh with a rotated-out token, 2FA challenge shape, rate-limit body is plain text with `Retry-After`.
- Device-link verify with a code generated through the seeded web session; API key works on JSON, stream, image, and socket; `?token=` with an API key is rejected.
- `GET /playback/stream`: `200`, `206` with `Range`, strong `ETag`, `If-Range` match and mismatch, `quality` variants, each error code.
- P6–P8 behaviours ([12](12-server-prerequisites-p6-p9.md)), including a play reported with `playedAt` and `listenedMs`, its idempotent retry, and a play under 5 seconds not being recorded.
- Offline: request album and playlist, complete, list, revoke through the admin switch, delete, cache-limit error body.
- Playback state round trip with `X-Playback-Device-Id`; queue truncation at 100.
- Playlist add, remove, and reorder by `playbackId`.
- Socket handshake with JWT and with API key; queue add by `playbackId`.
- Feature-disabled 404 shape.

**Fixtures.** `tool/capture_fixtures.dart` runs against the same server and writes scrubbed responses to `packages/soundspan_api/test/fixtures/`, for the decode smoke test. Fixtures are refreshed when the spec changes.

**Version matrix.** Nightly, the suite runs against `minServer`, the latest release, and `main`. A failure on `main` is the early warning that a server change breaks the client.

## CI Workflows

### `client-quality.yml`

```yaml
on:
  pull_request:
    paths:
      - "client/**"
      - "backend/src/routes/**"
      - "backend/src/openapi/**"
      - ".github/workflows/client-*.yml"
      - ".github/actions/client-flutter/**"
  push:
    branches: [main]
    paths: ["client/**"]
```

Server-only PRs do not trigger it, except route and `backend/src/openapi/**` changes, which run the spec check and the contract job only.

A first job, `changes`, diffs the pull request against the merge base with its base branch using plain `git diff --name-only` and sets three outputs: `client` (`client/**`, the client workflows, or the composite action changed), `apple` (`client/ios/**`, `client/macos/**`, `client/pubspec.lock`, `client/lib/platform/**`, `client-quality.yml`, or the composite action), and `api_surface` (`client/packages/soundspan_api/**`, `backend/src/routes/**`, `backend/src/openapi/**`). On `push` every output is true. Because the diff is against the base branch and not the previous push, a job that failed on an earlier push cannot be skipped on a later one. The analyze, test, golden, Android, Linux, web, and Windows jobs run when `client` is true; the Apple job runs when `apple` is true.

Every client job sets Flutter up with the composite action `.github/actions/client-flutter`: on Linux it installs the build packages of [01](01-toolchain-and-repository.md) (plugin native-asset hooks run during `flutter test` and need GTK and X11 headers), then it reads the version from `client/.fvmrc` with `jq`, installs it with `subosito/flutter-action`, caches Flutter on `.fvmrc` and pub on `.fvmrc` plus both `pubspec.lock` files, and runs `flutter pub get` in `client/` and `dart pub get` in the API package.

| Job | Runner | Blocking | Steps |
|---|---|---|---|
| `client-analyze` | ubuntu | Yes | `tool/gen.sh` + `git diff --exit-code`; `dart format --output=none --set-exit-if-changed .`; `flutter analyze --fatal-infos`; `dart analyze --fatal-infos` in the API package; `dart run tool/check_imports.dart`; `dart run tool/check_l10n.dart`; `dart run tool/license_audit.dart` |
| `client-test` | ubuntu | Yes | `dart test --coverage-path=coverage/lcov.info` in the API package; `flutter test --coverage --exclude-tags golden,contract,engine`; `dart run tool/coverage_floor.dart` |
| `client-golden` | ubuntu, directly on the runner with the pinned Flutter (no container) | Yes | `flutter test --tags golden`; on failure uploads `client/test/**/failures/**` as `client-golden-failures`, then reruns with `--update-goldens` and uploads every golden image as `client-golden-rendered`, with paths relative to `client/`, ready to commit |
| `client-spec` | ubuntu | Yes when the API package, backend routes, or `backend/src/openapi/**` changed | `npm --prefix backend run openapi:emit-client` + `git diff --exit-code`; `dart run tool/spec_compat.dart` |
| `client-contract` | ubuntu | Yes on the same paths | Build backend, `docker compose up` with response validation on, seed, `dart test --tags contract` |
| `client-build-android` | ubuntu | Yes | Temurin 17 (`actions/setup-java`); `flutter build apk --debug` |
| `client-build-linux` | ubuntu | Yes | `flutter build linux --release`; `tool/check_ldd.sh` runs `ldd` on the executable and every `.so` in `build/linux/x64/release/bundle/lib/` and fails on any `not found` line |
| `client-build-web` | ubuntu | Yes | `flutter build web --release`; `tool/web_bundle_report.sh` writes the gzip-compressed total of `build/web` and its five largest files to the job summary, with no threshold |
| `client-build-windows` | windows | Yes | `flutter build windows --release` |
| `client-build-macos-ios` | macos | Yes whenever it runs | `flutter build macos --release`; `flutter build ios --release --no-codesign` |

Every build job passes `--dart-define-from-file=config/dev.json`.

macOS minutes are the expensive ones, so on pull requests the Apple job runs only when the diff against the base branch touches `client/ios/**`, `client/macos/**`, `client/pubspec.lock`, `client/lib/platform/**`, `client-quality.yml`, or the composite action, and always on a push to `main`. Whenever it runs it is blocking, so a pull request cannot leave the Apple builds broken.

Actions are pinned by commit SHA, as in the existing workflows. Flutter and pub caches are keyed on `.fvmrc` and `pubspec.lock`.

### `client-nightly.yml`

Engine conformance on Linux, Windows, macOS, and an Android emulator; Patrol on the Android emulator; desktop integration tests; contract version matrix. Failures open or update one tracking issue.

### `client-release.yml`

Trigger: tag `client-v*`.

1. Validate the tag against `pubspec.yaml` `version`.
2. Build all targets in a matrix with `--dart-define-from-file=config/release.json` and `--build-number` from the run number.
3. Mark artifacts `-unsigned`. Signing steps are added when signing is set up.
4. Generate `SHA256SUMS` and build-provenance attestations.
5. Create a **draft** GitHub release with artifacts and notes from the `### Client` changelog sections.
6. Manual approval (environment protection) publishes the release as a **pre-release**, pushes the web image to GHCR as `ghcr.io/<repo>-client-web:<version>`, and updates desktop appcasts (M5).

### Local Equivalents

`client/tool/verify.sh` runs the `client-analyze` and `client-test` jobs. The root `package.json` gains `verify:client` (calls it) and it is listed in `AGENTS.md`'s verification table. `npm run verify` does not include it; client work runs `verify:client`, server work is unchanged.

## Gates Specific to the Client

| Gate | Tool | Fails when |
|---|---|---|
| Generated code is current | `tool/gen.sh` + diff | Any generated file differs |
| Layering and platform imports | `tool/check_imports.dart` | A rule in [01](01-toolchain-and-repository.md) is broken |
| Source-agnostic client | `tool/check_imports.dart` | Banned identifiers appear under `client/lib` or the API package |
| No hard-coded UI strings | `tool/check_l10n.dart` | A literal reaches a text widget |
| Token contrast | Unit test | A text/surface pair is under its ratio |
| Spec is current and compatible | `client-spec` job | The committed spec differs from the backend's, or breaks compatibility with the `minServer` snapshot |
| Dependency licences | `tool/license_audit.dart` | A dependency's licence is not on the allowlist (MIT, BSD-2/3, Apache-2.0, MPL-2.0, ISC, Zlib, LGPL for dynamically linked native libraries); GPL-only fails. The audited set is the transitive closure of the non-dev dependencies of the app and of `soundspan_api`, without Flutter SDK packages. LGPL needs a `linking: dynamic` entry in `tool/license_overrides.yaml`; an unrecognised or missing licence text needs an entry naming an allowed licence; an entry for a package outside the audited set fails. Also fails when a font file (`.ttf`, `.otf`, `.ttc`, `.woff`, `.woff2`) under `assets/fonts/` has no non-empty licence text at `assets/licenses/fonts/<Family>.txt`, where the family is the file name up to its first `-` |
| File size | `scripts/ci/check-file-size.mjs` | Existing thresholds, extended to Dart |
| ARB completeness | `flutter gen-l10n` with `--required-resource-attributes` | A message lacks a description |

## Signing and Store Distribution

Deferred until the software is ready for v1, and not tracked as tasks. Until then `client-release.yml` produces unsigned pre-release artifacts: a debug-signed APK, Windows `.exe` and MSIX, an ad-hoc signed macOS `.dmg` (opens after the user approves it in System Settings), Linux packages, and the web bundle. There is no iOS artifact, because iOS builds cannot be distributed without an Apple account; iOS is exercised in the simulator and on developers' own devices. Release notes state that the artifacts are unsigned test builds.

One consequence to plan for when signing starts: Android installs an update only over a build signed with the same key. Testers will have to uninstall a debug-signed pre-release once before installing the first properly signed build, which removes its local data. The remaining signing and store work is listed in [13](13-milestones-and-work-breakdown.md).

## Manual Release Matrix

A checklist issue template, modelled on `docs/NATIVE_AUDIO_ENGINE.md`'s validation pattern. Sections:

- **Playback:** gapless album on each platform by ear; seek; quality switch; loudness modes; podcast resume and speed.
- **Interruptions:** phone call, alarm, another media app, headphones unplugged, Bluetooth connect/disconnect, AirPods/headset buttons.
- **Background:** 1 hour screen-off playback on Android and iOS; app swiped away on Android; device reboot then play from notification.
- **OS controls:** lock screen and notification (Android), Control Center and lock screen (iOS), Now Playing and media keys (macOS), SMTC flyout and media keys (Windows), MPRIS in GNOME and KDE (Linux), Media Session in Chrome.
- **Cars:** Android Auto Desktop Head Unit: browse, play, voice search, offline.
- **Network:** Wi-Fi → mobile handoff mid-track; airplane mode mid-track with and without downloads; captive portal; server restart during playback; reverse proxy with sub-path; LAN `http://`.
- **Offline:** download album and playlist; kill app mid-download; resume; revoke from the server; quota reached.
- **Accounts:** password with 2FA; device link by code and by QR; expiring key; two profiles on one device.
- **Accessibility:** scripted pass with each screen reader; keyboard-only pass on desktop; text scale 2.0.
- **Resource budgets:** the table in the design document, measured with the platform profiler, recorded in the issue.
