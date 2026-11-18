// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/auth/device_link_sign_in.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/auth/secret_keys.dart';
import 'package:soundspan/core/auth/server_admission.dart';
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

void main() {
  late AppDatabase db;
  late InMemorySecretStore secrets;
  late FakeClock clock;
  late ProfileRepository profiles;
  late FakeDeviceLinkServer server;
  late DeviceLinkSignIn signIn;
  final baseUrl = Uri.parse('https://music.example.com');
  final code = DeviceLinkCode.tryParse('ABC234')!;

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
    signIn = DeviceLinkSignIn(
      profiles: profiles,
      admission: VersionGateAdmission(
        VersionGate(Version.tryParse('2.6.0')!, Version.tryParse('2.9.0')!),
        clock,
      ),
      clock: clock,
      userAgent: 'soundspan-test',
      apis: server.api,
    );
  });
  tearDown(() => db.close());

  Future<Profile> submit() =>
      signIn.submit(baseUrl: baseUrl, code: code, deviceName: _deviceName);

  void keysAnswer(List<Map<String, Object?>> keys) =>
      server.answers['GET /api/api-keys'] = ok({'apiKeys': keys});

  Map<String, Object?> key(String name, DateTime createdAt) => {
    'id': 'k-${createdAt.millisecondsSinceEpoch}',
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': createdAt.add(const Duration(days: 90)).toIso8601String(),
    'lastUsed': null,
  };

  test('sends the code and device name to verify', () async {
    await submit();

    final verify = server.to('POST /api/device-link/verify').single;
    expect(verify.body, {'code': 'ABC234', 'deviceName': _deviceName});
    expect(verify.headers['X-API-Key'], isNull);
  });

  test('success stores the key under the profile secret key and writes both '
      'dates', () async {
    final created = DateTime.utc(2026, 3, 1, 11, 59);
    keysAnswer([key(_deviceName, created)]);

    final profile = await submit();

    expect(secrets.values[SecretKeys.apiKey(profile.id)], issuedKey);
    expect(profile.authKind, AuthKind.deviceLink);
    expect(profile.userId, 'user-1');
    expect(profile.username, 'ada');
    expect(profile.role, 'admin');
    expect(profile.userDisplayName, 'Ada L.');
    expect(profile.credentialCreatedAt, created);
    expect(profile.credentialExpiresAt, created.add(const Duration(days: 90)));
    expect(await profiles.byId(profile.id), profile);
  });

  test('/auth/me and /api-keys are sent with the new key', () async {
    await submit();

    expect(
      server.to('GET /api/auth/me').single.headers['X-API-Key'],
      issuedKey,
    );
    expect(
      server.to('GET /api/api-keys').single.headers['X-API-Key'],
      issuedKey,
    );
  });

  test('success stores the server version and features', () async {
    final profile = await submit();

    expect(profile.serverVersion, '2.6.1');
    expect(profile.features, isNotNull);
    expect(profile.featuresFetchedAt, clock.now());
  });

  test('no matching key gives now + 90 days', () async {
    final profile = await submit();

    expect(profile.credentialCreatedAt, clock.now());
    expect(
      profile.credentialExpiresAt,
      clock.now().add(const Duration(days: 90)),
    );
  });

  test('the same (baseUrl, userId) updates rather than duplicates', () async {
    final first = await submit();
    server.answers['POST /api/device-link/verify'] = ok({
      'success': true,
      'apiKey': 'second-key',
      'userId': 'user-1',
      'username': 'ada',
    });

    final second = await submit();

    expect(second.id, first.id);
    expect(second.deviceId, first.deviceId);
    expect(await profiles.watchAll().first, hasLength(1));
    expect(secrets.values[SecretKeys.apiKey(first.id)], 'second-key');
  });

  group('failures', () {
    Future<void> expectFailure(FakeAnswer answer, Matcher matcher) async {
      server.answers['POST /api/device-link/verify'] = answer;
      await expectLater(submit(), throwsA(matcher));
      expect(await profiles.watchAll().first, isEmpty);
      expect(secrets.values, isEmpty);
    }

    test(
      '404 Invalid code is invalidCode',
      () => expectFailure(
        error(404, 'Invalid code'),
        isA<DeviceLinkInvalidCode>(),
      ),
    );

    test(
      '400 Code already used is codeUsed',
      () => expectFailure(
        error(400, 'Code already used'),
        isA<DeviceLinkCodeUsed>(),
      ),
    );

    test(
      '400 Code expired is codeExpired',
      () => expectFailure(
        error(400, 'Code expired'),
        isA<DeviceLinkCodeExpired>(),
      ),
    );

    test(
      'any other 400 is rejected with the message',
      () => expectFailure(
        error(400, 'Code is required'),
        isA<DeviceLinkRejected>().having(
          (f) => f.message,
          'message',
          'Code is required',
        ),
      ),
    );

    test(
      '429 is rateLimited with Retry-After',
      () => expectFailure(
        error(
          429,
          'Too many',
          headers: {
            'retry-after': ['120'],
          },
        ),
        isA<DeviceLinkRateLimited>().having(
          (f) => f.retryAfter,
          'retryAfter',
          const Duration(seconds: 120),
        ),
      ),
    );

    test(
      'anything else propagates the ApiException',
      () => expectFailure(
        error(500, 'Failed to verify device link code'),
        isA<ServerError>(),
      ),
    );
  });

  test('a server below minServer leaves no profile and no secret', () async {
    server.setVersion('2.5.9');

    await expectLater(
      submit(),
      throwsA(
        isA<ServerTooOld>().having(
          (e) => e.serverVersion,
          'serverVersion',
          '2.5.9',
        ),
      ),
    );

    expect(await profiles.watchAll().first, isEmpty);
    expect(secrets.values, isEmpty);
  });

  test('the key does not appear in captured log output', () async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: false);
    addTearDown(AppLogging.reset);

    await submit();
    server.setVersion('2.5.9');
    await expectLater(submit(), throwsA(isA<ServerTooOld>()));
    server.answers['POST /api/device-link/verify'] = error(500, 'boom');
    await expectLater(submit(), throwsA(isA<ServerError>()));

    expect(sink.entries, isNotEmpty);
    for (final entry in sink.entries) {
      expect(entry.toJson().toString(), isNot(contains(issuedKey)));
    }
  });

  test('a failure never names the key', () async {
    server.setVersion('2.5.9');
    try {
      await submit();
      fail('expected ServerTooOld');
    } on ServerTooOld catch (error) {
      expect(error.toString(), isNot(contains(issuedKey)));
    }
  });
}
