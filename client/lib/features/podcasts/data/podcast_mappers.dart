// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Maps the generated podcast wire models to domain values and back (doc 02,
/// Layers and Allowed Dependencies).
library;

import 'package:soundspan/features/podcasts/domain/podcast_detail.dart';
import 'package:soundspan/features/podcasts/domain/podcast_ref.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// A podcast of the subscribed list. The latest episodes the server sends
/// with it are not mapped; the detail carries the episodes.
Podcast podcastFromSubscribed(api.SubscribedPodcast wire) => Podcast(
  id: wire.id,
  title: wire.title,
  author: wire.author,
  description: wire.description,
  artworkRef: wire.coverUrl,
  episodeCount: wire.episodeCount,
);

/// The user's progress in an episode, or null when they never played it.
EpisodeProgress? episodeProgressFromWire(api.EpisodeProgress? wire) =>
    wire == null
    ? null
    : EpisodeProgress(
        currentTimeSec: wire.currentTime.toDouble(),
        isFinished: wire.isFinished,
      );

/// One episode of the podcast [podcastId]; its publication time is UTC.
Episode episodeFromWire(api.PodcastEpisode wire, {required String podcastId}) =>
    Episode(
      id: wire.id,
      podcastId: podcastId,
      title: wire.title,
      description: wire.description,
      durationSec: wire.duration,
      publishedAt: wire.publishedAt.toUtc(),
      artworkRef: wire.imageUrl,
      progress: episodeProgressFromWire(wire.progress),
    );

/// A subscribed podcast with its episodes in server order, newest first.
/// The server sends no episode count with a detail, so the podcast's count
/// is the number of episodes.
PodcastDetail podcastDetailFromWire(api.PodcastDetail wire) => PodcastDetail(
  podcast: Podcast(
    id: wire.id,
    title: wire.title,
    author: wire.author,
    description: wire.description,
    artworkRef: wire.coverUrl,
    episodeCount: wire.episodes.length,
  ),
  episodes: [
    for (final episode in wire.episodes)
      episodeFromWire(episode, podcastId: wire.id),
  ],
);

/// The subscribe request naming [ref]: `feedUrl` or `itunesId`, never both.
api.SubscribePodcastRequest subscribeRequestFromRef(PodcastRef ref) =>
    switch (ref) {
      FeedPodcastRef(:final feedUrl) => api.SubscribePodcastRequest(
        feedUrl: feedUrl,
      ),
      ItunesPodcastRef(:final itunesId) => api.SubscribePodcastRequest(
        itunesId: itunesId,
      ),
    };
