// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/domain.dart';

part 'podcast_ref.freezed.dart';

/// What `PodcastRepository.subscribe` sends to name a podcast: its RSS feed
/// URL or its iTunes directory id.
@freezed
sealed class PodcastRef with _$PodcastRef {
  /// The podcast whose RSS feed is at `feedUrl`.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PodcastRef.feed(String feedUrl) = FeedPodcastRef;

  /// The podcast the iTunes directory knows as `itunesId`.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PodcastRef.itunes(String itunesId) = ItunesPodcastRef;

  /// The reference of a directory or search [summary]: its feed URL when the
  /// server sent one (the server prefers it), else its iTunes id; null when
  /// it has neither.
  static PodcastRef? fromSummary(PodcastSummary summary) {
    if (summary.feedUrl case final feedUrl?) return PodcastRef.feed(feedUrl);
    if (summary.itunesId case final itunesId?) {
      return PodcastRef.itunes(itunesId);
    }
    return null;
  }
}
