// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/outbox/optimistic_overlay.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/data/playlist/playlist_outbox_handlers.dart';
import 'package:soundspan/shared/data/playlist/playlist_overlay.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/data/preference_overlay.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/util/uuid.dart';

/// The reserved playlist id of Liked Songs (doc 02, Routing), which no
/// edit accepts.
const String _likedId = 'liked';

/// [PlaylistRepository] over the cache and [PlaylistRemoteSource].
///
/// A detail is stored whole as the blob `playlist:<id>`; the playlist row is
/// upserted with its detail time, and the items' tracks are also written as
/// the list `playlist:<id>`. The playlists list comes from [_pages] as the
/// list `playlists`. A detail shows the pending likes and playlist edits
/// of the outbox ([PendingOps]), and the list the pending creates, renames
/// and deletes.
///
/// Edits enqueue into [_outbox]; the handlers of
/// `playlist_outbox_handlers.dart` are the only callers of the playlist
/// write endpoints. Without an outbox every edit throws [StateError].
class CachedPlaylistRepository implements PlaylistRepository {
  /// A repository reading [_remote] into [_store] through [_swr] and
  /// [_pages], overlaid with the ops [_pending] answers, and editing
  /// through [_outbox].
  new(
    this._remote,
    this._store,
    this._swr,
    this._pages, {
    this._pending = noPendingOps,
    this._outbox,
  });

  final PlaylistRemoteSource _remote;
  final CacheStore _store;
  final Swr _swr;
  final PagedSources _pages;
  final PendingOps _pending;
  final Outbox? _outbox;

  @override
  Stream<Cached<PlaylistDetail>> playlist(String id) => overlay(
    _swr.watch(
      key: 'playlist:$id',
      ttl: detailTtl,
      cache: () => _store.watchBlob(
        'playlist:$id',
        (json) => PlaylistDetail.fromJson(json! as Map<String, Object?>),
      ),
      // A playlist created on this device is unknown to the server until
      // its create is sent; it is read from the cache alone.
      fetch: () async {
        if (!_isTemporary(id)) await _fetch(id);
      },
    ),
    _pending({...trackPreferenceOps, ...playlistEditOps}),
    (detail, ops) =>
        overlayPlaylistDetail(applyPlaylistEdits(detail, ops), ops),
    hold: preferenceHold,
  );

  @override
  Future<void> refreshPlaylist(String id) =>
      _swr.refresh('playlist:$id', () => _fetch(id));

  @override
  PagedSource<PlaylistSummary> playlists() => OverlaidPagedSource(
    _serverPlaylists(),
    _pending,
    playlistEditOps,
    overlayPlaylistsPage,
  );

  PagedSource<PlaylistSummary> _serverPlaylists() => _pages.create(
    listKey: playlistsListKey,
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

  Future<void> _fetch(String id) => fetchPlaylistInto(_remote, _store, id);

  @override
  Future<String> create(String name) async {
    final trimmed = _validName(name);
    final outbox = _requireOutbox();
    final tempId = '${TempIdRewriter.prefix}${Uuid.v4()}';
    final summary = PlaylistSummary(
      id: tempId,
      name: trimmed,
      trackCount: 0,
      isOwner: true,
      isPublic: false,
    );
    await _store.transaction(() async {
      await _store.upsertPlaylists([summary], detail: true);
      await _store.putBlob(
        'playlist:$tempId',
        PlaylistDetail(summary: summary, items: const []),
      );
    });
    await outbox.enqueue(PlaylistCreateOp(tempId: tempId, name: trimmed));
    return tempId;
  }

  @override
  Future<void> rename(String id, String name) async {
    _checkId(id);
    final trimmed = _validName(name);
    await _requireOutbox().enqueue(
      PlaylistRenameOp(playlistId: id, name: trimmed),
    );
  }

  @override
  Future<void> delete(String id) async {
    _checkId(id);
    final seq = await _requireOutbox().enqueue(
      PlaylistDeleteOp(playlistId: id),
    );
    // The create was still pending: the server never saw the playlist.
    if (seq == null) await _store.removePlaylist(id);
  }

  @override
  Future<int> addTracks(String id, List<Track> tracks) async {
    _checkId(id);
    final outbox = _requireOutbox();
    var added = 0;
    for (final track in tracks) {
      final playbackId = track.playbackId;
      if (playbackId == null) continue;
      await outbox.enqueue(
        PlaylistAddOp(
          playlistId: id,
          opUuid: Uuid.v4(),
          playbackId: playbackId.value,
          metadata: track.meta.toJson(),
        ),
      );
      added++;
    }
    return added;
  }

  @override
  Future<void> removeItem(String id, PlaylistItem item) async {
    _checkId(id);
    final playbackId = item.track.playbackId;
    if (playbackId == null) {
      throw ArgumentError.value(item, 'item', 'has no playbackId');
    }
    final outbox = _requireOutbox();
    final pendingAdd = item.pendingOpUuid;
    final seq = await outbox.enqueue(
      PlaylistRemoveOp(
        playlistId: id,
        opUuid: pendingAdd ?? Uuid.v4(),
        playbackId: playbackId.value,
      ),
    );
    if (seq != null) return;
    // The add was cancelled; a pending reorder must not name its track.
    final pending = await outbox
        .watchPending(opTypes: {PlaylistReorderOp.type})
        .first;
    for (final entry in pending) {
      if (entry.op case PlaylistReorderOp(:final playlistId, :final playbackIds)
          when playlistId == id &&
              playbackIds.any((value) => PlaybackId(value) == playbackId)) {
        await outbox.enqueue(
          PlaylistReorderOp(
            playlistId: id,
            playbackIds: [
              for (final value in playbackIds)
                if (PlaybackId(value) != playbackId) value,
            ],
          ),
        );
      }
    }
  }

  @override
  Future<void> reorder(String id, List<PlaybackId> order) async {
    _checkId(id);
    await _requireOutbox().enqueue(
      PlaylistReorderOp(
        playlistId: id,
        playbackIds: [for (final playbackId in order) playbackId.value],
      ),
    );
  }

  @override
  Stream<PlaylistIdResolved> get resolvedIds =>
      _outbox?.resolved.map(
        (event) => (tempId: event.tempId, realId: event.realId),
      ) ??
      const Stream.empty();

  Outbox _requireOutbox() =>
      _outbox ?? (throw StateError('This repository has no outbox'));

  static bool _isTemporary(String id) => id.startsWith(TempIdRewriter.prefix);

  static void _checkId(String id) {
    if (id == _likedId) {
      throw ArgumentError.value(id, 'id', 'Liked Songs cannot be edited');
    }
  }

  static String _validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    return trimmed;
  }
}
