// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/release/check_artifacts.dart';

const _version = '0.1.0';

const _expected = [
  'soundspan-0.1.0-android-unsigned.apk',
  'soundspan-0.1.0-linux-x64-unsigned.tar.gz',
  'soundspan-0.1.0-macos-universal-unsigned.zip',
  'soundspan-0.1.0-web.tar.gz',
  'soundspan-0.1.0-windows-x64-unsigned.zip',
];

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('check_artifacts_test');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  /// Writes every expected artifact for 0.1.0, each with distinct content.
  void writeFullSet() {
    for (final name in _expected) {
      File(p.join(dir.path, name)).writeAsStringSync('content of $name\n');
    }
  }

  ArtifactCheck run({bool writeSums = false}) =>
      checkArtifacts(dir: dir, version: _version, writeSums: writeSums);

  File sums() => File(p.join(dir.path, 'SHA256SUMS'));

  test('expected names are built from the version', () {
    expect(expectedArtifactNames(_version)..sort(), _expected);
  });

  test(
    'the full set passes and --write-sums writes sorted sha256sum lines',
    () {
      writeFullSet();

      final result = run(writeSums: true);

      expect(result.ok, isTrue, reason: result.lines.join('\n'));
      String digest(String name) => sha256
          .convert(File(p.join(dir.path, name)).readAsBytesSync())
          .toString();
      final expectedLines = [
        for (final name in _expected) '${digest(name)}  $name',
      ];
      expect(sums().readAsStringSync(), '${expectedLines.join('\n')}\n');
    },
  );

  test('a missing file fails and names it', () {
    writeFullSet();
    File(p.join(dir.path, _expected.first)).deleteSync();

    final result = run(writeSums: true);

    expect(result.ok, isFalse);
    expect(result.lines.join('\n'), contains(_expected.first));
    expect(sums().existsSync(), isFalse);
  });

  test('an extra file fails and names it', () {
    writeFullSet();
    File(p.join(dir.path, 'notes.txt')).writeAsStringSync('extra');

    final result = run(writeSums: true);

    expect(result.ok, isFalse);
    expect(result.lines.join('\n'), contains('notes.txt'));
  });

  test('a zero-byte file fails', () {
    writeFullSet();
    File(p.join(dir.path, _expected[2])).writeAsBytesSync(const []);

    final result = run(writeSums: true);

    expect(result.ok, isFalse);
    expect(result.lines.join('\n'), contains(_expected[2]));
  });

  test('a file whose name carries another version fails', () {
    writeFullSet();
    File(p.join(dir.path, 'soundspan-0.1.1-web.tar.gz'))
        .writeAsStringSync('other version');

    final result = run(writeSums: true);

    expect(result.ok, isFalse);
    expect(result.lines.join('\n'), contains('soundspan-0.1.1-web.tar.gz'));
  });

  test('verify mode passes on untouched files and fails after a change', () {
    writeFullSet();
    expect(run(writeSums: true).ok, isTrue);

    final untouched = run();
    expect(untouched.ok, isTrue, reason: untouched.lines.join('\n'));

    final changed = File(p.join(dir.path, _expected[1]));
    final bytes = changed.readAsBytesSync();
    bytes[0] ^= 1;
    changed.writeAsBytesSync(bytes);

    final result = run();
    expect(result.ok, isFalse);
    expect(result.lines.join('\n'), contains(_expected[1]));
  });

  test('verify mode fails when SHA256SUMS is missing', () {
    writeFullSet();

    final result = run();

    expect(result.ok, isFalse);
    expect(result.lines.join('\n'), contains('SHA256SUMS'));
  });

  test('SHA256SUMS does not list itself', () {
    writeFullSet();
    expect(run(writeSums: true).ok, isTrue);
    // A second write sees the first SHA256SUMS in the directory.
    expect(run(writeSums: true).ok, isTrue);

    final listed = sums()
        .readAsLinesSync()
        .map((line) => line.split('  ').last)
        .toList();
    expect(listed, _expected);
    expect(listed, isNot(contains('SHA256SUMS')));
  });

  group('without macOS', () {
    const macos = 'soundspan-0.1.0-macos-universal-unsigned.zip';

    void writeSetWithoutMacos() {
      writeFullSet();
      File(p.join(dir.path, macos)).deleteSync();
    }

    test('expected names leave out the macOS zip', () {
      expect(
        expectedArtifactNames(_version, macos: false)..sort(),
        [..._expected]..remove(macos),
      );
    });

    test('the set without the macOS zip passes and is summed', () {
      writeSetWithoutMacos();

      final result = checkArtifacts(
        dir: dir,
        version: _version,
        writeSums: true,
        macos: false,
      );

      expect(result.ok, isTrue, reason: result.lines.join('\n'));
      expect(sums().readAsStringSync(), isNot(contains(macos)));
    });

    test('a macOS zip that is present fails as unexpected', () {
      writeFullSet();

      final result = checkArtifacts(
        dir: dir,
        version: _version,
        writeSums: true,
        macos: false,
      );

      expect(result.ok, isFalse);
      expect(result.lines, contains('unexpected: $macos'));
    });

    test('the default still requires the macOS zip', () {
      writeSetWithoutMacos();

      final result = run(writeSums: true);

      expect(result.ok, isFalse);
      expect(result.lines, contains('missing: $macos'));
    });
  });
}
