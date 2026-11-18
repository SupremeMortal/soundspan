// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/auth/secret_keys.dart';
import 'package:soundspan/core/storage/app/app_database.dart' hide Profile;
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/in_memory_secret_store.dart';

/// Records every call into [log], so call order across fakes is visible.
class _RecordingSecretStore extends InMemorySecretStore {
  new(this.log);

  final List<String> log;

  @override
  Future<void> write(String key, String value) {
    log.add('secret.write $key');
    return super.write(key, value);
  }

  @override
  Future<void> delete(String key) {
    log.add('secret.delete $key');
    return super.delete(key);
  }
}

class _RecordingAppPaths implements AppPaths {
  new(this.log);

  final List<String> log;
  Exception? failDelete;

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
  Future<void> deleteProfileTree(String profileId) async {
    log.add('paths.deleteProfileTree $profileId');
    if (failDelete case final error?) throw error;
  }
}

class _RecordingOpener implements DatabaseOpener {
  new(this.log);

  final List<String> log;
  final InMemoryDatabaseOpener _inner = InMemoryDatabaseOpener();

  @override
  bool get isVolatile => false;

  @override
  QueryExecutor open(DatabaseTarget target) => _inner.open(target);

  @override
  Future<void> delete(DatabaseTarget target) async {
    log.add('opener.delete $target');
  }
}

void main() {
  late AppDatabase db;
  late List<String> log;
  late _RecordingSecretStore secrets;
  late _RecordingAppPaths paths;
  late _RecordingOpener opener;
  late FakeClock clock;
  late ProfileRepository repo;
  late int nextId;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    log = [];
    secrets = _RecordingSecretStore(log);
    paths = _RecordingAppPaths(log);
    opener = _RecordingOpener(log);
    clock = FakeClock();
    nextId = 0;
    repo = ProfileRepository(
      db,
      secrets,
      paths,
      opener,
      clock,
      newId: () => 'uuid-${++nextId}',
    );
  });
  tearDown(() => db.close());

  const jwt = JwtCredentials(accessToken: 'access-1', refreshToken: 'ref-1');
  const key = ApiKeyCredentials(apiKey: 'key-1');
  final server = Uri.parse('https://music.example.com/sub');

  Future<Profile> signIn({
    Uri? baseUrl,
    String userId = 'u1',
    Credentials credentials = jwt,
    String? displayName,
    String username = 'alice',
  }) => repo.upsertSignedIn(
    baseUrl: baseUrl ?? server,
    displayName: displayName,
    userId: userId,
    username: username,
    userDisplayName: 'Alice',
    role: 'user',
    authKind: credentials is JwtCredentials
        ? AuthKind.password
        : AuthKind.apiKey,
    credentials: credentials,
    credentialCreatedAt: clock.now(),
  );

  test(
    'creates a profile with generated id and deviceId and host display name',
    () async {
      final profile = await signIn();
      expect(profile.id, 'uuid-1');
      expect(profile.deviceId, 'uuid-2');
      expect(profile.displayName, 'music.example.com');
      expect(profile.baseUrl, server);
      expect(profile.state, ProfileState.active);
      expect(profile.lastUsedAt, clock.now());
      expect(await repo.byId('uuid-1'), profile);
    },
  );

  test('an explicit display name is kept', () async {
    final profile = await signIn(displayName: 'Home');
    expect(profile.displayName, 'Home');
  });

  test('same baseUrl and userId updates the existing profile and keeps id and deviceId', () async {
    final first = await signIn(displayName: 'Home');
    await repo.setState(first.id, ProfileState.signedOut);
    clock.advance(const Duration(hours: 1));
    final second = await signIn(credentials: key, username: 'alice2');
    expect(second.id, first.id);
    expect(second.deviceId, first.deviceId);
    expect(second.displayName, 'Home');
    expect(second.username, 'alice2');
    expect(second.authKind, AuthKind.apiKey);
    expect(second.credentialCreatedAt, clock.now());
    expect(second.state, ProfileState.active);
    expect(second.lastUsedAt, clock.now());
    expect(await repo.watchAll().first, hasLength(1));
    expect(await repo.readCredentials(first.id), isA<ApiKeyCredentials>());
  });

  test('same server with a different user is a second profile', () async {
    final a = await signIn();
    final b = await signIn(userId: 'u2');
    expect(b.id, isNot(a.id));
    expect(await repo.watchAll().first, hasLength(2));
  });

  test('JWT credentials are stored as refresh then access', () async {
    await repo.writeCredentials('p1', jwt);
    expect(log, [
      'secret.write p/p1/refresh',
      'secret.write p/p1/access',
      'secret.delete p/p1/apikey',
    ]);
  });

  test('storing an API key removes JWT keys', () async {
    await repo.writeCredentials('p1', jwt);
    await repo.writeCredentials('p1', key);
    expect(secrets.values, {'p/p1/apikey': 'key-1'});
  });

  test('storing JWT credentials removes the API key', () async {
    await repo.writeCredentials('p1', key);
    await repo.writeCredentials('p1', jwt);
    expect(secrets.values, {
      'p/p1/refresh': 'ref-1',
      'p/p1/access': 'access-1',
    });
  });

  test(
    'readCredentials returns the stored kind, or null when incomplete',
    () async {
      expect(await repo.readCredentials('p1'), isNull);

      await repo.writeCredentials('p1', jwt);
      final read = await repo.readCredentials('p1');
      expect(read, isA<JwtCredentials>());
      final tokens = read! as JwtCredentials;
      expect(tokens.accessToken, 'access-1');
      expect(tokens.refreshToken, 'ref-1');

      await secrets.delete(SecretKeys.access('p1'));
      expect(await repo.readCredentials('p1'), isNull);

      await repo.writeCredentials('p1', key);
      final apiKey = await repo.readCredentials('p1');
      expect(apiKey, isA<ApiKeyCredentials>());
      expect((apiKey! as ApiKeyCredentials).apiKey, 'key-1');

      await repo.deleteCredentials('p1');
      expect(secrets.values, isEmpty);
    },
  );

  test('the profiles row contains no secret', () async {
    await signIn();
    await signIn(userId: 'u2', credentials: key);
    final rows = await db.customSelect('SELECT * FROM profiles').get();
    expect(rows, hasLength(2));
    for (final row in rows) {
      for (final value in row.data.values) {
        expect(value, isNot(anyOf('access-1', 'ref-1', 'key-1')));
        if (value is String) {
          expect(value, isNot(contains('access-1')));
          expect(value, isNot(contains('ref-1')));
          expect(value, isNot(contains('key-1')));
        }
      }
    }
  });

  test('watchAll orders by lastUsedAt', () async {
    final a = await signIn();
    clock.advance(const Duration(minutes: 1));
    final b = await signIn(userId: 'u2');
    final emitted = <List<String>>[];
    final sub = repo.watchAll().listen(
      (all) => emitted.add([for (final p in all) p.id]),
    );
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(emitted.last, [b.id, a.id]);

    clock.advance(const Duration(minutes: 1));
    await repo.touchLastUsed(a.id);
    await pumpEventQueue();
    expect(emitted.last, [a.id, b.id]);
    expect((await repo.byId(a.id))!.lastUsedAt, clock.now());
  });

  test('rename trims and falls back to the host', () async {
    final p = await signIn();
    await repo.rename(p.id, '  Living room  ');
    expect((await repo.byId(p.id))!.displayName, 'Living room');
    await repo.rename(p.id, '   ');
    expect((await repo.byId(p.id))!.displayName, 'music.example.com');
  });

  test('updateServerInfo and updateCredentialExpiry persist', () async {
    final p = await signIn();
    final fetched = DateTime.utc(2025, 2, 3, 4, 5, 6);
    await repo.updateServerInfo(
      p.id,
      serverVersion: '1.9.0',
      features: {
        'lyrics': true,
        'limits': {'queue': 500},
      },
      featuresFetchedAt: fetched,
    );
    final expiry = DateTime.utc(2025, 4);
    await repo.updateCredentialExpiry(p.id, expiry);

    final read = (await repo.byId(p.id))!;
    expect(read.serverVersion, '1.9.0');
    expect(read.features, {
      'lyrics': true,
      'limits': {'queue': 500},
    });
    expect(read.featuresFetchedAt, fetched);
    expect(read.credentialExpiresAt, expiry);

    await repo.updateCredentialExpiry(p.id, null);
    expect((await repo.byId(p.id))!.credentialExpiresAt, isNull);
  });

  test('setState persists', () async {
    final p = await signIn();
    await repo.setState(p.id, ProfileState.signedOut);
    expect((await repo.byId(p.id))!.state, ProfileState.signedOut);
  });

  test(
    'delete removes secrets, then data, then the row, in that order',
    () async {
      final p = await signIn();
      log.clear();
      await repo.delete(p.id);
      expect(log, [
        'secret.delete p/${p.id}/refresh',
        'secret.delete p/${p.id}/access',
        'secret.delete p/${p.id}/apikey',
        'paths.deleteProfileTree ${p.id}',
        'opener.delete ${StateDatabaseTarget(p.id)}',
        'opener.delete ${CacheDatabaseTarget(p.id)}',
      ]);
      expect(secrets.values, isEmpty);
      expect(await repo.byId(p.id), isNull);
    },
  );

  test('delete stops and keeps the row when data deletion fails', () async {
    final p = await signIn();
    paths.failDelete = const FileSystemFailure();
    log.clear();
    await expectLater(repo.delete(p.id), throwsA(isA<FileSystemFailure>()));
    expect(log.where((e) => e.startsWith('opener.')), isEmpty);
    expect(await repo.byId(p.id), isNotNull);

    // The delete can be repeated.
    paths.failDelete = null;
    await repo.delete(p.id);
    expect(await repo.byId(p.id), isNull);
  });

  test('delete refuses the active profile', () async {
    final p = await signIn();
    await AppSettingsStore(db).write(AppSettingKeys.activeProfileId, p.id);
    log.clear();
    await expectLater(repo.delete(p.id), throwsStateError);
    expect(log, isEmpty);
    expect(await repo.byId(p.id), isNotNull);
  });

  test('a baseUrl with a trailing slash is rejected', () async {
    for (final bad in [
      'https://music.example.com/',
      'https://music.example.com/sub/',
      'https://music.example.com?x=1',
      'https://music.example.com#top',
    ]) {
      await expectLater(
        signIn(baseUrl: Uri.parse(bad)),
        throwsArgumentError,
        reason: bad,
      );
    }
    expect(await repo.watchAll().first, isEmpty);
    expect(secrets.values, isEmpty);
  });

  test('the row mapping round-trips', () async {
    final p = await signIn();
    await repo.updateServerInfo(p.id, features: {'a': 1});
    final full = (await repo.byId(p.id))!;
    expect(profileFromRow(profileToRow(full)), full);
  });

  test('toString carries no secret and SecretKeys are namespaced', () async {
    final p = await signIn();
    expect(p.toString(), isNot(contains('access-1')));
    expect(SecretKeys.refresh('x'), 'p/x/refresh');
    expect(SecretKeys.access('x'), 'p/x/access');
    expect(SecretKeys.apiKey('x'), 'p/x/apikey');
  });
}

class FileSystemFailure implements Exception {
  const new();
}
