// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/config.dart';

/// The key under which [BaseUrlGuard] keeps the request's path relative to
/// the API root, for the log interceptor.
const apiPathExtra = 'soundspan.apiPath';

/// Interceptor 1: resolves a path relative to the API root against
/// `<baseUrl>/api` and refuses anything that would leave it.
class BaseUrlGuard extends Interceptor {
  /// Creates the guard for [config].
  new(this.config);

  /// The configuration whose base URL requests must stay under.
  final ApiConfig config;

  /// Resolves [path] (`/library/albums`) to `<baseUrl>/api<path>`.
  ///
  /// Throws [ArgumentError] when [path] is an absolute or scheme-relative
  /// URL, does not start with `/`, or resolves outside `<baseUrl>/api/`.
  Uri resolve(String path) {
    if (!path.startsWith('/') || path.startsWith('//')) {
      throw ArgumentError.value(path, 'path', 'must start with a single /');
    }
    final queryStart = path.indexOf('?');
    final rawPath = queryStart < 0 ? path : path.substring(0, queryStart);
    final query = queryStart < 0 ? null : path.substring(queryStart + 1);
    if (rawPath.contains('#') || rawPath.contains(':')) {
      throw ArgumentError.value(path, 'path', 'is not a path');
    }
    final apiRoot = '${config.baseUrl.path}/api';
    final resolved = _removeDotSegments('$apiRoot$rawPath');
    if (!resolved.startsWith('$apiRoot/')) {
      throw ArgumentError.value(path, 'path', 'leaves the API root');
    }
    return config.baseUrl.replace(path: resolved, query: query);
  }

  /// Removes `.` and `..` segments (RFC 3986, section 5.2.4), treating their
  /// percent-encoded forms the same way.
  static String _removeDotSegments(String path) {
    final out = <String>[];
    final segments = path.split('/');
    for (var i = 1; i < segments.length; i++) {
      final segment = segments[i].replaceAll(RegExp('%2[eE]'), '.');
      final last = i == segments.length - 1;
      if (segment == '.') {
        if (last) out.add('');
      } else if (segment == '..') {
        if (out.isNotEmpty) out.removeLast();
        if (last) out.add('');
      } else {
        out.add(segments[i]);
      }
    }
    return '/${out.join('/')}';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final resolved = resolve(options.path);
    options
      ..extra[apiPathExtra] = options.path.split('?').first
      ..baseUrl = ''
      ..path = resolved.toString();
    handler.next(options);
  }
}
