// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/app.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/app/app_database.dart' hide Profile;
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../core/profile/profile_harness.dart' show RecordingAppPaths;
import 'fake_clock.dart';
import 'in_memory_database_opener.dart';
import 'in_memory_secret_store.dart';

/// The profile stored as active before the root container is built.
enum StoredProfile {
  /// No profile.
  none,

  /// A signed-in profile.
  signedIn,

  /// A signed-out profile.
  signedOut,
}

/// A root container built by [createRootContainer] over in-memory storage.
class TestRoot {
  new _(this.container, this.database, this.profileId);

  /// Builds the root container with [stored] as the active profile. Call it
  /// outside fake async (in `tester.runAsync` within widget tests).
  static Future<TestRoot> create({
    StoredProfile stored = StoredProfile.none,
    List<Override> overrides = const [],
  }) async {
    final database = AppDatabase(NativeDatabase.memory());
    final secrets = InMemorySecretStore();
    final opener = InMemoryDatabaseOpener();
    final paths = RecordingAppPaths();
    final clock = FakeClock();
    String? profileId;
    if (stored != StoredProfile.none) {
      final repository = ProfileRepository(
        database,
        secrets,
        paths,
        opener,
        clock,
      );
      final profile = await repository.upsertSignedIn(
        baseUrl: Uri.parse('https://music.example.com'),
        userId: 'user-1',
        username: 'ada',
        role: 'user',
        authKind: AuthKind.password,
        credentials: const JwtCredentials(
          accessToken: 'access',
          refreshToken: 'refresh',
        ),
        credentialCreatedAt: clock.now(),
      );
      profileId = profile.id;
      if (stored == StoredProfile.signedOut) {
        await repository.setState(profile.id, ProfileState.signedOut);
      }
      await AppSettingsStore(database)
          .write(AppSettingKeys.activeProfileId, profile.id);
    }
    final container = await createRootContainer(
      paths: paths,
      databaseOpener: opener,
      appDatabase: database,
      secretStore: secrets,
      userAgent: 'soundspan-client/test (test)',
      overrides: [clockProvider.overrideWithValue(clock), ...overrides],
    );
    return TestRoot._(container, database, profileId);
  }

  /// The root container.
  final ProviderContainer container;

  /// `app.db`.
  final AppDatabase database;

  /// The stored profile's id, or null with [StoredProfile.none].
  final String? profileId;

  /// Disposes the runtime, the container and the database.
  Future<void> dispose() async {
    await container.read(profileRuntimeProvider).dispose();
    container.dispose();
    await database.close();
  }
}

/// Pumps the real app.
extension PumpSoundspanApp on WidgetTester {
  /// Builds a [TestRoot] with [stored] and pumps [SoundspanApp] on it at
  /// [size]; everything is released when the test ends.
  Future<TestRoot> pumpSoundspanApp({
    StoredProfile stored = StoredProfile.none,
    Size size = const Size(390, 844),
  }) async {
    view
      ..physicalSize = size
      ..devicePixelRatio = 1.0;
    addTearDown(view.reset);
    final root = (await runAsync(() => TestRoot.create(stored: stored)))!;
    addTearDown(() async {
      await pumpWidget(const SizedBox.shrink());
      await runAsync(root.dispose);
    });
    await pumpWidget(
      UncontrolledProviderScope(
        container: root.container,
        child: const SoundspanApp(),
      ),
    );
    await pumpAndSettle();
    return root;
  }
}
