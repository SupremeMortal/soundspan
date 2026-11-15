// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/data/playlist/playlist_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The network half of the playlist repositories: calls the generated
/// `PlaylistsClient` and returns domain values. `ApiException` propagates
/// unchanged. Liked Songs is `LibraryRemoteSource.liked`, not a playlist
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
}
