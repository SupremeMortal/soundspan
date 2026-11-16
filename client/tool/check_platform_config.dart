// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Checks the platform configuration files for the entries the app needs
// (doc 10, Deep Links Summary) and exits non-zero listing every missing one.
//
//   dart run tool/check_platform_config.dart [--android-manifest=<path>]
//       [--ios-plist=<path>] [--macos-plist=<path>] [--linux-desktop=<path>]
//
// Paths default to the source files under client/. Run from client/.

import 'dart:io';

import 'package:xml/xml.dart';

/// The URL scheme every native target registers.
const String urlScheme = 'soundspan';

/// The source file each flag defaults to, relative to `client/`.
const Map<String, String> defaultPaths = {
  'android-manifest': 'android/app/src/main/AndroidManifest.xml',
  'ios-plist': 'ios/Runner/Info.plist',
  'macos-plist': 'macos/Runner/Info.plist',
  'linux-desktop': 'linux/packaging/io.soundspan.app.desktop',
};

/// One entry a configuration file lacks.
class ConfigViolation {
  /// Creates a violation of [entry] in the file at [path].
  const new(this.path, this.entry);

  /// The file checked.
  final String path;

  /// What is missing.
  final String entry;

  @override
  String toString() => '$path: missing $entry';
}

/// Checks the four files named in [paths] (keys of [defaultPaths]; absent
/// keys take the default) and returns every missing entry.
List<ConfigViolation> checkPlatformConfig([
  Map<String, String> paths = const {},
]) {
  String path(String key) => paths[key] ?? defaultPaths[key]!;
  return [
    ...checkAndroidManifest(path('android-manifest')),
    ...checkPlist(path('ios-plist')),
    ...checkPlist(path('macos-plist')),
    ...checkLinuxDesktop(path('linux-desktop')),
  ];
}

XmlDocument? _readXml(String path, List<ConfigViolation> out) {
  final file = File(path);
  if (!file.existsSync()) {
    out.add(ConfigViolation(path, 'the file'));
    return null;
  }
  try {
    return XmlDocument.parse(file.readAsStringSync());
  } on XmlException catch (error) {
    out.add(ConfigViolation(path, 'well-formed XML (${error.message})'));
    return null;
  }
}

/// The URL-scheme intent filter on `MainActivity`: action `VIEW`, categories
/// `DEFAULT` and `BROWSABLE`, and `<data android:scheme="soundspan"/>`.
List<ConfigViolation> checkAndroidManifest(String path) {
  final out = <ConfigViolation>[];
  final document = _readXml(path, out);
  if (document == null) return out;
  const android = 'http://schemas.android.com/apk/res/android';
  String? attr(XmlElement e, String name) =>
      e.getAttribute(name, namespaceUri: android) ??
      e.getAttribute('android:$name');

  final activity = document.findAllElements('activity').where((e) {
    final name = attr(e, 'name');
    return name == '.MainActivity' ||
        (name?.endsWith('.MainActivity') ?? false);
  }).firstOrNull;
  if (activity == null) {
    out.add(ConfigViolation(path, '<activity android:name=".MainActivity">'));
    return out;
  }
  bool hasChild(XmlElement filter, String tag, String name, String value) =>
      filter.findElements(tag).any((e) => attr(e, name) == value);

  final filters = activity
      .findElements('intent-filter')
      .where(
        (f) =>
            f.findElements('data').any((d) => attr(d, 'scheme') == urlScheme),
      );
  if (filters.isEmpty) {
    out.add(
      ConfigViolation(
        path,
        'MainActivity <intent-filter> with <data android:scheme="$urlScheme"/>',
      ),
    );
    return out;
  }
  final filter = filters.first;
  for (final (tag, value) in const [
    ('action', 'android.intent.action.VIEW'),
    ('category', 'android.intent.category.DEFAULT'),
    ('category', 'android.intent.category.BROWSABLE'),
  ]) {
    if (!hasChild(filter, tag, 'name', value)) {
      out.add(
        ConfigViolation(
          path,
          '<$tag android:name="$value"/> in the $urlScheme intent filter',
        ),
      );
    }
  }
  return out;
}

/// `CFBundleURLTypes` with a `CFBundleURLSchemes` entry `soundspan` (iOS and
/// macOS `Info.plist`).
List<ConfigViolation> checkPlist(String path) {
  final out = <ConfigViolation>[];
  final document = _readXml(path, out);
  if (document == null) return out;
  final top = document.rootElement.findElements('dict').firstOrNull;
  final types = top == null ? null : _plistValue(top, 'CFBundleURLTypes');
  final registered =
      types != null &&
      types.name.local == 'array' &&
      types.findElements('dict').any((type) {
        final schemes = _plistValue(type, 'CFBundleURLSchemes');
        return schemes != null &&
            schemes
                .findElements('string')
                .any((s) => s.innerText.trim() == urlScheme);
      });
  if (!registered) {
    out.add(
      ConfigViolation(
        path,
        'CFBundleURLTypes with CFBundleURLSchemes $urlScheme',
      ),
    );
  }
  return out;
}

/// The value element following `<key>[key]</key>` in [dict].
XmlElement? _plistValue(XmlElement dict, String key) {
  final children = dict.childElements.toList();
  for (var i = 0; i < children.length - 1; i++) {
    if (children[i].name.local == 'key' &&
        children[i].innerText.trim() == key) {
      return children[i + 1];
    }
  }
  return null;
}

/// The `[Desktop Entry]` keys that register the scheme handler.
List<ConfigViolation> checkLinuxDesktop(String path) {
  final file = File(path);
  if (!file.existsSync()) return [ConfigViolation(path, 'the file')];
  final entries = <String, String>{};
  var inEntry = false;
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('[')) {
      inEntry = line == '[Desktop Entry]';
      continue;
    }
    final equals = line.indexOf('=');
    if (inEntry && equals > 0) {
      entries[line.substring(0, equals).trim()] = line
          .substring(equals + 1)
          .trim();
    }
  }
  final out = <ConfigViolation>[];
  final exec = (entries['Exec'] ?? '').split(RegExp(r'\s+'));
  if (!exec.contains('%u') && !exec.contains('%U')) {
    out.add(ConfigViolation(path, 'Exec=… %u'));
  }
  final mimeTypes = (entries['MimeType'] ?? '').split(';');
  if (!mimeTypes.contains('x-scheme-handler/$urlScheme')) {
    out.add(ConfigViolation(path, 'MimeType=x-scheme-handler/$urlScheme;'));
  }
  for (final key in const ['Icon', 'StartupWMClass']) {
    if (entries[key] != 'io.soundspan.app') {
      out.add(ConfigViolation(path, '$key=io.soundspan.app'));
    }
  }
  return out;
}

/// Parses `--name=value` and `--name value` flags; unknown flags throw a
/// [FormatException].
Map<String, String> parseFlags(List<String> args) {
  final paths = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) throw FormatException('Unexpected $arg');
    final equals = arg.indexOf('=');
    final name = arg.substring(2, equals < 0 ? null : equals);
    if (!defaultPaths.containsKey(name)) {
      throw FormatException('Unknown flag --$name');
    }
    if (equals >= 0) {
      paths[name] = arg.substring(equals + 1);
    } else if (i + 1 < args.length) {
      paths[name] = args[++i];
    } else {
      throw FormatException('--$name needs a path');
    }
  }
  return paths;
}

void main(List<String> args) {
  final Map<String, String> paths;
  try {
    paths = parseFlags(args);
  } on FormatException catch (error) {
    stderr.writeln('check_platform_config: ${error.message}');
    exitCode = 64;
    return;
  }
  final violations = checkPlatformConfig(paths)..forEach(stderr.writeln);
  if (violations.isNotEmpty) {
    stderr.writeln(
      'check_platform_config: ${violations.length} missing '
      '${violations.length == 1 ? 'entry' : 'entries'}',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('check_platform_config: all entries present');
}
