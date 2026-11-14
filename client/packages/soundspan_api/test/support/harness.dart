// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Base URL every harness talks to.
const testBase = 'https://h';

/// A credential provider holding a fixed credential.
class FixedCredentials implements CredentialProvider {
  /// Holds [current].
  new(this.current);

  @override
  final Credentials? current;

  @override
  Future<void> onTokensRotated(JwtCredentials next) async {}

  @override
  void onUnauthenticated(UnauthenticatedReason reason) {}
}

/// A Dio built by [createDio], served by an [DioAdapter], that records the
/// last request as it left the interceptor chain.
class Harness {
  /// Builds the Dio and the mock server.
  new({
    CredentialProvider? credentials,
    String? playbackDeviceId,
    ApiLogSink? log,
    DateTime Function()? now,
    String base = testBase,
  }) : config = ApiConfig(
         baseUrl: Uri.parse(base),
         userAgent: 'soundspan-client/1.0.0 (test)',
         playbackDeviceId: playbackDeviceId,
       ) {
    dio = createDio(
      config,
      credentials: credentials,
      log: log,
      now: now,
      delay: (_) async {},
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = options;
          handler.next(options);
        },
      ),
    );
    server = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
  }

  /// The configuration [dio] was built with.
  final ApiConfig config;

  /// The Dio under test.
  late final Dio dio;

  /// The mock server behind [dio].
  late final DioAdapter server;

  /// The last request that reached the adapter.
  RequestOptions? sent;

  /// The absolute URL [apiPath] resolves to.
  String url(String apiPath) => '${config.baseUrl}/api$apiPath';
}
