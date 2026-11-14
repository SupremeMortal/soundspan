// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/errors.dart';

/// The wait used when a 429 carries no usable `Retry-After`.
const _defaultRetryAfter = Duration(seconds: 60);

/// Interceptor 5: turns every non-2xx response and every [DioException] into
/// an [ApiException], carried as the [DioException.error] that the Dio of
/// `createDio` rethrows.
class ErrorMapper extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (response.requestOptions.responseType == ResponseType.json &&
        _isNonEmptyText(response.data)) {
      final error = NotSoundspan(status: response.statusCode);
      handler.reject(
        DioException.badResponse(
          statusCode: response.statusCode ?? 0,
          requestOptions: response.requestOptions,
          response: response,
        ).copyWith(error: error, message: error.toString()),
        true,
      );
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is Error) {
      // A programming error, such as the guard's ArgumentError, is not a
      // server failure and reaches the caller unchanged.
      handler.next(err);
      return;
    }
    final error = mapDioException(err);
    handler.next(err.copyWith(error: error, message: error.toString()));
  }
}

/// Classifies [error] as an [ApiException].
ApiException mapDioException(DioException error) {
  final cause = error.error;
  if (cause is ApiException) return cause;
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.badCertificate:
      return const Offline();
    case DioExceptionType.badResponse:
      final response = error.response;
      if (response != null) return mapResponse(response);
      return const Unexpected();
    case DioExceptionType.unknown:
      if (cause is FormatException) return const NotSoundspan();
      return const Unexpected();
    case DioExceptionType.cancel:
    case DioExceptionType.transformTimeout:
      return const Unexpected();
  }
}

/// Classifies a response that is not a usable 2xx.
ApiException mapResponse(Response<dynamic> response) {
  final status = response.statusCode ?? 0;
  final body = _ErrorBody.parse(response.data);
  final code = body?.code;
  final message = body?.error;

  if (status == 429) {
    return RateLimited(
      retryAfter: retryAfterOf(response.headers),
      status: status,
      code: code,
      serverMessage: message,
    );
  }
  if (status >= 500 && status <= 599) {
    if (code == 'UPSTREAM_FAILED' && status >= 502 && status <= 504) {
      return Upstream(status: status, code: code, serverMessage: message);
    }
    return ServerError(status: status, code: code, serverMessage: message);
  }
  if (status >= 200 && status <= 299) return NotSoundspan(status: status);
  if (status < 400 || status > 499) return Unexpected(status: status);
  if (body == null) return NotSoundspan(status: status);

  return switch ((status, code)) {
    (401, _) => Unauthenticated(
      status: status,
      code: code,
      serverMessage: message,
    ),
    (403, _) => Forbidden(status: status, code: code, serverMessage: message),
    (404, 'FEATURE_DISABLED') => FeatureDisabled(
      status: status,
      code: code,
      serverMessage: message,
    ),
    (404, _) => NotFound(status: status, code: code, serverMessage: message),
    (409, 'SOURCE_UNAVAILABLE') => SourceUnavailable(
      status: status,
      code: code,
      serverMessage: message,
    ),
    (409, 'SOURCE_DOWNLOADS_DISABLED') => DownloadsDisabled(
      status: status,
      code: code,
      serverMessage: message,
    ),
    (409, 'CACHE_LIMIT_EXCEEDED') => CacheLimitExceeded(
      limitBytes: body.integer('cacheLimitBytes'),
      usedBytes: body.integer('cacheUsedBytes'),
      estimatedBytes: body.integer('estimatedTotalBytes'),
      status: status,
      code: code,
      serverMessage: message,
    ),
    (409, _) => Conflict(status: status, code: code, serverMessage: message),
    _ => InvalidRequest(status: status, code: code, serverMessage: message),
  };
}

/// Runs [call], which sends a request and decodes its 2xx body, and turns a
/// failure to decode into [InvalidResponse].
///
/// [ApiException]s and the [ArgumentError] of the base-URL guard pass
/// through unchanged.
Future<T> guardDecode<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on Object catch (error, stackTrace) {
    if (error is ApiException || error is ArgumentError) rethrow;
    Error.throwWithStackTrace(
      InvalidResponse(serverMessage: error.runtimeType.toString()),
      stackTrace,
    );
  }
}

bool _isNonEmptyText(Object? data) => data is String && data.trim().isNotEmpty;

/// The `Retry-After` of a 429, in seconds; 60 s when it is missing or
/// unparseable.
Duration retryAfterOf(Headers headers) {
  final seconds = int.tryParse(headers.value('retry-after')?.trim() ?? '');
  if (seconds == null || seconds < 0) return _defaultRetryAfter;
  return Duration(seconds: seconds);
}

/// A JSON `{ error, code?, ... }` body.
class _ErrorBody {
  new(this.json);

  /// Returns the body when [data] has the `{ error }` shape, else null.
  static _ErrorBody? parse(Object? data) {
    var value = data;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        return null;
      }
    }
    if (value is Map<String, dynamic> && value['error'] is String) {
      return _ErrorBody(value);
    }
    return null;
  }

  final Map<String, dynamic> json;

  String get error => json['error']! as String;

  String? get code => switch (json['code']) {
    final String code => code,
    _ => null,
  };

  int integer(String key) => switch (json[key]) {
    final num value => value.toInt(),
    _ => 0,
  };
}
