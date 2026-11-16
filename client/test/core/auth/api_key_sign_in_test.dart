// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/api_key_sign_in.dart';
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

/// The key the user pastes in these tests.
const _key = 'pasted-key-0123456789abcdef0123456789abcdef';

void main() {
  late AppDatabase db;
  late InMemorySecretStore secrets;
  late FakeClock clock;
  late ProfileRepository profiles;
  late FakeDeviceLinkServer server;
  late ApiKeySignIn signIn;
  final baseUrl = Uri.parse('https://music.example.com');

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
    signIn = ApiKeySignIn(
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

  Future<Profile> submit([String apiKey = _key]) =>
      signIn.submit(baseUrl: baseUrl, apiKey: apiKey);

  test('success stores the key and writes authKind apiKey with a null '
      'expiry', () async {
    final profile = await submit();

    expect(secrets.values[SecretKeys.apiKey(profile.id)], _key);
    expect(profile.authKind, AuthKind.apiKey);
    expect(profile.userId, 'user-1');
    expect(profile.username, 'ada');
    expect(profile.role, 'admin');
    expect(profile.userDisplayName, 'Ada L.');
    expect(profile.credentialCreatedAt, clock.now());
    expect(profile.credentialExpiresAt, isNull);
    expect(profile.serverVersion, '2.6.1');
    expect(profile.featuresFetchedAt, clock.now());
    expect(await profiles.byId(profile.id), profile);
  });

  test('/auth/me is sent with the key and /api-keys is not asked', () async {
    await submit();

    expect(server.to('GET /api/auth/me').single.headers['X-API-Key'], _key);
    expect(server.to('GET /api/api-keys'), isEmpty);
  });

  test('a key pasted with a trailing newline and inner spaces is '
      'normalized', () async {
    final profile = await submit(
      '  pasted-key-0123456789abcdef\n 0123456789\tabcdef\r\n',
    );

    expect(server.to('GET /api/auth/me').single.headers['X-API-Key'], _key);
    expect(secrets.values[SecretKeys.apiKey(profile.id)], _key);
  });

  group('malformed input is refused without a request', () {
    for (final (name, input) in [
      ('empty', ''),
      ('only whitespace', ' \n\t '),
      ('300 characters', 'a' * 300),
      ('non-ASCII', 'clé-secrète'),
      ('a control character', 'abc\u0000def'),
    ]) {
      test(name, () async {
        await expectLater(submit(input), throwsA(isA<ApiKeyMalformed>()));
        expect(server.requests, isEmpty);
        expect(secrets.values, isEmpty);
      });
    }

    test('256 characters is still accepted', () async {
      await submit('a' * 256);
      expect(server.to('GET /api/auth/me'), hasLength(1));
    });
  });

  group('failures leave no secret and no profile', () {
    Future<void> expectFailure(FakeAnswer answer, Matcher matcher) async {
      server.answers['GET /api/auth/me'] = answer;
      await expectLater(submit(), throwsA(matcher));
      expect(await profiles.watchAll().first, isEmpty);
      expect(secrets.values, isEmpty);
    }

    test(
      '401 is rejected',
      () => expectFailure(error(401, 'Invalid API key'), isA<ApiKeyRejected>()),
    );

    test(
      '403 is rejected',
      () => expectFailure(error(403, 'Forbidden'), isA<ApiKeyRejected>()),
    );

    test(
      '429 is rateLimited with Retry-After',
      () => expectFailure(
        error(
          429,
          'Too many',
          headers: {
            'retry-after': ['90'],
          },
        ),
        isA<ApiKeyRateLimited>().having(
          (f) => f.retryAfter,
          'retryAfter',
          const Duration(seconds: 90),
        ),
      ),
    );

    test(
      'anything else propagates the ApiException',
      () => expectFailure(error(500, 'boom'), isA<ServerError>()),
    );
  });

  test('the same (baseUrl, userId) updates the existing profile', () async {
    final first = await submit();
    clock.advance(const Duration(days: 3));

    final second = await submit('another-key');

    expect(second.id, first.id);
    expect(second.deviceId, first.deviceId);
    expect(second.credentialCreatedAt, clock.now());
    expect(await profiles.watchAll().first, hasLength(1));
    expect(secrets.values[SecretKeys.apiKey(first.id)], 'another-key');
  });

  test('a server below minServer persists nothing', () async {
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

  test('the key is absent from captured logs and failures', () async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: false);
    addTearDown(AppLogging.reset);
    final failures = <Object>[];

    await submit();
    server.setVersion('2.5.9');
    await submit().then<void>((_) {}, onError: failures.add);
    server.setVersion('2.6.1');
    for (final answer in [error(401, 'Invalid API key'), error(500, 'boom')]) {
      server.answers['GET /api/auth/me'] = answer;
      await submit().then<void>((_) {}, onError: failures.add);
    }

    expect(failures, hasLength(3));
    expect(sink.entries, isNotEmpty);
    for (final entry in sink.entries) {
      expect(entry.toJson().toString(), isNot(contains(_key)));
    }
    for (final failure in failures) {
      expect(failure.toString(), isNot(contains(_key)));
    }
  });
}
