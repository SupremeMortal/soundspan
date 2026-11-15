// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
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

/// The request extra holding the spec's `operationId` of a call made through
/// the generated clients.
const operationIdExtra = 'soundspan.operationId';

/// The zone value through which [guardDecode] learns which request last
/// answered with a usable 2xx.
final _answeredKey = Object();

/// The response that last arrived inside one [guardDecode].
class _Answered {
  Response<dynamic>? response;
}

/// Notes that [response] is a usable 2xx, so a failure that follows inside
/// the enclosing [guardDecode] is a decode failure of its body. Called by
/// the Dio of `createDio` for every successful request.
void recordAnswered(Response<dynamic> response) {
  final answered = Zone.current[_answeredKey];
  if (answered is _Answered) answered.response = response;
}

/// Runs [call], which sends a request and decodes its 2xx body, and turns a
/// failure to decode into [InvalidResponse].
///
/// The [InvalidResponse] carries the status, the `operationId` of a call
/// made through the generated clients, and the failing key when the
/// decoder names it (a missing required key, a disallowed null, a checked
/// conversion); it never carries the payload. [ApiException]s pass through
/// unchanged, and so does the [ArgumentError] of the base-URL guard, which
/// is raised before any response arrives.
Future<T> guardDecode<T>(Future<T> Function() call) async {
  final answered = _Answered();
  try {
    return await runZoned(call, zoneValues: {_answeredKey: answered});
  } on Object catch (error, stackTrace) {
    if (error is ApiException) rethrow;
    final response = answered.response;
    if (response == null && error is ArgumentError) rethrow;
    Error.throwWithStackTrace(
      InvalidResponse(
        operationId: switch (response?.requestOptions.extra[operationIdExtra]) {
          final String id => id,
          _ => null,
        },
        key: _failingKey(error),
        status: response?.statusCode,
        serverMessage: error.runtimeType.toString(),
      ),
      stackTrace,
    );
  }
}

/// The key a json_serializable decode failure names, if any.
String? _failingKey(Object error) => switch (error) {
  MissingRequiredKeysException(:final missingKeys) => missingKeys.firstOrNull,
  DisallowedNullValueException(:final keysWithNullValues) =>
    keysWithNullValues.firstOrNull,
  CheckedFromJsonException(:final key) => key,
  _ => null,
};

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
