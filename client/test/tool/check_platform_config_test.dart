// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/check_platform_config.dart';

const _manifest = r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.WAKE_LOCK"/>
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-feature android:name="android.hardware.camera" android:required="false"/>
  <application
      android:networkSecurityConfig="@xml/network_security_config"
      android:dataExtractionRules="@xml/data_extraction_rules"
      android:fullBackupContent="@xml/backup_rules">
    <activity android:name=".MainActivity" android:exported="true"
        android:launchMode="singleTask">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
      <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="soundspan"/>
      </intent-filter>
    </activity>
    <service android:name="com.ryanheise.audioservice.AudioService"
        android:foregroundServiceType="mediaPlayback"
        android:exported="true">
      <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService"/>
      </intent-filter>
    </service>
    <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
        android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON"/>
      </intent-filter>
    </receiver>
    <meta-data android:name="com.google.android.gms.car.application"
        android:resource="@xml/automotive_app_desc"/>
    <provider android:name="androidx.core.content.FileProvider"
        android:authorities="${applicationId}.artwork"
        android:exported="false"
        android:grantUriPermissions="true">
      <meta-data android:name="android.support.FILE_PROVIDER_PATHS"
          android:resource="@xml/artwork_paths"/>
    </provider>
  </application>
</manifest>
''';

/// Each manifest row of doc 10 checked, as (text removed or replaced from
/// [_manifest], its replacement, the entry the violation names).
const List<(String, String, String)> _manifestRows = [
  (
    '<uses-permission android:name="android.permission.INTERNET"/>',
    '',
    '<uses-permission android:name="android.permission.INTERNET"/>',
  ),
  (
    '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>',
    '',
    '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>',
  ),
  (
    '<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>',
    '',
    '<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>',
  ),
  (
    '<uses-permission '
        'android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>',
    '',
    '<uses-permission '
        'android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>',
  ),
  (
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
    '',
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
  ),
  (
    '<uses-permission android:name="android.permission.WAKE_LOCK"/>',
    '',
    '<uses-permission android:name="android.permission.WAKE_LOCK"/>',
  ),
  (
    'android:launchMode="singleTask"',
    'android:launchMode="standard"',
    'MainActivity android:launchMode="singleTask"',
  ),
  (
    'android:foregroundServiceType="mediaPlayback"',
    '',
    '<service android:name="com.ryanheise.audioservice.AudioService" '
        'android:foregroundServiceType="mediaPlayback" '
        'android:exported="true"> with the '
        'android.media.browse.MediaBrowserService intent filter',
  ),
  (
    '<action android:name="android.media.browse.MediaBrowserService"/>',
    '',
    '<service android:name="com.ryanheise.audioservice.AudioService" '
        'android:foregroundServiceType="mediaPlayback" '
        'android:exported="true"> with the '
        'android.media.browse.MediaBrowserService intent filter',
  ),
  (
    '<action android:name="android.intent.action.MEDIA_BUTTON"/>',
    '',
    '<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" '
        'android:exported="true"> with the '
        'android.intent.action.MEDIA_BUTTON intent filter',
  ),
  (
    'android:networkSecurityConfig="@xml/network_security_config"',
    '',
    'android:networkSecurityConfig="@xml/network_security_config"',
  ),
  (
    'android:dataExtractionRules="@xml/data_extraction_rules"',
    '',
    'android:dataExtractionRules="@xml/data_extraction_rules"',
  ),
  (
    'android:fullBackupContent="@xml/backup_rules"',
    '',
    'android:fullBackupContent="@xml/backup_rules"',
  ),
  (
    'android:resource="@xml/automotive_app_desc"',
    'android:resource="@xml/other"',
    '<meta-data android:name="com.google.android.gms.car.application" '
        'android:resource="@xml/automotive_app_desc"/>',
  ),
  (
    'android:name="com.google.android.gms.car.application"',
    'android:name="other"',
    '<meta-data android:name="com.google.android.gms.car.application" '
        'android:resource="@xml/automotive_app_desc"/>',
  ),
  ('android:exported="false"', 'android:exported="true"', _artworkProvider),
  ('android:grantUriPermissions="true"', '', _artworkProvider),
  (r'${applicationId}.artwork', r'${applicationId}.files', _artworkProvider),
  ('@xml/artwork_paths', '@xml/other_paths', _artworkProvider),
  ('androidx.core.content.FileProvider', 'other.Provider', _artworkProvider),
];

const String _artworkProvider =
    '<provider android:name="androidx.core.content.FileProvider" '
    r'android:authorities="${applicationId}.artwork" '
    'android:exported="false" android:grantUriPermissions="true"> '
    'with @xml/artwork_paths';

const _automotiveAppDesc = '''
<automotiveApp>
  <uses name="media"/>
</automotiveApp>
''';

const _networkSecurityConfig = '''
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config cleartextTrafficPermitted="true">
    <trust-anchors>
      <certificates src="system"/>
      <certificates src="user"/>
    </trust-anchors>
  </base-config>
</network-security-config>
''';

const _excludes = '''
    <exclude domain="file" path="profiles/"/>
    <exclude domain="file" path="app.db"/>
    <exclude domain="file" path="app.db-wal"/>
    <exclude domain="file" path="app.db-shm"/>
    <exclude domain="file" path="app.db-journal"/>
    <exclude domain="sharedpref" path="FlutterSecureStorage.xml"/>
''';

const _dataExtractionRules =
    '''
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
  <cloud-backup>
$_excludes  </cloud-backup>
  <device-transfer>
$_excludes  </device-transfer>
</data-extraction-rules>
''';

const _backupRules =
    '''
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
$_excludes</full-backup-content>
''';

/// The entries the iOS and macOS Info.plist share.
const _sharedPlist = '''
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key>
      <string>io.soundspan.app</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>soundspan</string>
      </array>
    </dict>
  </array>
  <key>CFBundleExecutable</key>
  <string>soundspan</string>
  <key>NSCameraUsageDescription</key>
  <string>Scan a soundspan link code.</string>
  <key>NSLocalNetworkUsageDescription</key>
  <string>Connect to a soundspan server on your network.</string>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
  </dict>
''';

const _iosPlist =
    '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
$_sharedPlist
  <key>UIBackgroundModes</key>
  <array>
    <string>audio</string>
  </array>
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  <key>UIApplicationSupportsIndirectInputEvents</key>
  <true/>
  <key>UISupportsDocumentBrowser</key>
  <false/>
</dict>
</plist>
''';

const _macosPlist =
    '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
$_sharedPlist
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.music</string>
</dict>
</plist>
''';

const _entitlements = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>com.apple.security.app-sandbox</key>
  <true/>
  <key>com.apple.security.device.camera</key>
  <true/>
  <key>com.apple.security.network.client</key>
  <true/>
  <key>com.apple.security.network.server</key>
  <true/>
  <key>keychain-access-groups</key>
  <array>
    <string>ABCDE12345.io.soundspan.app</string>
  </array>
</dict>
</plist>
''';

const _privacy = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyTrackingDomains</key>
  <array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>C617.1</string>
      </array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>CA92.1</string>
      </array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>E174.1</string>
        <string>85F4.1</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
''';

const _desktop = '''
[Desktop Entry]
Type=Application
Name=soundspan
Exec=soundspan %u
Icon=io.soundspan.app
StartupWMClass=io.soundspan.app
MimeType=x-scheme-handler/soundspan;
''';

const _cameraPermission =
    '<uses-permission android:name="android.permission.CAMERA"/>';

const _requiredFeature =
    '<uses-feature android:name="android.hardware.camera" '
    'android:required="true"/>';

const _cameraDescription =
    'NSCameraUsageDescription "Scan a soundspan link code."';

const _missingLocalNetwork =
    'missing NSLocalNetworkUsageDescription '
    '"Connect to a soundspan server on your network."';

const _missingUserDefaults =
    'missing NSPrivacyAccessedAPITypes '
    'NSPrivacyAccessedAPICategoryUserDefaults with reasons CA92.1';

const _unexpectedBootTime =
    'unexpected NSPrivacyAccessedAPITypes '
    'NSPrivacyAccessedAPICategorySystemBootTime';

const _missingFileTimestamp =
    'missing NSPrivacyAccessedAPITypes '
    'NSPrivacyAccessedAPICategoryFileTimestamp with reasons C617.1';

late Directory _dir;

String _write(String name, String content) {
  final path = p.join(_dir.path, name);
  File(path).parent.createSync(recursive: true);
  File(path).writeAsStringSync(content);
  return path;
}

/// A resource directory with the four XML files, each overridable.
String _res({
  String networkSecurityConfig = _networkSecurityConfig,
  String dataExtractionRules = _dataExtractionRules,
  String backupRules = _backupRules,
  String automotiveAppDesc = _automotiveAppDesc,
}) {
  _write('res/xml/network_security_config.xml', networkSecurityConfig);
  _write('res/xml/data_extraction_rules.xml', dataExtractionRules);
  _write('res/xml/backup_rules.xml', backupRules);
  _write('res/xml/automotive_app_desc.xml', automotiveAppDesc);
  return p.join(_dir.path, 'res');
}

void main() {
  setUp(() => _dir = Directory.systemTemp.createTempSync('platform_config'));
  tearDown(() => _dir.deleteSync(recursive: true));

  group('Android manifest', () {
    test('passes with the soundspan intent filter', () {
      expect(checkAndroidManifest(_write('m.xml', _manifest)), isEmpty);
    });

    test('a merged manifest with fully qualified names passes', () {
      expect(
        checkAndroidManifest(
          _write(
            'm.xml',
            _manifest.replaceFirst(
              'android:name=".MainActivity"',
              'android:name="io.soundspan.app.MainActivity"',
            ),
          ),
        ),
        isEmpty,
      );
    });

    for (final (from, to, entry) in _manifestRows) {
      test('fails naming $entry when it is missing', () {
        expect(_manifest, contains(from));
        final path = _write('m.xml', _manifest.replaceFirst(from, to));
        expect(checkAndroidManifest(path).map((v) => v.toString()), [
          '$path: missing $entry',
        ]);
      });
    }

    test('a merged manifest with the application id resolved passes', () {
      final merged = _manifest.replaceFirst(
        r'${applicationId}.artwork',
        'io.soundspan.app.artwork',
      );
      expect(checkAndroidManifest(_write('m.xml', merged)), isEmpty);
    });

    test('a compiled manifest with numeric launch mode and service type '
        'passes', () {
      final compiled = _manifest
          .replaceFirst(
            'android:launchMode="singleTask"',
            'android:launchMode="2"',
          )
          .replaceFirst(
            'android:foregroundServiceType="mediaPlayback"',
            'android:foregroundServiceType="0x2"',
          );
      expect(checkAndroidManifest(_write('m.xml', compiled)), isEmpty);
    });

    test('a numeric launch mode other than singleTask fails', () {
      final path = _write(
        'm.xml',
        _manifest.replaceFirst(
          'android:launchMode="singleTask"',
          'android:launchMode="1"',
        ),
      );
      expect(
        checkAndroidManifest(path).single.entry,
        'MainActivity android:launchMode="singleTask"',
      );
    });

    test('fails when cleartext traffic is switched off', () {
      final path = _write(
        'm.xml',
        _manifest.replaceFirst(
          '<application',
          '<application android:usesCleartextTraffic="false"',
        ),
      );
      expect(checkAndroidManifest(path).single.entry, contains('cleartext'));
    });

    test('fails naming the file and entry without the scheme', () {
      final path = _write(
        'm.xml',
        _manifest.replaceFirst('<data android:scheme="soundspan"/>', ''),
      );
      final violations = checkAndroidManifest(path);
      const entry =
          'MainActivity <intent-filter> with <data android:scheme="soundspan"/>';
      expect(violations.map((v) => v.toString()), ['$path: missing $entry']);
    });

    test('fails naming BROWSABLE when it is missing', () {
      final path = _write(
        'm.xml',
        _manifest.replaceFirst(
          '<category android:name="android.intent.category.BROWSABLE"/>',
          '',
        ),
      );
      expect(checkAndroidManifest(path).single.entry, contains('BROWSABLE'));
    });

    test('fails naming the CAMERA permission when it is missing', () {
      final path = _write(
        'm.xml',
        _manifest.replaceFirst(
          '<uses-permission android:name="android.permission.CAMERA"/>',
          '',
        ),
      );
      expect(checkAndroidManifest(path).map((v) => v.toString()), [
        '$path: missing $_cameraPermission',
      ]);
    });

    test('fails when the camera feature is missing or required', () {
      const feature =
          '<uses-feature android:name="android.hardware.camera" '
          'android:required="false"/>';
      for (final replacement in [
        '',
        '<uses-feature android:name="android.hardware.camera"/>',
        _requiredFeature,
      ]) {
        final path = _write(
          'm.xml',
          _manifest.replaceFirst(feature, replacement),
        );
        expect(checkAndroidManifest(path).map((v) => v.toString()), [
          '$path: missing $feature',
        ], reason: replacement);
      }
    });
  });

  group('Android resources', () {
    test('pass with cleartext, user CAs and every backup exclusion', () {
      expect(checkAndroidRes(_res()), isEmpty);
    });

    test('fail without cleartext or the user trust anchor', () {
      for (final (from, to, entry) in const [
        (
          'cleartextTrafficPermitted="true"',
          'cleartextTrafficPermitted="false"',
          '<base-config cleartextTrafficPermitted="true">',
        ),
        (
          '<certificates src="user"/>',
          '',
          '<certificates src="user"/> in the base-config trust anchors',
        ),
        (
          '<certificates src="system"/>',
          '',
          '<certificates src="system"/> in the base-config trust anchors',
        ),
      ]) {
        final res = _res(
          networkSecurityConfig: _networkSecurityConfig.replaceFirst(from, to),
        );
        final violations = checkAndroidRes(res);
        expect(violations.map((v) => v.entry), [entry], reason: from);
        expect(
          p.basename(violations.single.path),
          'network_security_config.xml',
        );
      }
    });

    const exclusions = [
      ('file', 'profiles/'),
      ('file', 'app.db'),
      ('file', 'app.db-wal'),
      ('file', 'app.db-shm'),
      ('file', 'app.db-journal'),
      ('sharedpref', 'FlutterSecureStorage.xml'),
    ];

    for (final (domain, path) in exclusions) {
      final line = '    <exclude domain="$domain" path="$path"/>\n';
      final entry = '<exclude domain="$domain" path="$path"/>';

      test('backup rules without $path fail naming it', () {
        final res = _res(backupRules: _backupRules.replaceFirst(line, ''));
        final file = p.join(res, 'xml', 'backup_rules.xml');
        expect(checkAndroidRes(res).map((v) => v.toString()), [
          '$file: missing $entry in <full-backup-content>',
        ]);
      });

      test('data extraction rules without $path in device transfer fail '
          'naming it', () {
        final at = _dataExtractionRules.indexOf('<device-transfer>');
        final dataExtractionRules = _dataExtractionRules.replaceFirst(
          line,
          '',
          at,
        );
        expect(dataExtractionRules, isNot(_dataExtractionRules));
        final res = _res(dataExtractionRules: dataExtractionRules);
        expect(checkAndroidRes(res).map((v) => v.entry), [
          '$entry in <device-transfer>',
        ]);
      });
    }

    test('data extraction rules without cloud backup fail', () {
      final res = _res(
        dataExtractionRules: _dataExtractionRules.replaceAll(
          'cloud-backup',
          'x-backup',
        ),
      );
      expect(checkAndroidRes(res).map((v) => v.entry), ['<cloud-backup>']);
    });

    test('an Android Auto descriptor without the media use fails', () {
      final res = _res(
        automotiveAppDesc: _automotiveAppDesc.replaceFirst('media', 'video'),
      );
      final path = p.join(res, 'xml', 'automotive_app_desc.xml');
      expect(checkAndroidRes(res).map((v) => v.toString()), [
        '$path: missing <uses name="media"/> in <automotiveApp>',
      ]);
    });

    test('a missing Android Auto descriptor is reported', () {
      final res = _res();
      File(p.join(res, 'xml', 'automotive_app_desc.xml')).deleteSync();
      expect(checkAndroidRes(res).single.entry, 'the file');
    });

    test('a missing resource file is reported', () {
      final res = _res();
      File(p.join(res, 'xml', 'backup_rules.xml')).deleteSync();
      expect(checkAndroidRes(res).single.entry, 'the file');
    });
  });

  for (final (target, plist, check) in [
    ('iOS', _iosPlist, checkIosPlist),
    ('macOS', _macosPlist, checkMacosPlist),
  ]) {
    group('$target Info.plist', () {
      List<String> violations(String content) {
        final path = _write('Info.plist', content);
        return [
          for (final v in check(path)) v.toString().replaceFirst('$path: ', ''),
        ];
      }

      test('the complete fixture passes', () {
        expect(violations(plist), isEmpty);
        expect(checkPlist(_write('Info.plist', plist)), isEmpty);
      });

      test('fails naming the file and entry without the scheme', () {
        final path = _write(
          'Info.plist',
          plist.replaceFirst('<string>soundspan</string>', ''),
        );
        expect(check(path).map((v) => v.toString()), [
          '$path: missing CFBundleURLTypes with CFBundleURLSchemes soundspan',
        ]);
      });

      test('fails without the camera usage description', () {
        for (final replacement in [
          '',
          '<key>NSCameraUsageDescription</key>\n  <string></string>',
        ]) {
          expect(
            violations(
              plist.replaceFirst(
                '<key>NSCameraUsageDescription</key>\n'
                '  <string>Scan a soundspan link code.</string>',
                replacement,
              ),
            ),
            ['missing $_cameraDescription'],
            reason: replacement,
          );
        }
      });

      test('fails without the local network usage description', () {
        expect(
          violations(
            plist.replaceFirst(
              '<string>Connect to a soundspan server on your network.</string>',
              '<string>Local network</string>',
            ),
          ),
          [_missingLocalNetwork],
        );
      });

      test('fails without local networking in ATS', () {
        expect(
          violations(
            plist.replaceFirst(
              '<key>NSAllowsLocalNetworking</key>\n    <true/>',
              '<key>NSAllowsLocalNetworking</key>\n    <false/>',
            ),
          ),
          ['missing NSAppTransportSecurity with NSAllowsLocalNetworking true'],
        );
      });

      test('fails with NSAllowsArbitraryLoads', () {
        expect(
          violations(
            plist.replaceFirst(
              '<key>NSAllowsLocalNetworking</key>',
              '<key>NSAllowsArbitraryLoads</key>\n    <true/>\n'
                  '    <key>NSAllowsLocalNetworking</key>',
            ),
          ),
          ['unexpected NSAllowsArbitraryLoads in NSAppTransportSecurity'],
        );
      });
    });
  }

  group('iOS-only Info.plist keys', () {
    List<String> violations(String content) {
      final path = _write('Info.plist', content);
      return [
        for (final v in checkIosPlist(path))
          v.toString().replaceFirst('$path: ', ''),
      ];
    }

    test('fails with a background mode other than audio', () {
      expect(
        violations(
          _iosPlist.replaceFirst(
            '<string>audio</string>',
            '<string>audio</string>\n    <string>fetch</string>',
          ),
        ),
        ['unexpected UIBackgroundModes fetch'],
      );
    });

    test('fails without the audio background mode', () {
      expect(
        violations(
          _iosPlist.replaceFirst(
            '<string>audio</string>',
            '<string>processing</string>',
          ),
        ),
        [
          'missing UIBackgroundModes [audio]',
          'unexpected UIBackgroundModes processing',
        ],
      );
    });

    for (final (key, from, to) in [
      ('ITSAppUsesNonExemptEncryption false', '<false/>', '<true/>'),
      (
        'UIApplicationSupportsIndirectInputEvents true',
        '<key>UIApplicationSupportsIndirectInputEvents</key>\n  <true/>',
        '',
      ),
      (
        'UISupportsDocumentBrowser false',
        '<key>UISupportsDocumentBrowser</key>\n  <false/>',
        '<key>UISupportsDocumentBrowser</key>\n  <true/>',
      ),
    ]) {
      test('fails naming $key', () {
        expect(violations(_iosPlist.replaceFirst(from, to)), ['missing $key']);
      });
    }

    test('fails with LSApplicationQueriesSchemes', () {
      expect(
        violations(
          _iosPlist.replaceFirst(
            '</dict>\n</plist>',
            '  <key>LSApplicationQueriesSchemes</key>\n  <array/>\n'
                '</dict>\n</plist>',
          ),
        ),
        ['unexpected LSApplicationQueriesSchemes'],
      );
    });
  });

  group('macOS-only Info.plist keys', () {
    List<String> violations(String content) {
      final path = _write('Info.plist', content);
      return [
        for (final v in checkMacosPlist(path))
          v.toString().replaceFirst('$path: ', ''),
      ];
    }

    test('accepts the deployment-target build setting', () {
      expect(
        violations(
          _macosPlist.replaceFirst(
            '<string>12.0</string>',
            r'<string>$(MACOSX_DEPLOYMENT_TARGET)</string>',
          ),
        ),
        isEmpty,
      );
    });

    test('fails with another minimum system version', () {
      expect(
        violations(
          _macosPlist.replaceFirst(
            '<string>12.0</string>',
            '<string>10.15</string>',
          ),
        ),
        ['missing LSMinimumSystemVersion 12.0'],
      );
    });

    test('fails without the music category', () {
      expect(
        violations(
          _macosPlist.replaceFirst(
            'public.app-category.music',
            'public.app-category.utilities',
          ),
        ),
        ['missing LSApplicationCategoryType public.app-category.music'],
      );
    });
  });

  group('macOS entitlements', () {
    test('pass with every entitlement', () {
      final path = _write('a.entitlements', _entitlements);
      expect(checkMacosEntitlements(path), isEmpty);
      expect(checkMacosEntitlements(path, release: true), isEmpty);
    });

    for (final entitlement in [
      'com.apple.security.app-sandbox',
      'com.apple.security.network.client',
      'com.apple.security.network.server',
      'com.apple.security.device.camera',
    ]) {
      test('fail without $entitlement or with it false', () {
        for (final replacement in ['', '<key>$entitlement</key>\n  <false/>']) {
          final path = _write(
            'a.entitlements',
            _entitlements.replaceFirst(
              '<key>$entitlement</key>\n  <true/>',
              replacement,
            ),
          );
          expect(checkMacosEntitlements(path).map((v) => v.toString()), [
            '$path: missing <key>$entitlement</key><true/>',
          ], reason: replacement);
        }
      });
    }

    test('release fails without a keychain access group', () {
      for (final replacement in [
        '',
        '<key>keychain-access-groups</key>\n  <array/>',
      ]) {
        final path = _write(
          'a.entitlements',
          _entitlements.replaceFirst(
            '<key>keychain-access-groups</key>\n  <array>\n'
            '    <string>ABCDE12345.io.soundspan.app</string>\n  </array>',
            replacement,
          ),
        );
        expect(checkMacosEntitlements(path), isEmpty, reason: replacement);
        expect(
          checkMacosEntitlements(path, release: true).map((v) => v.toString()),
          ['$path: missing keychain-access-groups with a group'],
          reason: replacement,
        );
      }
    });

    test('ad hoc passes without a keychain access group', () {
      final path = _write(
        'a.entitlements',
        _entitlements.replaceFirst(
          '<key>keychain-access-groups</key>\n  <array>\n'
          '    <string>ABCDE12345.io.soundspan.app</string>\n  </array>',
          '',
        ),
      );
      expect(checkMacosEntitlements(path, adHoc: true), isEmpty);
    });

    test('ad hoc fails with the restricted keychain entitlement', () {
      final path = _write('a.entitlements', _entitlements);
      expect(
        checkMacosEntitlements(path, adHoc: true).map((v) => v.toString()),
        ['$path: unexpected keychain-access-groups'],
      );
    });

    test('ad hoc still needs every entitlement of every build', () {
      final path = _write(
        'a.entitlements',
        _entitlements.replaceFirst('com.apple.security.device.camera', 'x'),
      );
      expect(
        checkMacosEntitlements(path, adHoc: true).map((v) => v.entry),
        contains('<key>com.apple.security.device.camera</key><true/>'),
      );
    });
  });

  group('iOS privacy manifest', () {
    List<String> violations(String content) {
      final path = _write('PrivacyInfo.xcprivacy', content);
      return [
        for (final v in checkIosPrivacyManifest(path))
          v.toString().replaceFirst('$path: ', ''),
      ];
    }

    test('the complete fixture passes', () {
      expect(violations(_privacy), isEmpty);
    });

    test('fails with tracking true', () {
      expect(
        violations(
          _privacy.replaceFirst(
            '<key>NSPrivacyTracking</key>\n  <false/>',
            '<key>NSPrivacyTracking</key>\n  <true/>',
          ),
        ),
        ['missing NSPrivacyTracking false'],
      );
    });

    test('fails with a tracking domain or collected data type', () {
      for (final key in [
        'NSPrivacyTrackingDomains',
        'NSPrivacyCollectedDataTypes',
      ]) {
        expect(
          violations(
            _privacy.replaceFirst(
              '<key>$key</key>\n  <array/>',
              '<key>$key</key>\n  <array><string>x</string></array>',
            ),
          ),
          ['missing $key as an empty array'],
          reason: key,
        );
      }
    });

    test('fails without a category or with other reasons', () {
      expect(
        violations(
          _privacy.replaceFirst(
            'NSPrivacyAccessedAPICategoryUserDefaults',
            'NSPrivacyAccessedAPICategorySystemBootTime',
          ),
        ),
        [_missingUserDefaults, _unexpectedBootTime],
      );
      expect(violations(_privacy.replaceFirst('<string>C617.1</string>', '')), [
        _missingFileTimestamp,
      ]);
    });

    test('a missing manifest is reported', () {
      final path = p.join(_dir.path, 'PrivacyInfo.xcprivacy');
      expect(
        checkIosPrivacyManifest(path).single.toString(),
        '$path: missing the file',
      );
    });
  });

  group('Linux .desktop', () {
    test('passes with the scheme handler', () {
      expect(checkLinuxDesktop(_write('a.desktop', _desktop)), isEmpty);
    });

    test('fails naming the file and entry without the scheme', () {
      final path = _write(
        'a.desktop',
        _desktop.replaceFirst('MimeType=x-scheme-handler/soundspan;\n', ''),
      );
      expect(checkLinuxDesktop(path).map((v) => v.toString()), [
        '$path: missing MimeType=x-scheme-handler/soundspan;',
      ]);
    });

    test('fails without %u in Exec', () {
      final path = _write(
        'a.desktop',
        _desktop.replaceFirst('Exec=soundspan %u', 'Exec=soundspan'),
      );
      expect(checkLinuxDesktop(path).single.entry, 'Exec=… %u');
    });
  });

  test('a missing file is reported', () {
    final path = p.join(_dir.path, 'absent.plist');
    expect(checkPlist(path).single.toString(), '$path: missing the file');
  });

  test('checkPlatformConfig checks every file from flags', () {
    final paths = parseFlags([
      '--macos-entitlements=${[_write('d.entitlements', _entitlements), _write('r.entitlements', _entitlements)].join(',')}',
      '--android-manifest=${_write('m.xml', _manifest)}',
      '--ios-plist',
      _write('ios.plist', _iosPlist),
      '--macos-plist=${_write('macos.plist', _macosPlist.replaceFirst('<string>soundspan</string>', ''))}',
      '--linux-desktop=${_write('a.desktop', _desktop)}',
      '--android-res',
      _res(),
      '--macos-release-entitlements=${_write('built.entitlements', _entitlements)}',
      '--macos-adhoc-entitlements=${_write('adhoc.entitlements', _entitlements)}',
      '--ios-privacy-manifest=${_write('p.xcprivacy', _privacy)}',
    ]);
    final violations = checkPlatformConfig(paths);
    expect(violations.map((v) => p.basename(v.path)), [
      'macos.plist',
      'adhoc.entitlements',
    ]);
    expect(violations.first.entry, startsWith('CFBundleURLTypes'));
    expect(violations.last.toString(), endsWith('unexpected keychain-access-groups'));
  });

  test('the source files pass', () {
    expect(checkPlatformConfig(), isEmpty);
  });

  test('--macos-entitlements checks each comma-separated file', () {
    final good = _write('d.entitlements', _entitlements);
    final bad = _write(
      'r.entitlements',
      _entitlements.replaceFirst('com.apple.security.device.camera', 'x'),
    );
    final violations = checkPlatformConfig(
      parseFlags(['--macos-entitlements', '$good,$bad']),
    ).where((v) => v.path.endsWith('.entitlements'));
    expect(violations.map((v) => v.path), [bad]);
  });

  test('an unknown flag is rejected', () {
    expect(() => parseFlags(['--web']), throwsFormatException);
  });
}
