// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/home/cached_home_repository.dart';
import 'package:soundspan/shared/data/home/home_remote_source.dart';
import 'package:soundspan/shared/data/library/cached_library_repository.dart';
import 'package:soundspan/shared/data/library/library_remote_source.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/data/playlist/cached_playlist_repository.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/data/search/cached_search_repository.dart';
import 'package:soundspan/shared/data/search/search_remote_source.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' show FeatureDisabled, Offline;

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';

Track _track(String id) => Track(
  meta: TrackMeta(title: id, artist: 'Artist', album: 'Album', durationSec: 1),
  playbackId: PlaybackId(id),
);

const _album = Album(
  id: 'al-1',
  title: 'Album',
  artistName: 'Artist',
  artistId: 'ar-1',
);
const _artist = Artist(id: 'ar-1', name: 'Artist');
const _playlist = PlaylistSummary(
  id: 'p1',
  name: 'Mine',
  trackCount: 1,
  isOwner: true,
  isPublic: false,
);

/// Counts calls by name; [failures] makes the named call throw.
mixin _Calls {
  final Map<String, int> calls = {};
  final Map<String, Exception> failures = {};

  Future<T> answer<T>(String name, T value) async {
    calls.update(name, (n) => n + 1, ifAbsent: () => 1);
    if (failures[name] case final error?) throw error;
    return value;
  }

  int count(String name) => calls[name] ?? 0;
}

class _FakeLibrarySource with _Calls implements LibraryRemoteSource {
  @override
  Future<AlbumDetail> album(String id) => answer(
    'album',
    AlbumDetail(
      album: _album,
      tracks: [_track('t1'), _track('t2')],
      owned: true,
    ),
  );

  @override
  Future<ArtistDetail> artist(String id) => answer(
    'artist',
    const ArtistDetail(artist: _artist, albums: [_album], genres: ['rock']),
  );

  @override
  Future<List<Track>> shuffledTracks({int? limit}) =>
      answer('shuffledTracks', [_track('t2'), _track('t1')]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlaylistSource with _Calls implements PlaylistRemoteSource {
  @override
  Future<PlaylistDetail> playlist(String id) => answer(
    'playlist',
    PlaylistDetail(
      summary: _playlist,
      items: [
        PlaylistItem(id: 'i1', sort: 0, track: _track('t1'), isPlayable: true),
      ],
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHomeSource with _Calls implements HomeRemoteSource {
  @override
  Future<List<RecentItem>> recentlyListened({int? limit}) =>
      answer('recentlyListened', const [RecentItem.artist(artist: _artist)]);

  @override
  Future<List<Artist>> recentlyAdded({int? limit}) =>
      answer('recentlyAdded', const [_artist]);

  @override
  Future<List<MixSummary>> mixes() => answer('mixes', const [
    MixSummary(id: 'm1', name: 'Mix', description: 'd'),
  ]);

  @override
  Future<List<PodcastSummary>> topPodcasts({int? limit}) =>
      answer('topPodcasts', const [PodcastSummary(id: 'pc1', title: 'Pod')]);
}

class _FakeSearchSource with _Calls implements SearchRemoteSource {
  final List<(String, LibrarySearchType?)> libraryQueries = [];

  @override
  Future<LibrarySearchResults> library(
    String q, {
    LibrarySearchType? type,
    int? limit,
    int? offset,
  }) {
    libraryQueries.add((q, type));
    return answer('library', LibrarySearchResults(tracks: [_track(q)]));
  }

  @override
  Future<DiscoverResults> discover(
    String q, {
    DiscoverSearchType? type,
    int? limit,
  }) => answer(
    'discover',
    const DiscoverResults(hits: [SearchHit.artist(artist: _artist)]),
  );
}

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late FakeReachability reachability;
  late CacheStore store;
  late Swr swr;
  late _FakeLibrarySource librarySource;
  late _FakePlaylistSource playlistSource;
  late _FakeHomeSource homeSource;
  late _FakeSearchSource searchSource;
  late CachedLibraryRepository library;
  late CachedPlaylistRepository playlists;
  late CachedHomeRepository home;
  late CachedSearchRepository search;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    reachability = FakeReachability();
    store = CacheStore(db, clock);
    swr = Swr(clock: clock, reachability: reachability);
    librarySource = _FakeLibrarySource();
    playlistSource = _FakePlaylistSource();
    homeSource = _FakeHomeSource();
    searchSource = _FakeSearchSource();
    final pages = PagedSources(store, clock, reachability);
    library = CachedLibraryRepository(librarySource, store, swr, pages);
    playlists = CachedPlaylistRepository(playlistSource, store, swr, pages);
    home = CachedHomeRepository(homeSource, store, swr);
    search = CachedSearchRepository(searchSource, store, swr);
  });

  tearDown(() => db.close());

  /// Listens to [stream] until the event queue is empty and returns what it
  /// emitted and the errors it raised.
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

  /// Proves that the read [open] is fetched again only once it is older
  /// than [ttl], counting fetches with [calls].
  Future<void> expectTtl<T>(
    Duration ttl,
    Stream<Cached<T>> Function() open,
    int Function() calls,
  ) async {
    final (first, errors) = await listenOnce(open());
    expect(errors, isEmpty);
    expect(first, hasLength(1));
    expect(calls(), 1);

    clock.advance(ttl - const Duration(seconds: 1));
    await listenOnce(open());
    expect(calls(), 1, reason: 'still fresh just inside $ttl');

    clock.advance(const Duration(seconds: 2));
    final (second, _) = await listenOnce(open());
    expect(calls(), 2, reason: 'stale just past $ttl');
    expect(second.first.refreshing, isTrue);
    expect(second.last.refreshing, isFalse);
  }

  test('album detail uses the 10-minute TTL and round-trips', () async {
    await expectTtl(
      const Duration(minutes: 10),
      () => library.album('al-1'),
      () => librarySource.count('album'),
    );

    final cached = await library.album('al-1').first;
    expect(cached.value, await librarySource.album('al-1'));
    final entries = await (db.select(
      db.listEntries,
    )..where((e) => e.listKey.equals('album:al-1:tracks'))).get();
    expect(entries.map((e) => e.entityKey), ['t1', 't2']);
    expect((await db.select(db.albums).getSingle()).detailFetchedAt, isNotNull);
  });

  test(
    'shuffledTracks asks the server every time and keeps its order',
    () async {
      expect(await library.shuffledTracks(), [_track('t2'), _track('t1')]);
      await library.shuffledTracks();
      expect(librarySource.count('shuffledTracks'), 2);
    },
  );

  test('artist detail uses the 10-minute TTL and round-trips', () async {
    await expectTtl(
      const Duration(minutes: 10),
      () => library.artist('ar-1'),
      () => librarySource.count('artist'),
    );

    expect(
      (await library.artist('ar-1').first).value,
      await librarySource.artist('ar-1'),
    );
    expect(
      (await db.select(db.artists).getSingle()).detailFetchedAt,
      isNotNull,
    );
  });

  test('playlist detail uses the 10-minute TTL and round-trips', () async {
    await expectTtl(
      const Duration(minutes: 10),
      () => playlists.playlist('p1'),
      () => playlistSource.count('playlist'),
    );

    expect(
      (await playlists.playlist('p1').first).value,
      await playlistSource.playlist('p1'),
    );
    final entries = await (db.select(
      db.listEntries,
    )..where((e) => e.listKey.equals('playlist:p1'))).get();
    expect(entries.map((e) => e.entityKey), ['t1']);
  });

  test('home shelves use the 5-minute TTL', () async {
    for (final (name, open) in <(String, Stream<Cached<Object>> Function())>[
      ('recentlyListened', home.recentlyListened),
      ('recentlyAdded', home.recentlyAdded),
      ('mixes', home.mixes),
      ('topPodcasts', home.topPodcasts),
    ]) {
      await expectTtl(
        const Duration(minutes: 5),
        open,
        () => homeSource.count(name),
      );
    }

    expect((await home.recentlyListened().first).value, const [
      RecentItem.artist(artist: _artist),
    ]);
    expect((await home.mixes().first).value.single.id, 'm1');
    expect((await home.topPodcasts().first).value.single.id, 'pc1');
    expect((await home.recentlyAdded().first).value, const [_artist]);
  });

  test('search results use the 2-minute TTL', () async {
    await expectTtl(
      const Duration(minutes: 2),
      () => search.search('abba', SearchScope.all),
      () => searchSource.count('library'),
    );
  });

  test('each search scope calls the endpoints it needs', () async {
    final (all, _) = await listenOnce(search.search('q', SearchScope.all));
    expect(all.single.value.library!.tracks.single.meta.title, 'q');
    expect(all.single.value.discover!.hits, hasLength(1));
    expect(searchSource.count('discover'), 1);

    final (lib, _) = await listenOnce(search.search('q', SearchScope.library));
    expect(lib.single.value.discover, isNull);

    final (disc, _) = await listenOnce(
      search.search('q', SearchScope.discover),
    );
    expect(disc.single.value.library, isNull);
    expect(searchSource.count('discover'), 2);

    await listenOnce(search.search('q', SearchScope.podcasts));
    expect(searchSource.libraryQueries, [
      ('q', null),
      ('q', null),
      ('q', LibrarySearchType.podcasts),
    ]);
  });

  test('a search result is not served offline for a different query', () async {
    await listenOnce(search.search('abba', SearchScope.all));
    reachability.set(Reachability.serverUnreachable);
    clock.advance(const Duration(hours: 1));

    final (other, otherErrors) = await listenOnce(
      search.search('abb', SearchScope.all),
    );
    expect(other, isEmpty);
    expect(otherErrors, [isA<Offline>()]);

    final (otherScope, scopeErrors) = await listenOnce(
      search.search('abba', SearchScope.library),
    );
    expect(otherScope, isEmpty);
    expect(scopeErrors, [isA<Offline>()]);

    final (same, sameErrors) = await listenOnce(
      search.search('abba', SearchScope.all),
    );
    expect(sameErrors, isEmpty);
    expect(same.single.value.library!.tracks.single.meta.title, 'abba');
    expect(searchSource.count('library'), 1);
  });

  test('FeatureDisabled from mixes reaches the stream as an error', () async {
    homeSource.failures['mixes'] = const FeatureDisabled(status: 404);

    final (values, errors) = await listenOnce(home.mixes());

    expect(values, isEmpty);
    expect(errors, [isA<FeatureDisabled>()]);
  });

  test('refresh refetches regardless of age', () async {
    await listenOnce(library.album('al-1'));
    await listenOnce(library.artist('ar-1'));
    await listenOnce(playlists.playlist('p1'));
    await listenOnce(home.recentlyListened());
    await listenOnce(home.recentlyAdded());
    await listenOnce(home.mixes());
    await listenOnce(home.topPodcasts());
    await listenOnce(search.search('q', SearchScope.all));

    await library.refreshAlbum('al-1');
    await library.refreshArtist('ar-1');
    await playlists.refreshPlaylist('p1');
    await home.refreshRecentlyListened();
    await home.refreshRecentlyAdded();
    await home.refreshMixes();
    await home.refreshTopPodcasts();
    await search.refreshSearch('q', SearchScope.all);

    expect(librarySource.calls, {'album': 2, 'artist': 2});
    expect(playlistSource.calls, {'playlist': 2});
    expect(homeSource.calls, {
      'recentlyListened': 2,
      'recentlyAdded': 2,
      'mixes': 2,
      'topPodcasts': 2,
    });
    expect(searchSource.calls, {'library': 2, 'discover': 2});
  });
}
