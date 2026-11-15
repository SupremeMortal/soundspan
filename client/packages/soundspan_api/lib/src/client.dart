// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The `SoundspanApi` facade over the generated clients.
library;

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/config.dart';
import 'package:soundspan_api/src/generated/anonymous_operations.g.dart';
import 'package:soundspan_api/src/generated/soundspan_rest_client.dart';
import 'package:soundspan_api/src/operations.dart';
import 'package:soundspan_api/src/server_version.dart';
import 'package:soundspan_api/src/transport/dio_factory.dart';
import 'package:soundspan_api/src/transport/error_mapper.dart';
import 'package:soundspan_api/src/transport/log_interceptor.dart';
import 'package:soundspan_api/src/transport/replay.dart';

/// The `User-Agent` of [SoundspanApi.anonymous] when none is given.
const _defaultUserAgent = 'soundspan-client';

/// Owns the Dio of one server connection and exposes the generated clients.
class SoundspanApi {
  /// Creates the API of a signed-in connection; [credentials] supplies the
  /// credential each request carries.
  new(
    ApiConfig config, {
    required CredentialProvider credentials,
    ApiLogSink? log,
    HttpClientAdapter? adapter,
  }) : this._(config, credentials, log, adapter);

  /// For probe calls made before sign-in: no credential is ever attached.
  ///
  /// [connectTimeout] and [receiveTimeout] default to those of [ApiConfig].
  new anonymous(
    Uri baseUrl, {
    String userAgent = _defaultUserAgent,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
    ApiLogSink? log,
    HttpClientAdapter? adapter,
  }) : this._(
         ApiConfig(
           baseUrl: baseUrl,
           userAgent: userAgent,
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
         ),
         null,
         log,
         adapter,
       );

  new _(
    this.config,
    CredentialProvider? credentials,
    ApiLogSink? log,
    HttpClientAdapter? adapter,
  ) : _dio = createDio(
        config,
        credentials: credentials,
        log: log,
        adapter: adapter,
      ) {
    _dio.interceptors.insert(0, _OperationInterceptor());
    rest = SoundspanRestClient(_dio);
  }

  final Dio _dio;

  /// The server this API talks to.
  final ApiConfig config;

  /// The generated root client; it has one getter per tag (`rest.session`,
  /// `rest.library2`, ...).
  ///
  /// A call made directly on it throws the decoder's own error when a 2xx
  /// body does not match its model; [send] turns that into an
  /// `InvalidResponse`.
  late final SoundspanRestClient rest;

  /// Runs [call] against [rest] and turns a body that does not decode into
  /// its model into an `InvalidResponse`, naming the operation and the failing
  /// key.
  Future<T> send<T>(Future<T> Function(SoundspanRestClient rest) call) =>
      guardDecode(() => call(rest));

  /// The server's version, or null when it does not say.
  ///
  /// Reads `info.version` from `GET /api/docs.json` as a byte stream,
  /// cancelling the request as soon as it has been read, so the document is
  /// never held in memory. A 401, 403 or 404 there falls back to the
  /// `version` of `GET /api/health`. A missing value and the literal
  /// `unknown` give null; other failures propagate as an `ApiException`.
  Future<String?> fetchServerVersion() => fetchServerVersionWith(_dio, rest);

  /// Closes the HTTP adapter and its open connections.
  void close() => _dio.close(force: true);
}

/// The request extra that marks a request whose `/api` prefix was removed.
const _rewrittenExtra = 'soundspan.operationRewritten';

/// Runs before the base-URL guard. The generated clients send the spec's
/// paths, which start with `/api`; this removes the prefix (the guard
/// resolves paths against `<baseUrl>/api`), records the `operationId`, and
/// marks the operations the spec declares without security as anonymous.
///
/// A replay already carries the mark and passes through unchanged.
class _OperationInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (options.extra[_rewrittenExtra] == true || !path.startsWith('/api/')) {
      handler.next(options);
      return;
    }
    final key = matchOperation(operationIds.keys, options.method, path);
    options
      ..extra[_rewrittenExtra] = true
      ..path = path.substring('/api'.length);
    if (key != null) {
      options.extra[operationIdExtra] = operationIds[key];
      if (anonymousOperations.contains(key)) {
        options.extra[anonymousExtra] = true;
      }
    }
    handler.next(options);
  }
}
