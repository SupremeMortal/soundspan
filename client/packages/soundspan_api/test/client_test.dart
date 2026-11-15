// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support/session_harness.dart';

const Map<String, Object?> _health = {
  'status': 'ok',
  'draining': false,
  'startupComplete': true,
  'role': 'all',
  'uptimeSeconds': 12,
  'version': '2.6.1',
};

const Map<String, Object?> _user = {
  'id': 'u1',
  'username': 'alice',
  'displayName': 'Alice',
  'role': 'admin',
};

Map<String, Object?> _track({bool withPlaybackId = true}) => {
  'id': 't1',
  'title': 'Song',
  'duration': 180,
  'trackNo': 1,
  'album': {'id': 'a1', 'title': 'Album', 'coverArt': null},
  'source': 'local',
  if (withPlaybackId) 'playbackId': 'p1',
};

/// An API over [server] whose provider holds [credentials].
SoundspanApi _api(
  ScriptedServer server, {
  Credentials? credentials,
  RecordingCredentials? provider,
  String base = 'https://h',
}) => SoundspanApi(
  ApiConfig(baseUrl: Uri.parse(base), userAgent: 'soundspan-client/1 (test)'),
  credentials: provider ?? RecordingCredentials(credentials),
  adapter: server,
);

const _jwt = JwtCredentials(accessToken: 'opaque-a', refreshToken: 'rt-a');
const _key = ApiKeyCredentials(apiKey: 'key-1');

void main() {
  group('SoundspanApi', () {
    test('health on the anonymous API requests <base>/api/health with no '
        'credential and decodes it', () async {
      final server = ScriptedServer((_) => const HttpReply(200, _health));
      final api = SoundspanApi.anonymous(
        Uri.parse('https://h'),
        adapter: server,
      );
      final health = await api.rest.session.getHealth();
      expect(health.status, 'ok');
      expect(health.draining, isFalse);
      expect(health.startupComplete, isTrue);
      final sent = server.requests.single;
      expect(sent.uri.toString(), 'https://h/api/health');
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(sent.headers.containsKey('X-API-Key'), isFalse);
    });

    test('the anonymous API takes connect and receive timeouts', () {
      final api = SoundspanApi.anonymous(
        Uri.parse('https://h'),
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 5),
      );
      addTearDown(api.close);
      expect(api.config.connectTimeout, const Duration(seconds: 4));
      expect(api.config.receiveTimeout, const Duration(seconds: 5));
    });

    test('a base with a path prefix keeps it', () async {
      final server = ScriptedServer((_) => const HttpReply(200, _health));
      final api = SoundspanApi.anonymous(
        Uri.parse('https://h/soundspan'),
        adapter: server,
      );
      await api.rest.session.getHealth();
      expect(
        server.requests.single.uri.toString(),
        'https://h/soundspan/api/health',
      );
    });

    test('login decodes the token response', () async {
      final server = ScriptedServer(
        (_) => const HttpReply(200, {
          'token': 'jwt',
          'refreshToken': 'rt',
          'user': _user,
        }),
      );
      final result = await _api(server).rest.session.login(
        body: const LoginRequest(username: 'alice', password: 'pw'),
      );
      final tokens = result as LoginTokenResponse;
      expect(tokens.token, 'jwt');
      expect(tokens.refreshToken, 'rt');
      expect(tokens.user.id, 'u1');
      expect(tokens.user.username, 'alice');
      expect(tokens.user.displayName, 'Alice');
      expect(tokens.user.role, LoginUserRole.admin);
    });

    test('login decodes the second-factor challenge', () async {
      final server = ScriptedServer(
        (_) => const HttpReply(200, {
          'requires2FA': true,
          'message': '2FA token required',
        }),
      );
      final result = await _api(server).rest.session.login(
        body: const LoginRequest(username: 'alice', password: 'pw'),
      );
      expect(result, isA<LoginTwoFactorChallenge>());
    });

    test('login and refresh carry no credential while one is held', () async {
      final server = ScriptedServer((request) {
        if (request.uri.path == '/api/auth/refresh') {
          return const HttpReply(200, {'token': 't', 'refreshToken': 'r'});
        }
        return const HttpReply(200, {'requires2FA': true, 'message': 'm'});
      });
      for (final credentials in [_jwt, _key]) {
        server.requests.clear();
        final api = _api(server, credentials: credentials);
        await api.rest.session.login(
          body: const LoginRequest(username: 'a', password: 'b'),
        );
        await api.rest.session.refreshSession(
          body: const RefreshSessionRequest(refreshToken: 'rt'),
        );
        for (final sent in server.requests) {
          expect(sent.headers.containsKey('Authorization'), isFalse);
          expect(sent.headers.containsKey('X-API-Key'), isFalse);
        }
        expect(server.requests, hasLength(2));
      }
    });

    test('me sends a bearer token for JWTs and X-API-Key for keys', () async {
      final server = ScriptedServer((_) => const HttpReply(200, _user));
      await _api(server, credentials: _jwt).rest.session.getCurrentUser();
      expect(server.requests.last.headers['Authorization'], 'Bearer opaque-a');
      await _api(server, credentials: _key).rest.session.getCurrentUser();
      expect(server.requests.last.headers['X-API-Key'], 'key-1');
      expect(
        server.requests.last.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('a 401 on me refreshes once and replays', () async {
      final provider = RecordingCredentials(_jwt);
      final server = ScriptedServer((request) {
        if (request.uri.path == '/api/auth/refresh') {
          return const HttpReply(200, {
            'token': 'opaque-b',
            'refreshToken': 'rt-b',
          });
        }
        if (request.headers['Authorization'] == 'Bearer opaque-b') {
          return const HttpReply(200, _user);
        }
        return const HttpReply(401, {
          'error': 'Not authenticated',
          'code': 'AUTH_REQUIRED',
        });
      });
      final user = await _api(
        server,
        provider: provider,
      ).rest.session.getCurrentUser();
      expect(user.username, 'alice');
      expect(server.to('/auth/refresh'), hasLength(1));
      expect(server.to('/auth/me'), hasLength(2));
      expect(provider.events, ['rotated:opaque-b']);
    });

    test('a 404 FEATURE_DISABLED from a generated call is '
        'FeatureDisabled', () async {
      final server = ScriptedServer(
        (_) => const HttpReply(404, {
          'error': 'feature disabled',
          'code': 'FEATURE_DISABLED',
        }),
      );
      await expectLater(
        _api(server, credentials: _jwt).rest.discovery.listMixes(),
        throwsA(isA<FeatureDisabled>()),
      );
    });

    test('a 200 without a required key is InvalidResponse naming the '
        'operation and key, never the payload', () async {
      final server = ScriptedServer(
        (_) => const HttpReply(200, {
          'id': 'u1',
          'displayName': 'secret-display-name',
          'role': 'user',
        }),
      );
      final api = _api(server, credentials: _jwt);
      final error = await api
          .send((rest) => rest.session.getCurrentUser())
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(error, isA<InvalidResponse>());
      final invalid = error! as InvalidResponse;
      expect(invalid.operationId, 'getCurrentUser');
      expect(invalid.key, 'username');
      expect(invalid.status, 200);
      expect(invalid.toString(), isNot(contains('secret-display-name')));
      expect('${invalid.serverMessage}', isNot(contains('secret')));
    });

    test('a decode failure on a path with a parameter names its '
        'operation', () async {
      final server = ScriptedServer((_) => const HttpReply(200, {'id': 1}));
      final api = _api(server, credentials: _jwt);
      await expectLater(
        api.send((rest) => rest.library2.getAlbum(id: 'a1')),
        throwsA(
          isA<InvalidResponse>().having(
            (e) => e.operationId,
            'operationId',
            'getAlbum',
          ),
        ),
      );
    });

    test('an unknown key decodes and an unknown enum value is '
        'Unknown', () async {
      final server = ScriptedServer(
        (_) => HttpReply(
          200,
          Map.of(_health)
            ..['role'] = 'conductor'
            ..['addedByNewerServer'] = 1,
        ),
      );
      final health = await SoundspanApi.anonymous(
        Uri.parse('https://h'),
        adapter: server,
      ).rest.session.getHealth();
      expect(
        health.role,
        isA<HealthStatusRoleUnknown>().having(
          (r) => r.rawValue,
          'rawValue',
          'conductor',
        ),
      );
      expect(health.additionalProperties, {'addedByNewerServer': 1});
    });

    test('an absent optional key decodes as null', () async {
      final server = ScriptedServer(
        (_) => HttpReply(200, {
          'tracks': [_track(withPlaybackId: false), _track()],
          'total': 2,
          'offset': 0,
          'limit': 100,
        }),
      );
      final page = await _api(
        server,
        credentials: _jwt,
      ).rest.library2.listTracks();
      expect(page.tracks.first.playbackId, isNull);
      expect(page.tracks.last.playbackId, 'p1');
    });

    test('close closes the adapter', () {
      final server = _ClosingServer();
      final api = SoundspanApi.anonymous(
        Uri.parse('https://h'),
        adapter: server,
      )..close();
      expect(api.config.baseUrl, Uri.parse('https://h'));
      expect(server.closed, isTrue);
    });
  });
}

class _ClosingServer extends ScriptedServer {
  new() : super((_) => const HttpReply(200, _health));

  bool closed = false;

  @override
  void close({bool force = false}) => closed = true;
}
