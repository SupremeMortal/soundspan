// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

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

/// Records secret writes and deletes, and the moment the controller's
/// credential changes relative to them.
class _LoggingSecretStore extends InMemorySecretStore {
  new(this.log);

  final List<String> log;

  @override
  Future<void> write(String key, String value) async {
    await Future<void>.delayed(Duration.zero);
    log.add('write $key');
    await super.write(key, value);
  }

  @override
  Future<void> delete(String key) async {
    log.add('delete $key');
    await super.delete(key);
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
  late _LoggingSecretStore secrets;
  late ProfileRepository repo;
  late FakeClock clock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    log = [];
    secrets = _LoggingSecretStore(log);
    clock = FakeClock();
    var next = 0;
    repo = ProfileRepository(
      db,
      secrets,
      _NoPaths(),
      InMemoryDatabaseOpener(),
      clock,
      newId: () => 'id-${++next}',
    );
  });
  tearDown(() => db.close());

  const jwt = JwtCredentials(accessToken: 'a1', refreshToken: 'r1');
  const key = ApiKeyCredentials(apiKey: 'k1');

  Future<Profile> signIn(Credentials credentials) => repo.upsertSignedIn(
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

  Future<SessionController> loaded(Profile profile) async {
    final controller = SessionController(
      profileId: profile.id,
      repository: repo,
    );
    addTearDown(controller.dispose);
    await controller.load();
    return controller;
  }

  test('load exposes the stored JWT or API key', () async {
    final a = await loaded(await signIn(jwt));
    expect(
      a.current,
      isA<JwtCredentials>()
          .having((c) => c.accessToken, 'access', 'a1')
          .having((c) => c.refreshToken, 'refresh', 'r1'),
    );

    final b = await loaded(await signIn(key));
    expect(
      b.current,
      isA<ApiKeyCredentials>().having((c) => c.apiKey, 'apiKey', 'k1'),
    );
  });

  test('before load and without stored secrets current is null', () async {
    final profile = await signIn(jwt);
    final controller = SessionController(
      profileId: profile.id,
      repository: repo,
    );
    addTearDown(controller.dispose);
    expect(controller.current, isNull);
    await repo.deleteCredentials(profile.id);
    await controller.load();
    expect(controller.current, isNull);
  });

  test('tokens rotated: refresh is stored before access and before current changes', () async {
    final profile = await signIn(jwt);
    final controller = await loaded(profile);
    log.clear();
    final secretsSeen = <String>[];
    final pending = controller.onTokensRotated(
      const JwtCredentials(accessToken: 'a2', refreshToken: 'r2'),
    );
    // Sample the in-memory credential while the writes are in flight.
    while (log.length < 2) {
      secretsSeen.add((controller.current! as JwtCredentials).accessToken);
      await Future<void>.delayed(Duration.zero);
    }
    await pending;

    expect(log.take(2), [
      'write p/${profile.id}/refresh',
      'write p/${profile.id}/access',
    ]);
    expect(secretsSeen, everyElement('a1'));
    expect((controller.current! as JwtCredentials).accessToken, 'a2');
    final stored = await repo.readCredentials(profile.id);
    expect((stored! as JwtCredentials).refreshToken, 'r2');
  });

  for (final reason in UnauthenticatedReason.values) {
    test(
      '${reason.name} signs the profile out, deletes secrets, emits once',
      () async {
        final profile = await signIn(
          reason == UnauthenticatedReason.keyRejected ? key : jwt,
        );
        final controller = await loaded(profile);
        final states = <SessionState>[];
        controller.states.listen(states.add);

        controller.onUnauthenticated(reason);
        expect(controller.current, isNull);
        await pumpEventQueue();

        expect(states, [SessionState.signedOut(reason)]);
        expect(secrets.values, isEmpty);
        expect((await repo.byId(profile.id))!.state, ProfileState.signedOut);
      },
    );
  }

  test('a second onUnauthenticated is ignored', () async {
    final profile = await signIn(jwt);
    final controller = await loaded(profile);
    log.clear();
    final states = <SessionState>[];
    controller.states.listen(states.add);

    controller
      ..onUnauthenticated(UnauthenticatedReason.sessionExpired)
      ..onUnauthenticated(UnauthenticatedReason.keyRejected);
    await pumpEventQueue();
    controller.onUnauthenticated(UnauthenticatedReason.sessionExpired);
    await pumpEventQueue();

    expect(states, [
      const SessionState.signedOut(UnauthenticatedReason.sessionExpired),
    ]);
    expect(log.where((e) => e.startsWith('delete')), hasLength(3));
  });
}
