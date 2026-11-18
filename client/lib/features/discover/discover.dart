// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Discovery: the recommended and popular artists, this week's discovery
/// playlist and the Explore screen that collects them (doc 09, Home and
/// Shell by Window Class).
library;

export 'discover_providers.dart' show discoveryRepositoryProvider;
export 'domain/discovery_artist.dart' show DiscoveryArtist;
export 'domain/discovery_playlist.dart' show DiscoveryPlaylist;
export 'domain/discovery_repository.dart' show DiscoveryRepository;
export 'ui/discovery_artist_card.dart' show DiscoveryArtistCard;
export 'ui/discovery_view_model.dart'
    show
        currentDiscoveryProvider,
        discoveryEnabledProvider,
        popularArtistsProvider,
        recommendedForYouProvider,
        refreshDiscovery,
        retryDiscovery;
export 'ui/explore_card.dart' show ExploreCard;
export 'ui/explore_screen.dart' show ExploreScreen;
