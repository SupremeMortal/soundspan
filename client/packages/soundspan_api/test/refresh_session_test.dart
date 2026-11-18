// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support/session_harness.dart';

const _refreshPath = '/api/auth/refresh';
const _rotated = JwtCredentials(
  accessToken: 'opaque-new',
  refreshToken: 'rt-new',
);

SoundspanApi _api(ScriptedServer server, CredentialProvider provider) =>
    SoundspanApi(
      ApiConfig(baseUrl: Uri.parse('https://h'), userAgent: 'ua'),
      credentials: provider,
      adapter: server,
    );

RecordingCredentials _session() => RecordingCredentials(
  const JwtCredentials(accessToken: 'opaque-old', refreshToken: 'rt-old'),
);

void main() {
  group('SoundspanApi.refreshSession', () {
    test('renews the session, stores the new pair and returns it', () async {
      final server = ScriptedServer(
        (_) => const HttpReply(200, {
          'token': 'opaque-new',
          'refreshToken': 'rt-new',
        }),
      );
      final provider = _session();
      final next = await _api(server, provider).refreshSession();
      expect(next.accessToken, _rotated.accessToken);
      expect(next.refreshToken, _rotated.refreshToken);
      expect(provider.events, ['rotated:opaque-new']);
      expect(server.requests.single.uri.path, _refreshPath);
      expect(server.requests.single.data, {'refreshToken': 'rt-old'});
    });

    test('two concurrent calls send one refresh request', () async {
      final gate = Completer<void>();
      final server = ScriptedServer((_) async {
        await gate.future;
        return const HttpReply(200, {
          'token': 'opaque-new',
          'refreshToken': 'rt-new',
        });
      });
      final provider = _session();
      final api = _api(server, provider);
      final first = api.refreshSession();
      final second = api.refreshSession();
      gate.complete();
      final results = await Future.wait([first, second]);
      expect(results.map((c) => c.accessToken), ['opaque-new', 'opaque-new']);
      expect(server.to('/auth/refresh'), hasLength(1));
      expect(provider.events, ['rotated:opaque-new']);
    });

    test(
      'a call made while a 401 is being handled joins its refresh',
      () async {
        final gate = Completer<void>();
        final server = ScriptedServer((request) async {
          if (request.uri.path == _refreshPath) {
            await gate.future;
            return const HttpReply(200, {
              'token': 'opaque-new',
              'refreshToken': 'rt-new',
            });
          }
          if (request.headers['Authorization'] == 'Bearer opaque-new') {
            return const HttpReply(200, []);
          }
          return const HttpReply(401, {
            'error': 'Not authenticated',
            'code': 'AUTH_REQUIRED',
          });
        });
        final provider = _session();
        final api = _api(server, provider);
        final request = api.rest.session
            .getCurrentUser()
            .then<Object?>((u) => u)
            .catchError((Object _) => null);
        while (server.to('/auth/refresh').isEmpty) {
          await Future<void>.delayed(Duration.zero);
        }
        final refreshed = api.refreshSession();
        gate.complete();
        expect((await refreshed).accessToken, 'opaque-new');
        await request;
        expect(server.to('/auth/refresh'), hasLength(1));
        expect(provider.events, ['rotated:opaque-new']);
      },
    );

    test('a rejected refresh ends the session and throws Unauthenticated', () {
      final server = ScriptedServer(
        (_) => const HttpReply(401, {'error': 'Invalid refresh token'}),
      );
      final provider = _session();
      expect(
        _api(server, provider).refreshSession(),
        throwsA(isA<Unauthenticated>()),
      );
      addTearDown(
        () => expect(provider.events, ['unauthenticated:sessionExpired']),
      );
    });

    test('a refresh failing on the network throws Offline and keeps the '
        'session', () async {
      final server = ScriptedServer((_) => const NetworkFailure());
      final provider = _session();
      await expectLater(
        _api(server, provider).refreshSession(),
        throwsA(isA<Offline>()),
      );
      expect(provider.events, isEmpty);
    });

    test('an API key session throws Unauthenticated without a request', () {
      final server = ScriptedServer((_) => const HttpReply(200, {}));
      final api = _api(
        server,
        RecordingCredentials(const ApiKeyCredentials(apiKey: 'k')),
      );
      expect(api.refreshSession(), throwsA(isA<Unauthenticated>()));
      addTearDown(() => expect(server.requests, isEmpty));
    });
  });
}
