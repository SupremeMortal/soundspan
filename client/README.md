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

## Tests and checks

In `client/`:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
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
