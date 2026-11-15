// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/artist.dart';
import 'package:soundspan/shared/domain/podcast.dart';

part 'recent_item.freezed.dart';
part 'recent_item.g.dart';

/// One entry of the Home screen's Continue Listening shelf.
@Freezed(unionKey: 'kind')
sealed class RecentItem with _$RecentItem {
  /// An artist listened to recently.
  @FreezedUnionValue('artist')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory RecentItem.artist({
    /// The artist.
    required Artist artist,
  }) = RecentArtist;

  /// A podcast listened to recently.
  @FreezedUnionValue('podcast')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory RecentItem.podcast({
    /// The podcast.
    required Podcast podcast,
  }) = RecentPodcast;

  /// Decodes an item written by [RecentItem.toJson].
  factory fromJson(Map<String, Object?> json) => _$RecentItemFromJson(json);
}
