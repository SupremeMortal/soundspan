// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Answers every request with [status] and the JSON [body].
final class _FakeAdapter implements HttpClientAdapter {
  new(this.status, this.body);

  final int status;
  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Future<SchemaMismatchGuard> _fetchThroughGuard(int status, Object body) async {
  final guard = SchemaMismatchGuard(_FakeAdapter(status, body));
  final dio = Dio(BaseOptions(baseUrl: 'http://contract.test'))
    ..httpClientAdapter = guard;
  try {
    await dio.get<Object?>('/api/library/albums');
  } on DioException {
    // The guard records the mismatch; the status is the server's concern.
  }
  return guard;
}

void main() {
  group('SchemaMismatchGuard', () {
    test(
      'fails the test when a response carries RESPONSE_SCHEMA_MISMATCH',
      () async {
        final guard = await _fetchThroughGuard(500, {
          'error': 'Response does not match its schema',
          'code': 'RESPONSE_SCHEMA_MISMATCH',
        });

        expect(
          guard.verify,
          throwsA(
            isA<TestFailure>().having(
              (failure) => failure.message,
              'message',
              allOf(
                contains('RESPONSE_SCHEMA_MISMATCH'),
                contains('GET /api/library/albums'),
              ),
            ),
          ),
        );
      },
    );

    test('passes when responses carry another code or none', () async {
      final ok = await _fetchThroughGuard(200, {'albums': <Object?>[]});
      final conflict = await _fetchThroughGuard(409, {
        'error': 'TIDAL streaming is not available',
        'code': 'SOURCE_UNAVAILABLE',
      });

      expect(ok.verify, returnsNormally);
      expect(conflict.verify, returnsNormally);
    });

    test('passes the response body through unchanged', () async {
      final guard = SchemaMismatchGuard(_FakeAdapter(200, {'status': 'ok'}));
      final dio = Dio(BaseOptions(baseUrl: 'http://contract.test'))
        ..httpClientAdapter = guard;

      final response = await dio.get<Map<String, Object?>>('/api/health');

      expect(response.data, {'status': 'ok'});
    });
  });
}
