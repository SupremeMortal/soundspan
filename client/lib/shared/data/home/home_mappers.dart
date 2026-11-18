// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Maps the generated wire models of the Home shelves to domain values
/// (doc 02, Layers and Allowed Dependencies).
library;

import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// One Continue Listening entry, or null for an audiobook (not in v1) or a
/// kind this client does not know.
RecentItem? recentItemFromWire(api.RecentlyListenedItem wire) =>
    switch (wire.type) {
      api.RecentlyListenedItemTypeKnown(
        value: api.RecentlyListenedItemTypeValue.artist,
      ) =>
        RecentItem.artist(
          artist: Artist(
            id: wire.id,
            name: wire.name,
            artworkRef: wire.coverArt,
          ),
        ),
      api.RecentlyListenedItemTypeKnown(
        value: api.RecentlyListenedItemTypeValue.podcast,
      ) =>
        RecentItem.podcast(
          podcast: Podcast(
            id: wire.id,
            title: wire.name,
            author: wire.author,
            artworkRef: wire.coverArt,
          ),
        ),
      _ => null,
    };

/// The Continue Listening entries in server order.
List<RecentItem> recentItemsFromWire(api.RecentlyListenedResponse wire) => [
  for (final item in wire.items) ?recentItemFromWire(item),
];

/// The recently added artists in server order.
List<Artist> recentlyAddedFromWire(api.RecentlyAddedResponse wire) => [
  for (final artist in wire.artists)
    Artist(id: artist.id, name: artist.name, artworkRef: artist.coverArt),
];

/// A generated mix.
MixSummary mixSummaryFromWire(api.MixSummary wire) => MixSummary(
  id: wire.id,
  name: wire.name,
  description: wire.description,
  coverRefs: wire.coverUrls,
);

/// A podcast of the directory's top list, with the feed URL and iTunes id
/// a subscribe request names it by.
PodcastSummary podcastSummaryFromWire(api.PodcastSummary wire) =>
    PodcastSummary(
      id: wire.id,
      title: wire.title,
      author: wire.author,
      artworkRef: wire.coverUrl,
      feedUrl: wire.feedUrl,
      itunesId: '${wire.itunesId}',
    );
