// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/features/discover/data/cached_discovery_repository.dart';
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';

api.RecommendedArtist _recommended() => const api.RecommendedArtist(
  albumCount: 3,
  coverArt: null,
  heroUrl: 'https://img.example/hero.jpg',
  id: 'artist-1',
  mbid: 'mbid-1',
  name: 'Recommended One',
);

api.PopularArtist _popular() => const api.PopularArtist(
  id: 'mbid-2',
  image: 'https://img.example/chart.jpg',
  listeners: 1000,
  name: 'Chart Topper',
  playCount: 5000,
  mbid: 'mbid-2',
);

api.DiscoverTrack _track() => const api.DiscoverTrack(
  album: 'Fresh Album',
  albumId: 'rg-1',
  artist: 'New Voice',
  available: true,
  coverUrl: 'cover-1',
  duration: 245,
  id: 'track-1',
  isLiked: false,
  likedAt: null,
  similarity: 0.8,
  sourceType: api.DiscoverTrackSourceType.local,
  tier: api.RecommendationTier.high,
  title: 'First Light',
  loudnessLufs: -9.5,
);

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late FakeReachability reachability;
  late FakeDiscoveryClient server;
  late CachedDiscoveryRepository repository;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    reachability = FakeReachability();
    server = FakeApi().discovery
      ..recommended = [_recommended()]
      ..popular = [_popular()]
      ..current = [_track()];
    repository = CachedDiscoveryRepository(
      server,
      CacheStore(db, clock),
      Swr(clock: clock, reachability: reachability),
    );
  });

  tearDown(() => db.close());

  Future<(List<Cached<T>>, List<Object>)> listenOnce<T>(
    Stream<Cached<T>> stream,
  ) async {
    final values = <Cached<T>>[];
    final errors = <Object>[];
    final subscription = stream.listen(values.add, onError: errors.add);
    await pumpEventQueue();
    await subscription.cancel();
    return (values, errors);
  }

  int calls(String name) => server.calls[name] ?? 0;

  test('a recommended artist keeps its id as the library id', () async {
    final (values, errors) = await listenOnce(repository.recommendedForYou());

    expect(errors, isEmpty);
    expect(values.single.value, const [
      DiscoveryArtist(
        name: 'Recommended One',
        artworkRef: 'https://img.example/hero.jpg',
        libraryArtistId: 'artist-1',
      ),
    ]);
    expect(server.limits['getRecommendationsForYou'], 20);
  });

  test('a popular artist has no library id', () async {
    final (values, errors) = await listenOnce(
      repository.popularArtists(limit: 12),
    );

    expect(errors, isEmpty);
    expect(values.single.value, const [
      DiscoveryArtist(
        name: 'Chart Topper',
        artworkRef: 'https://img.example/chart.jpg',
      ),
    ]);
    expect(server.limits['listPopularArtists'], 12);
  });

  test('the discovery playlist maps its tracks, which are not playable '
      'without a playbackId', () async {
    final (values, errors) = await listenOnce(repository.currentDiscovery());

    expect(errors, isEmpty);
    final track = values.single.value!.tracks.single;
    expect(track.meta.title, 'First Light');
    expect(track.meta.artist, 'New Voice');
    expect(track.meta.album, 'Fresh Album');
    expect(track.meta.durationSec, 245);
    expect(track.meta.artworkRef, 'cover-1');
    expect(track.playbackId, isNull);
    expect(track.albumId, isNull);
    expect(track.libraryTrackId, 'track-1');
    expect(track.loudness?.loudnessLufs, -9.5);
  });

  test('an empty discovery playlist is null, and cached as null', () async {
    server.current = [];

    final (values, errors) = await listenOnce(repository.currentDiscovery());
    expect(errors, isEmpty);
    expect(values.single.value, isNull);

    final (cached, _) = await listenOnce(repository.currentDiscovery());
    expect(cached.single.value, isNull);
    expect(calls('getCurrentDiscover'), 1);
  });

  test('a cache hit emits first and refreshes only after 5 minutes', () async {
    await listenOnce(repository.recommendedForYou());
    server.recommended = [_recommended().copyWith(name: 'Renamed')];

    clock.advance(const Duration(minutes: 5) - const Duration(seconds: 1));
    final (fresh, _) = await listenOnce(repository.recommendedForYou());
    expect(calls('getRecommendationsForYou'), 1);
    expect(fresh.single.value.single.name, 'Recommended One');

    clock.advance(const Duration(seconds: 2));
    final (stale, _) = await listenOnce(repository.recommendedForYou());
    expect(calls('getRecommendationsForYou'), 2);
    expect(stale.first.refreshing, isTrue);
    expect(stale.first.value.single.name, 'Recommended One');
    expect(stale.last.refreshing, isFalse);
    expect(stale.last.value.single.name, 'Renamed');
  });

  test('refresh fetches whatever the age', () async {
    await listenOnce(repository.popularArtists());
    await listenOnce(repository.currentDiscovery());

    await repository.refreshPopularArtists();
    await repository.refreshRecommendedForYou();
    await repository.refreshCurrentDiscovery();

    expect(calls('listPopularArtists'), 2);
    expect(calls('getRecommendationsForYou'), 1);
    expect(calls('getCurrentDiscover'), 2);
  });

  test('FeatureDisabled with nothing cached errors the stream', () async {
    server.failures['listPopularArtists'] = const api.FeatureDisabled(
      status: 404,
    );

    final (values, errors) = await listenOnce(repository.popularArtists());

    expect(values, isEmpty);
    expect(errors.single, isA<api.FeatureDisabled>());
  });

  test('offline with a cache serves it without a request', () async {
    await listenOnce(repository.currentDiscovery());
    clock.advance(const Duration(hours: 1));
    reachability.set(Reachability.serverUnreachable);

    final (values, errors) = await listenOnce(repository.currentDiscovery());

    expect(errors, isEmpty);
    expect(values.single.value!.tracks, hasLength(1));
    expect(calls('getCurrentDiscover'), 1);
  });
}
