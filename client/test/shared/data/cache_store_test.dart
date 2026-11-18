// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_clock.dart';

Track _track(String title, {String? playbackId}) => Track(
  meta: TrackMeta(
    title: title,
    artist: 'Artist',
    album: 'Album',
    durationSec: 200,
  ),
  playbackId: playbackId == null ? null : PlaybackId(playbackId),
);

Album _album(String id) =>
    Album(id: id, title: 'Album $id', artistName: 'Artist', artistId: 'ar-1');

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late CacheStore store;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    store = CacheStore(db, clock);
  });

  tearDown(() => db.close());

  Future<List<String>> entryKeys(String listKey) async {
    final rows =
        await (db.select(db.listEntries)
              ..where((e) => e.listKey.equals(listKey))
              ..orderBy([(e) => OrderingTerm(expression: e.position)]))
            .get();
    return [for (final row in rows) row.entityKey];
  }

  test('a page write replaces only its range', () async {
    const key = 'albums?filter=owned&sort=name&origin=all';
    await store.writePage(
      key,
      offset: 0,
      items: [_album('a'), _album('b')],
      total: 4,
    );
    await store.writePage(
      key,
      offset: 2,
      items: [_album('c'), _album('d')],
      total: 4,
      complete: true,
    );

    clock.advance(const Duration(minutes: 1));
    await store.writePage(
      key,
      offset: 0,
      items: [_album('x'), _album('y')],
      total: 4,
    );

    expect(await entryKeys(key), ['x', 'y', 'c', 'd']);
    final list = await store.watchList(key).first;
    expect(list!.items, [_album('x'), _album('y'), _album('c'), _album('d')]);
    expect(list.total, 4);
    expect(list.fetchedAt, clock.now());
    expect(list.complete, isFalse);
  });

  test(
    'a page write past a shrunken total drops the entries beyond it',
    () async {
      const key = 'playlist:p1';
      await store.writePage(
        key,
        offset: 0,
        items: [
          _track('a', playbackId: 'a'),
          _track('b', playbackId: 'b'),
        ],
        total: 2,
        complete: true,
      );
      await store.writePage(
        key,
        offset: 0,
        items: [_track('a', playbackId: 'a')],
        total: 1,
        complete: true,
      );

      expect(await entryKeys(key), ['a']);
    },
  );

  test('entities shared by two lists are stored once', () async {
    final shared = _track('Shared', playbackId: 'pb-shared');
    await store.writePage(
      'album:al-1:tracks',
      offset: 0,
      items: [
        shared,
        _track('One', playbackId: 'pb-1'),
      ],
      complete: true,
    );
    await store.writePage(
      'playlist:p1',
      offset: 0,
      items: [
        _track('Two', playbackId: 'pb-2'),
        shared,
      ],
      complete: true,
    );

    final tracks = await db.select(db.tracks).get();
    expect(
      tracks.map((t) => t.key),
      unorderedEquals(['pb-shared', 'pb-1', 'pb-2']),
    );
    expect(await entryKeys('playlist:p1'), ['pb-2', 'pb-shared']);
  });

  test('tracks without a playbackId get a stable x: key', () async {
    final unplayable = _track('Gone');
    final key = CacheStore.trackKey(unplayable);

    expect(key, startsWith('x:'));
    expect(key, hasLength(2 + 40));
    expect(CacheStore.trackKey(_track('Gone')), key);
    expect(CacheStore.trackKey(_track('Other')), isNot(key));
    expect(CacheStore.trackKey(_track('Gone', playbackId: 'pb-9')), 'pb-9');

    await store.upsertTracks([unplayable]);
    final row = await db.select(db.tracks).getSingle();
    expect(row.key, key);
    expect(row.playbackId, isNull);
    expect(await store.watchTrack(key).first, (
      value: unplayable,
      fetchedAt: clock.now(),
    ));
  });

  test('reading a list updates lastReadAt', () async {
    const key = 'album:al-1:tracks';
    await store.writePage(
      key,
      offset: 0,
      items: [_track('a', playbackId: 'a')],
    );
    clock.advance(const Duration(days: 2));

    await store.watchList(key).first;
    await pumpEventQueue();

    final row = await db.select(db.lists).getSingle();
    expect(row.lastReadAt, clock.now());
  });

  test('a watch query emits after a write', () async {
    final albums = <Object?>[];
    final subscription = store.watchAlbum('al-1').listen(albums.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await store.upsertAlbums([_album('al-1')]);
    await pumpEventQueue();
    clock.advance(const Duration(minutes: 1));
    await store.upsertAlbums([
      _album('al-1').copyWith(year: 1999),
    ], detail: true);
    await pumpEventQueue();

    expect(albums, [
      null,
      (value: _album('al-1'), fetchedAt: FakeClock.defaultStart),
      (value: _album('al-1').copyWith(year: 1999), fetchedAt: clock.now()),
    ]);
    final row = await db.select(db.albums).getSingle();
    expect(row.year, 1999);
    expect(row.detailFetchedAt, clock.now());
  });

  test(
    'artists and playlists round-trip, and a list upsert keeps the detail time',
    () async {
      const artist = Artist(id: 'ar-1', name: 'Band');
      const playlist = PlaylistSummary(
        id: 'p1',
        name: 'Mine',
        trackCount: 3,
        isOwner: true,
        isPublic: false,
      );
      await store.upsertArtists([artist], detail: true);
      await store.upsertPlaylists([playlist], detail: true);
      final detailAt = clock.now();
      clock.advance(const Duration(minutes: 1));
      await store.upsertArtists([artist]);
      await store.upsertPlaylists([playlist]);

      expect(await store.watchArtist('ar-1').first, (
        value: artist,
        fetchedAt: clock.now(),
      ));
      expect(await store.watchPlaylist('p1').first, (
        value: playlist,
        fetchedAt: clock.now(),
      ));
      expect(
        (await db.select(db.artists).getSingle()).detailFetchedAt,
        detailAt,
      );
      expect(
        (await db.select(db.playlists).getSingle()).detailFetchedAt,
        detailAt,
      );
    },
  );

  test('an undecodable entity row is a miss', () async {
    await db
        .into(db.albums)
        .insert(
          AlbumsCompanion.insert(
            id: 'al-1',
            json: '{"id": 3}',
            title: 't',
            artistName: 'a',
            fetchedAt: clock.now(),
          ),
        );

    expect(await store.watchAlbum('al-1').first, isNull);
  });
}
