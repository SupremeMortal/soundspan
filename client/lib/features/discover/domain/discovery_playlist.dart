// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'discovery_playlist.freezed.dart';
part 'discovery_playlist.g.dart';

/// The current week's discovery playlist.
@freezed
abstract class DiscoveryPlaylist with _$DiscoveryPlaylist {
  /// Creates a discovery playlist.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory DiscoveryPlaylist({
    /// The tracks, in server order; at least one.
    required List<Track> tracks,
  }) = _DiscoveryPlaylist;

  /// Decodes a playlist written by [DiscoveryPlaylist.toJson].
  factory fromJson(Map<String, Object?> json) =>
      _$DiscoveryPlaylistFromJson(json);
}
