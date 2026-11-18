// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/paths/paths_io.dart';

import '../../helpers/in_memory_database_opener.dart';

void main() {
  test('the root storage providers throw until bootstrap overrides them', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    for (final provider in [
      appPathsProvider,
      databaseOpenerProvider,
      appDatabaseProvider,
      appSettingsProvider,
    ]) {
      expect(
        () => container.read(provider),
        throwsA(anything),
        reason: provider.toString(),
      );
    }
  });

  test('overridden, they provide the bootstrap values', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    const paths = IoAppPaths(appSupport: '/s', appCache: '/c');
    final opener = InMemoryDatabaseOpener();
    final container = ProviderContainer(
      overrides: [
        appPathsProvider.overrideWithValue(paths),
        databaseOpenerProvider.overrideWithValue(opener),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appPathsProvider), same(paths));
    expect(container.read(databaseOpenerProvider), same(opener));
    expect(container.read(appDatabaseProvider), same(db));

    final store = container.read(appSettingsProvider);
    await store.write(AppSettingKeys.locale, 'fr');
    expect(await AppSettingsStore(db).read(AppSettingKeys.locale), 'fr');
  });
}
