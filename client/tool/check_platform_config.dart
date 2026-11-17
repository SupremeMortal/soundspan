// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Checks the platform configuration files for the entries the app needs
// (doc 10: the Android manifest table, Cleartext HTTP and backup rules, the
// Deep Links Summary, and the camera entries of the QR scanner) and exits
// non-zero listing every missing one.
//
//   dart run tool/check_platform_config.dart [--android-manifest=<path>]
//       [--android-res=<dir>] [--ios-plist=<path>] [--macos-plist=<path>]
//       [--linux-desktop=<path>] [--macos-entitlements=<path>[,<path>…]]
//
// Paths default to the source files under client/. Run from client/.
// --android-manifest also takes the merged manifest of a built APK
// (`apkanalyzer manifest print`).

import 'dart:io';

import 'package:xml/xml.dart';

/// The URL scheme every native target registers.
const String urlScheme = 'soundspan';

/// The `NSCameraUsageDescription` of the iOS and macOS apps (doc 10).
const String cameraUsageDescription = 'Scan a soundspan link code.';

/// The macOS entitlement that lets the QR scanner use the camera.
const String cameraEntitlement = 'com.apple.security.device.camera';

/// The source file each flag defaults to, relative to `client/`.
/// `macos-entitlements` is a comma-separated list.
const Map<String, String> defaultPaths = {
  'android-manifest': 'android/app/src/main/AndroidManifest.xml',
  'android-res': 'android/app/src/main/res',
  'ios-plist': 'ios/Runner/Info.plist',
  'macos-plist': 'macos/Runner/Info.plist',
  'linux-desktop': 'linux/packaging/io.soundspan.app.desktop',
  'macos-entitlements':
      'macos/Runner/DebugProfile.entitlements,'
      'macos/Runner/Release.entitlements',
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

/// Checks the files named in [paths] (keys of [defaultPaths]; absent keys
/// take the default) and returns every missing entry.
List<ConfigViolation> checkPlatformConfig([
  Map<String, String> paths = const {},
]) {
  String path(String key) => paths[key] ?? defaultPaths[key]!;
  return [
    ...checkAndroidManifest(path('android-manifest')),
    ...checkAndroidRes(path('android-res')),
    ...checkPlist(path('ios-plist')),
    ...checkPlist(path('macos-plist')),
    ...checkLinuxDesktop(path('linux-desktop')),
    for (final entitlements in path('macos-entitlements').split(','))
      if (entitlements.trim().isNotEmpty)
        ...checkMacosEntitlements(entitlements.trim()),
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

/// The permissions of the doc 10 manifest table, the QR scanner's camera
/// included. `FOREGROUND_SERVICE_DATA_SYNC` comes with the download
/// notifications.
const List<String> androidPermissions = [
  'android.permission.INTERNET',
  'android.permission.ACCESS_NETWORK_STATE',
  'android.permission.FOREGROUND_SERVICE',
  'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.WAKE_LOCK',
  'android.permission.CAMERA',
];

/// The `audio_service` playback service.
const String audioServiceClass = 'com.ryanheise.audioservice.AudioService';

/// The `audio_service` media-button receiver.
const String mediaButtonReceiverClass =
    'com.ryanheise.audioservice.MediaButtonReceiver';

/// The doc 10 manifest table (except `FOREGROUND_SERVICE_DATA_SYNC` and the
/// Android Auto meta-data): [androidPermissions], the optional camera
/// feature of the QR scanner, the `<application>` network security config
/// and backup rules, cleartext traffic not switched off, `MainActivity` with
/// `launchMode="singleTask"` and the URL-scheme intent filter (action
/// `VIEW`, categories `DEFAULT` and `BROWSABLE`,
/// `<data android:scheme="soundspan"/>`), the exported `AudioService` with
/// `foregroundServiceType="mediaPlayback"` and the `MediaBrowserService`
/// intent filter, and the exported `MediaButtonReceiver` with the
/// `MEDIA_BUTTON` intent filter.
List<ConfigViolation> checkAndroidManifest(String path) {
  final out = <ConfigViolation>[];
  final document = _readXml(path, out);
  if (document == null) return out;
  const android = 'http://schemas.android.com/apk/res/android';
  String? attr(XmlElement e, String name) =>
      e.getAttribute(name, namespaceUri: android) ??
      e.getAttribute('android:$name');
  bool hasChild(XmlElement filter, String tag, String name, String value) =>
      filter.findElements(tag).any((e) => attr(e, name) == value);
  bool filtersAction(XmlElement component, String action) => component
      .findElements('intent-filter')
      .any((f) => hasChild(f, 'action', 'name', action));

  for (final permission in androidPermissions) {
    if (!document.rootElement
        .findElements('uses-permission')
        .any((e) => attr(e, 'name') == permission)) {
      out.add(
        ConfigViolation(path, '<uses-permission android:name="$permission"/>'),
      );
    }
  }
  const feature = 'android.hardware.camera';
  if (!document.rootElement
      .findElements('uses-feature')
      .any(
        (e) => attr(e, 'name') == feature && attr(e, 'required') == 'false',
      )) {
    out.add(
      ConfigViolation(
        path,
        '<uses-feature android:name="$feature" android:required="false"/>',
      ),
    );
  }

  final application = document.rootElement
      .findElements('application')
      .firstOrNull;
  for (final (name, value) in const [
    ('networkSecurityConfig', '@xml/network_security_config'),
    ('dataExtractionRules', '@xml/data_extraction_rules'),
    ('fullBackupContent', '@xml/backup_rules'),
  ]) {
    if (application == null || attr(application, name) != value) {
      out.add(ConfigViolation(path, 'android:$name="$value"'));
    }
  }
  if (application != null &&
      attr(application, 'usesCleartextTraffic') == 'false') {
    out.add(
      ConfigViolation(
        path,
        'cleartext traffic (android:usesCleartextTraffic="false" is set)',
      ),
    );
  }

  final service = document
      .findAllElements('service')
      .where((e) => attr(e, 'name') == audioServiceClass)
      .firstOrNull;
  if (service == null ||
      !_isMediaPlayback(attr(service, 'foregroundServiceType')) ||
      attr(service, 'exported') != 'true' ||
      !filtersAction(service, 'android.media.browse.MediaBrowserService')) {
    out.add(
      ConfigViolation(
        path,
        '<service android:name="$audioServiceClass" '
        'android:foregroundServiceType="mediaPlayback" '
        'android:exported="true"> with the '
        'android.media.browse.MediaBrowserService intent filter',
      ),
    );
  }
  final receiver = document
      .findAllElements('receiver')
      .where((e) => attr(e, 'name') == mediaButtonReceiverClass)
      .firstOrNull;
  if (receiver == null ||
      attr(receiver, 'exported') != 'true' ||
      !filtersAction(receiver, 'android.intent.action.MEDIA_BUTTON')) {
    out.add(
      ConfigViolation(
        path,
        '<receiver android:name="$mediaButtonReceiverClass" '
        'android:exported="true"> with the '
        'android.intent.action.MEDIA_BUTTON intent filter',
      ),
    );
  }

  final activity = document.findAllElements('activity').where((e) {
    final name = attr(e, 'name');
    return name == '.MainActivity' ||
        (name?.endsWith('.MainActivity') ?? false);
  }).firstOrNull;
  if (activity == null) {
    out.add(ConfigViolation(path, '<activity android:name=".MainActivity">'));
    return out;
  }
  // A compiled manifest carries the enum value: singleTask is 2.
  if (!const {'singleTask', '2'}.contains(attr(activity, 'launchMode'))) {
    out.add(
      ConfigViolation(path, 'MainActivity android:launchMode="singleTask"'),
    );
  }

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

/// Whether a `foregroundServiceType` value includes `mediaPlayback`: by
/// name in a source manifest, or as the flag 0x2 in a compiled one.
bool _isMediaPlayback(String? value) {
  if (value == null) return false;
  if (value.split('|').contains('mediaPlayback')) return true;
  final number = value.startsWith('0x')
      ? int.tryParse(value.substring(2), radix: 16)
      : int.tryParse(value);
  return number != null && number & 0x2 != 0;
}

/// What the backup rules exclude (doc 10, `android:dataExtractionRules`):
/// the profiles' tree and `app.db` under the app-support directory (the
/// `file` domain on Android), and the shared preferences of
/// `flutter_secure_storage`. The other databases live under `profiles/` or
/// in the cache directory, which is never backed up.
const List<(String, String)> backupExclusions = [
  ('file', 'profiles/'),
  ('file', 'app.db'),
  ('file', 'app.db-wal'),
  ('file', 'app.db-shm'),
  ('file', 'app.db-journal'),
  ('sharedpref', 'FlutterSecureStorage.xml'),
];

/// The resource files under the Android `res` directory [dir]:
/// `xml/network_security_config.xml` permits cleartext in its base config
/// and trusts the system and user certificate authorities;
/// `xml/data_extraction_rules.xml` (`<cloud-backup>` and
/// `<device-transfer>`) and `xml/backup_rules.xml` exclude every one of
/// [backupExclusions].
List<ConfigViolation> checkAndroidRes(String dir) {
  final out = <ConfigViolation>[];
  final security = '$dir/xml/network_security_config.xml';
  final config = _readXml(security, out);
  if (config != null) {
    final base = config.rootElement.findElements('base-config').firstOrNull;
    if (base?.getAttribute('cleartextTrafficPermitted') != 'true') {
      out.add(
        ConfigViolation(
          security,
          '<base-config cleartextTrafficPermitted="true">',
        ),
      );
    }
    final anchors = base?.findElements('trust-anchors').firstOrNull;
    for (final source in const ['system', 'user']) {
      if (anchors == null ||
          !anchors
              .findElements('certificates')
              .any((c) => c.getAttribute('src') == source)) {
        out.add(
          ConfigViolation(
            security,
            '<certificates src="$source"/> in the base-config trust anchors',
          ),
        );
      }
    }
  }

  void checkExcludes(String path, XmlElement? section, String tag) {
    if (section == null) {
      out.add(ConfigViolation(path, '<$tag>'));
      return;
    }
    for (final (domain, file) in backupExclusions) {
      if (!section
          .findElements('exclude')
          .any(
            (e) =>
                e.getAttribute('domain') == domain &&
                e.getAttribute('path') == file,
          )) {
        out.add(
          ConfigViolation(
            path,
            '<exclude domain="$domain" path="$file"/> in <$tag>',
          ),
        );
      }
    }
  }

  final extraction = '$dir/xml/data_extraction_rules.xml';
  final rules = _readXml(extraction, out);
  if (rules != null) {
    for (final tag in const ['cloud-backup', 'device-transfer']) {
      checkExcludes(
        extraction,
        rules.rootElement.findElements(tag).firstOrNull,
        tag,
      );
    }
  }
  final backup = '$dir/xml/backup_rules.xml';
  final full = _readXml(backup, out);
  if (full != null) {
    checkExcludes(
      backup,
      full.rootElement.name.local == 'full-backup-content'
          ? full.rootElement
          : null,
      'full-backup-content',
    );
  }
  return out;
}

/// `CFBundleURLTypes` with a `CFBundleURLSchemes` entry `soundspan`, and the
/// [cameraUsageDescription] (iOS and macOS `Info.plist`).
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
  final camera = top == null
      ? null
      : _plistValue(top, 'NSCameraUsageDescription');
  if (camera == null ||
      camera.name.local != 'string' ||
      camera.innerText.trim() != cameraUsageDescription) {
    out.add(
      ConfigViolation(
        path,
        'NSCameraUsageDescription "$cameraUsageDescription"',
      ),
    );
  }
  return out;
}

/// `<key>com.apple.security.device.camera</key><true/>` in a macOS
/// `.entitlements` file.
List<ConfigViolation> checkMacosEntitlements(String path) {
  final out = <ConfigViolation>[];
  final document = _readXml(path, out);
  if (document == null) return out;
  final top = document.rootElement.findElements('dict').firstOrNull;
  final value = top == null ? null : _plistValue(top, cameraEntitlement);
  if (value == null || value.name.local != 'true') {
    out.add(ConfigViolation(path, '<key>$cameraEntitlement</key><true/>'));
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
