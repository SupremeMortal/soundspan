// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:soundspan_api/src/transport/error_mapper.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

const Map<String, List<String>> _json = {
  Headers.contentTypeHeader: [Headers.jsonContentType],
};
const Map<String, List<String>> _text = {
  Headers.contentTypeHeader: ['text/plain; charset=utf-8'],
};
const Map<String, List<String>> _html = {
  Headers.contentTypeHeader: ['text/html'],
};
const _proxyPage = '<html><body><h1>502 Bad Gateway</h1></body></html>';

/// One row of the response table.
class _Case {
  const new(
    this.name,
    this.status,
    this.body,
    this.expected, {
    this.headers = _json,
    this.code,
  });

  final String name;
  final int status;
  final Object? body;
  final TypeMatcher<ApiException> expected;
  final Map<String, List<String>> headers;
  final String? code;
}

Future<ApiException> _failureOf(Harness h, String path) async {
  try {
    await h.dio.get<dynamic>(path);
  } on Object catch (error) {
    expect(error, isA<ApiException>(), reason: 'no DioException escapes');
    return error as ApiException;
  }
  fail('the request did not fail');
}

void main() {
  final cases = <_Case>[
    _Case(
      '401 is Unauthenticated carrying AUTH_REQUIRED',
      401,
      {'error': 'Not authenticated', 'code': 'AUTH_REQUIRED'},
      isA<Unauthenticated>(),
      code: 'AUTH_REQUIRED',
    ),
    _Case('403 is Forbidden', 403, {'error': 'Forbidden'}, isA<Forbidden>()),
    _Case('404 is NotFound', 404, {'error': 'Not found'}, isA<NotFound>()),
    _Case(
      '404 with FEATURE_DISABLED is FeatureDisabled',
      404,
      {'error': 'feature disabled', 'code': 'FEATURE_DISABLED'},
      isA<FeatureDisabled>(),
      code: 'FEATURE_DISABLED',
    ),
    _Case('409 is Conflict', 409, {'error': 'Conflict'}, isA<Conflict>()),
    _Case(
      '409 with SOURCE_UNAVAILABLE is SourceUnavailable',
      409,
      {'error': 'Source unavailable', 'code': 'SOURCE_UNAVAILABLE'},
      isA<SourceUnavailable>(),
      code: 'SOURCE_UNAVAILABLE',
    ),
    _Case(
      '409 with SOURCE_DOWNLOADS_DISABLED is DownloadsDisabled',
      409,
      {'error': 'Downloads disabled', 'code': 'SOURCE_DOWNLOADS_DISABLED'},
      isA<DownloadsDisabled>(),
      code: 'SOURCE_DOWNLOADS_DISABLED',
    ),
    _Case(
      '409 with an unknown code keeps Conflict and carries the code',
      409,
      {'error': 'Newer server', 'code': 'SOMETHING_NEW'},
      isA<Conflict>().having(
        (e) => e is SourceUnavailable,
        'subclass',
        isFalse,
      ),
      code: 'SOMETHING_NEW',
    ),
    _Case(
      '400 is InvalidRequest carrying METADATA_REQUIRED',
      400,
      {'error': 'Metadata required', 'code': 'METADATA_REQUIRED'},
      isA<InvalidRequest>(),
      code: 'METADATA_REQUIRED',
    ),
    _Case('422 with a JSON error is InvalidRequest', 422, {
      'error': 'Unprocessable',
    }, isA<InvalidRequest>()),
    _Case(
      '502 with UPSTREAM_FAILED is Upstream',
      502,
      {'error': 'Upstream failed', 'code': 'UPSTREAM_FAILED'},
      isA<Upstream>(),
      code: 'UPSTREAM_FAILED',
    ),
    _Case(
      '503 with AUTH_BACKEND_UNAVAILABLE is ServerError',
      503,
      {'error': 'Auth backend unavailable', 'code': 'AUTH_BACKEND_UNAVAILABLE'},
      isA<ServerError>(),
      code: 'AUTH_BACKEND_UNAVAILABLE',
    ),
    _Case('500 is ServerError', 500, {'error': 'Boom'}, isA<ServerError>()),
    const _Case(
      '502 with an HTML body is ServerError',
      502,
      _proxyPage,
      TypeMatcher<ServerError>(),
      headers: _html,
    ),
    const _Case(
      '404 with an HTML body is NotSoundspan',
      404,
      '<html><body>Not Found</body></html>',
      TypeMatcher<NotSoundspan>(),
      headers: _html,
    ),
    const _Case(
      '401 with a plain-text body is NotSoundspan',
      401,
      'Unauthorized',
      TypeMatcher<NotSoundspan>(),
      headers: _text,
    ),
    _Case('a 3xx is Unexpected', 304, {
      'error': 'Not modified',
    }, isA<Unexpected>()),
  ];

  group('ErrorMapper responses', () {
    for (final c in cases) {
      test(c.name, () async {
        final h = Harness();
        h.server.onGet(
          h.url('/x'),
          (s) => s.reply(c.status, c.body, headers: c.headers),
        );
        final error = await _failureOf(h, '/x');
        expect(error, c.expected);
        expect(error.status, c.status);
        expect(error.code, c.code);
      });
    }

    test(
      '409 with CACHE_LIMIT_EXCEEDED carries the three byte counts',
      () async {
        final h = Harness();
        h.server.onPost(
          h.url('/offline/items'),
          (s) => s.reply(409, {
            'error': 'Cache size limit exceeded',
            'code': 'CACHE_LIMIT_EXCEEDED',
            'cacheLimitBytes': 1000,
            'cacheUsedBytes': 900,
            'estimatedTotalBytes': 250,
          }),
        );
        try {
          await h.dio.post<dynamic>('/offline/items');
          fail('the request did not fail');
        } on CacheLimitExceeded catch (error) {
          expect(error, isA<Conflict>());
          expect(error.limitBytes, 1000);
          expect(error.usedBytes, 900);
          expect(error.estimatedBytes, 250);
          expect(error.code, 'CACHE_LIMIT_EXCEEDED');
        }
      },
    );

    test(
      '429 with a plain-text body and Retry-After: 7 is RateLimited(7 s)',
      () async {
        final h = Harness();
        h.server.onGet(
          h.url('/x'),
          (s) => s.reply(
            429,
            'Too many requests from this IP, please try again later.',
            headers: {
              ..._text,
              'retry-after': ['7'],
            },
          ),
        );
        final error = await _failureOf(h, '/x');
        expect(
          error,
          isA<RateLimited>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 7),
          ),
        );
        expect(error.status, 429);
      },
    );

    test('429 without Retry-After waits 60 s', () async {
      final h = Harness();
      h.server.onGet(
        h.url('/x'),
        (s) => s.reply(429, 'Too many requests', headers: _text),
      );
      expect(
        await _failureOf(h, '/x'),
        isA<RateLimited>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 60),
        ),
      );
    });

    test('200 with an HTML body is NotSoundspan', () async {
      final h = Harness();
      h.server.onGet(
        h.url('/x'),
        (s) => s.reply(200, '<html>login portal</html>', headers: _html),
      );
      expect(
        await _failureOf(h, '/x'),
        isA<NotSoundspan>().having((e) => e.status, 'status', 200),
      );
    });

    test('a 2xx with an empty body is not an error', () async {
      final h = Harness();
      h.server.onPost(h.url('/auth/logout'), (s) => s.reply(204, null));
      final response = await h.dio.post<dynamic>('/auth/logout');
      expect(response.statusCode, 204);
    });

    test("serverMessage holds the server's error string", () async {
      final h = Harness();
      h.server.onGet(h.url('/x'), (s) => s.reply(403, {'error': 'Admin only'}));
      expect((await _failureOf(h, '/x')).serverMessage, 'Admin only');
    });
  });

  group('ErrorMapper transport failures', () {
    final offline = <String, DioExceptionType>{
      'connection error': DioExceptionType.connectionError,
      'connect timeout': DioExceptionType.connectionTimeout,
      'send timeout': DioExceptionType.sendTimeout,
      'receive timeout': DioExceptionType.receiveTimeout,
      'bad certificate': DioExceptionType.badCertificate,
    };
    for (final entry in offline.entries) {
      test('${entry.key} is Offline', () async {
        final h = Harness();
        h.server.onGet(
          h.url('/x'),
          (s) => s.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: '/x'),
              type: entry.value,
            ),
          ),
        );
        final error = await _failureOf(h, '/x');
        expect(error, isA<Offline>());
        expect(error.status, isNull);
      });
    }

    test('an unclassifiable DioException is Unexpected', () {
      final error = mapDioException(
        DioException(requestOptions: RequestOptions(path: '/x')),
      );
      expect(error, isA<Unexpected>());
    });

    test('a cancelled request is Unexpected', () {
      final error = mapDioException(
        DioException.requestCancelled(
          requestOptions: RequestOptions(path: '/x'),
          reason: 'user',
        ),
      );
      expect(error, isA<Unexpected>());
    });

    test('a 2xx body that is not valid JSON is NotSoundspan', () {
      final error = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const FormatException('Unexpected character'),
        ),
      );
      expect(error, isA<NotSoundspan>());
    });

    test('an ApiException already mapped is kept', () {
      const mapped = Forbidden(status: 403);
      final error = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: mapped,
        ),
      );
      expect(error, same(mapped));
    });
  });

  group('guardDecode', () {
    test('a decode failure of a 2xx body is InvalidResponse', () async {
      final h = Harness();
      h.server.onGet(h.url('/auth/me'), (s) => s.reply(200, {'id': 7}));
      await expectLater(
        guardDecode(() async {
          final response = await h.dio.get<Map<String, dynamic>>('/auth/me');
          return response.data!['id']! as String;
        }),
        throwsA(isA<InvalidResponse>()),
      );
    });

    test('passes the decoded value and ApiExceptions through', () async {
      expect(await guardDecode(() async => 'ok'), 'ok');
      await expectLater(
        guardDecode<String>(() async => throw const NotFound(status: 404)),
        throwsA(isA<NotFound>()),
      );
    });

    test('passes a guard ArgumentError through', () async {
      await expectLater(
        guardDecode<String>(() async => throw ArgumentError('path')),
        throwsArgumentError,
      );
    });
  });

  test('every ApiException describes itself without its server message', () {
    const error = Forbidden(status: 403, code: 'X', serverMessage: 'secret');
    expect(error.toString(), 'Forbidden(status: 403, code: X)');
  });
}
