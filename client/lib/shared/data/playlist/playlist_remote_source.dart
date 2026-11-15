// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/data/playback_metadata.dart';
import 'package:soundspan/shared/data/playlist/playlist_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The network half of the playlist repositories: calls the generated
/// `PlaylistsClient` and returns domain values. `ApiException` propagates
/// unchanged; each write is one request, with no caching, queuing or
/// optimistic state. Liked Songs is `LibraryRemoteSource.liked`, not a playlist
/// here.
final class PlaylistRemoteSource {
  /// Creates a source over the generated playlists client.
  new(this._client);

  /// The server's page size when none is requested.
  static const serverDefaultLimit = 500;

  final api.PlaylistsClient _client;

  /// One page of playlists, newest first (`GET /playlists`). The server
  /// sends no total, so the page's `total` is null.
  Future<api.OffsetPage<PlaylistSummary>> playlists({
    int? offset,
    int? limit,
  }) async {
    final response = await _client.listPlaylists(offset: offset, limit: limit);
    return api.OffsetPage(
      items: [
        for (final playlist in response) playlistSummaryFromWire(playlist),
      ],
      offset: offset ?? 0,
      limit: limit ?? serverDefaultLimit,
    );
  }

  /// A playlist with its items in sort order (`GET /playlists/:id`).
  Future<PlaylistDetail> playlist(String id) async =>
      playlistDetailFromWire(await _client.getPlaylist(id: id));

  /// Creates a playlist named [name] (`POST /playlists`) and answers it,
  /// owned and empty. [isPublic] defaults to the server's private.
  Future<PlaylistSummary> create(String name, {bool? isPublic}) async {
    final record = await _client.createPlaylist(
      body: api.CreatePlaylistRequest(name: name, isPublic: isPublic ?? false),
    );
    return PlaylistSummary(
      id: record.id,
      name: record.name,
      trackCount: 0,
      isOwner: true,
      isPublic: record.isPublic,
    );
  }

  /// Renames the playlist [id] or changes its visibility
  /// (`PUT /playlists/:id`); only the fields given are sent.
  Future<void> update(String id, {String? name, bool? isPublic}) async {
    await _client.updatePlaylist(
      id: id,
      body: api.UpdatePlaylistRequest(name: name, isPublic: isPublic),
    );
  }

  /// Deletes the playlist [id] (`DELETE /playlists/:id`).
  Future<void> delete(String id) async {
    await _client.deletePlaylist(id: id);
  }

  /// Appends the track [playbackId] to the playlist [id]
  /// (`POST /playlists/:id/items`) with [meta] as its `metadata`, and
  /// answers the new item, or the existing one when the track was already
  /// in the playlist.
  Future<PlaylistItem> addItem(
    String id,
    PlaybackId playbackId, {
    required TrackMeta meta,
  }) async {
    final response = await _client.addPlaylistItem(
      id: id,
      body: api.AddPlaylistItemRequest(
        playbackId: playbackId.value,
        metadata: playbackMetadataFromMeta(meta),
      ),
    );
    return playlistItemFromWire(
      response.asPlaylistItemDuplicate?.item ?? response.asPlaylistItem!,
    );
  }

  /// Removes the track [playbackId] from the playlist [id]
  /// (`DELETE /playlists/:id/items/:playbackId`); the id travels as one
  /// percent-encoded path segment.
  Future<void> removeItem(String id, PlaybackId playbackId) async {
    await _client.removePlaylistItem(
      id: id,
      playbackId: Uri.encodeComponent(playbackId.value),
    );
  }

  /// Puts the items of the playlist [id] in [fullOrder], which names every
  /// track of the playlist (`PUT /playlists/:id/items/reorder`).
  Future<void> reorder(String id, List<PlaybackId> fullOrder) async {
    await _client.reorderPlaylistItems(
      id: id,
      body: api.ReorderPlaylistItemsRequest(
        playbackIds: [for (final playbackId in fullOrder) playbackId.value],
      ),
    );
  }
}
