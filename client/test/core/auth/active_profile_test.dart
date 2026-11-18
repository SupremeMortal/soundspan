// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/paths/paths_io.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/shared/clock.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/in_memory_secret_store.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<ProviderContainer> start() async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialActiveProfileIdProvider.overrideWithValue(
          await AppSettingsStore(db).read(AppSettingKeys.activeProfileId),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the initial value is the one supplied at bootstrap', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialActiveProfileIdProvider.overrideWithValue('p0'),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(activeProfileIdProvider), 'p0');
  });

  test('without a bootstrap value the provider throws', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(activeProfileIdProvider), throwsA(anything));
  });

  test('set persists before state changes', () async {
    final container = await start();
    final seen = <(String?, String?)>[];
    final store = AppSettingsStore(db);
    container.listen<String?>(activeProfileIdProvider, (_, next) async {
      // The setting is already stored when the state is observed.
      seen.add((next, await store.read(AppSettingKeys.activeProfileId)));
    });
    expect(container.read(activeProfileIdProvider), isNull);

    await container.read(activeProfileIdProvider.notifier).set('p1');
    await pumpEventQueue();
    expect(container.read(activeProfileIdProvider), 'p1');
    expect(seen, [('p1', 'p1')]);

    await container.read(activeProfileIdProvider.notifier).set(null);
    await pumpEventQueue();
    expect(container.read(activeProfileIdProvider), isNull);
    expect(await store.read(AppSettingKeys.activeProfileId), isNull);
  });

  test(
    'a new container started from the same database sees the stored id',
    () async {
      final first = await start();
      await first.read(activeProfileIdProvider.notifier).set('p7');
      first.dispose();

      final second = await start();
      expect(second.read(activeProfileIdProvider), 'p7');
    },
  );

  test('profileRepositoryProvider builds over the root providers', () {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secretStoreProvider.overrideWithValue(InMemorySecretStore()),
        appPathsProvider.overrideWithValue(
          const IoAppPaths(appSupport: '/s', appCache: '/c'),
        ),
        databaseOpenerProvider.overrideWithValue(InMemoryDatabaseOpener()),
        clockProvider.overrideWithValue(FakeClock()),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(profileRepositoryProvider), isA<ProfileRepository>());
  });
}
