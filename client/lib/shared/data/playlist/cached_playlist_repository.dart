// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// [PlaylistRepository] over the cache and [PlaylistRemoteSource].
///
/// A detail is stored whole as the blob `playlist:<id>`; the playlist row is
/// upserted with its detail time, and the items' tracks are also written as
/// the list `playlist:<id>`.
class CachedPlaylistRepository implements PlaylistRepository {
  /// A repository reading [_remote] into [_store] through [_swr].
  new(this._remote, this._store, this._swr);

  final PlaylistRemoteSource _remote;
  final CacheStore _store;
  final Swr _swr;

  @override
  Stream<Cached<PlaylistDetail>> playlist(String id) => _swr.watch(
    key: 'playlist:$id',
    ttl: detailTtl,
    cache: () => _store.watchBlob(
      'playlist:$id',
      (json) => PlaylistDetail.fromJson(json! as Map<String, Object?>),
    ),
    fetch: () => _fetch(id),
  );

  @override
  Future<void> refreshPlaylist(String id) =>
      _swr.refresh('playlist:$id', () => _fetch(id));

  Future<void> _fetch(String id) async {
    final detail = await _remote.playlist(id);
    await _store.transaction(() async {
      await _store.upsertPlaylists([detail.summary], detail: true);
      await _store.writePage(
        'playlist:$id',
        offset: 0,
        items: [for (final item in detail.items) item.track],
        total: detail.items.length,
        complete: true,
      );
      await _store.putBlob('playlist:$id', detail);
    });
  }
}
