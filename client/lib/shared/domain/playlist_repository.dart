// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan/shared/domain/playlist.dart';

/// Playlist reads, served from the cache and refreshed in the background
/// (doc 05, Read Policy: Stale-While-Revalidate).
abstract interface class PlaylistRepository {
  /// The playlist [id] with its items.
  Stream<Cached<PlaylistDetail>> playlist(String id);

  /// Fetches the playlist [id] again, whatever its age.
  Future<void> refreshPlaylist(String id);
}
