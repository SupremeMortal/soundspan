// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show ProviderBase;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/shared/providers/cache.dart';

import '../../core/profile/profile_harness.dart';

void main() {
  test('the cache providers exist only inside a profile scope', () async {
    final harness = await ProfileHarness.create();

    await expectLater(
      harness.root.read(cacheDatabaseProvider.future),
      throwsA(anything),
    );
    await expectLater(
      harness.root.read(cacheStoreProvider.future),
      throwsA(anything),
    );
    for (final provider in <ProviderBase<Object?>>[
      libraryRemoteSourceProvider,
      playlistRemoteSourceProvider,
      searchRemoteSourceProvider,
      homeRemoteSourceProvider,
    ]) {
      expect(() => harness.root.read(provider), throwsA(anything));
    }
  });

  test(
    'switching profile closes the cache database and yields a new one',
    () async {
      final harness = await ProfileHarness.create();
      final runtime = harness.root.read(profileRuntimeProvider);
      addTearDown(runtime.dispose);

      await runtime.switchTo(harness.a);
      final a = runtime.container!;
      final databaseA = await a.read(cacheDatabaseProvider.future);
      final storeA = await a.read(cacheStoreProvider.future);
      final sources = [
        a.read(libraryRemoteSourceProvider),
        a.read(playlistRemoteSourceProvider),
        a.read(searchRemoteSourceProvider),
        a.read(homeRemoteSourceProvider),
      ];
      expect(harness.opener.opened, contains(CacheDatabaseTarget(harness.a)));
      expect(
        harness.opener.closed,
        isNot(contains(CacheDatabaseTarget(harness.a))),
      );

      await runtime.switchTo(harness.b);
      final b = runtime.container!;

      expect(harness.opener.closed, contains(CacheDatabaseTarget(harness.a)));
      expect(
        await b.read(cacheDatabaseProvider.future),
        isNot(same(databaseA)),
      );
      expect(await b.read(cacheStoreProvider.future), isNot(same(storeA)));
      expect(harness.opener.opened, contains(CacheDatabaseTarget(harness.b)));
      expect(b.read(libraryRemoteSourceProvider), isNot(same(sources[0])));
      expect(b.read(playlistRemoteSourceProvider), isNot(same(sources[1])));
      expect(b.read(searchRemoteSourceProvider), isNot(same(sources[2])));
      expect(b.read(homeRemoteSourceProvider), isNot(same(sources[3])));
    },
  );
}
