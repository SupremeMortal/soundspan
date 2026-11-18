// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/album.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'artist.freezed.dart';
part 'artist.g.dart';

/// An artist as the browse screens show it.
@freezed
abstract class Artist with _$Artist {
  /// Creates an artist.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory Artist({
    /// The server's artist id.
    required String id,

    /// The artist name.
    required String name,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,
  }) = _Artist;

  /// Decodes an artist written by [Artist.toJson].
  factory fromJson(Map<String, Object?> json) => _$ArtistFromJson(json);
}

/// An artist similar to another one.
@freezed
abstract class SimilarArtist with _$SimilarArtist {
  /// Creates a similar artist.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SimilarArtist({
    /// The artist name.
    required String name,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,

    /// The library artist id, when the library holds the artist.
    String? libraryId,
  }) = _SimilarArtist;

  /// Decodes a similar artist written by [SimilarArtist.toJson].
  factory fromJson(Map<String, Object?> json) => _$SimilarArtistFromJson(json);
}

/// An artist with albums, top tracks, similar artists and biography.
@freezed
abstract class ArtistDetail with _$ArtistDetail {
  /// Creates an artist detail.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory ArtistDetail({
    /// The artist.
    required Artist artist,

    /// The artist's albums.
    @Default(<Album>[]) List<Album> albums,

    /// The artist's most played tracks.
    @Default(<Track>[]) List<Track> topTracks,

    /// Artists similar to this one.
    @Default(<SimilarArtist>[]) List<SimilarArtist> similarArtists,

    /// The artist's biography, if the server has one.
    String? biography,

    /// The artist's genres.
    @Default(<String>[]) List<String> genres,
  }) = _ArtistDetail;

  /// Decodes an artist detail written by [ArtistDetail.toJson].
  factory fromJson(Map<String, Object?> json) => _$ArtistDetailFromJson(json);
}
