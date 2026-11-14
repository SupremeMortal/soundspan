# soundspan client

The first-party soundspan client, written in Flutter for Android, iOS, Linux,
macOS, Windows and the web. The design documents are under
[`docs/designs/flutter-client/`](../docs/designs/flutter-client.md).

## Toolchain

Use the Flutter release pinned in [`.fvmrc`](.fvmrc), for example with
[FVM](https://fvm.app/) (`fvm use`). Linux desktop builds also need
`clang cmake ninja-build pkg-config libgtk-3-dev libmpv-dev libsecret-1-dev libjsoncpp-dev`.

```bash
flutter pub get
```

## File names

The repository's root `.gitignore` ignores `*.conf` and `*.seed` everywhere,
so client files must not use those extensions.

## Code generation

Generated files are committed. After changing an input of code generation
(ARB files, annotated sources, the API spec), run:

```bash
tool/gen.sh
```

## Run

Pass the build configuration with `--dart-define-from-file`:

| Target | Command |
|---|---|
| Android | `flutter run -d android --dart-define-from-file=config/dev.json` |
| iOS | `flutter run -d ios --dart-define-from-file=config/dev.json` |
| Linux | `flutter run -d linux --dart-define-from-file=config/dev.json` |
| macOS | `flutter run -d macos --dart-define-from-file=config/dev.json` |
| Windows | `flutter run -d windows --dart-define-from-file=config/dev.json` |
| Web | `flutter run -d chrome --dart-define-from-file=config/dev.json` |

## Build

Release builds use `config/release.json`:

| Target | Command |
|---|---|
| Android | `flutter build appbundle --dart-define-from-file=config/release.json` and `flutter build apk --dart-define-from-file=config/release.json` |
| iOS | `flutter build ipa --dart-define-from-file=config/release.json` |
| Linux | `flutter build linux --dart-define-from-file=config/release.json` |
| macOS | `flutter build macos --dart-define-from-file=config/release.json` |
| Windows | `flutter build windows --dart-define-from-file=config/release.json` |
| Web | `flutter build web --dart-define-from-file=config/release.json` |

## Web database files

The web build runs its drift databases through two files in `web/`, taken
from the releases that match the `sqlite3` and `drift` versions in
`pubspec.lock`. Replace both when either package changes version.

| File | Source | SHA-256 |
|---|---|---|
| `web/sqlite3.wasm` | <https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.9.1/sqlite3.wasm> | `e7451780e78c56ff864fe9317a0fbcd6aeb2e8de3beba7f5efd963202f7ec3d9` |
| `web/drift_worker.js` | <https://github.com/simolus3/drift/releases/download/drift-2.35.4/drift_worker.js> | `48c950cd8e3bc3cddb34816c860e228be8832bef07a297c27e9907c057ff8162` |

## Tests and checks

In `client/`:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

The web storage integration test runs in Chrome with a `chromedriver` that
matches the installed Chrome listening on port 4444:

```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/web/storage_web_test.dart \
  -d web-server --browser-name=chrome --headless
```

In `client/packages/soundspan_api/`:

```bash
dart pub get
dart analyze --fatal-infos
dart test
```

## Licence

The client is licensed under GPL-3.0 with an additional permission for
distribution through application stores. See [`LICENSE`](LICENSE). Every
hand-written Dart file starts with:

```dart
// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
```
