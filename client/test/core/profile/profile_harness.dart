// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/app/app_database.dart' hide Profile;
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/in_memory_secret_store.dart';

/// An [AppPaths] without files that records [deleteProfileTree].
class RecordingAppPaths implements AppPaths {
  /// The profiles whose trees were deleted.
  final List<String> deletedTrees = [];

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
  Future<void> deleteProfileTree(String profileId) async =>
      deletedTrees.add(profileId);
}

/// An [InMemoryDatabaseOpener] that can make a profile's `state.db` look
/// written by a newer app version.
class TestOpener extends InMemoryDatabaseOpener {
  /// The state databases whose stored schema version is 99.
  final Set<String> tooNew = {};

  @override
  QueryExecutor open(DatabaseTarget target) {
    if (target case StateDatabaseTarget(:final profileId)
        when tooNew.contains(profileId)) {
      opened.add(target);
      return NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA user_version = 99'),
      );
    }
    return super.open(target);
  }

  @override
  Future<void> delete(DatabaseTarget target) async {
    await super.delete(target);
    if (target case StateDatabaseTarget(:final profileId)) {
      tooNew.remove(profileId);
    }
  }
}

/// The root scope of profile tests: in-memory `app.db`, secrets and
/// databases, a [FakeClock], and two signed-in profiles `A` and `B`.
class ProfileHarness {
  new _(this.appDb, this.secrets, this.opener, this.paths, this.clock);

  /// Creates the harness; its resources are released when the test ends.
  static Future<ProfileHarness> create({
    String? storedActiveId,
    List<Override> overrides = const [],
  }) async {
    final harness = ProfileHarness._(
      AppDatabase(NativeDatabase.memory()),
      InMemorySecretStore(),
      TestOpener(),
      RecordingAppPaths(),
      FakeClock(),
    );
    addTearDown(harness.appDb.close);
    harness.root = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(harness.appDb),
        secretStoreProvider.overrideWithValue(harness.secrets),
        databaseOpenerProvider.overrideWithValue(harness.opener),
        appPathsProvider.overrideWithValue(harness.paths),
        clockProvider.overrideWithValue(harness.clock),
        initialActiveProfileIdProvider.overrideWithValue(storedActiveId),
        userAgentProvider.overrideWithValue('soundspan-client/test (test)'),
        ...overrides,
      ],
    );
    addTearDown(harness.root.dispose);
    final repository = harness.root.read(profileRepositoryProvider);
    for (final (name, credentials) in [
      ('a', const JwtCredentials(accessToken: 'a-access', refreshToken: 'a-r')),
      ('b', const ApiKeyCredentials(apiKey: 'b-key')),
    ]) {
      final profile = await repository.upsertSignedIn(
        baseUrl: Uri.parse('https://$name.example.com'),
        userId: 'user-$name',
        username: name,
        role: 'user',
        authKind: credentials is JwtCredentials
            ? AuthKind.password
            : AuthKind.apiKey,
        credentials: credentials,
        credentialCreatedAt: harness.clock.now(),
      );
      harness.ids[name] = profile.id;
    }
    return harness;
  }

  /// `app.db`.
  final AppDatabase appDb;

  /// The secret store.
  final InMemorySecretStore secrets;

  /// The database opener.
  final TestOpener opener;

  /// The paths.
  final RecordingAppPaths paths;

  /// The clock.
  final FakeClock clock;

  /// The root container.
  late final ProviderContainer root;

  /// Profile ids by name: `a` and `b`.
  final Map<String, String> ids = {};

  /// Profile A's id.
  String get a => ids['a']!;

  /// Profile B's id.
  String get b => ids['b']!;
}
