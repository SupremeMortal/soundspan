// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:soundspan_api/src/transport/base_url_guard.dart';
import 'package:soundspan_api/src/transport/credential_interceptor.dart';
import 'package:soundspan_api/src/transport/error_mapper.dart';
import 'package:soundspan_api/src/transport/log_interceptor.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  final config = ApiConfig(
    baseUrl: Uri.parse(testBase),
    userAgent: 'ua',
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 7),
  );

  group('createDio', () {
    test('installs the interceptors in the documented order', () {
      final dio = createDio(config);
      final ours = dio.interceptors
          .where(
            (i) =>
                i is BaseUrlGuard ||
                i is CredentialInterceptor ||
                i is ErrorMapper ||
                i is ApiLogInterceptor,
          )
          .map((i) => i.runtimeType)
          .toList();
      expect(ours, [
        BaseUrlGuard,
        CredentialInterceptor,
        ErrorMapper,
        ApiLogInterceptor,
      ]);
    });

    test('sends no credential header without a CredentialProvider', () async {
      final h = Harness();
      h.server.onGet(h.url('/auth/me'), (s) => s.reply(200, {'id': 'u'}));
      await h.dio.get<dynamic>('/auth/me');
      expect(h.sent!.headers.containsKey('Authorization'), isFalse);
      expect(h.sent!.headers.containsKey('X-API-Key'), isFalse);
    });

    test('uses the ApiConfig timeouts', () {
      final dio = createDio(config);
      expect(dio.options.connectTimeout, const Duration(seconds: 3));
      expect(dio.options.receiveTimeout, const Duration(seconds: 7));
    });

    test('uses the given adapter, or the platform adapter', () {
      final adapter = platformHttpClientAdapter();
      expect(createDio(config, adapter: adapter).httpClientAdapter, adapter);
      expect(createDio(config).httpClientAdapter, isA<HttpClientAdapter>());
    });

    test('a guard rejection reaches the caller as an ArgumentError', () {
      final dio = createDio(config);
      expect(dio.get<dynamic>('//evil.example/x'), throwsArgumentError);
    });

    test('clone keeps the configuration', () {
      final dio = createDio(config);
      final copy = dio.clone();
      expect(copy.options.connectTimeout, dio.options.connectTimeout);
      expect(copy.httpClientAdapter, dio.httpClientAdapter);
    });
  });
}
