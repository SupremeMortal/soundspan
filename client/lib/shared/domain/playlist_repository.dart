// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan/shared/domain/paged_source.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/playlist.dart';
import 'package:soundspan/shared/domain/track.dart';

/// Playlist reads, served from the cache and refreshed in the background
/// (doc 05, Read Policy: Stale-While-Revalidate), and playlist edits, which
/// go through the outbox and show at once (doc 07, Outbox).
///
/// Every edit only enqueues. A name is trimmed and an empty one is
/// rejected with [ArgumentError]; the reserved id `liked` (Liked Songs)
/// rejects every edit with [ArgumentError]. Edits accept a temporary id
/// (`tmp_…`) returned by [create].
abstract interface class PlaylistRepository {
  /// The playlist [id] with its items.
  Stream<Cached<PlaylistDetail>> playlist(String id);

  /// Fetches the playlist [id] again, whatever its age.
  Future<void> refreshPlaylist(String id);

  /// The user's playlists, newest first, in pages of [listPageSize].
  PagedSource<PlaylistSummary> playlists();

  /// Creates a playlist named [name] and answers its temporary id, under
  /// which it is listed and can be edited until the server assigns one.
  Future<String> create(String name);

  /// Renames the playlist [id] to [name].
  Future<void> rename(String id, String name);

  /// Deletes the playlist [id]; its pending edits are dropped.
  Future<void> delete(String id);

  /// Appends [tracks] to the playlist [id], skipping tracks without a
  /// `playbackId`; answers how many were added.
  Future<int> addTracks(String id, List<Track> tracks);

  /// Removes [item] from the playlist [id]. An item that is only a pending
  /// add cancels that add. Throws [ArgumentError] for an item without a
  /// `playbackId`.
  Future<void> removeItem(String id, PlaylistItem item);

  /// Puts the items of the playlist [id] in [order], which names every
  /// item's `playbackId`.
  Future<void> reorder(String id, List<PlaybackId> order);

  /// Every temporary id of [create] the server replaced with its own.
  Stream<PlaylistIdResolved> get resolvedIds;
}

/// The temporary id of a playlist created on this device and the id the
/// server gave it.
typedef PlaylistIdResolved = ({String tempId, String realId});

/// Whether the items of [detail] can be reordered: the playlist is the
/// user's and every item has a `playbackId`, because a reorder names the
/// full order by `playbackId`.
bool canReorderPlaylist(PlaylistDetail detail) =>
    detail.summary.isOwner &&
    detail.items.every((item) => item.track.playbackId != null);
