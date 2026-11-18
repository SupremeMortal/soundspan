// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/file_sizes/file_sizes_io.dart';
import 'package:soundspan/platform/file_sizes/file_sizes_web.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('file_sizes'));
  tearDown(() => dir.deleteSync(recursive: true));

  void write(String path, int bytes) => File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(List.filled(bytes, 1));

  const sizes = IoFileSizes();

  test('directoryBytes sums every file below the directory', () async {
    write(p.join(dir.path, 'a'), 10);
    write(p.join(dir.path, 'x', 'y', 'b'), 5);

    expect(await sizes.directoryBytes(dir.path), 15);
    expect(await sizes.directoryBytes(p.join(dir.path, 'missing')), 0);
  });

  test('filesBytes sums the files that exist', () async {
    write(p.join(dir.path, 'a'), 10);
    write(p.join(dir.path, 'b'), 3);

    expect(
      await sizes.filesBytes([
        p.join(dir.path, 'a'),
        p.join(dir.path, 'b'),
        p.join(dir.path, 'c'),
      ]),
      13,
    );
  });

  test('clearDirectory empties the directory and keeps it', () async {
    final media = p.join(dir.path, 'media');
    write(p.join(media, 'ab', 'one.flac'), 10);
    write(p.join(media, 'cd', 'two.part'), 10);

    await sizes.clearDirectory(media);
    await sizes.clearDirectory(p.join(dir.path, 'missing'));

    expect(Directory(media).existsSync(), isTrue);
    expect(Directory(media).listSync(), isEmpty);
    expect(Directory(p.join(dir.path, 'missing')).existsSync(), isFalse);
  });

  test('the web seam has no files', () async {
    const none = NoFileSizes();
    write(p.join(dir.path, 'a'), 10);

    expect(await none.directoryBytes(dir.path), 0);
    expect(await none.filesBytes([p.join(dir.path, 'a')]), 0);
    await none.clearDirectory(dir.path);
    expect(File(p.join(dir.path, 'a')).existsSync(), isTrue);
  });
}
