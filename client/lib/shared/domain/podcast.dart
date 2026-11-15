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

    /// The podcast's description, if any.
    String? description,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,

    /// How many episodes the podcast has, if known.
    int? episodeCount,
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

    /// The podcast's RSS feed URL, if the server sent one.
    String? feedUrl,

    /// The podcast's iTunes directory id, if the server sent one.
    String? itunesId,
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

    /// The episode's description, if any.
    String? description,

    /// The duration in whole seconds, if known.
    int? durationSec,

    /// When the episode was published, in UTC, if known.
    DateTime? publishedAt,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,

    /// How far the user got, or null when they never played it.
    EpisodeProgress? progress,
  }) = _Episode;

  /// Decodes an episode written by [Episode.toJson].
  factory fromJson(Map<String, Object?> json) => _$EpisodeFromJson(json);
}

/// How far the user got in an [Episode].
@freezed
abstract class EpisodeProgress with _$EpisodeProgress {
  /// Creates a progress.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory EpisodeProgress({
    /// The position reached, in seconds.
    required double currentTimeSec,

    /// Whether the user finished the episode.
    required bool isFinished,
  }) = _EpisodeProgress;

  /// Decodes a progress written by [EpisodeProgress.toJson].
  factory fromJson(Map<String, Object?> json) =>
      _$EpisodeProgressFromJson(json);
}
