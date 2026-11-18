// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/queue_item.dart';

/// What the players show of a queue entry.
extension PlayerItemText on QueueItem {
  /// The track or episode title.
  String get playerTitle => switch (this) {
    TrackQueueItem(:final track) => track.meta.title,
    EpisodeQueueItem(:final episode) => episode.title,
  };

  /// The artist of a track, the podcast of an episode.
  String get playerSubtitle => switch (this) {
    TrackQueueItem(:final track) => track.meta.artist,
    EpisodeQueueItem(:final podcast) => podcast.title,
  };

  /// The cover of a track, or of an episode and else its podcast.
  String? get playerArtworkRef => switch (this) {
    TrackQueueItem(:final track) => track.meta.artworkRef,
    EpisodeQueueItem(:final episode, :final podcast) =>
      episode.artworkRef ?? podcast.artworkRef,
  };

  /// The length of the item; zero when it is not known.
  Duration get playerDuration => Duration(
    seconds: switch (this) {
      TrackQueueItem(:final track) => track.meta.durationSec,
      EpisodeQueueItem(:final episode) => episode.durationSec ?? 0,
    },
  );

  /// The artist page a track links to; null for an episode and for a track
  /// without one.
  String? get playerArtistId => switch (this) {
    TrackQueueItem(:final track) => track.artistId,
    EpisodeQueueItem() => null,
  };
}
