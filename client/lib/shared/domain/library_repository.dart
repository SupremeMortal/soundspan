// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/album.dart';
import 'package:soundspan/shared/domain/artist.dart';
import 'package:soundspan/shared/domain/cached.dart';

/// Library reads, served from the cache and refreshed in the background
/// (doc 05, Read Policy: Stale-While-Revalidate).
abstract interface class LibraryRepository {
  /// The album [id] with its tracks.
  Stream<Cached<AlbumDetail>> album(String id);

  /// Fetches the album [id] again, whatever its age.
  Future<void> refreshAlbum(String id);

  /// The artist [id] with albums, top tracks and similar artists.
  Stream<Cached<ArtistDetail>> artist(String id);

  /// Fetches the artist [id] again, whatever its age.
  Future<void> refreshArtist(String id);
}
