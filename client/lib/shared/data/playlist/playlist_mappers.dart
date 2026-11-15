// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Maps the generated playlist wire models to domain values (doc 02,
/// Layers and Allowed Dependencies).
library;

import 'package:soundspan/shared/data/library/library_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The most cover refs a playlist summary carries, for a 2 x 2 mosaic.
const maxPlaylistCovers = 4;

/// A playlist of the playlists list; its cover refs are the first four
/// album covers of the server's cover seeds.
PlaylistSummary playlistSummaryFromWire(api.PlaylistSummary wire) =>
    PlaylistSummary(
      id: wire.id,
      name: wire.name,
      trackCount: wire.trackCount,
      isOwner: wire.isOwner,
      isPublic: wire.isPublic,
      coverRefs: [for (final item in wire.items) ?item.track?.album.coverArt]
          .take(maxPlaylistCovers)
          .toList(),
    );

/// One playlist entry; [PlaylistItem.isPlayable] and
/// [PlaylistItem.message] are the server's `playback` values.
PlaylistItem playlistItemFromWire(api.PlaylistItem wire) => PlaylistItem(
  id: wire.id,
  sort: wire.sort,
  track: trackFromLibraryTrack(wire.track),
  isPlayable: wire.playback.isPlayable,
  message: wire.playback.message,
);

/// A playlist with its items in ascending sort order. Its summary carries
/// the covers of its first four items.
PlaylistDetail playlistDetailFromWire(api.PlaylistDetail wire) {
  final items = [for (final item in wire.items) playlistItemFromWire(item)]
    ..sort((a, b) => a.sort.compareTo(b.sort));
  return PlaylistDetail(
    summary: PlaylistSummary(
      id: wire.id,
      name: wire.name,
      trackCount: wire.trackCount,
      isOwner: wire.isOwner,
      isPublic: wire.isPublic,
      coverRefs: [for (final item in items) ?item.track.meta.artworkRef]
          .take(maxPlaylistCovers)
          .toList(),
    ),
    items: items,
  );
}
