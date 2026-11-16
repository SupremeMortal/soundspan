// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The optimistic overlays of playlist edits (doc 07, Worker: optimistic
/// state): pure functions that show the pending `playlist*` ops on the
/// playlists list and on a playlist detail.
library;

import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// The op types of playlist edits.
const Set<String> playlistEditOps = {
  PlaylistCreateOp.type,
  PlaylistRenameOp.type,
  PlaylistDeleteOp.type,
  PlaylistAddOp.type,
  PlaylistRemoveOp.type,
  PlaylistReorderOp.type,
};

/// The item id a pending add with [opUuid] shows under.
String pendingItemId(String opUuid) => 'pending:$opUuid';

/// The playlist a pending create of [ops] stands for: owned, named as
/// created and counting the pending adds to it. It is the same summary the
/// repository caches under the temporary id.
PlaylistSummary pendingCreatedPlaylist(
  PlaylistCreateOp create,
  List<OutboxEntry> ops,
) => PlaylistSummary(
  id: create.tempId,
  name: create.name,
  trackCount: ops
      .where(
        (entry) => switch (entry.op) {
          PlaylistAddOp(:final playlistId) => playlistId == create.tempId,
          _ => false,
        },
      )
      .length,
  isOwner: true,
  isPublic: create.isPublic ?? false,
);

/// [detail] with the pending edits of [ops] to it applied, in `seq`
/// order: a rename changes the name, an add appends an item marked with
/// its `opUuid`, a remove hides the items of its track, and a reorder
/// orders the items it lists and leaves the others, and later adds, after
/// them.
PlaylistDetail applyPlaylistEdits(
  PlaylistDetail detail,
  List<OutboxEntry> ops,
) {
  final id = detail.summary.id;
  var summary = detail.summary;
  var items = detail.items;
  var changed = false;
  for (final entry in ops) {
    switch (entry.op) {
      case PlaylistRenameOp(:final playlistId, :final name)
          when playlistId == id:
        summary = summary.copyWith(name: name);
        changed = true;
      case PlaylistAddOp(
            :final playlistId,
            :final opUuid,
            :final playbackId,
            :final metadata,
          )
          when playlistId == id:
        items = [
          ...items,
          PlaylistItem(
            id: pendingItemId(opUuid),
            sort: (items.lastOrNull?.sort ?? -1) + 1,
            track: Track(
              meta: TrackMeta.fromJson(metadata),
              playbackId: PlaybackId(playbackId),
            ),
            isPlayable: true,
            pendingOpUuid: opUuid,
          ),
        ];
        changed = true;
      case PlaylistRemoveOp(:final playlistId, :final playbackId)
          when playlistId == id:
        items = removePlaylistTrack(items, PlaybackId(playbackId));
        changed = true;
      case PlaylistReorderOp(:final playlistId, :final playbackIds)
          when playlistId == id:
        items = orderPlaylistItems(items, [
          for (final value in playbackIds) PlaybackId(value),
        ]);
        changed = true;
      default:
        break;
    }
  }
  if (!changed) return detail;
  return detail.copyWith(
    summary: summary.copyWith(trackCount: items.length),
    items: items,
  );
}

/// [items] without the items of the track [playbackId].
List<PlaylistItem> removePlaylistTrack(
  List<PlaylistItem> items,
  PlaybackId playbackId,
) => [
  for (final item in items)
    if (item.track.playbackId != playbackId) item,
];

/// [items] with those whose track [order] names first, in that order, and
/// the rest after them in their current order.
List<PlaylistItem> orderPlaylistItems(
  List<PlaylistItem> items,
  List<PlaybackId> order,
) {
  final rank = {for (final (index, id) in order.indexed) id: index};
  final listed =
      [
        for (final item in items)
          if (rank.containsKey(item.track.playbackId)) item,
      ]..sort(
        (a, b) =>
            rank[a.track.playbackId]!.compareTo(rank[b.track.playbackId]!),
      );
  return [
    ...listed,
    for (final item in items)
      if (!rank.containsKey(item.track.playbackId)) item,
  ];
}

/// [snapshot] of the playlists list with the pending edits of [ops]: the
/// playlists created while pending first, newest first, then the loaded
/// playlists with pending renames applied and pending deletes left out,
/// the playlists after a deleted one moving up.
PagedSnapshot<PlaylistSummary> overlayPlaylistsPage(
  PagedSnapshot<PlaylistSummary> snapshot,
  List<OutboxEntry> ops,
) {
  final names = <String, String>{};
  final deleted = <String>{};
  final created = <PlaylistSummary>[];
  for (final entry in ops) {
    switch (entry.op) {
      case PlaylistRenameOp(:final playlistId, :final name):
        names[playlistId] = name;
      case PlaylistDeleteOp(:final playlistId):
        deleted.add(playlistId);
      case final PlaylistCreateOp create:
        created.insert(0, pendingCreatedPlaylist(create, ops));
      default:
        break;
    }
  }
  final loaded = snapshot.loaded;
  final loadedIds = {for (final playlist in loaded.values) playlist.id};
  final prepended = [
    for (final playlist in created)
      if (!loadedIds.contains(playlist.id) && !deleted.contains(playlist.id))
        playlist.copyWith(name: names[playlist.id] ?? playlist.name),
  ];
  final items = <int, PlaylistSummary>{
    for (final (index, playlist) in prepended.indexed) index: playlist,
  };
  var omitted = 0;
  for (final index in loaded.keys.toList()..sort()) {
    final playlist = loaded[index]!;
    if (deleted.contains(playlist.id)) {
      omitted++;
      continue;
    }
    final name = names[playlist.id];
    items[index + prepended.length - omitted] = name == null
        ? playlist
        : playlist.copyWith(name: name);
  }
  final total = snapshot.total;
  return PagedSnapshot<PlaylistSummary>(
    total: total == null ? null : total + prepended.length - omitted,
    items: items,
    refreshing: snapshot.refreshing,
    refreshError: snapshot.refreshError,
  );
}
