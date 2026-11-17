// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/playlist/playlist_overlay.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/cache.dart';

/// The cache key of the playlists list.
const String playlistsListKey = 'playlists';

/// Opens the profile's cache on first use.
typedef PlaylistCacheAccess = Future<CacheStore> Function();

/// Fetches the playlist [id] from [remote] and stores it in [store]: the
/// detail as the blob `playlist:<id>`, the row with its detail time and
/// the items' tracks as the list `playlist:<id>`, in one transaction.
Future<PlaylistDetail> fetchPlaylistInto(
  PlaylistRemoteSource remote,
  CacheStore store,
  String id,
) async {
  final detail = await remote.playlist(id);
  await store.transaction(() async {
    await store.upsertPlaylists([detail.summary], detail: true);
    await store.writePage(
      'playlist:$id',
      offset: 0,
      items: [for (final item in detail.items) item.track],
      total: detail.items.length,
      complete: true,
    );
    await store.putBlob('playlist:$id', detail);
  });
  return detail;
}

/// Delivers one kind of playlist op and applies its outcome to the cache
/// (doc 07, Worker).
///
/// On success the cached detail takes the edit and is marked stale, and
/// the playlists list is marked stale, so the next read of either fetches
/// it. A dropped create removes the playlist cached under its temporary
/// id; a conflict on any other op fetches the playlist again, and a
/// missing target removes it from the cache. Any other drop needs nothing:
/// removing the op removes its overlay.
final class PlaylistOpHandler<T extends OutboxOp> implements OutboxHandler<T> {
  /// Creates the handler that sends with [_send] and edits the cached
  /// detail with [_edit].
  const new(this._remote, this._cache, this._send, {this._edit});

  final PlaylistRemoteSource _remote;
  final PlaylistCacheAccess _cache;
  final Future<Object?> Function(PlaylistRemoteSource remote, T op) _send;
  final PlaylistDetail Function(PlaylistDetail detail, T op, Object? response)?
  _edit;

  @override
  Future<Object?> send(T op) => _send(_remote, op);

  @override
  Future<void> onSuccess(T op, Object? response) async {
    final store = await _cache();
    switch (op) {
      case PlaylistCreateOp():
        // The worker has already given the cached rows the server's id.
        if (response is PlaylistSummary) {
          await store.prependPlaylist(playlistsListKey, response);
        }
      case PlaylistDeleteOp(:final playlistId):
        await store.removePlaylist(playlistId);
      default:
        final edit = _edit;
        final id = _playlistIdOf(op);
        if (edit != null && id != null) {
          await store.editPlaylistDetail(
            id,
            (detail) => edit(detail, op, response),
          );
        }
    }
    await store.markListStale(playlistsListKey);
  }

  @override
  Future<void> onDropped(T op, OutboxDropReason reason) async {
    final store = await _cache();
    if (op case PlaylistCreateOp(:final tempId)) {
      await store.removePlaylist(tempId);
      return;
    }
    final id = _playlistIdOf(op);
    if (id == null) return;
    switch (reason) {
      case OutboxDropReason.conflict:
        await fetchPlaylistInto(_remote, store, id);
        await store.markListStale(playlistsListKey);
      case OutboxDropReason.notFound:
        await store.removePlaylist(id);
      case OutboxDropReason.invalid:
        break;
    }
  }

  static String? _playlistIdOf(OutboxOp op) => switch (op) {
    PlaylistRenameOp(:final playlistId) ||
    PlaylistDeleteOp(:final playlistId) ||
    PlaylistAddOp(:final playlistId) ||
    PlaylistRemoveOp(:final playlistId) ||
    PlaylistReorderOp(:final playlistId) => playlistId,
    _ => null,
  };
}

/// The handlers of the six playlist ops over [remote] and the cache
/// [cache] opens. The create handler answers the created
/// `PlaylistSummary`, whose id replaces the temporary one.
List<OutboxHandlerEntry> playlistOutboxHandlers(
  PlaylistRemoteSource remote,
  PlaylistCacheAccess cache,
) => [
  outboxHandlerEntry(
    PlaylistCreateOp.type,
    PlaylistOpHandler<PlaylistCreateOp>(
      remote,
      cache,
      (remote, op) => remote.create(op.name, isPublic: op.isPublic),
    ),
  ),
  outboxHandlerEntry(
    PlaylistRenameOp.type,
    PlaylistOpHandler<PlaylistRenameOp>(
      remote,
      cache,
      (remote, op) async => await remote.update(op.playlistId, name: op.name),
      edit: (detail, op, _) =>
          detail.copyWith(summary: detail.summary.copyWith(name: op.name)),
    ),
  ),
  outboxHandlerEntry(
    PlaylistDeleteOp.type,
    PlaylistOpHandler<PlaylistDeleteOp>(
      remote,
      cache,
      (remote, op) async => await remote.delete(op.playlistId),
    ),
  ),
  outboxHandlerEntry(
    PlaylistAddOp.type,
    PlaylistOpHandler<PlaylistAddOp>(
      remote,
      cache,
      (remote, op) => remote.addItem(
        op.playlistId,
        PlaybackId(op.playbackId),
        meta: TrackMeta.fromJson(op.metadata),
      ),
      edit: (detail, op, response) {
        if (response is! PlaylistItem ||
            detail.items.any((item) => item.id == response.id)) {
          return detail;
        }
        final items = [...detail.items, response];
        return detail.copyWith(
          summary: detail.summary.copyWith(trackCount: items.length),
          items: items,
        );
      },
    ),
  ),
  outboxHandlerEntry(
    PlaylistRemoveOp.type,
    PlaylistOpHandler<PlaylistRemoveOp>(
      remote,
      cache,
      (remote, op) async =>
          await remote.removeItem(op.playlistId, PlaybackId(op.playbackId)),
      edit: (detail, op, _) {
        final items = removePlaylistTrack(
          detail.items,
          PlaybackId(op.playbackId),
        );
        return detail.copyWith(
          summary: detail.summary.copyWith(trackCount: items.length),
          items: items,
        );
      },
    ),
  ),
  outboxHandlerEntry(
    PlaylistReorderOp.type,
    PlaylistOpHandler<PlaylistReorderOp>(
      remote,
      cache,
      (remote, op) async => await remote.reorder(op.playlistId, [
        for (final id in op.playbackIds) PlaybackId(id),
      ]),
      edit: (detail, op, _) => detail.copyWith(
        items: orderPlaylistItems(detail.items, [
          for (final id in op.playbackIds) PlaybackId(id),
        ]),
      ),
    ),
  ),
];

/// The outbox handlers of the playlist repository.
final Provider<List<OutboxHandlerEntry>> playlistOutboxHandlersProvider =
    Provider<List<OutboxHandlerEntry>>(
      (ref) => playlistOutboxHandlers(
        ref.watch(playlistRemoteSourceProvider),
        () => ref.read(cacheStoreProvider.future),
      ),
      dependencies: [playlistRemoteSourceProvider, cacheStoreProvider],
    );
