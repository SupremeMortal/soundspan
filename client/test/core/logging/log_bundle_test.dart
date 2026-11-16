// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/log_bundle.dart';

import 'recording_sink.dart';

void main() {
  group('zipLogFiles', () {
    test('unzips to the same file names and bytes', () {
      final files = {
        'app.0.log': utf8.encode('{"message":"newest"}\n'),
        'app.1.log': utf8.encode('{"message":"older"}\n'),
      };

      final archive = ZipDecoder().decodeBytes(zipLogFiles(files));

      expect(archive.files.map((f) => f.name), ['app.0.log', 'app.1.log']);
      for (final file in archive.files) {
        expect(file.content, files[file.name]);
      }
    });

    test('an empty map produces a valid empty archive', () {
      final archive = ZipDecoder().decodeBytes(zipLogFiles(const {}));
      expect(archive.files, isEmpty);
    });
  });

  group('ringToText', () {
    test('writes one JSON line per entry, in order', () {
      final text = ringToText([
        entryWith(message: 'one', fields: {'bytes': 3}),
        entryWith(message: 'two', error: 'e'),
      ]);

      final lines = const LineSplitter().convert(text);
      expect(lines, hasLength(2));
      expect(text, endsWith('\n'));
      final first = jsonDecode(lines[0]) as Map<String, Object?>;
      expect(first, {
        'time': '2026-01-01T00:00:00.000Z',
        'level': 'info',
        'scope': 'Test',
        'message': 'one',
        'fields': {'bytes': 3},
      });
      expect((jsonDecode(lines[1]) as Map<String, Object?>)['message'], 'two');
    });

    test('an empty list gives an empty string', () {
      expect(ringToText(const []), '');
    });
  });

  test('logBundleName stamps the time as yyyyMMdd-HHmmss', () {
    expect(
      logBundleName(DateTime.utc(2026, 3, 4, 5, 6, 7), 'zip'),
      'soundspan-logs-20260304-050607.zip',
    );
  });
}
