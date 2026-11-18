// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/media_files/media_files_io.dart';
import 'package:soundspan/platform/media_files/media_files_web.dart'
    show NoMediaFiles;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('media_files'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('delete removes the file', () async {
    final file = File('${dir.path}/a.mp3')..writeAsStringSync('x');

    await const IoMediaFiles().delete(file.path);

    expect(file.existsSync(), isFalse);
  });

  test('deleting a missing file is not an error', () async {
    await expectLater(
      const IoMediaFiles().delete('${dir.path}/missing.part'),
      completes,
    );
  });

  test('a failure other than a missing file throws', () async {
    final sub = Directory('${dir.path}/sub')..createSync();
    File('${sub.path}/inner').writeAsStringSync('x');

    // A non-empty directory cannot be deleted as a file.
    await expectLater(
      const IoMediaFiles().delete(sub.path),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('the web seam does nothing', () async {
    await expectLater(const NoMediaFiles().delete('/any'), completes);
  });

  test('length answers the size, or null for a missing file', () async {
    final file = File('${dir.path}/a.part')..writeAsBytesSync([1, 2, 3]);

    expect(await const IoMediaFiles().length(file.path), 3);
    expect(await const IoMediaFiles().length('${dir.path}/missing'), isNull);
    expect(await const NoMediaFiles().length(file.path), isNull);
  });

  test('replace renames over an existing file', () async {
    final from = File('${dir.path}/a.part')..writeAsBytesSync([1, 2, 3]);
    final to = File('${dir.path}/a.flac')..writeAsStringSync('stale');

    await const IoMediaFiles().replace(from.path, to.path);

    expect(from.existsSync(), isFalse);
    expect(to.readAsBytesSync(), [1, 2, 3]);
  });

  test('replace throws when the source is missing', () async {
    await expectLater(
      const IoMediaFiles().replace('${dir.path}/missing', '${dir.path}/b'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('deleteTree removes every file and the directory', () async {
    final root = Directory('${dir.path}/media');
    File('${root.path}/ab/a.flac')
      ..createSync(recursive: true)
      ..writeAsStringSync('x');
    File('${root.path}/cd/b.part')
      ..createSync(recursive: true)
      ..writeAsStringSync('y');

    await const IoMediaFiles().deleteTree(root.path);

    expect(root.existsSync(), isFalse);
  });

  test('deleteTree of a missing directory is not an error', () async {
    await expectLater(
      const IoMediaFiles().deleteTree('${dir.path}/missing'),
      completes,
    );
    await expectLater(const NoMediaFiles().deleteTree('/any'), completes);
  });

  test('createMediaFiles answers the io seam', () {
    expect(createMediaFiles(), isA<IoMediaFiles>());
  });
}
