// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/transport/error_mapper.dart';
import 'package:soundspan_api/src/transport/replay.dart';

/// The longest `Retry-After` a 429 is waited out for.
const _maxRetryAfter = Duration(seconds: 60);

const _idempotent = {'GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS'};

const _gatewayBackoff = [
  Duration(milliseconds: 500),
  Duration(seconds: 1),
  Duration(seconds: 2),
];

const _networkBackoff = [Duration(milliseconds: 500), Duration(seconds: 1)];

/// Interceptor 4: retries rate-limited requests and idempotent reads that
/// failed transiently, with bounded, jittered backoff.
///
/// | Condition | Policy |
/// |---|---|
/// | 429, `Retry-After` at most 60 s | wait it plus 0–20 % jitter; 2 retries for idempotent methods, 1 for others |
/// | 429, `Retry-After` over 60 s | no retry |
/// | 502, 503, 504 on `GET` | 3 retries after 0.5, 1, 2 s plus jitter |
/// | connection error or timeout on `GET` | 2 retries after 0.5, 1 s plus jitter |
///
/// Nothing else is retried, nor is a request marked `noRetry` or a 401
/// (which belongs to the refresh interceptor). A retry is sent through the
/// whole chain of [dio], so it carries the current credential.
class RetryInterceptor extends Interceptor {
  /// Creates the interceptor. [delay] defaults to [Future.delayed] and
  /// [random], which draws the jitter, to a new [Random].
  new({
    required this.dio,
    Future<void> Function(Duration)? delay,
    Random? random,
  }) : _delay = delay ?? Future<void>.delayed,
       _random = random ?? Random();

  /// The Dio retries are sent through.
  final Dio dio;

  final Future<void> Function(Duration) _delay;
  final Random _random;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    unawaited(_onError(err, handler));
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final plan = options.extra[noRetryExtra] == true || err.error is Error
        ? null
        : _plan(err);
    if (plan == null) return handler.next(err);
    final (:kind, :maxRetries, :wait) = plan;
    final key = 'soundspan.retries.$kind';
    final attempt = options.extra[key] as int? ?? 0;
    if (attempt >= maxRetries) return handler.next(err);
    await _delay(wait(attempt) * (1 + _random.nextDouble() * 0.2));
    try {
      handler.resolve(await replay(dio, options, {key: attempt + 1}));
    } on DioException catch (failure) {
      handler.reject(failure);
    }
  }

  _Plan? _plan(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    final response = err.response;
    switch (response?.statusCode) {
      case 429:
        final retryAfter = retryAfterOf(response!.headers);
        if (retryAfter > _maxRetryAfter) return null;
        return (
          kind: 'rateLimited',
          maxRetries: _idempotent.contains(method) ? 2 : 1,
          wait: (_) => retryAfter,
        );
      case 502 || 503 || 504 when method == 'GET':
        return (
          kind: 'gateway',
          maxRetries: _gatewayBackoff.length,
          wait: (attempt) => _gatewayBackoff[attempt],
        );
    }
    final transient = switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      _ => false,
    };
    if (transient && method == 'GET') {
      return (
        kind: 'network',
        maxRetries: _networkBackoff.length,
        wait: (attempt) => _networkBackoff[attempt],
      );
    }
    return null;
  }
}

typedef _Plan = ({
  String kind,
  int maxRetries,
  Duration Function(int attempt) wait,
});
