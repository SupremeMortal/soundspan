// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/library/library_remote_source.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api show OffsetPage;

/// [LibraryRepository] over the cache and [LibraryRemoteSource].
///
/// A detail is stored whole as the blob `album:<id>` or `artist:<id>`; the
/// album or artist row is upserted with its detail time, and an album's
/// tracks are also written as the list `album:<id>:tracks`. Paged lists
/// come from [_pages] under the query's `listKey`, or `liked`.
class CachedLibraryRepository implements LibraryRepository {
  /// A repository reading [_remote] into [_store] through [_swr] and
  /// [_pages].
  new(this._remote, this._store, this._swr, this._pages);

  final LibraryRemoteSource _remote;
  final CacheStore _store;
  final Swr _swr;
  final PagedSources _pages;

  @override
  Stream<Cached<AlbumDetail>> album(String id) => _swr.watch(
    key: 'album:$id',
    ttl: detailTtl,
    cache: () => _store.watchBlob(
      'album:$id',
      (json) => AlbumDetail.fromJson(json! as Map<String, Object?>),
    ),
    fetch: () => _fetchAlbum(id),
  );

  @override
  Future<void> refreshAlbum(String id) =>
      _swr.refresh('album:$id', () => _fetchAlbum(id));

  @override
  Stream<Cached<ArtistDetail>> artist(String id) => _swr.watch(
    key: 'artist:$id',
    ttl: detailTtl,
    cache: () => _store.watchBlob(
      'artist:$id',
      (json) => ArtistDetail.fromJson(json! as Map<String, Object?>),
    ),
    fetch: () => _fetchArtist(id),
  );

  @override
  Future<void> refreshArtist(String id) =>
      _swr.refresh('artist:$id', () => _fetchArtist(id));

  @override
  PagedSource<Album> albums(AlbumQuery query) => _pages.create(
    listKey: query.listKey,
    pageSize: gridPageSize,
    fetchPage: (request) async => _offsetPage(
      await _remote.albums(
        artistId: query.artistId,
        offset: request.offset,
        limit: request.limit,
        filter: query.filter,
        sortBy: query.sortBy,
        origin: query.origin,
      ),
    ),
  );

  @override
  PagedSource<Artist> artists(ArtistQuery query) => _pages.create(
    listKey: query.listKey,
    pageSize: gridPageSize,
    fetchPage: (request) async => _offsetPage(
      await _remote.artists(
        offset: request.offset,
        limit: request.limit,
        cursor: request.cursor as String?,
        filter: query.filter,
        sortBy: query.sortBy,
        origin: query.origin,
      ),
    ),
  );

  @override
  PagedSource<Track> tracks(TrackQuery query) => _pages.create(
    listKey: query.listKey,
    pageSize: listPageSize,
    fetchPage: (request) async => _offsetPage(
      await _remote.tracks(
        albumId: query.albumId,
        offset: request.offset,
        limit: request.limit,
        sortBy: query.sortBy,
        origin: query.origin,
      ),
    ),
  );

  @override
  PagedSource<Track> likedTracks() => _pages.create(
    listKey: 'liked',
    pageSize: listPageSize,
    style: PagingStyle.keyset,
    fetchPage: (request) async {
      final page = await _remote.liked(
        limit: request.limit,
        cursor: request.cursor as LikedCursor?,
      );
      return FetchedPage(
        items: page.items,
        hasMore: page.hasMore,
        total: page.total,
        nextCursor: page.nextCursor,
      );
    },
  );

  static FetchedPage<T> _offsetPage<T>(api.OffsetPage<T> page) => FetchedPage(
    items: page.items,
    hasMore: page.hasMore,
    total: page.total,
    nextCursor: page.nextCursor,
  );

  Future<void> _fetchAlbum(String id) async {
    final detail = await _remote.album(id);
    await _store.transaction(() async {
      await _store.upsertAlbums([detail.album], detail: true);
      await _store.writePage(
        'album:$id:tracks',
        offset: 0,
        items: detail.tracks,
        total: detail.tracks.length,
        complete: true,
      );
      await _store.putBlob('album:$id', detail);
    });
  }

  Future<void> _fetchArtist(String id) async {
    final detail = await _remote.artist(id);
    await _store.transaction(() async {
      await _store.upsertArtists([detail.artist], detail: true);
      await _store.putBlob('artist:$id', detail);
    });
  }
}
