// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/api_key_repository.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/auth/device_link_sign_in.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/auth/relink.dart';
import 'package:soundspan/core/auth/secret_keys.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/core/storage/app/app_database.dart' hide Profile;
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/in_memory_secret_store.dart';
import '../logging/recording_sink.dart';
import '../profile/profile_harness.dart';
import 'device_link_fakes.dart';

const _deviceName = 'studio-pc (soundspan Linux)';
const _oldKey =
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

/// An adapter whose every request fails as if the network were down.
class _OfflineAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late InMemorySecretStore secrets;
  late FakeClock clock;
  late ProfileRepository profiles;
  late FakeDeviceLinkServer server;
  late RecordingSink logs;
  final baseUrl = Uri.parse('https://music.example.com');
  final code = DeviceLinkCode.tryParse('ABC234')!;
  final oldCreated = DateTime.utc(2026);
  final newCreated = DateTime.utc(2026, 3, 1, 11);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    secrets = InMemorySecretStore();
    clock = FakeClock(start: DateTime.utc(2026, 3, 1, 12));
    var next = 0;
    profiles = ProfileRepository(
      db,
      secrets,
      RecordingAppPaths(),
      InMemoryDatabaseOpener(),
      clock,
      newId: () => 'uuid-${++next}',
    );
    server = FakeDeviceLinkServer();
    server.answers['GET /api/api-keys'] = ok({
      'apiKeys': [
        {
          'id': 'k-new',
          'name': _deviceName,
          'createdAt': newCreated.toIso8601String(),
          'expiresAt': newCreated
              .add(const Duration(days: 90))
              .toIso8601String(),
          'lastUsed': null,
        },
      ],
    });
    logs = RecordingSink();
    AppLogging.configure(sinks: [logs], releaseMode: false);
  });
  tearDown(() async {
    AppLogging.reset();
    await db.close();
  });

  Future<Profile> linkedProfile({String? key = _oldKey}) async {
    final profile = await profiles.upsertSignedIn(
      baseUrl: baseUrl,
      userId: 'user-1',
      username: 'ada',
      role: 'admin',
      authKind: AuthKind.deviceLink,
      credentials: const ApiKeyCredentials(apiKey: _oldKey),
      credentialCreatedAt: oldCreated,
      credentialExpiresAt: oldCreated.add(const Duration(days: 90)),
    );
    if (key == null) await profiles.deleteCredentials(profile.id);
    return profile;
  }

  RelinkUseCase relink({
    KeyedApiFactory? revokeApis,
    Duration revokeTimeout = const Duration(seconds: 5),
  }) => RelinkUseCase(
    profiles: profiles,
    signIn: DeviceLinkSignIn(
      profiles: profiles,
      admission: VersionGateAdmission(
        VersionGate(Version.tryParse('2.6.0')!, Version.tryParse('2.9.0')!),
        clock,
      ),
      clock: clock,
      userAgent: 'soundspan-test',
      apis: server.api,
    ),
    userAgent: 'soundspan-test',
    apis: revokeApis ?? server.api,
    revokeTimeout: revokeTimeout,
  );

  Future<Profile> run(Profile profile, {RelinkUseCase? useCase}) =>
      (useCase ?? relink()).run(profile, code, _deviceName);

  test(
    'stores the new key and dates and revokes the old key with itself',
    () async {
      final profile = await linkedProfile();

      final result = await run(profile);

      expect(result.id, profile.id);
      expect(await secrets.read(SecretKeys.apiKey(profile.id)), issuedKey);
      expect(result.credentialCreatedAt, newCreated);
      expect(
        result.credentialExpiresAt,
        newCreated.add(const Duration(days: 90)),
      );
      final revoke = server.to('DELETE /api/api-keys/current').single;
      expect(revoke.headers['X-API-Key'], _oldKey);
    },
  );

  for (final (name, answer) in [
    ('500', error(500, 'boom')),
    ('401', error(401, 'Invalid API key')),
  ]) {
    test('a revoke failing with $name is logged and ignored', () async {
      server.answers['DELETE /api/api-keys/current'] = answer;
      final profile = await linkedProfile();

      final result = await run(profile);

      expect(result.state, ProfileState.active);
      expect(await secrets.read(SecretKeys.apiKey(profile.id)), issuedKey);
      final warning = logs.entries.singleWhere(
        (e) => e.level == 'warning' && e.message.contains('revoke'),
      );
      expect(warning.message, isNot(contains(_oldKey)));
      expect(warning.fields.values, isNot(contains(_oldKey)));
    });
  }

  test('a revoke that times out is ignored', () async {
    final hanging = FakeDeviceLinkServer()..hang = true;
    final profile = await linkedProfile();

    final result = await run(
      profile,
      useCase: relink(
        revokeApis: hanging.api,
        revokeTimeout: const Duration(milliseconds: 50),
      ),
    );

    expect(result.state, ProfileState.active);
    expect(hanging.to('DELETE /api/api-keys/current'), hasLength(1));
    expect(await secrets.read(SecretKeys.apiKey(profile.id)), issuedKey);
  });

  test('a revoke while offline is ignored', () async {
    final offline = _OfflineAdapter();
    final profile = await linkedProfile();

    final result = await run(
      profile,
      useCase: relink(
        revokeApis: (config, apiKey) =>
            SoundspanApi.anonymous(config.baseUrl, adapter: offline),
      ),
    );

    expect(result.state, ProfileState.active);
    expect(offline.requests, greaterThan(0));
    expect(await secrets.read(SecretKeys.apiKey(profile.id)), issuedKey);
  });

  test('without an old key no revoke is sent', () async {
    final profile = await linkedProfile(key: null);

    await run(profile);

    expect(server.to('DELETE /api/api-keys/current'), isEmpty);
    expect(await secrets.read(SecretKeys.apiKey(profile.id)), issuedKey);
  });

  test('a code of another user leaves the profile untouched', () async {
    server.answers['POST /api/device-link/verify'] = ok({
      'success': true,
      'apiKey': issuedKey,
      'userId': 'user-2',
      'username': 'grace',
    });
    server.answers['GET /api/auth/me'] = ok({
      'id': 'user-2',
      'username': 'grace',
      'role': 'user',
      'displayName': null,
    });
    final profile = await linkedProfile();

    final result = await run(profile);

    expect(result.id, isNot(profile.id));
    expect(result.userId, 'user-2');
    expect(await secrets.read(SecretKeys.apiKey(profile.id)), _oldKey);
    final unchanged = (await profiles.byId(profile.id))!;
    expect(unchanged.credentialCreatedAt, oldCreated);
    expect(
      unchanged.credentialExpiresAt,
      oldCreated.add(const Duration(days: 90)),
    );
    expect(server.to('DELETE /api/api-keys/current'), isEmpty);
  });

  test('a signed-out profile becomes active', () async {
    final profile = await linkedProfile(key: null);
    await profiles.setState(profile.id, ProfileState.signedOut);

    final result = await run((await profiles.byId(profile.id))!);

    expect(result.state, ProfileState.active);
    expect((await profiles.byId(profile.id))!.state, ProfileState.active);
  });

  test('a failed verify leaves the old key in place', () async {
    server.answers['POST /api/device-link/verify'] = error(404, 'Invalid code');
    final profile = await linkedProfile();

    await expectLater(run(profile), throwsA(isA<DeviceLinkInvalidCode>()));

    expect(await secrets.read(SecretKeys.apiKey(profile.id)), _oldKey);
    expect(server.to('DELETE /api/api-keys/current'), isEmpty);
  });
}
