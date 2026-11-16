// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/check_platform_config.dart';

const _manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application>
    <activity android:name=".MainActivity" android:exported="true">
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
  </application>
</manifest>
''';

const _plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
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

late Directory _dir;

String _write(String name, String content) {
  final path = p.join(_dir.path, name);
  File(path).writeAsStringSync(content);
  return path;
}

void main() {
  setUp(() => _dir = Directory.systemTemp.createTempSync('platform_config'));
  tearDown(() => _dir.deleteSync(recursive: true));

  group('Android manifest', () {
    test('passes with the soundspan intent filter', () {
      expect(checkAndroidManifest(_write('m.xml', _manifest)), isEmpty);
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
  });

  for (final target in ['iOS', 'macOS']) {
    group('$target Info.plist', () {
      test('passes with CFBundleURLTypes', () {
        expect(checkPlist(_write('Info.plist', _plist)), isEmpty);
      });

      test('fails naming the file and entry without the scheme', () {
        final path = _write(
          'Info.plist',
          _plist.replaceFirst('<string>soundspan</string>', ''),
        );
        expect(checkPlist(path).map((v) => v.toString()), [
          '$path: missing CFBundleURLTypes with CFBundleURLSchemes soundspan',
        ]);
      });
    });
  }

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

  test('checkPlatformConfig checks all four files from flags', () {
    final paths = parseFlags([
      '--android-manifest=${_write('m.xml', _manifest)}',
      '--ios-plist',
      _write('ios.plist', _plist),
      '--macos-plist=${_write('macos.plist', _plist.replaceFirst('<string>soundspan</string>', ''))}',
      '--linux-desktop=${_write('a.desktop', _desktop)}',
    ]);
    final violations = checkPlatformConfig(paths);
    expect(violations.map((v) => p.basename(v.path)), ['macos.plist']);
    expect(violations.single.entry, startsWith('CFBundleURLTypes'));
  });

  test('the source files pass', () {
    expect(checkPlatformConfig(), isEmpty);
  });

  test('an unknown flag is rejected', () {
    expect(() => parseFlags(['--web']), throwsFormatException);
  });
}
