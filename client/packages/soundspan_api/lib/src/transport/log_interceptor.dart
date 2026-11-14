// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:soundspan_api/src/transport/base_url_guard.dart';

/// Receives one [ApiLogEntry] per finished request. The app logs it at
/// level `fine`.
typedef ApiLogSink = void Function(ApiLogEntry entry);

/// What is logged about one request: never headers, query values or bodies.
@immutable
final class ApiLogEntry {
  /// Creates an entry.
  const new({
    required this.method,
    required this.pathTemplate,
    required this.status,
    required this.duration,
  });

  /// The HTTP method.
  final String method;

  /// The path relative to the API root with every identifier replaced by
  /// `:id` (see [pathTemplate]).
  final String pathTemplate;

  /// The HTTP status, or null when no response arrived.
  final int? status;

  /// Time from sending to the response or failure.
  final Duration duration;

  @override
  String toString() =>
      '$method $pathTemplate ${status ?? '-'} ${duration.inMilliseconds}ms';
}

final _wordSegment = RegExp(r'^[a-z-]*$');

/// Replaces every segment of [path] that is not made only of lower-case
/// letters and hyphens with `:id`.
String pathTemplate(String path) => path
    .split('/')
    .map((segment) => _wordSegment.hasMatch(segment) ? segment : ':id')
    .join('/');

const _startExtra = 'soundspan.logStart';

/// Interceptor 6: reports method, path template, status and duration.
class ApiLogInterceptor extends Interceptor {
  /// Creates the interceptor; [now] defaults to [DateTime.now].
  new(this.sink, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Where entries go.
  final ApiLogSink sink;

  final DateTime Function() _now;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startExtra] = _now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _report(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _report(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _report(RequestOptions options, int? status) {
    final start = options.extra[_startExtra];
    final path = switch (options.extra[apiPathExtra]) {
      final String apiPath => apiPath,
      _ => Uri.parse(options.path).path,
    };
    sink(
      ApiLogEntry(
        method: options.method,
        pathTemplate: pathTemplate(path),
        status: status,
        duration: start is DateTime ? _now().difference(start) : Duration.zero,
      ),
    );
  }
}
