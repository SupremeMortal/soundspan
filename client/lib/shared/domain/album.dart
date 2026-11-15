// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'album.freezed.dart';
part 'album.g.dart';

/// An album as the browse screens show it.
@freezed
abstract class Album with _$Album {
  /// Creates an album.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory Album({
    /// The server's album id.
    required String id,

    /// The album title.
    required String title,

    /// The album artist's name.
    required String artistName,

    /// The album artist's id.
    required String artistId,

    /// The release year, if known.
    int? year,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,

    /// The number of tracks, when the server sent the tracks.
    int? trackCount,

    /// The release type (album, EP, single), when the server sent one.
    String? releaseType,
  }) = _Album;

  /// Decodes an album written by [Album.toJson].
  factory fromJson(Map<String, Object?> json) => _$AlbumFromJson(json);
}

/// An album with its tracks.
@freezed
abstract class AlbumDetail with _$AlbumDetail {
  /// Creates an album detail.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory AlbumDetail({
    /// The album.
    required Album album,

    /// The album's tracks in disc and track order.
    required List<Track> tracks,

    /// Whether the user's library holds the album.
    required bool owned,
  }) = _AlbumDetail;

  /// Decodes an album detail written by [AlbumDetail.toJson].
  factory fromJson(Map<String, Object?> json) => _$AlbumDetailFromJson(json);
}
