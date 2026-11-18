// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _densityPngs = '''
Package name=io.soundspan.app id=7f
  type mipmap id=0d entryCount=2
    resource 0x7f0d0000 mipmap/ic_launcher
      (mdpi) (file) res/mipmap-mdpi-v4/ic_launcher.png type=PNG
      (hdpi) (file) res/mipmap-hdpi-v4/ic_launcher.png type=PNG
      (xxxhdpi) (file) res/mipmap-xxxhdpi-v4/ic_launcher.png type=PNG
    resource 0x7f0d0001 mipmap/ic_launcher_foreground
      (anydpi) (file) res/mipmap-anydpi-v26/ic_launcher_foreground.xml type=XML
''';

const _anydpi = '''
Package name=io.soundspan.app id=7f
  type mipmap id=0d entryCount=1
    resource 0x7f0d0000 mipmap/ic_launcher
      (mdpi) (file) res/mipmap-mdpi-v4/ic_launcher.png type=PNG
      (anydpi) (file) res/Xx.xml type=XML
''';

const _anydpiV26 = '''
Package name=io.soundspan.app id=7f
  type mipmap id=0d entryCount=1
    resource 0x7f0d0000 mipmap/ic_launcher
      (mdpi) (file) res/mipmap-mdpi-v4/ic_launcher.png type=PNG
      (anydpi-v26) (file) res/mipmap-anydpi-v26/ic_launcher.xml type=XML
''';

const _noLauncher = '''
Package name=io.soundspan.app id=7f
  type drawable id=08 entryCount=1
    resource 0x7f080000 drawable/launch_background
      () (file) res/drawable/launch_background.xml type=XML
''';

late Directory _dir;

ProcessResult _check(String dump) {
  final file = File(p.join(_dir.path, 'resources.txt'))
    ..writeAsStringSync(dump);
  return Process.runSync('bash', [
    'tool/ci/check_apk_icon.sh',
    '--resources',
    file.path,
  ]);
}

void main() {
  setUp(() => _dir = Directory.systemTemp.createTempSync('apk_icon_'));
  tearDown(() => _dir.deleteSync(recursive: true));

  group('check_apk_icon.sh --resources', () {
    test('fails when the launcher icon has only density PNGs', () {
      final result = _check(_densityPngs);
      expect(result.exitCode, 1, reason: '${result.stderr}');
      expect('${result.stderr}', contains('no adaptive'));
    });

    test('passes on an anydpi XML variant (minSdk 26 or more)', () {
      final result = _check(_anydpi);
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });

    test('passes on an anydpi-v26 XML variant', () {
      final result = _check(_anydpiV26);
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });

    test('fails when there is no mipmap/ic_launcher resource', () {
      final result = _check(_noLauncher);
      expect(result.exitCode, 1, reason: '${result.stderr}');
      expect('${result.stderr}', contains('no mipmap/ic_launcher'));
    });

    test('exits 2 when the resources file does not exist', () {
      final result = Process.runSync('bash', [
        'tool/ci/check_apk_icon.sh',
        '--resources',
        p.join(_dir.path, 'missing.txt'),
      ]);
      expect(result.exitCode, 2, reason: '${result.stderr}');
    });
  }, skip: Platform.isWindows ? 'bash script; CI runs it on Linux' : null);
}
