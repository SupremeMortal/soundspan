// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';

part 'discovery_artist.freezed.dart';
part 'discovery_artist.g.dart';

/// An artist of the "Recommended For You" or "Popular Artists" lists.
@freezed
abstract class DiscoveryArtist with _$DiscoveryArtist {
  /// Creates a discovery artist.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory DiscoveryArtist({
    /// The artist name.
    required String name,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,

    /// The id of the artist in the user's library, when the payload names
    /// one; null for an artist the library does not hold.
    String? libraryArtistId,
  }) = _DiscoveryArtist;

  /// Decodes an artist written by [DiscoveryArtist.toJson].
  factory fromJson(Map<String, Object?> json) =>
      _$DiscoveryArtistFromJson(json);
}
