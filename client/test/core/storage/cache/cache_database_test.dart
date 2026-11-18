// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';

final _at = DateTime.utc(2025, 1, 2, 3, 4, 5, 678);

void main() {
  late CacheDatabase db;

  setUp(() => db = CacheDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> addList(String listKey) => db
      .into(db.lists)
      .insert(
        ListsCompanion.insert(
          listKey: listKey,
          fetchedAt: _at,
          lastReadAt: _at,
        ),
      );

  ListEntriesCompanion entry(String listKey, int position, String key) =>
      ListEntriesCompanion.insert(
        listKey: listKey,
        position: position,
        entityKind: CacheEntityKind.track,
        entityKey: key,
      );

  test('version 1 matches drift_schemas/cache/drift_schema_v1.json', () async {
    final dump = jsonDecode(
      File('drift_schemas/cache/drift_schema_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final entities = (dump['entities'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    Map<String, bool> dumpedColumns(Map<String, dynamic> data) => {
      for (final c
          in (data['columns'] as List<dynamic>).cast<Map<String, dynamic>>())
        c['name'] as String: c['nullable'] as bool,
    };

    final dumpedTables = {
      for (final e in entities.where((e) => e['type'] == 'table'))
        (e['data'] as Map<String, dynamic>)['name'] as String: dumpedColumns(
          e['data'] as Map<String, dynamic>,
        ),
    };
    final liveTables = <String, Map<String, bool>>{};
    final tableNames = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((row) => row.read<String>('name'))
        .get();
    for (final table in tableNames) {
      final columns = await db
          .customSelect(
            'SELECT name, "notnull" FROM pragma_table_info(?)',
            variables: [Variable.withString(table)],
          )
          .get();
      liveTables[table] = {
        for (final c in columns)
          c.read<String>('name'): c.read<int>('notnull') == 0,
      };
    }

    final dumpedIndexes = {
      for (final e in entities.where((e) => e['type'] == 'index'))
        (e['data'] as Map<String, dynamic>)['name'] as String,
    };
    final liveIndexes = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((row) => row.read<String>('name'))
        .get();

    expect(db.schemaVersion, 1);
    expect(liveTables, dumpedTables);
    expect(liveIndexes.toSet(), dumpedIndexes);
  });

  test('tracks: insert and read; a null playbackId is accepted', () async {
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            key: 'x:abc',
            json: '{"title":"T"}',
            title: 'T',
            fetchedAt: _at,
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            key: 'p1',
            playbackId: const Value('p1'),
            json: '{}',
            albumId: const Value('al'),
            artistId: const Value('ar'),
            title: 'U',
            fetchedAt: _at,
          ),
        );

    final rows = await (db.select(
      db.tracks,
    )..orderBy([(t) => OrderingTerm.asc(t.key)])).get();
    expect(rows.map((r) => r.playbackId), ['p1', null]);
    expect(rows.last.json, '{"title":"T"}');
    expect(rows.first.albumId, 'al');
    expect(rows.first.fetchedAt, _at);
  });

  test('albums: insert and read', () async {
    await db
        .into(db.albums)
        .insert(
          AlbumsCompanion.insert(
            id: 'al',
            json: '{}',
            title: 'Album',
            artistName: 'Artist',
            year: const Value(1999),
            fetchedAt: _at,
          ),
        );
    final row = await db.select(db.albums).getSingle();
    expect(row.year, 1999);
    expect(row.artistName, 'Artist');
    expect(row.detailFetchedAt, isNull);
  });

  test('artists: insert and read', () async {
    await db
        .into(db.artists)
        .insert(
          ArtistsCompanion.insert(
            id: 'ar',
            json: '{}',
            name: 'Artist',
            fetchedAt: _at,
            detailFetchedAt: Value(_at),
          ),
        );
    final row = await db.select(db.artists).getSingle();
    expect(row.name, 'Artist');
    expect(row.detailFetchedAt, _at);
  });

  test('playlists: insert and read', () async {
    await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            id: 'pl',
            json: '{}',
            name: 'Mix',
            fetchedAt: _at,
          ),
        );
    expect((await db.select(db.playlists).getSingle()).name, 'Mix');
  });

  test('podcasts and episodes: insert and read', () async {
    await db
        .into(db.podcasts)
        .insert(PodcastsCompanion.insert(id: 'pc', json: '{}', fetchedAt: _at));
    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: 'ep',
            podcastId: 'pc',
            json: '{}',
            fetchedAt: _at,
          ),
        );
    expect((await db.select(db.podcasts).getSingle()).id, 'pc');
    expect((await db.select(db.episodes).getSingle()).podcastId, 'pc');
  });

  test('lists: insert and read; complete defaults to false', () async {
    await addList('albums?sort=name');
    final row = await db.select(db.lists).getSingle();
    expect(row.complete, isFalse);
    expect(row.total, isNull);
    expect(row.lastReadAt, _at);
  });

  test('list_entries: insert and read', () async {
    await addList('l');
    await db.into(db.listEntries).insert(entry('l', 0, 'p1'));
    final row = await db.select(db.listEntries).getSingle();
    expect(row.entityKind, CacheEntityKind.track);
    expect(row.entityKey, 'p1');
  });

  test('blobs: insert and read', () async {
    await db
        .into(db.blobs)
        .insert(BlobsCompanion.insert(key: 'home', json: '[]', fetchedAt: _at));
    expect((await db.select(db.blobs).getSingle()).json, '[]');
  });

  test('(listKey, position) is unique', () async {
    await addList('l');
    await db.into(db.listEntries).insert(entry('l', 0, 'a'));
    await expectLater(
      db.into(db.listEntries).insert(entry('l', 0, 'b')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('deleting a list removes its entries', () async {
    await addList('l');
    await addList('other');
    await db.into(db.listEntries).insert(entry('l', 0, 'a'));
    await db.into(db.listEntries).insert(entry('other', 0, 'a'));

    await (db.delete(db.lists)..where((l) => l.listKey.equals('l'))).go();

    final rows = await db.select(db.listEntries).get();
    expect(rows.map((r) => r.listKey), ['other']);
  });
}
