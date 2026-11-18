// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/storage/app/app_database.dart' hide Profile;
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/in_memory_secret_store.dart';

/// A JWT whose payload carries only `exp`, [expiresAt]; the transport's
/// proactive check needs `iat` too, so it never renews these on its own.
String _token(DateTime expiresAt, String tag) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return [
    part({'alg': 'HS256'}),
    part({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000, 'tag': tag}),
    'sig',
  ].join('.');
}

/// What the scripted server answers to `/api/auth/refresh`.
enum _RefreshReply { ok, offline, serverError, rejected }

/// Answers `/api/auth/refresh` per [refresh] (after [gate], when set) and
/// any other request with 200 when it carries the rotated token and 401
/// otherwise.
class _Server implements HttpClientAdapter {
  new(this.rotatedAccess);

  final String rotatedAccess;
  _RefreshReply refresh = _RefreshReply.ok;
  Completer<void>? gate;
  final List<String> paths = [];

  int get refreshes => paths.where((p) => p == '/api/auth/refresh').length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    paths.add(path);
    if (path == '/api/auth/refresh') {
      await gate?.future;
      return switch (refresh) {
        _RefreshReply.ok => _json(200, {
          'token': rotatedAccess,
          'refreshToken': 'r2',
        }),
        _RefreshReply.offline => throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        ),
        _RefreshReply.serverError => _json(500, {'error': 'boom'}),
        _RefreshReply.rejected => _json(401, {'error': 'Invalid token'}),
      };
    }
    if (options.headers['Authorization'] == 'Bearer $rotatedAccess') {
      return _json(200, {
        'id': 'u1',
        'username': 'alice',
        'displayName': 'Alice',
        'role': 'user',
      });
    }
    return _json(401, {'error': 'Not authenticated', 'code': 'AUTH_REQUIRED'});
  }

  static ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      'content-type': ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// Records the order of secret writes against the controller's credential.
class _LoggingSecretStore extends InMemorySecretStore {
  new(this.log);

  final List<String> log;

  @override
  Future<void> write(String key, String value) async {
    await Future<void>.delayed(Duration.zero);
    log.add('write $key');
    await super.write(key, value);
  }
}

class _NoPaths implements AppPaths {
  @override
  String get appSupport => '/support';

  @override
  String get appCache => '/cache';

  @override
  String get logs => logsDirectory(appSupport);

  @override
  ProfilePaths profile(String profileId) => ProfilePaths.derive(
    appSupport: appSupport,
    appCache: appCache,
    profileId: profileId,
  );

  @override
  Future<void> deleteProfileTree(String profileId) async {}
}

void main() {
  late AppDatabase db;
  late List<String> log;
  late ProfileRepository repo;
  late FakeClock clock;
  late String rotated;
  late _Server server;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    log = [];
    clock = FakeClock();
    rotated = _token(clock.now().add(const Duration(hours: 24)), 'new');
    server = _Server(rotated);
    var next = 0;
    repo = ProfileRepository(
      db,
      _LoggingSecretStore(log),
      _NoPaths(),
      InMemoryDatabaseOpener(),
      clock,
      newId: () => 'id-${++next}',
    );
  });
  tearDown(() => db.close());

  /// A signed-in profile with [credentials], its loaded controller and the
  /// API wired to it.
  Future<(SessionController, SoundspanApi, Profile)> signedIn(
    Credentials credentials,
  ) async {
    final profile = await repo.upsertSignedIn(
      baseUrl: Uri.parse('https://music.example.com'),
      userId: 'u1',
      username: 'alice',
      role: 'user',
      authKind: credentials is JwtCredentials
          ? AuthKind.password
          : AuthKind.deviceLink,
      credentials: credentials,
      credentialCreatedAt: clock.now(),
    );
    final controller = SessionController(
      profileId: profile.id,
      repository: repo,
      clock: clock,
    );
    addTearDown(controller.dispose);
    await controller.load();
    final api = SoundspanApi(
      ApiConfig(baseUrl: profile.baseUrl, userAgent: 'ua'),
      credentials: controller,
      adapter: server,
    );
    controller.refresher = api.refreshSession;
    return (controller, api, profile);
  }

  JwtCredentials jwtLeft(Duration left) => JwtCredentials(
    accessToken: _token(clock.now().add(left), 'old'),
    refreshToken: 'r1',
  );

  String accessOf(Credentials credentials) =>
      (credentials as JwtCredentials).accessToken;

  const twoHours = Duration(hours: 2);

  test('a token with 3 h left and minRemaining 2 h is not refreshed', () async {
    final start = jwtLeft(const Duration(hours: 3));
    final (controller, _, _) = await signedIn(start);
    final result = await controller.ensureFresh(minRemaining: twoHours);
    expect(accessOf(result), start.accessToken);
    expect(server.refreshes, 0);
  });

  test('a token with 1 h left is refreshed and the new one returned', () async {
    final (controller, _, _) = await signedIn(
      jwtLeft(const Duration(hours: 1)),
    );
    final result = await controller.ensureFresh(minRemaining: twoHours);
    expect(accessOf(result), rotated);
    expect(accessOf(controller.current!), rotated);
    expect(server.refreshes, 1);
  });

  test('two concurrent calls cause one refresh request', () async {
    final (controller, _, _) = await signedIn(
      jwtLeft(const Duration(hours: 1)),
    );
    server.gate = Completer<void>();
    final a = controller.ensureFresh(minRemaining: twoHours);
    final b = controller.ensureFresh(minRemaining: twoHours);
    server.gate!.complete();
    final results = await Future.wait([a, b]);
    expect(results.map(accessOf), [rotated, rotated]);
    expect(server.refreshes, 1);
  });

  test(
    'a call concurrent with a 401-triggered refresh causes one request',
    () async {
      final (controller, api, _) = await signedIn(
        jwtLeft(const Duration(hours: 1)),
      );
      server.gate = Completer<void>();
      final request = api.rest.session.getCurrentUser();
      while (server.refreshes == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      final fresh = controller.ensureFresh(minRemaining: twoHours);
      server.gate!.complete();
      expect(accessOf(await fresh), rotated);
      expect((await request).username, 'alice');
      expect(server.refreshes, 1);
    },
  );

  test('an offline refresh with an unexpired token returns the current '
      'credential', () async {
    final start = jwtLeft(const Duration(hours: 1));
    final (controller, _, _) = await signedIn(start);
    server.refresh = _RefreshReply.offline;
    final result = await controller.ensureFresh(minRemaining: twoHours);
    expect(accessOf(result), start.accessToken);
  });

  test('a server error on refresh with an unexpired token returns the '
      'current credential', () async {
    final start = jwtLeft(const Duration(hours: 1));
    final (controller, _, _) = await signedIn(start);
    server.refresh = _RefreshReply.serverError;
    final result = await controller.ensureFresh(minRemaining: twoHours);
    expect(accessOf(result), start.accessToken);
  });

  test('an offline refresh with an expired token throws Offline', () async {
    final (controller, _, _) = await signedIn(
      jwtLeft(const Duration(minutes: -5)),
    );
    server.refresh = _RefreshReply.offline;
    await expectLater(
      controller.ensureFresh(minRemaining: twoHours),
      throwsA(isA<Offline>()),
    );
  });

  test('a rejected refresh signs the profile out and throws '
      'Unauthenticated', () async {
    final (controller, _, profile) = await signedIn(
      jwtLeft(const Duration(hours: 1)),
    );
    server.refresh = _RefreshReply.rejected;
    final states = <SessionState>[];
    controller.states.listen(states.add);
    await expectLater(
      controller.ensureFresh(minRemaining: twoHours),
      throwsA(isA<Unauthenticated>()),
    );
    await pumpEventQueue();
    expect(states, [
      const SessionState.signedOut(UnauthenticatedReason.sessionExpired),
    ]);
    expect((await repo.byId(profile.id))!.state, ProfileState.signedOut);
    await expectLater(
      controller.ensureFresh(minRemaining: twoHours),
      throwsA(isA<Unauthenticated>()),
    );
  });

  test('an API key session is returned at once and never refreshed', () async {
    const key = ApiKeyCredentials(apiKey: 'k1');
    final (controller, _, _) = await signedIn(key);
    final fresh = await controller.ensureFresh(minRemaining: twoHours);
    expect((fresh as ApiKeyCredentials).apiKey, 'k1');
    final now = await controller.refreshNow();
    expect((now as ApiKeyCredentials).apiKey, 'k1');
    expect(server.refreshes, 0);
  });

  test('refreshNow refreshes a fresh JWT', () async {
    final (controller, _, _) = await signedIn(
      jwtLeft(const Duration(hours: 10)),
    );
    final result = await controller.refreshNow();
    expect(accessOf(result), rotated);
    expect(server.refreshes, 1);
  });

  test('rotated tokens are persisted before the future completes', () async {
    final (controller, _, profile) = await signedIn(
      jwtLeft(const Duration(hours: 1)),
    );
    log.clear();
    await controller.ensureFresh(minRemaining: twoHours);
    expect(log, [
      'write p/${profile.id}/refresh',
      'write p/${profile.id}/access',
    ]);
    final stored = await repo.readCredentials(profile.id);
    expect(accessOf(stored!), rotated);
  });

  test('a signed-out controller throws Unauthenticated', () async {
    final (controller, _, profile) = await signedIn(
      jwtLeft(const Duration(hours: 3)),
    );
    await repo.deleteCredentials(profile.id);
    await controller.load();
    await expectLater(
      controller.ensureFresh(minRemaining: twoHours),
      throwsA(isA<Unauthenticated>()),
    );
    await expectLater(controller.refreshNow(), throwsA(isA<Unauthenticated>()));
  });
}
