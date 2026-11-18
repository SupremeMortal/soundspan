// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/features/explore/data/radio_repository.dart';
import 'package:soundspan/features/explore/explore.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';

api.RadioTrack _track(String id, {String playbackId = 'pb-1'}) =>
    api.RadioTrack(
      id: id,
      title: 'Song $id',
      duration: 210,
      trackNo: 3,
      discNo: 1,
      playbackId: playbackId,
      albumId: 'al-1',
      album: const api.TrackAlbumRef(
        id: 'al-1',
        title: 'Record',
        coverArt: 'cover-1',
        albumLoudnessLufs: -8,
      ),
      artist: const api.TrackArtistRef(id: 'ar-1', name: 'Band'),
      isrc: 'ISRC1',
      loudnessLufs: -9.5,
      truePeakDb: -1,
    );

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late FakeReachability reachability;
  late FakeDiscoveryClient server;
  late CachedRadioRepository repository;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    reachability = FakeReachability();
    server = FakeApi().discovery
      ..radioGenres = const [
        api.RadioGenre(genre: 'rock', count: 40),
        api.RadioGenre(genre: 'jazz', count: 18),
      ]
      ..radioDecades = const [
        api.RadioDecade(decade: 1990, count: 25),
        api.RadioDecade(decade: 2010, count: 30),
      ]
      ..radioTracks = [_track('t1'), _track('t2', playbackId: '')];
    repository = CachedRadioRepository(
      server,
      CacheStore(db, clock),
      Swr(clock: clock, reachability: reachability),
    );
  });

  tearDown(() => db.close());

  Future<List<Cached<T>>> listenOnce<T>(Stream<Cached<T>> stream) async {
    final values = <Cached<T>>[];
    final subscription = stream.listen(values.add);
    await pumpEventQueue();
    await subscription.cancel();
    return values;
  }

  int calls(String name) => server.calls[name] ?? 0;

  test('genres map name and track count, and are cached', () async {
    final values = await listenOnce(repository.genres());

    expect(values.last.value, const [
      RadioGenre(name: 'rock', trackCount: 40),
      RadioGenre(name: 'jazz', trackCount: 18),
    ]);

    // Within the TTL a second read is served from the cache.
    clock.advance(const Duration(minutes: 9));
    final again = await listenOnce(repository.genres());
    expect(again.single.value, hasLength(2));
    expect(calls('listRadioGenres'), 1);

    // Past it the list is fetched again.
    clock.advance(const Duration(minutes: 2));
    await listenOnce(repository.genres());
    expect(calls('listRadioGenres'), 2);
  });

  test('decades map decade and track count, and are cached', () async {
    final values = await listenOnce(repository.decades());

    expect(values.last.value, const [
      RadioDecade(decade: 1990, trackCount: 25),
      RadioDecade(decade: 2010, trackCount: 30),
    ]);
    await listenOnce(repository.decades());
    expect(calls('listRadioDecades'), 1);
  });

  test('a genre station sends type genre, the name and the limit', () async {
    await repository.station(const GenreStation('rock'));
    await repository.station(const GenreStation('jazz'), limit: 20);

    expect(server.radioRequests, [
      ('genre', 'rock', 50),
      ('genre', 'jazz', 20),
    ]);
  });

  test('a decade station sends type decade and the decade', () async {
    await repository.station(const DecadeStation(1990));

    expect(server.radioRequests, [('decade', '1990', 50)]);
  });

  test('a station maps its tracks, and is never cached', () async {
    final tracks = await repository.station(const GenreStation('rock'));

    final first = tracks.first;
    expect(first.playbackId, const PlaybackId('pb-1'));
    expect(first.meta.title, 'Song t1');
    expect(first.meta.artist, 'Band');
    expect(first.meta.album, 'Record');
    expect(first.meta.durationSec, 210);
    expect(first.meta.artworkRef, 'cover-1');
    expect(first.meta.isrc, 'ISRC1');
    expect(first.albumId, 'al-1');
    expect(first.artistId, 'ar-1');
    expect(first.libraryTrackId, 't1');
    expect(first.trackNumber, 3);
    expect(first.loudness?.loudnessLufs, -9.5);
    expect(first.loudness?.albumLoudnessLufs, -8);
    // An empty playback id is a track the server cannot play.
    expect(tracks[1].playbackId, isNull);

    await repository.station(const GenreStation('rock'));
    expect(calls('getRadio'), 2);
  });
}
