// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/stream_auth/stream_auth.dart';
import 'package:soundspan/platform/stream_auth/stream_auth_io.dart';
import 'package:soundspan/platform/stream_auth/stream_auth_web.dart';
import 'package:soundspan_api/soundspan_api.dart';

void main() {
  final uri = Uri.parse(
    'https://music.example.com/api/playback/stream/p%3A1?quality=high&report=0',
  );
  const jwt = JwtCredentials(accessToken: 'access-1', refreshToken: 'r1');
  const key = ApiKeyCredentials(apiKey: 'key-1');

  group('native', () {
    test('the provider of a native test run sends headers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(streamAuthProvider), isA<HeaderStreamAuth>());
    });

    test('a JWT travels as a bearer header and the URI is unchanged', () {
      final result = const HeaderStreamAuth().apply(uri, jwt);
      expect(result.uri, uri);
      expect(result.headers, {'Authorization': 'Bearer access-1'});
    });

    test('an API key travels as X-API-Key and the URI is unchanged', () {
      final result = const HeaderStreamAuth().apply(uri, key);
      expect(result.uri, uri);
      expect(result.headers, {'X-API-Key': 'key-1'});
    });
  });

  group('web', () {
    test('a JWT is added as the token parameter and no headers are sent', () {
      final result = const QueryTokenStreamAuth().apply(uri, jwt);
      expect(result.headers, isEmpty);
      expect(result.uri.path, uri.path);
      expect(result.uri.queryParameters, {
        'quality': 'high',
        'report': '0',
        'token': 'access-1',
      });
    });

    test('an API key throws UnsupportedError', () {
      expect(
        () => const QueryTokenStreamAuth().apply(uri, key),
        throwsUnsupportedError,
      );
    });
  });
}
