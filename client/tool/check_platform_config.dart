// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Checks the platform configuration files for the entries the app needs
// (doc 10: the Android manifest table, Cleartext HTTP and backup rules, the
// Deep Links Summary, the camera entries of the QR scanner, and the iOS and
// macOS Info.plist, entitlements and privacy manifest tables) and exits
// non-zero listing every missing or unexpected one.
//
//   dart run tool/check_platform_config.dart [--android-manifest=<path>]
//       [--android-res=<dir>] [--ios-plist=<path>] [--macos-plist=<path>]
//       [--linux-desktop=<path>] [--macos-entitlements=<path>[,<path>…]]
//       [--macos-release-entitlements=<path>]
//       [--ios-privacy-manifest=<path>]
//
// Paths default to the source files under client/. Run from client/.
// --android-manifest also takes the merged manifest of a built APK
// (`apkanalyzer manifest print`). The plist files must be XML property
// lists; convert a built binary one first with `plutil -convert xml1`.

import 'dart:io';

import 'package:xml/xml.dart';

/// The URL scheme every native target registers.
const String urlScheme = 'soundspan';

/// The `NSCameraUsageDescription` of the iOS and macOS apps (doc 10).
const String cameraUsageDescription = 'Scan a soundspan link code.';

/// The `NSLocalNetworkUsageDescription` of the iOS and macOS apps (doc 10).
const String localNetworkUsageDescription =
    'Connect to a soundspan server on your network.';

/// The macOS entitlement that lets the QR scanner use the camera.
const String cameraEntitlement = 'com.apple.security.device.camera';

/// The entitlements every macOS build carries (doc 10, macOS).
const List<String> macosEntitlements = [
  'com.apple.security.app-sandbox',
  'com.apple.security.network.client',
  'com.apple.security.network.server',
  cameraEntitlement,
];

/// The entitlement the release build adds for secure storage; its value is
/// an array of access groups.
const String keychainEntitlement = 'keychain-access-groups';

/// The lowest macOS release the app supports (doc 10, macOS).
const String macosMinimumVersion = '12.0';

/// The required-reason API categories of the iOS privacy manifest and the
/// reason codes the bundled plugins need (doc 10, App Store notes): file
/// timestamps of files inside the app container, the app's own user
/// defaults, and free disk space checked before downloads and shown in the
/// storage settings.
const Map<String, List<String>> privacyAccessedApiReasons = {
  'NSPrivacyAccessedAPICategoryFileTimestamp': ['C617.1'],
  'NSPrivacyAccessedAPICategoryUserDefaults': ['CA92.1'],
  'NSPrivacyAccessedAPICategoryDiskSpace': ['E174.1', '85F4.1'],
};

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
  'macos-release-entitlements': 'macos/Runner/Release.entitlements',
  'ios-privacy-manifest': 'ios/Runner/PrivacyInfo.xcprivacy',
};

/// One entry a configuration file lacks, or carries but must not.
class ConfigViolation {
  /// Creates a violation of [entry] in the file at [path]; [unexpected]
  /// when the file has an entry it must not have.
  const new(this.path, this.entry, {this.unexpected = false});

  /// The file checked.
  final String path;

  /// What is missing or unexpected.
  final String entry;

  /// Whether [entry] is present but must not be.
  final bool unexpected;

  @override
  String toString() => '$path: ${unexpected ? 'unexpected' : 'missing'} $entry';
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
    ...checkIosPlist(path('ios-plist')),
    ...checkMacosPlist(path('macos-plist')),
    ...checkLinuxDesktop(path('linux-desktop')),
    for (final entitlements in path('macos-entitlements').split(','))
      if (entitlements.trim().isNotEmpty)
        ...checkMacosEntitlements(entitlements.trim()),
    ...checkMacosEntitlements(
      path('macos-release-entitlements'),
      release: true,
    ),
    ...checkIosPrivacyManifest(path('ios-privacy-manifest')),
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
/// included.
const List<String> androidPermissions = [
  'android.permission.INTERNET',
  'android.permission.ACCESS_NETWORK_STATE',
  'android.permission.FOREGROUND_SERVICE',
  'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
  'android.permission.FOREGROUND_SERVICE_DATA_SYNC',
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.WAKE_LOCK',
  'android.permission.CAMERA',
];

/// The `audio_service` playback service.
const String audioServiceClass = 'com.ryanheise.audioservice.AudioService';

/// The `<meta-data>` name that lists the app in Android Auto.
const String carApplicationMetaData = 'com.google.android.gms.car.application';

/// The `FileProvider` that serves pinned covers to Android Auto.
const String fileProviderClass = 'androidx.core.content.FileProvider';

/// The `audio_service` media-button receiver.
const String mediaButtonReceiverClass =
    'com.ryanheise.audioservice.MediaButtonReceiver';

/// The doc 10 manifest table: [androidPermissions], the optional camera
/// feature of the QR scanner, the `<application>` network security config
/// and backup rules, cleartext traffic not switched off, `MainActivity` with
/// `launchMode="singleTask"` and the URL-scheme intent filter (action
/// `VIEW`, categories `DEFAULT` and `BROWSABLE`,
/// `<data android:scheme="soundspan"/>`), the exported `AudioService` with
/// `foregroundServiceType="mediaPlayback"` and the `MediaBrowserService`
/// intent filter, the exported `MediaButtonReceiver` with the
/// `MEDIA_BUTTON` intent filter, the Android Auto `<meta-data>` naming
/// `@xml/automotive_app_desc`, and the artwork `FileProvider` (authority
/// `<applicationId>.artwork`, not exported, granting URI permissions, with
/// `@xml/artwork_paths`).
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

  if (application == null ||
      !application
          .findElements('meta-data')
          .any(
            (e) =>
                attr(e, 'name') == carApplicationMetaData &&
                attr(e, 'resource') == '@xml/automotive_app_desc',
          )) {
    out.add(
      ConfigViolation(
        path,
        '<meta-data android:name="$carApplicationMetaData" '
        'android:resource="@xml/automotive_app_desc"/>',
      ),
    );
  }

  final provider = document
      .findAllElements('provider')
      .where((e) => attr(e, 'name') == fileProviderClass)
      .firstOrNull;
  final authority = provider == null ? null : attr(provider, 'authorities');
  if (provider == null ||
      authority == null ||
      !(authority == r'${applicationId}.artwork' ||
          RegExp(r'^[A-Za-z0-9_.]+\.artwork$').hasMatch(authority)) ||
      attr(provider, 'exported') != 'false' ||
      attr(provider, 'grantUriPermissions') != 'true' ||
      !provider
          .findElements('meta-data')
          .any(
            (e) =>
                attr(e, 'name') == 'android.support.FILE_PROVIDER_PATHS' &&
                attr(e, 'resource') == '@xml/artwork_paths',
          )) {
    out.add(
      ConfigViolation(
        path,
        '<provider android:name="$fileProviderClass" '
        r'android:authorities="${applicationId}.artwork" '
        'android:exported="false" android:grantUriPermissions="true"> '
        'with @xml/artwork_paths',
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
/// [backupExclusions]; `xml/automotive_app_desc.xml` declares
/// `<uses name="media"/>` for Android Auto.
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
  final automotive = '$dir/xml/automotive_app_desc.xml';
  final app = _readXml(automotive, out);
  if (app != null &&
      (app.rootElement.name.local != 'automotiveApp' ||
          !app.rootElement
              .findElements('uses')
              .any((e) => e.getAttribute('name') == 'media'))) {
    out.add(
      ConfigViolation(automotive, '<uses name="media"/> in <automotiveApp>'),
    );
  }
  return out;
}

/// The top-level `<dict>` of the property list at [path], or `null` after
/// adding the violation to [out].
XmlElement? _readPlistDict(String path, List<ConfigViolation> out) {
  final document = _readXml(path, out);
  if (document == null) return null;
  final top = document.rootElement.findElements('dict').firstOrNull;
  if (top == null) out.add(ConfigViolation(path, 'a top-level <dict>'));
  return top;
}

bool _isTrue(XmlElement? value) => value?.name.local == 'true';

bool _isFalse(XmlElement? value) => value?.name.local == 'false';

bool _isString(XmlElement? value, String expected) =>
    value?.name.local == 'string' && value!.innerText.trim() == expected;

List<String>? _stringArray(XmlElement? value) => value?.name.local != 'array'
    ? null
    : [for (final e in value!.childElements) e.innerText.trim()];

/// The entries the iOS and macOS `Info.plist` share: `CFBundleURLTypes`
/// with a `CFBundleURLSchemes` entry `soundspan`, the camera and local
/// network usage descriptions, and `NSAppTransportSecurity` allowing local
/// networking and no arbitrary loads.
List<ConfigViolation> checkPlist(String path) {
  final out = <ConfigViolation>[];
  final top = _readPlistDict(path, out);
  if (top != null) _checkSharedPlist(path, top, out);
  return out;
}

void _checkSharedPlist(String path, XmlElement top, List<ConfigViolation> out) {
  final types = _plistValue(top, 'CFBundleURLTypes');
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
  if (!_isString(
    _plistValue(top, 'NSCameraUsageDescription'),
    cameraUsageDescription,
  )) {
    out.add(
      ConfigViolation(
        path,
        'NSCameraUsageDescription "$cameraUsageDescription"',
      ),
    );
  }
  if (!_isString(
    _plistValue(top, 'NSLocalNetworkUsageDescription'),
    localNetworkUsageDescription,
  )) {
    out.add(
      ConfigViolation(
        path,
        'NSLocalNetworkUsageDescription "$localNetworkUsageDescription"',
      ),
    );
  }
  final ats = _plistValue(top, 'NSAppTransportSecurity');
  if (ats?.name.local != 'dict' ||
      !_isTrue(_plistValue(ats!, 'NSAllowsLocalNetworking'))) {
    out.add(
      ConfigViolation(
        path,
        'NSAppTransportSecurity with NSAllowsLocalNetworking true',
      ),
    );
  }
  if (ats != null && ats.name.local == 'dict') {
    for (final key in ats.findElements('key')) {
      final name = key.innerText.trim();
      if (name.startsWith('NSAllowsArbitraryLoads')) {
        out.add(
          ConfigViolation(
            path,
            '$name in NSAppTransportSecurity',
            unexpected: true,
          ),
        );
      }
      if (name == 'NSExceptionDomains') {
        out.add(
          ConfigViolation(
            path,
            'NSExceptionDomains in NSAppTransportSecurity',
            unexpected: true,
          ),
        );
      }
    }
  }
}

/// The iOS `Info.plist` (doc 10, iOS): the shared entries of [checkPlist],
/// `UIBackgroundModes` of `audio` only, `ITSAppUsesNonExemptEncryption`
/// false, `UIApplicationSupportsIndirectInputEvents` true,
/// `UISupportsDocumentBrowser` false and no `LSApplicationQueriesSchemes`.
List<ConfigViolation> checkIosPlist(String path) {
  final out = <ConfigViolation>[];
  final top = _readPlistDict(path, out);
  if (top == null) return out;
  _checkSharedPlist(path, top, out);
  final modes = _stringArray(_plistValue(top, 'UIBackgroundModes'));
  if (modes == null || !modes.contains('audio')) {
    out.add(ConfigViolation(path, 'UIBackgroundModes [audio]'));
  }
  for (final mode in modes ?? const <String>[]) {
    if (mode != 'audio') {
      out.add(
        ConfigViolation(path, 'UIBackgroundModes $mode', unexpected: true),
      );
    }
  }
  if (!_isFalse(_plistValue(top, 'ITSAppUsesNonExemptEncryption'))) {
    out.add(ConfigViolation(path, 'ITSAppUsesNonExemptEncryption false'));
  }
  if (!_isTrue(_plistValue(top, 'UIApplicationSupportsIndirectInputEvents'))) {
    out.add(
      ConfigViolation(path, 'UIApplicationSupportsIndirectInputEvents true'),
    );
  }
  if (!_isFalse(_plistValue(top, 'UISupportsDocumentBrowser'))) {
    out.add(ConfigViolation(path, 'UISupportsDocumentBrowser false'));
  }
  if (_plistValue(top, 'LSApplicationQueriesSchemes') != null) {
    out.add(
      ConfigViolation(path, 'LSApplicationQueriesSchemes', unexpected: true),
    );
  }
  return out;
}

/// The macOS `Info.plist` (doc 10, macOS): the shared entries of
/// [checkPlist], `LSMinimumSystemVersion` of [macosMinimumVersion] (or the
/// build setting that expands to it in the source file) and
/// `LSApplicationCategoryType` `public.app-category.music`.
List<ConfigViolation> checkMacosPlist(String path) {
  final out = <ConfigViolation>[];
  final top = _readPlistDict(path, out);
  if (top == null) return out;
  _checkSharedPlist(path, top, out);
  final minimum = _plistValue(top, 'LSMinimumSystemVersion');
  if (!_isString(minimum, macosMinimumVersion) &&
      !_isString(minimum, r'$(MACOSX_DEPLOYMENT_TARGET)')) {
    out.add(
      ConfigViolation(path, 'LSMinimumSystemVersion $macosMinimumVersion'),
    );
  }
  if (!_isString(
    _plistValue(top, 'LSApplicationCategoryType'),
    'public.app-category.music',
  )) {
    out.add(
      ConfigViolation(
        path,
        'LSApplicationCategoryType public.app-category.music',
      ),
    );
  }
  return out;
}

/// The [macosEntitlements] set to true in a macOS `.entitlements` file
/// (or the output of `codesign -d --entitlements - --xml`); with
/// [release], also a non-empty [keychainEntitlement] array.
List<ConfigViolation> checkMacosEntitlements(
  String path, {
  bool release = false,
}) {
  final out = <ConfigViolation>[];
  final top = _readPlistDict(path, out);
  if (top == null) return out;
  for (final entitlement in macosEntitlements) {
    if (!_isTrue(_plistValue(top, entitlement))) {
      out.add(ConfigViolation(path, '<key>$entitlement</key><true/>'));
    }
  }
  if (release) {
    final groups = _stringArray(_plistValue(top, keychainEntitlement));
    if (groups == null || groups.isEmpty || groups.any((g) => g.isEmpty)) {
      out.add(ConfigViolation(path, '$keychainEntitlement with a group'));
    }
  }
  return out;
}

/// The iOS privacy manifest `PrivacyInfo.xcprivacy` (doc 10, App Store
/// notes): no tracking, no tracking domains, no collected data types, and
/// exactly the [privacyAccessedApiReasons].
List<ConfigViolation> checkIosPrivacyManifest(String path) {
  final out = <ConfigViolation>[];
  final top = _readPlistDict(path, out);
  if (top == null) return out;
  if (!_isFalse(_plistValue(top, 'NSPrivacyTracking'))) {
    out.add(ConfigViolation(path, 'NSPrivacyTracking false'));
  }
  for (final key in const [
    'NSPrivacyTrackingDomains',
    'NSPrivacyCollectedDataTypes',
  ]) {
    final value = _plistValue(top, key);
    if (value?.name.local != 'array' || value!.childElements.isNotEmpty) {
      out.add(ConfigViolation(path, '$key as an empty array'));
    }
  }
  final types = _plistValue(top, 'NSPrivacyAccessedAPITypes');
  final declared = <String, List<String>>{};
  if (types?.name.local == 'array') {
    for (final entry in types!.findElements('dict')) {
      final category = _plistValue(entry, 'NSPrivacyAccessedAPIType');
      final reasons = _stringArray(
        _plistValue(entry, 'NSPrivacyAccessedAPITypeReasons'),
      );
      if (category != null) {
        declared[category.innerText.trim()] = reasons ?? const [];
      }
    }
  }
  for (final MapEntry(key: category, value: reasons)
      in privacyAccessedApiReasons.entries) {
    final found = declared[category];
    if (found == null ||
        found.length != reasons.length ||
        !reasons.every(found.contains)) {
      out.add(
        ConfigViolation(
          path,
          'NSPrivacyAccessedAPITypes $category with reasons '
          '${reasons.join(', ')}',
        ),
      );
    }
  }
  for (final category in declared.keys) {
    if (!privacyAccessedApiReasons.containsKey(category)) {
      out.add(
        ConfigViolation(
          path,
          'NSPrivacyAccessedAPITypes $category',
          unexpected: true,
        ),
      );
    }
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
      'check_platform_config: ${violations.length} missing or unexpected '
      '${violations.length == 1 ? 'entry' : 'entries'}',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('check_platform_config: all entries present');
}
