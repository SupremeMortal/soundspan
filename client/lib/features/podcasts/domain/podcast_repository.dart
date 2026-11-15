// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/podcasts/domain/podcast_detail.dart';
import 'package:soundspan/features/podcasts/domain/podcast_ref.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// The user's podcasts, served from the cache and refreshed in the
/// background (doc 05, Read Policy: Stale-While-Revalidate), and the
/// podcast writes that are direct calls rather than outbox operations.
abstract interface class PodcastRepository {
  /// The podcasts the user is subscribed to, most recently subscribed first.
  Stream<Cached<List<Podcast>>> subscribed();

  /// Fetches the subscribed podcasts again, whatever their age; throws
  /// `Offline` while the server is not reachable.
  Future<void> refreshSubscribed();

  /// The subscribed podcast [podcastId] with its episodes, newest first.
  Stream<Cached<PodcastDetail>> detail(String podcastId);

  /// Fetches the podcast [podcastId] again, whatever its age; throws
  /// `Offline` while the server is not reachable.
  Future<void> refreshDetail(String podcastId);

  /// Subscribes to the podcast [ref] names. Throws `Offline` while the
  /// server is not reachable.
  Future<void> subscribe(PodcastRef ref);

  /// Unsubscribes from the podcast [podcastId]. Throws `Offline` while the
  /// server is not reachable.
  Future<void> unsubscribe(String podcastId);

  /// Saves the user's progress in the episode [episodeId] of [podcastId]
  /// on the server, then in the cached episode.
  Future<void> postProgress({
    required String podcastId,
    required String episodeId,
    required double currentTimeSec,
    required int durationSec,
    required bool isFinished,
  });
}
