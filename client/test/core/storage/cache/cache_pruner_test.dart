// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/cache/cache_pruner.dart';

import '../../../helpers/fake_clock.dart';

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late CachePruner pruner;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    pruner = CachePruner(db, clock);
  });
  tearDown(() => db.close());

  DateTime daysAgo(int days) => clock.now().subtract(Duration(days: days));

  Future<void> addAlbum(String id, {String json = '{}'}) => db
      .into(db.albums)
      .insert(
        AlbumsCompanion.insert(
          id: id,
          json: json,
          title: 'Album $id',
          artistName: 'Artist',
          fetchedAt: clock.now(),
        ),
      );

  Future<void> addList(
    String listKey, {
    required DateTime lastReadAt,
    List<String> albums = const [],
  }) async {
    await db
        .into(db.lists)
        .insert(
          ListsCompanion.insert(
            listKey: listKey,
            fetchedAt: lastReadAt,
            lastReadAt: lastReadAt,
          ),
        );
    for (final (i, id) in albums.indexed) {
      await db
          .into(db.listEntries)
          .insert(
            ListEntriesCompanion.insert(
              listKey: listKey,
              position: i,
              entityKind: CacheEntityKind.album,
              entityKey: id,
            ),
          );
    }
  }

  Future<List<String>> listKeys() =>
      db.select(db.lists).map((l) => l.listKey).get();
  Future<List<String>> albumIds() =>
      db.select(db.albums).map((a) => a.id).get();
  Future<List<CacheListEntry>> entriesOf(String listKey) => (db.select(
    db.listEntries,
  )..where((e) => e.listKey.equals(listKey))).get();

  test('a list read 31 days ago is removed with its entries, '
      'one read 29 days ago is kept', () async {
    await addAlbum('a');
    await addAlbum('b');
    await addList('old', lastReadAt: daysAgo(31), albums: ['a']);
    await addList('recent', lastReadAt: daysAgo(29), albums: ['b']);

    final report = await pruner.prune();

    expect(await listKeys(), ['recent']);
    expect(await entriesOf('old'), isEmpty);
    expect(await entriesOf('recent'), hasLength(1));
    expect(report.lists, 1);
  });

  test('an entity referenced by a surviving list is kept, '
      'an unreferenced one is removed', () async {
    await addAlbum('kept');
    await addAlbum('orphan');
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            key: 'kept',
            json: '{}',
            title: 'Same key as an album',
            fetchedAt: clock.now(),
          ),
        );
    await addList('list', lastReadAt: clock.now(), albums: ['kept']);

    final report = await pruner.prune();

    expect(await albumIds(), ['kept']);
    // The entry points at an album, not at the track with the same key.
    expect(await db.select(db.tracks).get(), isEmpty);
    expect(report.entities, 2);
  });

  test('an entity shared by a pruned and a kept list is kept', () async {
    await addAlbum('shared');
    await addAlbum('only-old');
    await addList(
      'old',
      lastReadAt: daysAgo(31),
      albums: ['shared', 'only-old'],
    );
    await addList('kept', lastReadAt: daysAgo(1), albums: ['shared']);

    await pruner.prune();

    expect(await albumIds(), ['shared']);
  });

  test('a blob fetched 31 days ago is removed', () async {
    for (final (key, age) in [('old', 31), ('recent', 29)]) {
      await db
          .into(db.blobs)
          .insert(
            BlobsCompanion.insert(
              key: key,
              json: '{}',
              fetchedAt: daysAgo(age),
            ),
          );
    }

    final report = await pruner.prune();

    expect(await db.select(db.blobs).map((b) => b.key).get(), ['recent']);
    expect(report.blobs, 1);
  });

  test('touchList protects a list from pruning', () async {
    await addAlbum('a');
    await addList('list', lastReadAt: daysAgo(31), albums: ['a']);

    await pruner.touchList('list');
    await pruner.prune();

    expect(await listKeys(), ['list']);
    expect(await albumIds(), ['a']);
    final list = await db.select(db.lists).getSingle();
    expect(list.lastReadAt, clock.now());
  });

  test('pruneIfNeeded does nothing under 64 MB outside start-up', () async {
    await addAlbum('orphan');
    await addList('old', lastReadAt: daysAgo(31));

    expect(cacheSizeLimitBytes, 64 * 1024 * 1024);
    final report = await pruner.pruneIfNeeded();

    expect(report, PruneReport.none);
    expect(await listKeys(), ['old']);
    expect(await albumIds(), ['orphan']);

    await pruner.pruneIfNeeded(atStartup: true);
    expect(await listKeys(), isEmpty);
    expect(await albumIds(), isEmpty);
  });

  test('above 64 MB the least recently read lists go first until the size is '
      'under the limit', () async {
    final big = '"${'x' * 20000}"';
    // 120 lists of one large album each, read on consecutive days.
    for (var i = 0; i < 120; i++) {
      final id = 'a$i';
      await addAlbum(id, json: big);
      await addList(
        'list-${i.toString().padLeft(3, '0')}',
        lastReadAt: daysAgo(29).add(Duration(minutes: i)),
        albums: [id],
      );
    }
    final full = await pruner.sizeBytes();
    // Room for about half of the rows.
    final limit = full ~/ 2;
    pruner = CachePruner(db, clock, sizeLimitBytes: limit);

    final report = await pruner.pruneIfNeeded();

    expect(await pruner.sizeBytes(), lessThanOrEqualTo(limit));
    final keys = await listKeys();
    // Whole batches of 50, the least recently read first.
    expect(report.lists, 100);
    expect(keys, [
      for (var i = 100; i < 120; i++) 'list-${i.toString().padLeft(3, '0')}',
    ]);
    expect(
      await albumIds(),
      unorderedEquals([for (var i = 100; i < 120; i++) 'a$i']),
    );
  });

  test('prune on an empty database succeeds', () async {
    expect(await pruner.prune(), PruneReport.none);
    expect(await pruner.pruneIfNeeded(atStartup: true), PruneReport.none);
  });
}
