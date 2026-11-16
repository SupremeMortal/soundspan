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

  test('createMediaFiles answers the io seam', () {
    expect(createMediaFiles(), isA<IoMediaFiles>());
  });
}
