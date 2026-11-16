// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

/// A playlist as the Library and Home screens list it.
@freezed
abstract class PlaylistSummary with _$PlaylistSummary {
  /// Creates a playlist summary.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PlaylistSummary({
    /// The server's playlist id.
    required String id,

    /// The playlist name.
    required String name,

    /// The number of tracks.
    required int trackCount,

    /// Whether the signed-in user owns the playlist.
    required bool isOwner,

    /// Whether the playlist is public.
    required bool isPublic,

    /// Up to four values to pass to the cover-art endpoint, for the mosaic.
    @Default(<String>[]) List<String> coverRefs,
  }) = _PlaylistSummary;

  /// Decodes a summary written by [PlaylistSummary.toJson].
  factory fromJson(Map<String, Object?> json) =>
      _$PlaylistSummaryFromJson(json);
}

/// One entry of a playlist.
@freezed
abstract class PlaylistItem with _$PlaylistItem {
  /// Creates a playlist item.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PlaylistItem({
    /// The server's item id.
    required String id,

    /// The item's position key; items are listed in ascending order.
    required int sort,

    /// The track.
    required Track track,

    /// Whether the server can play the item; a row that cannot is shown
    /// disabled.
    required bool isPlayable,

    /// The server's explanation when the item cannot be played.
    String? message,

    /// The `opUuid` of the pending add that shows this item before the
    /// server has it; null for an item the server sent.
    String? pendingOpUuid,
  }) = _PlaylistItem;

  /// Decodes an item written by [PlaylistItem.toJson].
  factory fromJson(Map<String, Object?> json) => _$PlaylistItemFromJson(json);
}

/// A playlist with its items.
@freezed
abstract class PlaylistDetail with _$PlaylistDetail {
  /// Creates a playlist detail.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PlaylistDetail({
    /// The playlist.
    required PlaylistSummary summary,

    /// The items in ascending [PlaylistItem.sort] order.
    required List<PlaylistItem> items,
  }) = _PlaylistDetail;

  /// Decodes a detail written by [PlaylistDetail.toJson].
  factory fromJson(Map<String, Object?> json) => _$PlaylistDetailFromJson(json);
}
