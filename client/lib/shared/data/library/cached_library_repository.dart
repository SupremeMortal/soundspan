// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/library/library_remote_source.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// [LibraryRepository] over the cache and [LibraryRemoteSource].
///
/// A detail is stored whole as the blob `album:<id>` or `artist:<id>`; the
/// album or artist row is upserted with its detail time, and an album's
/// tracks are also written as the list `album:<id>:tracks`.
class CachedLibraryRepository implements LibraryRepository {
  /// A repository reading [_remote] into [_store] through [_swr].
  new(this._remote, this._store, this._swr);

  final LibraryRemoteSource _remote;
  final CacheStore _store;
  final Swr _swr;

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
