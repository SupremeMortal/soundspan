// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The HTTP status of a stream request, for a player whose error does not
/// carry one.
library;

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/transport/adapter.dart';

/// Asks the server which HTTP status a stream request gets.
///
/// A player engine calls it after a stream source failed and the player's
/// error named no HTTP status (Android, web), so a 404 and a 401 can still
/// be told apart.
final class StreamStatusProbe {
  /// Creates a probe with its own connection pool.
  new({Duration timeout = const Duration(seconds: 10)})
    : _dio = Dio(
        BaseOptions(
          connectTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (_) => true,
          responseType: ResponseType.bytes,
        ),
      )..httpClientAdapter = platformHttpClientAdapter();

  final Dio _dio;

  /// Requests the first byte of [uri] once with [headers] and returns the
  /// HTTP status, or null when no response arrived.
  Future<int?> status(Uri uri, {Map<String, String> headers = const {}}) async {
    try {
      final response = await _dio.getUri<List<int>>(
        uri,
        options: Options(headers: {...headers, 'Range': 'bytes=0-0'}),
      );
      return response.statusCode;
    } on DioException {
      return null;
    }
  }

  /// Closes the connection pool.
  void close() => _dio.close(force: true);
}
