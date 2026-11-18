// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The library the car's media browser shows (doc 10, Android Auto): the
/// seam between the browse tree in `core` and the cached repositories,
/// which `core` may not reach through `features`.
library;

import 'package:soundspan/shared/domain/track.dart';

/// The lists Android Auto browses and searches, read through the profile's
/// cache so lists loaded before are served without a network.
abstract interface class MediaBrowseSource {
  /// The tracks listened to recently, at most [limit].
  Future<List<Track>> recent({int limit = 50});

  /// The user's playlists.
  Future<List<BrowsePlaylist>> playlists();

  /// The tracks of the playlist [playlistId], in order.
  Future<List<Track>> playlistTracks(String playlistId);

  /// The library's albums, alphabetical by title, at most [limit].
  Future<List<BrowseAlbum>> albums({int limit = 200});

  /// The tracks of the album [albumId], in order.
  Future<List<Track>> albumTracks(String albumId);

  /// The tracks [query] finds, at most [limit].
  Future<List<Track>> searchTracks(String query, {int limit = 25});
}

/// A playlist as the browse tree lists it.
final class BrowsePlaylist {
  /// Creates a playlist entry.
  const new({required this.id, required this.name, required this.trackCount});

  /// The playlist's id.
  final String id;

  /// The playlist's name.
  final String name;

  /// How many tracks it holds.
  final int trackCount;
}

/// An album as the browse tree lists it.
final class BrowseAlbum {
  /// Creates an album entry.
  const new({required this.id, required this.title, required this.artist});

  /// The album's id.
  final String id;

  /// The album's title.
  final String title;

  /// The album's artist.
  final String artist;
}
