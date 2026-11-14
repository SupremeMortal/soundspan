// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/config.dart';
import 'package:soundspan_api/src/errors.dart';
import 'package:soundspan_api/src/transport/adapter.dart';
import 'package:soundspan_api/src/transport/base_url_guard.dart';
import 'package:soundspan_api/src/transport/credential_interceptor.dart';
import 'package:soundspan_api/src/transport/error_mapper.dart';
import 'package:soundspan_api/src/transport/log_interceptor.dart';
import 'package:soundspan_api/src/transport/refresh_interceptor.dart';
import 'package:soundspan_api/src/transport/retry_interceptor.dart';

/// Builds the one Dio of a SoundspanApi. Interceptor order is fixed here.
///
/// The order is: base-URL guard, credential, refresh, retry, error mapper,
/// log. With [credentials] null every request is anonymous. A failed
/// request throws its [ApiException]; a path the guard refuses throws its
/// [ArgumentError].
///
/// [now] is the clock of token-age checks and logged durations, [delay]
/// waits out retry backoff, and [random] draws its jitter; tests replace
/// them so nothing sleeps.
Dio createDio(
  ApiConfig config, {
  CredentialProvider? credentials,
  ApiLogSink? log,
  HttpClientAdapter? adapter,
  DateTime Function()? now,
  Future<void> Function(Duration)? delay,
  Random? random,
}) {
  final dio = _ApiDio(
    BaseOptions(
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
    ),
  )..httpClientAdapter = adapter ?? platformHttpClientAdapter();
  dio.interceptors.addAll([
    BaseUrlGuard(config),
    CredentialInterceptor(config, credentials),
    RefreshInterceptor(
      dio: dio,
      config: config,
      credentials: credentials,
      now: now,
    ),
    RetryInterceptor(dio: dio, delay: delay, random: random),
    ErrorMapper(),
    ApiLogInterceptor(log ?? _discard, now: now),
  ]);
  return dio;
}

void _discard(ApiLogEntry entry) {}

/// A Dio that throws the [ApiException] (or guard [ArgumentError]) carried
/// by a failed request instead of the [DioException] wrapping it.
class _ApiDio extends DioMixin {
  new(BaseOptions options) {
    this.options = options;
  }

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) async {
    try {
      return await super.fetch<T>(requestOptions);
    } on DioException catch (error) {
      final cause = error.error;
      if (cause is Error) Error.throwWithStackTrace(cause, error.stackTrace);
      Error.throwWithStackTrace(mapDioException(error), error.stackTrace);
    }
  }

  @override
  Dio clone({
    BaseOptions? options,
    Interceptors? interceptors,
    HttpClientAdapter? httpClientAdapter,
    Transformer? transformer,
  }) {
    final clone = _ApiDio(options ?? this.options.copyWith())
      ..httpClientAdapter = httpClientAdapter ?? this.httpClientAdapter
      ..transformer = transformer ?? this.transformer;
    clone.interceptors.addAll(interceptors ?? this.interceptors);
    return clone;
  }
}
