// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// A track titled [title]; without [playbackId] it is not playable.
Track browseTrack(String title, {String? playbackId}) => Track(
  meta: TrackMeta(
    title: title,
    artist: 'Artist $title',
    album: 'Album',
    durationSec: 100,
  ),
  playbackId: playbackId == null ? null : PlaybackId(playbackId),
);

/// A [MediaBrowseSource] serving fixed lists; with [failing] every call
/// throws.
class FakeMediaBrowseSource implements MediaBrowseSource {
  /// The recently played tracks.
  List<Track> recentTracks = const [];

  /// The playlists.
  List<BrowsePlaylist> playlistList = const [];

  /// The tracks of each playlist by id.
  Map<String, List<Track>> playlistTrackMap = const {};

  /// The albums.
  List<BrowseAlbum> albumList = const [];

  /// The tracks of each album by id.
  Map<String, List<Track>> albumTrackMap = const {};

  /// The tracks each search query finds.
  Map<String, List<Track>> searchHits = const {};

  /// Whether every call throws.
  bool failing = false;

  /// The `limit` of the last [albums] call.
  int? lastAlbumLimit;

  /// How many calls were made.
  int calls = 0;

  Future<T> _answer<T>(T value) async {
    calls++;
    if (failing) throw StateError('source failed');
    return value;
  }

  @override
  Future<List<Track>> recent({int limit = 50}) =>
      _answer(recentTracks.take(limit).toList());

  @override
  Future<List<BrowsePlaylist>> playlists() => _answer(playlistList);

  @override
  Future<List<Track>> playlistTracks(String playlistId) =>
      _answer(playlistTrackMap[playlistId] ?? const []);

  @override
  Future<List<BrowseAlbum>> albums({int limit = 200}) {
    lastAlbumLimit = limit;
    return _answer(albumList.take(limit).toList());
  }

  @override
  Future<List<Track>> albumTracks(String albumId) =>
      _answer(albumTrackMap[albumId] ?? const []);

  @override
  Future<List<Track>> searchTracks(String query, {int limit = 25}) =>
      _answer((searchHits[query] ?? const []).take(limit).toList());
}
