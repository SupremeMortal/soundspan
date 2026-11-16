// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/outbox/optimistic_overlay.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/data/preference_overlay.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// [PlaylistRepository] over the cache and [PlaylistRemoteSource].
///
/// A detail is stored whole as the blob `playlist:<id>`; the playlist row is
/// upserted with its detail time, and the items' tracks are also written as
/// the list `playlist:<id>`. The playlists list comes from [_pages] as the
/// list `playlists`. A detail shows the pending likes of the outbox
/// ([PendingOps]).
class CachedPlaylistRepository implements PlaylistRepository {
  /// A repository reading [_remote] into [_store] through [_swr] and
  /// [_pages], overlaid with the ops [_pending] answers.
  new(
    this._remote,
    this._store,
    this._swr,
    this._pages, {
    this._pending = noPendingOps,
  });

  final PlaylistRemoteSource _remote;
  final CacheStore _store;
  final Swr _swr;
  final PagedSources _pages;
  final PendingOps _pending;

  @override
  Stream<Cached<PlaylistDetail>> playlist(String id) => overlay(
    _swr.watch(
      key: 'playlist:$id',
      ttl: detailTtl,
      cache: () => _store.watchBlob(
        'playlist:$id',
        (json) => PlaylistDetail.fromJson(json! as Map<String, Object?>),
      ),
      fetch: () => _fetch(id),
    ),
    _pending(trackPreferenceOps),
    overlayPlaylistDetail,
    hold: preferenceHold,
  );

  @override
  Future<void> refreshPlaylist(String id) =>
      _swr.refresh('playlist:$id', () => _fetch(id));

  @override
  PagedSource<PlaylistSummary> playlists() => _pages.create(
    listKey: 'playlists',
    pageSize: listPageSize,
    fetchPage: (request) async {
      final page = await _remote.playlists(
        offset: request.offset,
        limit: request.limit,
      );
      return FetchedPage(
        items: page.items,
        hasMore: page.hasMore,
        total: page.total,
      );
    },
  );

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
