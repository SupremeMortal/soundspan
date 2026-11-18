// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Maps the generated discovery wire models to domain values (doc 02,
/// Layers and Allowed Dependencies).
library;

import 'package:soundspan/features/discover/domain/discovery_artist.dart';
import 'package:soundspan/features/discover/domain/discovery_playlist.dart';
import 'package:soundspan/shared/data/library/library_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// A recommended artist. Its id is the server's artist id, which the
/// artist page opens.
DiscoveryArtist recommendedArtistFromWire(api.RecommendedArtist wire) =>
    DiscoveryArtist(
      name: wire.name,
      artworkRef: wire.coverArt ?? wire.heroUrl,
      libraryArtistId: wire.id,
    );

/// An artist of the popularity chart. Its id names the chart entry, not a
/// library artist, so the artist has no library id.
DiscoveryArtist popularArtistFromWire(api.PopularArtist wire) =>
    DiscoveryArtist(name: wire.name, artworkRef: wire.image);

/// A track of the discovery playlist. It is playable by its `playbackId`;
/// its album id names a release group, not a library album, so the track
/// has no album id.
Track trackFromDiscover(api.DiscoverTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: wire.playbackId,
  title: wire.title,
  artistName: wire.artist,
  albumTitle: wire.album,
  durationSec: wire.duration,
  artworkRef: wire.coverUrl,
  isrc: null,
  albumId: null,
  artistId: null,
  loudnessLufs: wire.loudnessLufs,
  truePeakDb: wire.truePeakDb,
  albumLoudnessLufs: wire.albumLoudnessLufs,
  albumTruePeakDb: wire.albumTruePeakDb,
  discNumber: null,
  trackNumber: null,
);

/// This week's discovery playlist, or null when it has no tracks.
DiscoveryPlaylist? discoveryPlaylistFromWire(api.DiscoverCurrent wire) =>
    wire.tracks.isEmpty
    ? null
    : DiscoveryPlaylist(
        tracks: [for (final t in wire.tracks) trackFromDiscover(t)],
      );
