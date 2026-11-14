// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';
import 'package:soundspan_api/src/transport/base_url_guard.dart';
import 'package:test/test.dart';

void main() {
  BaseUrlGuard guardFor(String base) =>
      BaseUrlGuard(ApiConfig(baseUrl: Uri.parse(base), userAgent: 'ua'));

  group('BaseUrlGuard', () {
    test(
      '/library/albums with base https://h resolves to /api/library/albums',
      () {
        expect(
          guardFor('https://h').resolve('/library/albums'),
          Uri.parse('https://h/api/library/albums'),
        );
      },
    );

    test('a base with a path prefix keeps the prefix', () {
      expect(
        guardFor('https://h/soundspan').resolve('/library/albums'),
        Uri.parse('https://h/soundspan/api/library/albums'),
      );
    });

    test('keeps a query written into the path', () {
      expect(
        guardFor('https://h').resolve('/search?q=a'),
        Uri.parse('https://h/api/search?q=a'),
      );
    });

    test('an absolute URL to another origin throws', () {
      expect(
        () => guardFor('https://h').resolve('https://evil.example/api/x'),
        throwsArgumentError,
      );
    });

    test('an absolute URL to the same origin throws', () {
      expect(
        () => guardFor('https://h').resolve('https://h/api/library/albums'),
        throwsArgumentError,
      );
    });

    test('a scheme-relative path throws', () {
      expect(
        () => guardFor('https://h').resolve('//evil.example/x'),
        throwsArgumentError,
      );
    });

    test('a path without a leading slash throws', () {
      expect(
        () => guardFor('https://h').resolve('library/albums'),
        throwsArgumentError,
      );
    });

    test('/../admin throws', () {
      expect(
        () => guardFor('https://h').resolve('/../admin'),
        throwsArgumentError,
      );
    });

    test('/library/../../x throws', () {
      expect(
        () => guardFor('https://h/soundspan').resolve('/library/../../x'),
        throwsArgumentError,
      );
    });

    test('a .. that stays under /api resolves', () {
      expect(
        guardFor('https://h').resolve('/library/x/../albums'),
        Uri.parse('https://h/api/library/albums'),
      );
    });
  });
}
