// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/config.dart';

/// True when compiled for the web, where the browser owns `User-Agent`.
const _isWeb = bool.fromEnvironment('dart.library.js_interop');

/// Interceptor 2: adds the credential and the client identification headers.
class CredentialInterceptor extends Interceptor {
  /// Creates the interceptor. With [credentials] null every request is
  /// anonymous.
  new(this.config, this.credentials);

  /// Supplies `X-Playback-Device-Id` and `User-Agent`.
  final ApiConfig config;

  /// Supplies the credential, if any.
  final CredentialProvider? credentials;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = options.headers
      ..remove('Authorization')
      ..remove('X-API-Key');
    final anonymous = options.extra['anonymous'] == true;
    switch (anonymous ? null : credentials?.current) {
      case ApiKeyCredentials(:final apiKey):
        headers['X-API-Key'] = apiKey;
      case JwtCredentials(:final accessToken):
        headers['Authorization'] = 'Bearer $accessToken';
      case null:
        break;
    }
    final deviceId = config.playbackDeviceId;
    if (deviceId != null) headers['X-Playback-Device-Id'] = deviceId;
    if (!_isWeb) headers['User-Agent'] = config.userAgent;
    handler.next(options);
  }
}
