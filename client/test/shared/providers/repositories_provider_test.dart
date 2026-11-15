// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/repositories.dart';

import '../../core/profile/profile_harness.dart';

/// The four repositories of [container].
Future<List<Object>> _repositories(ProviderContainer container) async => [
  await container.read(libraryRepositoryProvider.future),
  await container.read(playlistRepositoryProvider.future),
  await container.read(homeRepositoryProvider.future),
  await container.read(searchRepositoryProvider.future),
];

/// Whether the cache of [container] holds the list [listKey]; reads the
/// table directly, so the list is not marked as read.
Future<bool> _hasList(ProviderContainer container, String listKey) async {
  final db = await container.read(cacheDatabaseProvider.future);
  final row = await (db.select(
    db.lists,
  )..where((l) => l.listKey.equals(listKey))).getSingleOrNull();
  return row != null;
}

Future<void> _until(Future<bool> Function() condition) async {
  for (var i = 0; i < 200; i++) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('condition not met');
}

void main() {
  test('each provider yields an implementation of its interface inside a '
      'profile scope and throws outside one', () async {
    final harness = await ProfileHarness.create();
    for (final provider in [
      libraryRepositoryProvider,
      playlistRepositoryProvider,
      homeRepositoryProvider,
      searchRepositoryProvider,
    ]) {
      await expectLater(harness.root.read(provider.future), throwsA(anything));
    }

    final runtime = harness.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);
    await runtime.switchTo(harness.a);
    final container = runtime.container!;

    expect(
      await container.read(libraryRepositoryProvider.future),
      isA<LibraryRepository>(),
    );
    expect(
      await container.read(playlistRepositoryProvider.future),
      isA<PlaylistRepository>(),
    );
    expect(
      await container.read(homeRepositoryProvider.future),
      isA<HomeRepository>(),
    );
    expect(
      await container.read(searchRepositoryProvider.future),
      isA<SearchRepository>(),
    );
  });

  test('switching profile yields new repositories', () async {
    final harness = await ProfileHarness.create();
    final runtime = harness.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);

    await runtime.switchTo(harness.a);
    final a = await _repositories(runtime.container!);
    await runtime.switchTo(harness.b);
    final b = await _repositories(runtime.container!);

    for (final (index, repository) in b.indexed) {
      expect(repository, isNot(same(a[index])));
    }
  });

  test(
    'pruning runs once after the first frame for the active profile',
    () async {
      expect(postFirstFrameTasks, contains(startCachePruning));
      final harness = await ProfileHarness.create();
      final runtime = harness.root.read(profileRuntimeProvider);
      addTearDown(runtime.dispose);
      await runtime.switchTo(harness.a);
      final a = runtime.container!;
      final store = await a.read(cacheStoreProvider.future);
      await store.writePage('old', offset: 0, items: const []);
      harness.clock.advance(const Duration(days: 31));

      await startCachePruning(harness.root);
      await _until(() async => !await _hasList(a, 'old'));

      // A list that ages past the limit afterwards is left until the next
      // profile container or until the cache outgrows its limit.
      await store.writePage('later', offset: 0, items: const []);
      harness.clock.advance(const Duration(days: 31));
      await pumpEventQueue();
      expect(await _hasList(a, 'later'), isTrue);
    },
  );
}
