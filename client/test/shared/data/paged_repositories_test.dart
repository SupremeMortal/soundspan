// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/library/cached_library_repository.dart';
import 'package:soundspan/shared/data/library/library_remote_source.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/data/playlist/cached_playlist_repository.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';

Track _track(String id) => Track(
  meta: TrackMeta(title: id, artist: 'Artist', album: 'Album', durationSec: 1),
  playbackId: PlaybackId(id),
);

/// Records the arguments of every paged call.
class _LibrarySource implements LibraryRemoteSource {
  final List<Map<String, Object?>> calls = [];

  @override
  Future<api.OffsetPage<Album>> albums({
    String? artistId,
    int? offset,
    int? limit,
    AlbumFilter? filter,
    AlbumSort? sortBy,
    LibraryOrigin? origin,
  }) async {
    calls.add({
      'call': 'albums',
      'artistId': artistId,
      'offset': offset,
      'limit': limit,
      'filter': filter,
      'sortBy': sortBy,
      'origin': origin,
    });
    return api.OffsetPage(
      items: const [
        Album(
          id: 'al-1',
          title: 'Album',
          artistName: 'Artist',
          artistId: 'ar-1',
        ),
      ],
      offset: offset ?? 0,
      limit: limit ?? 0,
      total: 1,
    );
  }

  @override
  Future<api.OffsetPage<Artist>> artists({
    int? offset,
    int? limit,
    String? cursor,
    ArtistFilter? filter,
    ArtistSort? sortBy,
    LibraryOrigin? origin,
    String? query,
  }) async {
    calls.add({
      'call': 'artists',
      'offset': offset,
      'limit': limit,
      'cursor': cursor,
      'filter': filter,
      'sortBy': sortBy,
      'origin': origin,
    });
    return api.OffsetPage(
      items: const [Artist(id: 'ar-1', name: 'Artist')],
      offset: offset ?? 0,
      limit: limit ?? 0,
      total: 1,
    );
  }

  @override
  Future<api.OffsetPage<Track>> tracks({
    String? albumId,
    int? offset,
    int? limit,
    TrackSort? sortBy,
    LibraryOrigin? origin,
  }) async {
    calls.add({
      'call': 'tracks',
      'albumId': albumId,
      'offset': offset,
      'limit': limit,
      'sortBy': sortBy,
      'origin': origin,
    });
    return api.OffsetPage(
      items: [_track('t1')],
      offset: offset ?? 0,
      limit: limit ?? 0,
      total: 1,
    );
  }

  @override
  Future<api.KeysetPage<Track, LikedCursor>> liked({
    int? limit,
    LikedCursor? cursor,
  }) async {
    calls.add({'call': 'liked', 'limit': limit, 'cursor': cursor});
    return api.KeysetPage(items: [_track('t1')], hasMore: false, total: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PlaylistSource implements PlaylistRemoteSource {
  final List<Map<String, Object?>> calls = [];

  @override
  Future<api.OffsetPage<PlaylistSummary>> playlists({
    int? offset,
    int? limit,
  }) async {
    calls.add({'call': 'playlists', 'offset': offset, 'limit': limit});
    return api.OffsetPage(
      items: [
        if ((offset ?? 0) == 0)
          const PlaylistSummary(
            id: 'p1',
            name: 'Mine',
            trackCount: 0,
            isOwner: true,
            isPublic: false,
          ),
      ],
      offset: offset ?? 0,
      limit: limit ?? 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late CacheDatabase db;
  late _LibrarySource librarySource;
  late _PlaylistSource playlistSource;
  late CachedLibraryRepository library;
  late CachedPlaylistRepository playlists;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    final clock = FakeClock();
    final reachability = FakeReachability();
    final store = CacheStore(db, clock);
    final swr = Swr(clock: clock, reachability: reachability);
    final pages = PagedSources(store, clock, reachability);
    librarySource = _LibrarySource();
    playlistSource = _PlaylistSource();
    library = CachedLibraryRepository(librarySource, store, swr, pages);
    playlists = CachedPlaylistRepository(playlistSource, store, swr, pages);
  });

  tearDown(() => db.close());

  /// Loads the first page of [source] and answers its first snapshot with
  /// an item.
  Future<PagedSnapshot<T>> firstPage<T>(PagedSource<T> source) async {
    addTearDown(source.dispose);
    final loaded = source.watch().firstWhere((s) => s.itemAt(0) != null);
    source.ensureVisible(0, 0);
    return await loaded;
  }

  test('albums pass the query and use the grid page size', () async {
    const query = AlbumQuery(
      artistId: 'ar-1',
      filter: AlbumFilter.owned,
      sortBy: AlbumSort.recent,
      origin: LibraryOrigin.local,
    );
    final source = library.albums(query);
    expect(source.pageSize, gridPageSize);
    final snapshot = await firstPage(source);

    expect(snapshot.itemAt(0)?.id, 'al-1');
    expect(librarySource.calls.first, {
      'call': 'albums',
      'artistId': 'ar-1',
      'offset': 0,
      'limit': 60,
      'filter': AlbumFilter.owned,
      'sortBy': AlbumSort.recent,
      'origin': LibraryOrigin.local,
    });
  });

  test('artists pass the query and use the grid page size', () async {
    const query = ArtistQuery(
      filter: ArtistFilter.owned,
      sortBy: ArtistSort.tracks,
      origin: LibraryOrigin.remote,
    );
    final source = library.artists(query);
    expect(source.pageSize, gridPageSize);
    final snapshot = await firstPage(source);

    expect(snapshot.itemAt(0)?.id, 'ar-1');
    expect(librarySource.calls.first, {
      'call': 'artists',
      'offset': 0,
      'limit': 60,
      'cursor': null,
      'filter': ArtistFilter.owned,
      'sortBy': ArtistSort.tracks,
      'origin': LibraryOrigin.remote,
    });
  });

  test('tracks pass the query and use the list page size', () async {
    const query = TrackQuery(
      albumId: 'al-1',
      sortBy: TrackSort.nameDesc,
      origin: LibraryOrigin.peers,
    );
    final source = library.tracks(query);
    expect(source.pageSize, listPageSize);
    final snapshot = await firstPage(source);

    expect(snapshot.itemAt(0)?.meta.title, 't1');
    expect(librarySource.calls.first, {
      'call': 'tracks',
      'albumId': 'al-1',
      'offset': 0,
      'limit': 100,
      'sortBy': TrackSort.nameDesc,
      'origin': LibraryOrigin.peers,
    });
  });

  test(
    'liked tracks start without a cursor and use the list page size',
    () async {
      final source = library.likedTracks();
      expect(source.pageSize, listPageSize);
      final snapshot = await firstPage(source);

      expect(snapshot.itemAt(0)?.meta.title, 't1');
      expect(snapshot.total, 1);
      expect(librarySource.calls, [
        {'call': 'liked', 'limit': 100, 'cursor': null},
      ]);
    },
  );

  test('playlists use the list page size', () async {
    final source = playlists.playlists();
    expect(source.pageSize, listPageSize);
    final snapshot = await firstPage(source);

    expect(snapshot.itemAt(0)?.id, 'p1');
    expect(snapshot.total, 1);
    expect(playlistSource.calls.first, {
      'call': 'playlists',
      'offset': 0,
      'limit': 100,
    });
  });
}
