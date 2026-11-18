// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

void main() {
  ApiConfig configFor(String url) => ApiConfig(
    baseUrl: Uri.parse(url),
    userAgent: 'soundspan-client/1 (test)',
  );

  group('ApiConfig', () {
    test('accepts a base URL with and without a path prefix', () {
      expect(configFor('https://h').baseUrl, Uri.parse('https://h'));
      expect(
        configFor('https://h/soundspan').baseUrl,
        Uri.parse('https://h/soundspan'),
      );
    });

    test('defaults to a 10 s connect and a 30 s receive timeout', () {
      final config = configFor('https://h');
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(seconds: 30));
      expect(config.playbackDeviceId, isNull);
    });

    test('rejects a base URL with a trailing slash', () {
      expect(() => configFor('https://h/'), throwsArgumentError);
      expect(() => configFor('https://h/soundspan/'), throwsArgumentError);
    });

    test('rejects a base URL with a query', () {
      expect(() => configFor('https://h?x=1'), throwsArgumentError);
    });

    test('rejects a base URL with a fragment', () {
      expect(() => configFor('https://h#top'), throwsArgumentError);
    });
  });

  group('Credentials', () {
    test('carry their secrets', () {
      const jwt = JwtCredentials(accessToken: 'a', refreshToken: 'r');
      const key = ApiKeyCredentials(apiKey: 'k');
      expect(jwt.accessToken, 'a');
      expect(jwt.refreshToken, 'r');
      expect(key.apiKey, 'k');
    });

    test('never print their secrets', () {
      const jwt = JwtCredentials(accessToken: 'secret-a', refreshToken: 'r');
      const key = ApiKeyCredentials(apiKey: 'secret-k');
      expect('$jwt$key', isNot(contains('secret')));
    });
  });
}
