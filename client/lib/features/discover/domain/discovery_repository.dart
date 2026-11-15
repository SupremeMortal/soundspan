// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/discover/domain/discovery_artist.dart';
import 'package:soundspan/features/discover/domain/discovery_playlist.dart';
import 'package:soundspan/shared/domain/cached.dart';

/// The discovery content of servers with `discovery` on, served from the
/// cache and refreshed in the background (doc 05, Read Policy:
/// Stale-While-Revalidate). Each read errors with `FeatureDisabled` when
/// the server has discovery off.
abstract interface class DiscoveryRepository {
  /// Artists similar to the ones the user plays most.
  Stream<Cached<List<DiscoveryArtist>>> recommendedForYou({int limit = 20});

  /// Fetches [recommendedForYou] again, whatever its age.
  Future<void> refreshRecommendedForYou({int limit = 20});

  /// The artists of the popularity chart.
  Stream<Cached<List<DiscoveryArtist>>> popularArtists({int limit = 20});

  /// Fetches [popularArtists] again, whatever its age.
  Future<void> refreshPopularArtists({int limit = 20});

  /// This week's discovery playlist; null when the server has none.
  Stream<Cached<DiscoveryPlaylist?>> currentDiscovery();

  /// Fetches [currentDiscovery] again, whatever its age.
  Future<void> refreshCurrentDiscovery();
}
