// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support/session_harness.dart';

final String oldAccess = jwt(iat: 0, exp: 100000, tag: 'old');
final String newAccess = jwt(iat: 0, exp: 200000, tag: 'new');
const refreshPath = '/api/auth/refresh';

RecordingCredentials session([String? access]) => RecordingCredentials(
  JwtCredentials(accessToken: access ?? oldAccess, refreshToken: 'rt-old'),
);

/// Answers a refresh with [newAccess]; answers other requests with 200 when
/// they carry [newAccess] and with [stale] otherwise.
Route server({
  HttpReply stale = const HttpReply(401, {
    'error': 'Not authenticated',
    'code': 'AUTH_REQUIRED',
  }),
  FutureOr<Reply> Function()? refresh,
}) => (request) {
  if (request.uri.path == refreshPath) {
    return refresh?.call() ??
        HttpReply(200, {'token': newAccess, 'refreshToken': 'rt-new'});
  }
  if (bearerOf(request) == 'Bearer $newAccess') {
    return const HttpReply(200, {'ok': true});
  }
  return stale;
};

void main() {
  group('RefreshInterceptor, proactive', () {
    test('a token at 79 % of its lifetime is sent without refresh', () async {
      final h = SessionHarness(
        credentials: session(),
        nowSeconds: 79000,
        route: (_) => const HttpReply(200, {'ok': true}),
      );
      await h.get();
      expect(h.server.to('/auth/refresh'), isEmpty);
      expect(bearerOf(h.server.requests.single), 'Bearer $oldAccess');
    });

    test('a token at 81 % of its lifetime is refreshed first and the request '
        'carries the new token', () async {
      final creds = session();
      final h = SessionHarness(
        credentials: creds,
        nowSeconds: 81000,
        route: server(),
      );
      final response = await h.get();
      expect(response.data, {'ok': true});
      expect(h.server.requests.map((r) => r.uri.path), [
        refreshPath,
        '/api/library/albums',
      ]);
      expect(bearerOf(h.server.requests.last), 'Bearer $newAccess');
      expect(creds.events, ['rotated:$newAccess']);
    });

    test('an undecodable token is sent as is', () async {
      final h = SessionHarness(
        credentials: session('not-a-jwt'),
        nowSeconds: 999999,
        route: (_) => const HttpReply(200, {'ok': true}),
      );
      await h.get();
      expect(h.server.to('/auth/refresh'), isEmpty);
      expect(bearerOf(h.server.requests.single), 'Bearer not-a-jwt');
    });

    test('a token without iat or exp is sent as is', () async {
      final h = SessionHarness(
        credentials: session(jwt(exp: 10)),
        nowSeconds: 999999,
        route: (_) => const HttpReply(200, {'ok': true}),
      );
      await h.get();
      expect(h.server.to('/auth/refresh'), isEmpty);
    });
  });

  group('RefreshInterceptor, reactive', () {
    test('401 AUTH_REQUIRED causes one refresh and one replay with the new '
        'token, and the caller gets the replay response', () async {
      final h = SessionHarness(credentials: session(), route: server());
      final response = await h.get();
      expect(response.data, {'ok': true});
      expect(h.server.to('/auth/refresh'), hasLength(1));
      final albums = h.server.to('/library/albums');
      expect(albums.map(bearerOf), ['Bearer $oldAccess', 'Bearer $newAccess']);
    });

    test('a 401 without a code behaves the same', () async {
      final h = SessionHarness(
        credentials: session(),
        route: server(stale: const HttpReply(401, {'error': 'nope'})),
      );
      final response = await h.get();
      expect(response.data, {'ok': true});
      expect(h.server.to('/auth/refresh'), hasLength(1));
    });

    test('a 401 with another code is not refreshed', () async {
      final h = SessionHarness(
        credentials: session(),
        route: server(
          stale: const HttpReply(401, {'error': 'x', 'code': 'OTHER'}),
        ),
      );
      await expectLater(h.get(), throwsA(isA<Unauthenticated>()));
      expect(h.server.to('/auth/refresh'), isEmpty);
    });

    test(
      'a second 401 on the replay is Unauthenticated, with no second refresh',
      () async {
        final creds = session();
        final h = SessionHarness(
          credentials: creds,
          route: (request) => request.uri.path == refreshPath
              ? HttpReply(200, {'token': newAccess, 'refreshToken': 'rt-new'})
              : const HttpReply(401, {'error': 'no', 'code': 'AUTH_REQUIRED'}),
        );
        await expectLater(h.get(), throwsA(isA<Unauthenticated>()));
        expect(h.server.to('/auth/refresh'), hasLength(1));
        expect(h.server.to('/library/albums'), hasLength(2));
        expect(creds.events, ['rotated:$newAccess']);
      },
    );

    test(
      'five concurrent requests that all get 401 cause exactly one refresh',
      () async {
        final gate = Completer<void>();
        final h = SessionHarness(
          credentials: session(),
          route: server(
            refresh: () async {
              await gate.future;
              return HttpReply(200, {
                'token': newAccess,
                'refreshToken': 'rt-new',
              });
            },
          ),
        );
        final calls = [for (var i = 0; i < 5; i++) h.get()];
        await pumpEventQueue();
        gate.complete();
        final responses = await Future.wait(calls);
        expect(responses.map((r) => r.data), everyElement({'ok': true}));
        expect(h.server.to('/auth/refresh'), hasLength(1));
      },
    );

    test('a request built with the stale token that gets 401 after another '
        'request refreshed is replayed without a refresh call', () async {
      final creds = session();
      final staleAnswer = Completer<Reply>();
      final h = SessionHarness(
        credentials: creds,
        route: (request) {
          if (request.uri.path == '/api/slow' &&
              bearerOf(request) == 'Bearer $oldAccess') {
            return staleAnswer.future;
          }
          return server()(request);
        },
      );
      final slow = h.get('/slow');
      await pumpEventQueue();
      await h.get();
      expect(h.server.to('/auth/refresh'), hasLength(1));
      staleAnswer.complete(
        const HttpReply(401, {'error': 'x', 'code': 'AUTH_REQUIRED'}),
      );
      expect((await slow).data, {'ok': true});
      expect(h.server.to('/auth/refresh'), hasLength(1));
      expect(h.server.to('/slow').map(bearerOf), [
        'Bearer $oldAccess',
        'Bearer $newAccess',
      ]);
    });

    test('onTokensRotated completes before the replay is sent', () async {
      final order = <String>[];
      final creds = session()..rotationGate = Completer<void>();
      final h = SessionHarness(
        credentials: creds,
        route: (request) {
          order.add('send:${request.uri.path}');
          return server()(request);
        },
      );
      final call = h.get();
      await pumpEventQueue();
      order.add('persisted');
      creds.rotationGate!.complete();
      await call;
      expect(order, [
        'send:/api/library/albums',
        'send:$refreshPath',
        'persisted',
        'send:/api/library/albums',
      ]);
    });

    test(
      'the refresh request is anonymous and sends the refresh token',
      () async {
        final h = SessionHarness(credentials: session(), route: server());
        await h.get();
        final refresh = h.server.to('/auth/refresh').single;
        expect(refresh.method, 'POST');
        expect(refresh.headers.containsKey('Authorization'), isFalse);
        expect(refresh.headers.containsKey('X-API-Key'), isFalse);
        expect(refresh.data, {'refreshToken': 'rt-old'});
      },
    );
  });

  group('RefreshInterceptor, refresh failures', () {
    for (final message in [
      'Invalid refresh token',
      'User not found',
      'Token invalidated',
    ]) {
      test('refresh answering 401 "$message" ends the session once and every '
          'waiter fails with Unauthenticated', () async {
        final creds = session();
        final h = SessionHarness(
          credentials: creds,
          route: server(refresh: () => HttpReply(401, {'error': message})),
        );
        final calls = [
          for (var i = 0; i < 3; i++)
            expectLater(h.get(), throwsA(isA<Unauthenticated>())),
        ];
        await Future.wait(calls);
        expect(creds.events, ['unauthenticated:sessionExpired']);
        expect(h.server.to('/auth/refresh'), hasLength(1));
      });
    }

    test(
      'refresh answering 503 AUTH_BACKEND_UNAVAILABLE fails waiters with '
      'ServerError, keeps the session, and a later request refreshes again',
      () async {
        final creds = session();
        final h = SessionHarness(
          credentials: creds,
          route: server(
            refresh: () => const HttpReply(503, {
              'error': 'Authentication backend unavailable',
              'code': 'AUTH_BACKEND_UNAVAILABLE',
            }),
          ),
        );
        await expectLater(h.get(), throwsA(isA<ServerError>()));
        expect(creds.events, isEmpty);
        await expectLater(h.get(), throwsA(isA<ServerError>()));
        expect(h.server.to('/auth/refresh'), hasLength(2));
        expect(h.delays, isEmpty, reason: 'the refresh call is never retried');
      },
    );

    test('refresh failing on the network fails waiters with Offline and keeps '
        'the session', () async {
      final creds = session();
      final h = SessionHarness(
        credentials: creds,
        route: server(refresh: () => const NetworkFailure()),
      );
      await expectLater(h.get(), throwsA(isA<Offline>()));
      expect(creds.events, isEmpty);
      expect(creds.current, isA<JwtCredentials>());
    });

    test('a proactive refresh failure fails the request', () async {
      final h = SessionHarness(
        credentials: session(),
        nowSeconds: 90000,
        route: server(refresh: () => const NetworkFailure()),
      );
      await expectLater(h.get(), throwsA(isA<Offline>()));
      expect(h.server.to('/library/albums'), isEmpty);
    });
  });

  group('RefreshInterceptor, other credentials', () {
    test('API key + 401 calls onUnauthenticated(keyRejected) once, with no '
        'refresh', () async {
      final creds = RecordingCredentials(const ApiKeyCredentials(apiKey: 'k'));
      final h = SessionHarness(credentials: creds, route: server());
      await expectLater(h.get(), throwsA(isA<Unauthenticated>()));
      expect(creds.events, ['unauthenticated:keyRejected']);
      expect(h.server.to('/auth/refresh'), isEmpty);
    });

    test('an anonymous request that gets 401 is Unauthenticated, with no '
        'refresh', () async {
      final creds = session();
      final h = SessionHarness(credentials: creds, route: server());
      await expectLater(
        h.dio.get<dynamic>(
          '/auth/me',
          options: Options(extra: {'anonymous': true}),
        ),
        throwsA(isA<Unauthenticated>()),
      );
      expect(h.server.to('/auth/refresh'), isEmpty);
      expect(creds.events, isEmpty);
    });

    test('a request with no credential that gets 401 is Unauthenticated, with '
        'no refresh', () async {
      final h = SessionHarness(
        credentials: RecordingCredentials(null),
        route: server(),
      );
      await expectLater(h.get(), throwsA(isA<Unauthenticated>()));
      expect(h.server.to('/auth/refresh'), isEmpty);
    });
  });
}
