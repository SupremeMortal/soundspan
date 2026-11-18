// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/data/home/home_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The network half of the Home shelves: calls the generated library,
/// discovery and podcasts clients and returns domain values.
/// `ApiException` propagates unchanged, including `FeatureDisabled` from
/// [mixes].
class HomeRemoteSource {
  /// Creates a source over the generated clients.
  new({
    required api.LibraryClient libraryClient,
    required api.DiscoveryClient discoveryClient,
    required api.PodcastsClient podcastsClient,
  }) : _library = libraryClient,
       _discovery = discoveryClient,
       _podcasts = podcastsClient;

  final api.LibraryClient _library;
  final api.DiscoveryClient _discovery;
  final api.PodcastsClient _podcasts;

  /// Continue Listening (`GET /library/recently-listened`).
  Future<List<RecentItem>> recentlyListened({int? limit}) async =>
      recentItemsFromWire(await _library.listRecentlyListened(limit: limit));

  /// Recently added artists (`GET /library/recently-added`).
  Future<List<Artist>> recentlyAdded({int? limit}) async =>
      recentlyAddedFromWire(await _library.listRecentlyAdded(limit: limit));

  /// The user's generated mixes (`GET /mixes`).
  Future<List<MixSummary>> mixes() async => [
    for (final mix in await _discovery.listMixes()) mixSummaryFromWire(mix),
  ];

  /// Popular podcasts of the directory (`GET /podcasts/discover/top`).
  Future<List<PodcastSummary>> topPodcasts({int? limit}) async => [
    for (final podcast in await _podcasts.listTopPodcasts(limit: limit))
      podcastSummaryFromWire(podcast),
  ];
}
