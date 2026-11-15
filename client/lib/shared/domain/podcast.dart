// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';

part 'podcast.freezed.dart';
part 'podcast.g.dart';

/// A podcast the user follows.
@freezed
abstract class Podcast with _$Podcast {
  /// Creates a podcast.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory Podcast({
    /// The server's podcast id.
    required String id,

    /// The podcast title.
    required String title,

    /// The author, if known.
    String? author,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,
  }) = _Podcast;

  /// Decodes a podcast written by [Podcast.toJson].
  factory fromJson(Map<String, Object?> json) => _$PodcastFromJson(json);
}

/// A podcast as a directory or search lists it; the user may not follow it.
@freezed
abstract class PodcastSummary with _$PodcastSummary {
  /// Creates a podcast summary.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PodcastSummary({
    /// The podcast id the server sent.
    required String id,

    /// The podcast title.
    required String title,

    /// The author, if known.
    String? author,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,
  }) = _PodcastSummary;

  /// Decodes a summary written by [PodcastSummary.toJson].
  factory fromJson(Map<String, Object?> json) => _$PodcastSummaryFromJson(json);
}

/// One episode of a [Podcast].
@freezed
abstract class Episode with _$Episode {
  /// Creates an episode.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory Episode({
    /// The server's episode id.
    required String id,

    /// The id of the podcast the episode belongs to.
    required String podcastId,

    /// The episode title.
    required String title,

    /// The duration in whole seconds, if known.
    int? durationSec,

    /// When the episode was published, in UTC, if known.
    DateTime? publishedAt,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,
  }) = _Episode;

  /// Decodes an episode written by [Episode.toJson].
  factory fromJson(Map<String, Object?> json) => _$EpisodeFromJson(json);
}
