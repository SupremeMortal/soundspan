// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_clock.dart';

Track _track(String title, String playbackId) => Track(
  meta: TrackMeta(
    title: title,
    artist: 'Artist',
    album: 'Album',
    durationSec: 200,
  ),
  playbackId: PlaybackId(playbackId),
);

void main() {
  late CacheDatabase db;
  late CacheStore store;

  setUp(() async {
    db = CacheDatabase(NativeDatabase.memory());
    store = CacheStore(db, FakeClock());
    await store.upsertTracks([
      _track('Blue Moon', 'p1'),
      _track('100% Pure', 'p2'),
      _track('1000 Pure', 'p3'),
      _track('snake_case', 'p4'),
      _track('snakeXcase', 'p5'),
    ]);
    await store.upsertAlbums([
      const Album(
        id: 'al1',
        title: 'Moonlight',
        artistName: 'Someone',
        artistId: 'ar1',
      ),
    ]);
    await store.upsertArtists([const Artist(id: 'ar1', name: 'MOONRISE')]);
    await store.upsertPlaylists([
      const PlaylistSummary(
        id: 'pl1',
        name: 'Moon walks',
        trackCount: 3,
        isOwner: true,
        isPublic: false,
      ),
    ]);
  });
  tearDown(() => db.close());

  test('matches titles and names case-insensitively in every table', () async {
    final found = await store.searchLocal('moon');
    expect([for (final t in found.tracks) t.meta.title], ['Blue Moon']);
    expect([for (final a in found.albums) a.title], ['Moonlight']);
    expect([for (final a in found.artists) a.name], ['MOONRISE']);
    expect([for (final p in found.playlists) p.name], ['Moon walks']);
  });

  test('% and _ in the text match literally', () async {
    expect(
      [for (final t in (await store.searchLocal('0%')).tracks) t.meta.title],
      ['100% Pure'],
    );
    expect(
      [for (final t in (await store.searchLocal('e_c')).tracks) t.meta.title],
      ['snake_case'],
    );
  });
}
