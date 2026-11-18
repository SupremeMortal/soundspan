// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'queue_item.freezed.dart';
part 'queue_item.g.dart';

/// Where an item was queued from. Drives loudness "auto" mode and playlist
/// radio (doc 02, Domain Model).
enum QueueContextKind {
  /// An album.
  album,

  /// A playlist.
  playlist,

  /// An artist.
  artist,

  /// A mix.
  mix,

  /// A radio station.
  radio,

  /// Search results.
  search,

  /// A library list.
  library,

  /// A single track.
  single,
}

/// The context an item was queued from.
@freezed
abstract class QueueContext with _$QueueContext {
  /// Creates a queue context.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory QueueContext({
    /// What kind of list the item came from.
    required QueueContextKind kind,

    /// The id of that list (album, playlist, artist, mix), if it has one.
    String? id,

    /// The title of that list, for display.
    String? title,
  }) = _QueueContext;

  /// Decodes a context written by [QueueContext.toJson].
  factory fromJson(Map<String, Object?> json) => _$QueueContextFromJson(json);
}

/// One entry of the play queue.
@Freezed(unionKey: 'type')
sealed class QueueItem with _$QueueItem {
  /// A track entry.
  @FreezedUnionValue('track')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory QueueItem.track({
    /// Client-generated UUID, unique per queue entry.
    required String queueItemId,

    /// The track.
    required Track track,

    /// Where the track was queued from.
    required QueueContext context,
  }) = TrackQueueItem;

  /// A podcast episode entry.
  @FreezedUnionValue('episode')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory QueueItem.episode({
    /// Client-generated UUID, unique per queue entry.
    required String queueItemId,

    /// The episode.
    required Episode episode,

    /// The podcast the episode belongs to.
    required Podcast podcast,
  }) = EpisodeQueueItem;

  /// Decodes an item written by [QueueItem.toJson].
  factory fromJson(Map<String, Object?> json) => _$QueueItemFromJson(json);
}
