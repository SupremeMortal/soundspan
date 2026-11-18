// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/artist.dart';
import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan/shared/domain/mix.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/domain/recent_item.dart';

/// The Home shelves, served from the cache and refreshed in the background
/// (doc 05, Read Policy: Stale-While-Revalidate).
abstract interface class HomeRepository {
  /// Continue Listening.
  Stream<Cached<List<RecentItem>>> recentlyListened();

  /// Fetches Continue Listening again, whatever its age.
  Future<void> refreshRecentlyListened();

  /// Recently added artists.
  Stream<Cached<List<Artist>>> recentlyAdded();

  /// Fetches the recently added artists again, whatever their age.
  Future<void> refreshRecentlyAdded();

  /// The user's mixes; errors with `FeatureDisabled` when the server has
  /// them off.
  Stream<Cached<List<MixSummary>>> mixes();

  /// Fetches the mixes again, whatever their age.
  Future<void> refreshMixes();

  /// Popular podcasts.
  Stream<Cached<List<PodcastSummary>>> topPodcasts();

  /// Fetches the popular podcasts again, whatever their age.
  Future<void> refreshTopPodcasts();
}
