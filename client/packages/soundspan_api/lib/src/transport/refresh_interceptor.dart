// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/config.dart';
import 'package:soundspan_api/src/errors.dart';
import 'package:soundspan_api/src/transport/base_url_guard.dart';
import 'package:soundspan_api/src/transport/credential_interceptor.dart';
import 'package:soundspan_api/src/transport/error_mapper.dart';
import 'package:soundspan_api/src/transport/replay.dart';

/// Marks a replay of a request that already got a 401.
const _replayedExtra = 'soundspan.refreshReplayed';

/// The share of an access token's lifetime after which it is renewed before
/// use.
const _refreshAt = 0.8;

/// Interceptor 3: renews JWT sessions, once at a time.
///
/// - Before a request with [JwtCredentials] is sent, a token past 80 % of
///   its lifetime (`exp - iat`, read without a signature check) is renewed
///   first. A token that cannot be decoded is sent as is.
/// - A 401 whose `code` is `AUTH_REQUIRED` or absent renews the session
///   once and replays the request; a 401 on the replay is final.
/// - Concurrent callers share one renewal. A request sent with a token that
///   is no longer current is replayed without another renewal.
/// - [CredentialProvider.onTokensRotated] completes before any request
///   carries the new token.
/// - A renewal answered with 401 calls
///   [CredentialProvider.onUnauthenticated] with
///   [UnauthenticatedReason.sessionExpired] and fails every waiter with
///   [Unauthenticated]. Any other failure fails the waiters with its own
///   [ApiException] and keeps the session.
/// - A 401 with [ApiKeyCredentials] calls
///   [CredentialProvider.onUnauthenticated] with
///   [UnauthenticatedReason.keyRejected], once per key.
///
/// A plain [Interceptor] rather than a `QueuedInterceptor`: a replay goes
/// back through the whole chain, and a queued error handler would wait on
/// itself when the replay fails with 401. The shared in-flight renewal is
/// what serializes renewals.
class RefreshInterceptor extends Interceptor {
  /// Creates the interceptor. [now] defaults to [DateTime.now].
  new({
    required this.dio,
    required this.config,
    required this.credentials,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// The Dio replays are sent through; renewals use its adapter.
  final Dio dio;

  /// The configuration renewals are sent with.
  final ApiConfig config;

  /// Supplies and stores the credential; null means every request is
  /// anonymous.
  final CredentialProvider? credentials;

  final DateTime Function() _now;

  Future<JwtCredentials>? _inFlight;
  String? _rejectedKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    unawaited(_onRequest(options, handler));
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final provider = credentials;
    if (provider == null || options.extra[anonymousExtra] == true) {
      return handler.next(options);
    }
    try {
      await _inFlight;
      final current = provider.current;
      if (current is! JwtCredentials) return handler.next(options);
      if (_isAging(current.accessToken)) await _refresh(current);
    } on ApiException catch (error, stackTrace) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
    final current = provider.current;
    if (current is JwtCredentials) {
      options.headers['Authorization'] = 'Bearer ${current.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    unawaited(_onError(err, handler));
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final provider = credentials;
    if (err.response?.statusCode != 401 ||
        provider == null ||
        options.extra[anonymousExtra] == true) {
      return handler.next(err);
    }
    switch (provider.current) {
      case ApiKeyCredentials(:final apiKey):
        if (_rejectedKey != apiKey) {
          _rejectedKey = apiKey;
          provider.onUnauthenticated(UnauthenticatedReason.keyRejected);
        }
        return handler.next(err);
      case JwtCredentials():
        if (options.extra[_replayedExtra] == true ||
            !_isRefreshable(err.response!.data)) {
          return handler.next(err);
        }
      case null:
        return handler.next(err);
    }
    try {
      await _inFlight;
      final current = provider.current;
      if (current is! JwtCredentials) return handler.next(err);
      if (options.headers['Authorization'] == 'Bearer ${current.accessToken}') {
        await _refresh(current);
      }
    } on ApiException catch (error) {
      return handler.reject(err.copyWith(error: error));
    }
    try {
      handler.resolve(await replay(dio, options, {_replayedExtra: true}));
    } on DioException catch (failure) {
      handler.reject(failure);
    }
  }

  Future<JwtCredentials> _refresh(JwtCredentials stale) =>
      _inFlight ??= _doRefresh(stale).whenComplete(() => _inFlight = null);

  Future<JwtCredentials> _doRefresh(JwtCredentials stale) async {
    final bare = Dio(
      BaseOptions(
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
      ),
    )..httpClientAdapter = dio.httpClientAdapter;
    bare.interceptors.addAll([
      BaseUrlGuard(config),
      CredentialInterceptor(config, null),
      ErrorMapper(),
    ]);
    final Response<dynamic> response;
    try {
      response = await bare.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': stale.refreshToken},
        options: Options(extra: {anonymousExtra: true, noRetryExtra: true}),
      );
    } on DioException catch (failure, stackTrace) {
      final cause = failure.error;
      if (cause is Error) Error.throwWithStackTrace(cause, stackTrace);
      final error = mapDioException(failure);
      if (failure.response?.statusCode != 401) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      credentials!.onUnauthenticated(UnauthenticatedReason.sessionExpired);
      Error.throwWithStackTrace(
        error is Unauthenticated ? error : const Unauthenticated(status: 401),
        stackTrace,
      );
    }
    final next = switch (response.data) {
      {'token': final String token, 'refreshToken': final String refresh} =>
        JwtCredentials(accessToken: token, refreshToken: refresh),
      _ => throw InvalidResponse(
        status: response.statusCode,
        serverMessage: 'refresh response without token and refreshToken',
      ),
    };
    await credentials!.onTokensRotated(next);
    return next;
  }

  bool _isAging(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    final Object? claims;
    try {
      claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
    } on FormatException {
      return false;
    }
    if (claims case {'iat': final num iat, 'exp': final num exp}) {
      final lifetime = exp - iat;
      if (lifetime <= 0) return false;
      final now = _now().millisecondsSinceEpoch / 1000;
      return now - iat > lifetime * _refreshAt;
    }
    return false;
  }

  static bool _isRefreshable(Object? body) {
    var value = body;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        return true;
      }
    }
    if (value is Map<String, dynamic>) {
      final code = value['code'];
      return code == null || code == 'AUTH_REQUIRED';
    }
    return true;
  }
}
