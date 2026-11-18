// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Maps the generated search wire models to domain values (doc 02,
/// Layers and Allowed Dependencies). Nothing in a mapped value says where a
/// result came from: remote results become ordinary tracks and albums.
library;

import 'package:soundspan/shared/data/library/library_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// An artist of a library search.
Artist artistFromSearch(api.SearchArtist wire) =>
    Artist(id: wire.id, name: wire.name, artworkRef: wire.heroUrl);

/// An album of a library search.
Album albumFromSearch(api.SearchAlbum wire) => Album(
  id: wire.id,
  title: wire.title,
  artistName: wire.artist.name,
  artistId: wire.artistId,
  year: wire.year,
  artworkRef: wire.coverUrl,
);

/// A liked streaming album that the library does not hold.
Album albumFromRemoteSearch(api.SearchRemoteAlbum wire) => Album(
  id: wire.id,
  title: wire.title,
  artistName: wire.artist.name,
  artistId: wire.artistId,
  year: wire.year,
  artworkRef: wire.coverUrl,
);

/// A track of a library search.
Track trackFromSearch(api.SearchTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: wire.playbackId,
  title: wire.title,
  artistName: wire.artist?.name ?? wire.album?.artist?.name,
  albumTitle: wire.album?.title,
  durationSec: wire.duration,
  artworkRef: wire.album?.coverArt ?? wire.album?.coverUrl,
  isrc: wire.isrc,
  albumId: wire.albumId,
  artistId: wire.artist?.id,
  loudnessLufs: wire.loudnessLufs,
  truePeakDb: wire.truePeakDb,
  albumLoudnessLufs: wire.album?.albumLoudnessLufs,
  albumTruePeakDb: wire.album?.albumTruePeakDb,
  discNumber: wire.discNo,
  trackNumber: wire.trackNo,
);

/// A liked streaming track that the library does not hold.
Track trackFromRemoteSearch(api.SearchRemoteTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: wire.playbackId,
  title: wire.title,
  artistName: wire.artist?.name ?? wire.album.artist?.name,
  albumTitle: wire.album.title,
  durationSec: wire.duration,
  artworkRef: wire.album.coverArt ?? wire.album.coverUrl,
  isrc: wire.isrc,
  albumId: wire.albumId ?? wire.album.id,
  artistId: wire.artistId ?? wire.artist?.id,
  loudnessLufs: wire.loudnessLufs,
  truePeakDb: wire.truePeakDb,
  albumLoudnessLufs: wire.album.albumLoudnessLufs,
  albumTruePeakDb: wire.album.albumTruePeakDb,
  discNumber: wire.discNo,
  trackNumber: wire.trackNo,
);

/// A podcast of a library search.
PodcastSummary podcastFromSearch(api.SearchPodcast wire) => PodcastSummary(
  id: wire.id,
  title: wire.title,
  author: wire.author,
  artworkRef: wire.imageUrl,
);

/// The groups of a library search. Remote tracks and albums follow the
/// library ones, each in server order; episodes are not mapped.
LibrarySearchResults librarySearchResultsFromWire(api.SearchResponse wire) =>
    LibrarySearchResults(
      artists: [for (final artist in wire.artists) artistFromSearch(artist)],
      albums: [
        for (final album in wire.albums) albumFromSearch(album),
        for (final album in wire.remoteAlbums) albumFromRemoteSearch(album),
      ],
      tracks: [
        for (final track in wire.tracks) trackFromSearch(track),
        for (final track in wire.remoteTracks) trackFromRemoteSearch(track),
      ],
      podcasts: [
        for (final podcast in wire.podcasts) podcastFromSearch(podcast),
      ],
    );

/// One catalogue result, or null for a kind this client does not know.
/// A track without `playbackId` is not playable.
SearchHit? searchHitFromDiscover(api.DiscoverResult wire) {
  final id = wire.id;
  final artwork = wire.coverUrl ?? wire.image;
  return switch (wire.type) {
    api.DiscoverResultTypeKnown(value: api.DiscoverResultTypeValue.track) =>
      SearchHit.track(
        track: Track(
          playbackId: wire.playbackId == null
              ? null
              : PlaybackId(wire.playbackId!),
          meta: TrackMeta(
            title: wire.name,
            artist: wire.artist ?? '',
            album: wire.album ?? '',
            durationSec: wire.durationSec?.round() ?? 0,
            artworkRef: artwork,
          ),
        ),
      ),
    api.DiscoverResultTypeKnown(value: api.DiscoverResultTypeValue.music) =>
      SearchHit.artist(
        artist: Artist(id: id, name: wire.name, artworkRef: artwork),
      ),
    api.DiscoverResultTypeKnown(value: api.DiscoverResultTypeValue.podcast) =>
      SearchHit.podcast(
        podcast: PodcastSummary(
          id: id,
          title: wire.name,
          author: wire.artist,
          artworkRef: artwork,
        ),
      ),
    _ => null,
  };
}

/// The results of a catalogue search in server order, and the correction
/// the server applied to the query.
DiscoverResults discoverResultsFromWire(api.DiscoverSearchResponse wire) =>
    DiscoverResults(
      hits: [for (final result in wire.results) ?searchHitFromDiscover(result)],
      aliasInfo: switch (wire.aliasInfo) {
        final alias? => AliasInfo(
          original: alias.original,
          canonical: alias.canonical,
        ),
        null => null,
      },
    );
