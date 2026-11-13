# 01. Toolchain and Repository

Status: design phase.

## Toolchain Pin

| Tool | Pin | Where |
|---|---|---|
| Flutter | 3.50.0 stable (Dart 3.14.0) | `client/.fvmrc`; CI reads the same file |
| FVM | 3.x | Developer machines and CI (`subosito/flutter-action` with `flutter-version-file: client/.fvmrc`) |
| Java | 17 (Temurin) | Android Gradle builds |
| Android | compileSdk 37 (`flutter_local_notifications` and `androidx.core` require it), targetSdk = Flutter default for the pinned SDK, minSdk 26, core library desugaring with `desugar_jdk_libs` 2.1.4 (required by `flutter_local_notifications`) | `client/android/app/build.gradle.kts` |
| Xcode | Latest stable on the `macos-latest` runner | iOS deployment target 15.0, macOS 12.0 (the pinned SDK's minimum) |
| Visual Studio | 2022 Build Tools with "Desktop development with C++" | Windows |
| Linux build deps | `clang cmake ninja-build pkg-config libgtk-3-dev libmpv-dev libsecret-1-dev libjsoncpp-dev` | Linux |

Flutter is upgraded deliberately: one PR that bumps `.fvmrc`, runs `flutter pub upgrade --major-versions` where wanted, regenerates code, and re-runs the full matrix. No floating `stable`.

## Directory Tree

```
client/
├── .fvmrc
├── LICENSE                         # GPL-3.0 + section 7 app-store permission (design doc, Licensing)
├── README.md                       # Build and run instructions per target
├── analysis_options.yaml
├── build.yaml                      # build_runner builder options
├── dart_test.yaml                  # Tags: contract, golden, engine
├── l10n.yaml
├── pubspec.yaml
├── pubspec.lock                    # Committed
├── assets/
│   ├── fonts/Montserrat-VariableFont_wght.ttf
│   ├── fonts/TurretRoad-ExtraBold.ttf  # Wordmark only
│   ├── brand/                      # soundspan-mark.svg, soundspan-mark-mono.svg, tray icons
│   └── licenses/                   # Notices for bundled native libraries (libmpv, ffmpeg)
├── lib/
│   ├── main.dart                   # Calls bootstrap(); no logic
│   ├── bootstrap.dart              # Zone, error hooks, logging, ProviderScope
│   ├── app/
│   │   ├── app.dart                # MaterialApp.router
│   │   ├── router/                 # routes.dart, guards.dart, shell_route.dart
│   │   ├── shell/                  # AdaptiveShell: bottom bar | rail | sidebar; player bar host
│   │   ├── theme/                  # tokens.dart, color_schemes.dart, typography.dart, extensions.dart
│   │   └── l10n/                   # app_en.arb, generated localizations
│   ├── core/
│   │   ├── auth/                   # ProfileRepository, SessionController, sign-in use cases
│   │   ├── connectivity/           # ReachabilityController
│   │   ├── downloads/              # DownloadController, DownloadStore, reconciliation
│   │   ├── logging/                # AppLogger, redaction, rolling file sink
│   │   ├── playback/               # PlaybackController, queue model, engines, media controls
│   │   ├── profile/                # ProfileScope, deviceId, capability refresh
│   │   ├── realtime/               # SocketClient, ListenTogetherController, PresenceController
│   │   ├── storage/                # AppDatabase, CacheDatabase, StateDatabase, SecretStore, paths
│   │   └── sync/                   # Outbox, PlayReporter, PlaybackStateSync
│   ├── features/
│   │   ├── connect/                # Add server, probe, sign-in, device link, QR
│   │   ├── home/
│   │   ├── search/
│   │   ├── library/                # Playlists, Artists, Albums, Songs, Downloads tabs
│   │   ├── album/  artist/  playlist/
│   │   ├── player/                 # Mini player, player bar, now playing, queue, lyrics
│   │   ├── podcasts/
│   │   ├── listen_together/        # M4
│   │   ├── discover/               # M4: explore, mixes, vibe
│   │   └── settings/               # Servers, playback, storage, appearance, about
│   │       └── <each feature>/{data,domain,ui}/
│   ├── platform/                   # One interface + io/web implementations per seam
│   └── shared/                     # Widgets and utilities used by 2+ features
├── packages/
│   ├── soundspan_api/              # Pure Dart. Transport plus models and clients generated from the server spec.
│   └── soundspan_smtc/             # Only if spike S4 rejects smtc_windows: C++/WinRT plugin
├── test/                           # Mirrors lib/
│   ├── goldens/
│   └── helpers/                    # pumpApp, fakes, fixture loader
├── integration_test/               # Patrol and desktop integration tests
├── contract_test/                  # Runs soundspan_api against a real server with response validation on
├── tool/
│   ├── check_imports.dart          # Layer and platform import rules
│   ├── check_l10n.dart             # No hard-coded user-visible strings in ui/
│   ├── license_audit.dart          # Dependency license allowlist
│   ├── gen.sh                      # build_runner + gen-l10n
│   ├── gen_icons.dart              # Icon sets from the vector logo master
│   ├── specs/                      # Client-surface spec snapshot of the minServer release
│   └── spec_compat.dart            # Fails when the current spec is not backward compatible with it
└── android/ ios/ macos/ windows/ linux/ web/
```

## `pubspec.yaml`

Version floors are the releases current when the plan was written; every floor resolves on the pinned SDK. The lockfile is the real pin. Dependencies are listed alphabetically (`sort_pub_dependencies`). `material_ui` carries the Material widgets, which moved out of the Flutter SDK (`package:flutter/material.dart` is deprecated in the pinned release).

```yaml
name: soundspan
description: First-party soundspan client.
publish_to: none
version: 0.1.0+1

environment:
  sdk: ^3.14.0
  flutter: ^3.50.0

dependencies:
  app_links: ^7.2.0
  audio_service: ^0.18.19
  audio_service_mpris: ^0.2.1
  audio_session: ^0.2.4
  background_downloader: ^9.6.0
  cached_network_image: ^4.0.0
  collection: ^1.19.0
  connectivity_plus: ^7.3.0
  drift: ^2.35.0
  drift_flutter: ^0.3.0
  dynamic_color: ^2.1.0          # Only to read the platform contrast setting; palette is fixed
  flutter: { sdk: flutter }
  flutter_cache_manager: any
  flutter_local_notifications: ^23.0.0
  flutter_localizations: { sdk: flutter }
  flutter_riverpod: ^3.5.0
  flutter_secure_storage: ^11.2.0
  freezed_annotation: ^3.0.0
  go_router: ^18.1.0
  intl: any
  json_annotation: ^4.9.0
  just_audio: ^0.10.6            # Android, iOS, macOS, web
  logging: ^1.3.0
  material_ui: ^1.1.0            # Material widgets; moved out of the Flutter SDK
  media_kit: ^1.2.6              # Windows, Linux
  media_kit_libs_linux: any
  media_kit_libs_windows_audio: any
  mobile_scanner: ^7.5.0         # QR; Android, iOS, macOS, web
  package_info_plus: ^10.2.0
  path: ^1.9.0
  path_provider: ^2.1.6
  riverpod_annotation: ^4.0.0
  smtc_windows: ^1.1.0           # Subject to spike S4
  socket_io_client: ^3.1.6
  soundspan_api: { path: packages/soundspan_api }
  tray_manager: ^0.9.0
  url_launcher: any
  window_manager: ^0.7.0

dev_dependencies:
  alchemist: ^0.14.0
  build_runner: any
  drift_dev: ^2.35.0
  flutter_test: { sdk: flutter }
  freezed: ^4.0.0
  http_mock_adapter: any
  integration_test: { sdk: flutter }
  json_serializable: ^6.15.0
  mocktail: ^1.0.5
  patrol: ^4.11.0
  riverpod_generator: ^4.0.0
  very_good_analysis: ^11.0.0

flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/brand/
    - assets/licenses/
  fonts:
    - family: Montserrat
      fonts:
        - asset: assets/fonts/Montserrat-VariableFont_wght.ttf
    - family: Turret Road          # Wordmark only
      fonts:
        - asset: assets/fonts/TurretRoad-ExtraBold.ttf
          weight: 800
```

Added in later milestones, not in M0: `auto_updater` (after signing, subject to spike S7), `home_widget` (M6). There is no crash-reporting package.

### Package Review Outcomes

Every package in the design document's table was checked for release cadence and platform coverage.

| Package | Finding | Action |
|---|---|---|
| `just_audio_media_kit` | Low release cadence; sits between the app and mpv | Dropped |
| `smtc_windows` | Low release cadence; wraps WinRT through generated bindings | Spike S4 decides between it and an in-repo C++/WinRT plugin (`soundspan_smtc`) |
| `auto_updater` | Low release cadence; wraps Sparkle and WinSparkle | Spike S7 in M5; fallback is a version check that opens the release page |
| `sqlite3_flutter_libs` | End of life | Not referenced. `drift_flutter` brings the supported SQLite integration |
| `openapi_generator` | Wraps the Java OpenAPI Generator, so CI and every developer machine would need a JDK | Replaced by `swagger_parser` (pure Dart). Kept as the fallback if spike S8 fails |
| `media_kit_libs_linux` | Uses the system libmpv | Packaging handles libmpv per format |
| All others | Actively released | Adopted |

`soundspan_api/pubspec.yaml` depends only on `dio`, `retrofit`, `freezed_annotation`, `json_annotation`, `meta`, and `collection` (dev: `swagger_parser`, `retrofit_generator`, `freezed`, `json_serializable`, `build_runner`, plus `test` for its runner and `very_good_analysis` for the shared analysis options it includes), so it can be tested with plain `dart test` and reused by a future CLI or TV app.

## Static Analysis

`client/analysis_options.yaml`:

```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore   # freezed + json_serializable
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - packages/soundspan_api/lib/src/generated/**
    - lib/app/l10n/generated/**
linter:
  rules:
    public_member_api_docs: true        # AGENTS.md documentation-coverage rule
    avoid_print: true                   # AGENTS.md logging rule: use AppLogger
    lines_longer_than_80_chars: false   # dart format decides
```

Rules the analyzer cannot express are enforced by `tool/check_imports.dart`, which parses import directives and fails CI on a violation:

| Rule | Reason |
|---|---|
| `dart:io`, `dart:js_interop`, and `package:web` only under `lib/platform/**` and `packages/**` | Platform seams (design doc, Architecture) |
| `package:just_audio` and `package:media_kit` only under `lib/core/playback/engines/**` | Playback packages stay behind `PlayerEngine` |
| `package:dio` only under `packages/soundspan_api/**` and `lib/core/downloads/**` | Single HTTP boundary |
| `features/<a>/**` never imports `features/<b>/**` except `features/<b>/<b>.dart` (its public barrel) | Feature isolation |
| `**/domain/**` imports no Flutter, no drift, no dio | Pure domain |
| `**/ui/**` imports no `data/` | UI talks to providers |
| No file under `lib/` contains the identifiers `streamSource`, `tidalTrackId`, `youtubeVideoId`, or a string-prefix test on a `playbackId` | Source-agnostic rule (design doc, Source-Agnostic Tracks) |

## Code Generation

One command, `tool/gen.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
(cd packages/soundspan_api && dart run swagger_parser && dart run build_runner build --delete-conflicting-outputs)
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

| Generator | Inputs | Outputs |
|---|---|---|
| `swagger_parser` | `packages/soundspan_api/openapi/soundspan-client.json` (emitted by the backend, P9) | `packages/soundspan_api/lib/src/generated/` |
| `retrofit_generator` | Generated client interfaces | `*.g.dart` |
| `freezed` + `json_serializable` | Generated API models, domain value types | `*.freezed.dart`, `*.g.dart` |
| `drift_dev` | `lib/core/storage/**/tables/*.dart`, `*.drift` | `*.g.dart`, schema dumps under `drift_schemas/` |
| `riverpod_generator` | `@riverpod` functions and classes | `*.g.dart` |
| `gen-l10n` | `lib/app/l10n/app_*.arb` | `lib/app/l10n/generated/` |

Generated files are **committed**. CI runs `tool/gen.sh` and fails if `git diff --exit-code` reports a change. This keeps `flutter analyze` usable without a build step and makes generated diffs reviewable.

## Build Configuration

The client is published by the upstream soundspan project under the soundspan name, logo, and application id `io.soundspan.app`, so there are no product flavors and no white-label system. Build-time values come from `--dart-define-from-file`:

| File | Used by | Contents |
|---|---|---|
| `client/config/dev.json` | Local runs | `{"CHANNEL":"dev"}` |
| `client/config/release.json` | Release workflow | `{"CHANNEL":"stable"}` |

`lib/app/build_config.dart` exposes them as typed `const` values (`BuildConfig.channel`, `BuildConfig.minServer`, `BuildConfig.maxTestedServer`). `minServer` and `maxTestedServer` are Dart constants in source, not defines, because they describe what the code was tested against.

## Changes to the Repository Contract

These land with the scaffold PR (`M0-01`) so the client is covered by the same rules as the rest of the repo.

| File | Change |
|---|---|
| `AGENTS.md` | Handbook language list gains Dart (`dart/` module) for `client/**`. Repository-specific rules gain: API boundary is `client/packages/soundspan_api`; logging helper is `client/lib/core/logging/app_logger.dart`; the import rules above. The verification table gains the client gates from [11](11-testing-and-ci.md). |
| `scripts/ci/check-file-size.mjs` | Adds `{ directory: "client/lib", extensions: [".dart"] }` and `client/packages/*/lib`, excluding `*.g.dart`, `*.freezed.dart`, `packages/soundspan_api/lib/src/generated/**`, and generated l10n. Same 1,500 and 3,000 line thresholds. |
| `CHANGELOG.md` | Client entries go under a `### Client` subsection inside the normal headings. |
| `CONTRIBUTING.md` | Client setup section; license note for `client/` contributions. |
| `.github/workflows/` | New `client-quality.yml` and `client-release.yml`, path-filtered ([11](11-testing-and-ci.md)). |
| `.gitignore` | Flutter build outputs under `client/`. |
| `docs/README.md` | Links the client plan. |

Every Dart source file under `client/` starts with the SPDX header chosen in the design document's Licensing section. `tool/check_imports.dart` also checks for the header.
