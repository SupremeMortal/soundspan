// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support/session_harness.dart';

/// Answers the first [failures] requests with [failure], then 200.
Route failThen(int failures, Reply failure) {
  var count = 0;
  return (_) =>
      count++ < failures ? failure : const HttpReply(200, {'ok': true});
}

HttpReply tooMany(String? retryAfter, {Object? body = 'Too many requests'}) =>
    HttpReply(429, body, {'Retry-After': ?retryAfter});

Matcher within(double low, double high) => predicate<Duration>(
  (d) => d.inMicroseconds >= low * 1e6 && d.inMicroseconds <= high * 1e6,
  'a duration in [$low s, $high s]',
);

Future<Response<dynamic>> send(SessionHarness h, String method) =>
    h.dio.request<dynamic>('/library/albums', options: Options(method: method));

void main() {
  group('RetryInterceptor, 429', () {
    test(
      'GET + 429 Retry-After: 2 waits 2.0 to 2.4 s, retries and succeeds',
      () async {
        final h = SessionHarness(route: failThen(1, tooMany('2')));
        final response = await h.get();
        expect(response.data, {'ok': true});
        expect(h.delays, [within(2, 2.4)]);
        expect(h.server.requests, hasLength(2));
      },
    );

    test('GET + 429 three times: two retries, then RateLimited', () async {
      final h = SessionHarness(route: failThen(3, tooMany('1')));
      await expectLater(h.get(), throwsA(isA<RateLimited>()));
      expect(h.server.requests, hasLength(3));
      expect(h.delays, hasLength(2));
    });

    test('POST + 429: one retry, then RateLimited', () async {
      final h = SessionHarness(route: failThen(5, tooMany('1')));
      await expectLater(send(h, 'POST'), throwsA(isA<RateLimited>()));
      expect(h.server.requests, hasLength(2));
      expect(h.delays, hasLength(1));
    });

    test(
      '429 Retry-After: 120 surfaces RateLimited(120 s) without waiting',
      () async {
        final h = SessionHarness(route: failThen(5, tooMany('120')));
        await expectLater(
          h.get(),
          throwsA(
            isA<RateLimited>().having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 120),
            ),
          ),
        );
        expect(h.delays, isEmpty);
        expect(h.server.requests, hasLength(1));
      },
    );

    test('a missing Retry-After counts as 60 s', () async {
      final h = SessionHarness(route: failThen(1, tooMany(null)));
      await h.get();
      expect(h.delays, [within(60, 72)]);
    });

    test('429 with a JSON body is handled like a plain-text one', () async {
      final h = SessionHarness(
        route: failThen(1, tooMany('2', body: {'error': 'slow down'})),
      );
      await h.get();
      expect(h.delays, [within(2, 2.4)]);
    });

    for (final method in ['PUT', 'DELETE']) {
      test('$method + 429 gets two retries', () async {
        final h = SessionHarness(route: failThen(5, tooMany('1')));
        await expectLater(send(h, method), throwsA(isA<RateLimited>()));
        expect(h.server.requests, hasLength(3));
      });
    }
  });

  group('RetryInterceptor, 5xx', () {
    for (final status in [502, 503, 504]) {
      test('GET + $status backs off 0.5, 1, 2 s, then ServerError after the '
          'fourth response', () async {
        final h = SessionHarness(
          route: failThen(9, HttpReply(status, {'error': 'down'})),
        );
        await expectLater(h.get(), throwsA(isA<ServerError>()));
        expect(h.server.requests, hasLength(4));
        expect(h.delays, [within(0.5, 0.6), within(1, 1.2), within(2, 2.4)]);
      });

      test('GET + $status succeeds when a retry succeeds', () async {
        final h = SessionHarness(
          route: failThen(2, HttpReply(status, {'error': 'down'})),
        );
        expect((await h.get()).data, {'ok': true});
        expect(h.server.requests, hasLength(3));
      });
    }

    test('POST + 503 is not retried', () async {
      final h = SessionHarness(
        route: failThen(9, const HttpReply(503, {'error': 'down'})),
      );
      await expectLater(send(h, 'POST'), throwsA(isA<ServerError>()));
      expect(h.server.requests, hasLength(1));
      expect(h.delays, isEmpty);
    });

    test('500 is not retried', () async {
      final h = SessionHarness(
        route: failThen(9, const HttpReply(500, {'error': 'bug'})),
      );
      await expectLater(h.get(), throwsA(isA<ServerError>()));
      expect(h.server.requests, hasLength(1));
    });
  });

  group('RetryInterceptor, network', () {
    test('GET + connection error: two retries, then Offline', () async {
      final h = SessionHarness(route: failThen(9, const NetworkFailure()));
      await expectLater(h.get(), throwsA(isA<Offline>()));
      expect(h.server.requests, hasLength(3));
      expect(h.delays, [within(0.5, 0.6), within(1, 1.2)]);
    });

    test('GET + connection error succeeds when a retry succeeds', () async {
      final h = SessionHarness(route: failThen(1, const NetworkFailure()));
      expect((await h.get()).data, {'ok': true});
    });

    test('POST + connection error is not retried', () async {
      final h = SessionHarness(route: failThen(9, const NetworkFailure()));
      await expectLater(send(h, 'POST'), throwsA(isA<Offline>()));
      expect(h.server.requests, hasLength(1));
    });
  });

  group('RetryInterceptor, exclusions', () {
    test('extra noRetry suppresses every retry', () async {
      for (final failure in [
        tooMany('1'),
        const HttpReply(503, {'error': 'down'}),
        const NetworkFailure(),
      ]) {
        final h = SessionHarness(route: failThen(9, failure));
        await expectLater(
          h.dio.get<dynamic>(
            '/library/albums',
            options: Options(extra: {'noRetry': true}),
          ),
          throwsA(isA<ApiException>()),
        );
        expect(h.server.requests, hasLength(1));
        expect(h.delays, isEmpty);
      }
    });

    test('401 is not retried by this interceptor', () async {
      final h = SessionHarness(
        route: failThen(9, const HttpReply(401, {'error': 'no'})),
      );
      await expectLater(h.get(), throwsA(isA<Unauthenticated>()));
      expect(h.server.requests, hasLength(1));
      expect(h.delays, isEmpty);
    });

    test('a replay carries the current credential', () async {
      final creds = RecordingCredentials(const ApiKeyCredentials(apiKey: 'k1'));
      final h = SessionHarness(
        credentials: creds,
        route: (request) {
          creds.current = const ApiKeyCredentials(apiKey: 'k2');
          return request.headers['X-API-Key'] == 'k1'
              ? const HttpReply(503, {'error': 'down'})
              : const HttpReply(200, {'ok': true});
        },
      );
      await h.get();
      expect(h.server.requests.map((r) => r.headers['X-API-Key']), [
        'k1',
        'k2',
      ]);
    });

    test('a query string survives a replay', () async {
      final h = SessionHarness(
        route: failThen(1, const HttpReply(503, {'error': 'down'})),
      );
      await h.get('/library/albums?limit=5');
      expect(h.server.requests.map((r) => r.uri.toString()), [
        'https://h/api/library/albums?limit=5',
        'https://h/api/library/albums?limit=5',
      ]);
    });
  });
}
