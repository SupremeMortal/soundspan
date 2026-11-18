// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  Future<Map<String, dynamic>> headersOf(
    Harness h, {
    Map<String, dynamic>? extra,
  }) async {
    h.server.onGet(h.url('/auth/me'), (s) => s.reply(200, {'id': 'u'}));
    await h.dio.get<dynamic>('/auth/me', options: Options(extra: extra));
    return h.sent!.headers;
  }

  group('CredentialInterceptor', () {
    test('API key credentials send X-API-Key and no Authorization', () async {
      final h = Harness(
        credentials: FixedCredentials(const ApiKeyCredentials(apiKey: 'k1')),
      );
      final headers = await headersOf(h);
      expect(headers['X-API-Key'], 'k1');
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('JWT credentials send a bearer token and no X-API-Key', () async {
      final h = Harness(
        credentials: FixedCredentials(
          const JwtCredentials(accessToken: 'at', refreshToken: 'rt'),
        ),
      );
      final headers = await headersOf(h);
      expect(headers['Authorization'], 'Bearer at');
      expect(headers.containsKey('X-API-Key'), isFalse);
    });

    test(
      'anonymous requests send neither, even when credentials exist',
      () async {
        final h = Harness(
          credentials: FixedCredentials(
            const JwtCredentials(accessToken: 'at', refreshToken: 'rt'),
          ),
        );
        final headers = await headersOf(h, extra: {'anonymous': true});
        expect(headers.containsKey('Authorization'), isFalse);
        expect(headers.containsKey('X-API-Key'), isFalse);
      },
    );

    test('no credential is sent when the provider holds none', () async {
      final h = Harness(credentials: FixedCredentials(null));
      final headers = await headersOf(h);
      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers.containsKey('X-API-Key'), isFalse);
    });

    test('X-Playback-Device-Id is sent when configured', () async {
      final h = Harness(playbackDeviceId: 'dev-1');
      expect((await headersOf(h))['X-Playback-Device-Id'], 'dev-1');
    });

    test('X-Playback-Device-Id is absent otherwise', () async {
      final h = Harness();
      expect((await headersOf(h)).containsKey('X-Playback-Device-Id'), isFalse);
    });

    test('User-Agent equals ApiConfig.userAgent on the VM', () async {
      final h = Harness();
      expect((await headersOf(h))['User-Agent'], h.config.userAgent);
    });
  });
}
