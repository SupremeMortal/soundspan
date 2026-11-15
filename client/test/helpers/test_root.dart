// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/app.dart';
import 'package:soundspan/app/router/routes.dart';
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
  new _(
    this.container,
    this.database,
    this.profileId,
    this.otherIds, {
    required this._ownsDatabase,
  });

  final bool _ownsDatabase;
  bool _disposed = false;

  /// Builds the root container with [stored] as the active profile. Call it
  /// outside fake async (in `tester.runAsync` within widget tests).
  ///
  /// [database] reuses an `app.db` (its profile and settings stay as they
  /// are; [stored] must then be [StoredProfile.none]); [opener] replaces
  /// the [InMemoryDatabaseOpener]; [role] is the stored profile's role.
  /// Each name in [others] adds a signed-in profile of user `<name>` on
  /// `https://<name>.example.com`, each used one minute after the one
  /// before; their ids are in [otherIds]. [secrets] and [clock] replace the
  /// new [InMemorySecretStore] and [FakeClock].
  static Future<TestRoot> create({
    StoredProfile stored = StoredProfile.none,
    List<Override> overrides = const [],
    AppDatabase? database,
    InMemoryDatabaseOpener? opener,
    String role = 'user',
    List<String> others = const [],
    InMemorySecretStore? secrets,
    FakeClock? clock,
  }) async {
    final reused = database != null;
    database ??= AppDatabase(NativeDatabase.memory());
    secrets ??= InMemorySecretStore();
    opener ??= InMemoryDatabaseOpener();
    final paths = RecordingAppPaths();
    clock ??= FakeClock();
    String? profileId;
    final otherIds = <String, String>{};
    final repository = ProfileRepository(
      database,
      secrets,
      paths,
      opener,
      clock,
    );
    if (stored != StoredProfile.none) {
      final profile = await repository.upsertSignedIn(
        baseUrl: Uri.parse('https://music.example.com'),
        userId: 'user-1',
        username: 'ada',
        role: role,
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
    for (final name in others) {
      clock.advance(const Duration(minutes: 1));
      final other = await repository.upsertSignedIn(
        baseUrl: Uri.parse('https://$name.example.com'),
        userId: 'user-$name',
        username: name,
        role: 'user',
        authKind: AuthKind.password,
        credentials: JwtCredentials(
          accessToken: '$name-access',
          refreshToken: '$name-refresh',
        ),
        credentialCreatedAt: clock.now(),
      );
      otherIds[name] = other.id;
    }
    clock.advance(const Duration(minutes: 1));
    final container = await createRootContainer(
      paths: paths,
      databaseOpener: opener,
      appDatabase: database,
      secretStore: secrets,
      userAgent: 'soundspan-client/test (test)',
      overrides: [clockProvider.overrideWithValue(clock), ...overrides],
    );
    return TestRoot._(
      container,
      database,
      profileId,
      otherIds,
      ownsDatabase: !reused,
    );
  }

  /// The root container.
  final ProviderContainer container;

  /// `app.db`.
  final AppDatabase database;

  /// The stored profile's id, or null with [StoredProfile.none].
  final String? profileId;

  /// The ids of the profiles named in `others`, by name.
  final Map<String, String> otherIds;

  /// Disposes the runtime and the container, and closes the database
  /// unless it was passed in.
  /// Calling it again does nothing.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await container.read(profileRuntimeProvider).dispose();
    container.dispose();
    if (_ownsDatabase) await database.close();
  }
}

/// Pumps the real app.
extension PumpSoundspanApp on WidgetTester {
  /// Builds a [TestRoot] with [stored] and pumps [SoundspanApp] on it at
  /// [size]; everything is released when the test ends.
  ///
  /// [overrides], [database], [opener], [role], [others], [secrets] and
  /// [clock] are passed to [TestRoot.create].
  Future<TestRoot> pumpSoundspanApp({
    StoredProfile stored = StoredProfile.none,
    Size size = const Size(390, 844),
    List<Override> overrides = const [],
    AppDatabase? database,
    InMemoryDatabaseOpener? opener,
    String role = 'user',
    List<String> others = const [],
    InMemorySecretStore? secrets,
    FakeClock? clock,
  }) async {
    view
      ..physicalSize = size
      ..devicePixelRatio = 1.0;
    addTearDown(view.reset);
    final root = (await runAsync(
      () => TestRoot.create(
        stored: stored,
        overrides: overrides,
        database: database,
        opener: opener,
        role: role,
        others: others,
        secrets: secrets,
        clock: clock,
      ),
    ))!;
    addTearDown(() async {
      await pumpWidget(const SizedBox.shrink());
      // drift keeps a cancelled watch query for one event-loop turn with a
      // zero-duration timer, and closing `cache.db` waits for that timer.
      // Fake time only moves when pumped with a duration, so let it fire.
      await pump(Duration.zero);
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

/// A [ProfileRuntime] that records the ids passed to [switchTo] and
/// [resetLocalState], then does what the real one does while [delegate] is
/// true.
class RecordingProfileRuntime extends ProfileRuntime {
  /// Creates the runtime under the root container.
  new(super._root);

  /// Whether calls go on to the real runtime after being recorded.
  bool delegate = true;

  /// The ids passed to [switchTo], in call order.
  final List<String?> switched = [];

  /// The ids passed to [resetLocalState], in call order.
  final List<String> reset = [];

  @override
  Future<void> switchTo(String? profileId) {
    switched.add(profileId);
    return delegate ? super.switchTo(profileId) : Future<void>.value();
  }

  @override
  Future<void> resetLocalState(String profileId) {
    reset.add(profileId);
    return delegate ? super.resetLocalState(profileId) : Future<void>.value();
  }
}

/// Overrides `profileRuntimeProvider` with a [RecordingProfileRuntime],
/// which [onCreate] receives.
Override recordingRuntimeOverride(
  void Function(RecordingProfileRuntime runtime) onCreate,
) => profileRuntimeProvider.overrideWith((ref) {
  final runtime = RecordingProfileRuntime(ref.container);
  onCreate(runtime);
  ref.onDispose(() => unawaited(runtime.dispose()));
  return runtime;
});

/// The location of the top-most route in [root], including routes pushed
/// with `GoRouter.push`.
String locationOf(TestRoot root) =>
    root.container.read(routerProvider).state.uri.toString();
