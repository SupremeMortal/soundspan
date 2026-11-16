// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Maps the generated library wire models to domain values (doc 02,
/// Layers and Allowed Dependencies).
library;

import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The domain preference of a server preference state; absent and unknown
/// values are [Preference.neutral].
Preference preferenceFromWire(api.PreferenceState? state) => switch (state) {
  api.PreferenceStateKnown(value: api.PreferenceStateValue.liked) =>
    Preference.liked,
  api.PreferenceStateKnown(value: api.PreferenceStateValue.disliked) =>
    Preference.disliked,
  _ => Preference.neutral,
};

/// A library track of the Songs list.
Track trackFromLibraryTrack(api.LibraryTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: wire.playbackId,
  title: wire.title,
  artistName: wire.artist?.name ?? wire.album.artist?.name,
  albumTitle: wire.album.title,
  durationSec: wire.duration,
  artworkRef: wire.album.coverArt ?? wire.album.coverUrl,
  isrc: wire.isrc,
  albumId: wire.albumId ?? wire.album.id,
  artistId: wire.artist?.id,
  loudnessLufs: wire.loudnessLufs,
  truePeakDb: wire.truePeakDb,
  albumLoudnessLufs: wire.album.albumLoudnessLufs,
  albumTruePeakDb: wire.album.albumTruePeakDb,
  discNumber: wire.discNo,
  trackNumber: wire.trackNo,
);

/// A track of the liked list; its preference is [Preference.liked].
Track trackFromLikedTrack(api.LikedTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: wire.playbackId,
  title: wire.title,
  artistName: wire.artist?.name ?? wire.album.artist?.name,
  albumTitle: wire.album.title,
  durationSec: wire.duration,
  artworkRef: wire.album.coverArt ?? wire.album.coverUrl,
  isrc: wire.isrc,
  albumId: wire.albumId ?? wire.album.id,
  artistId: wire.artist?.id,
  loudnessLufs: wire.loudnessLufs,
  truePeakDb: wire.truePeakDb,
  albumLoudnessLufs: wire.album.albumLoudnessLufs,
  albumTruePeakDb: wire.album.albumTruePeakDb,
  discNumber: wire.discNo,
  trackNumber: wire.trackNo,
  preference: Preference.liked,
);

/// A track of an album or artist detail. The [fallback] album fills the
/// album title, artist and artwork the track itself does not carry.
Track trackFromSummary(api.TrackSummary wire, {Album? fallback}) =>
    trackFromParts(
      id: wire.id,
      playbackId: wire.playbackId,
      title: wire.title,
      artistName: wire.artist?.name ?? wire.album?.artist?.name,
      albumTitle: wire.album?.title,
      durationSec: wire.duration,
      artworkRef: wire.album?.coverArt ?? wire.album?.coverUrl,
      isrc: wire.isrc,
      albumId: wire.albumId ?? wire.album?.id,
      artistId: wire.artist?.id,
      loudnessLufs: wire.loudnessLufs,
      truePeakDb: wire.truePeakDb,
      albumLoudnessLufs: wire.album?.albumLoudnessLufs,
      albumTruePeakDb: wire.album?.albumTruePeakDb,
      discNumber: wire.discNo,
      trackNumber: wire.trackNo,
      fallback: fallback,
    );

/// A top track of an artist detail.
Track trackFromTopTrack(api.ArtistTopTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: wire.playbackId,
  title: wire.title,
  artistName: wire.artist?.name ?? wire.album?.artist?.name,
  albumTitle: wire.album?.title,
  durationSec: wire.duration,
  artworkRef: wire.album?.coverArt ?? wire.album?.coverUrl,
  isrc: wire.isrc,
  albumId: wire.albumId ?? wire.album?.id,
  artistId: wire.artist?.id,
  loudnessLufs: wire.loudnessLufs,
  truePeakDb: wire.truePeakDb,
  albumLoudnessLufs: wire.album?.albumLoudnessLufs,
  albumTruePeakDb: wire.album?.albumTruePeakDb,
  discNumber: wire.discNo,
  trackNumber: wire.trackNo,
);

/// A track built from the fields every wire track shape carries; the
/// shared core of the track mappers. A null [playbackId] makes the track
/// not playable, and the [fallback] album fills what the track lacks.
Track trackFromParts({
  required String id,
  required String? playbackId,
  required String title,
  required String? artistName,
  required String? albumTitle,
  required int durationSec,
  required String? artworkRef,
  required String? isrc,
  required String? albumId,
  required String? artistId,
  required num? loudnessLufs,
  required num? truePeakDb,
  required num? albumLoudnessLufs,
  required num? albumTruePeakDb,
  required int? discNumber,
  required int? trackNumber,
  Preference preference = Preference.neutral,
  Album? fallback,
}) {
  final hasLoudness = [
    loudnessLufs,
    truePeakDb,
    albumLoudnessLufs,
    albumTruePeakDb,
  ].any((value) => value != null);
  return Track(
    playbackId: playbackId == null ? null : PlaybackId(playbackId),
    meta: TrackMeta(
      title: title,
      artist: artistName ?? fallback?.artistName ?? '',
      album: albumTitle ?? fallback?.title ?? '',
      durationSec: durationSec,
      artworkRef: artworkRef ?? fallback?.artworkRef,
      isrc: isrc,
    ),
    albumId: albumId ?? fallback?.id,
    artistId: artistId ?? fallback?.artistId,
    loudness: hasLoudness
        ? Loudness(
            loudnessLufs: loudnessLufs?.toDouble(),
            truePeakDb: truePeakDb?.toDouble(),
            albumLoudnessLufs: albumLoudnessLufs?.toDouble(),
            albumTruePeakDb: albumTruePeakDb?.toDouble(),
          )
        : null,
    preference: preference,
    discNumber: discNumber,
    trackNumber: trackNumber,
    libraryTrackId: id.isEmpty ? null : id,
  );
}

/// An album of the albums list.
Album albumFromSummary(api.AlbumSummary wire) => Album(
  id: wire.id,
  title: wire.title,
  artistName: wire.artist.name,
  artistId: wire.artistId,
  year: wire.year,
  artworkRef: wire.coverArt,
  preference: preferenceFromWire(wire.preference),
);

/// An album of an artist's discography; the artist is [artist].
Album albumFromArtistAlbum(api.ArtistAlbum wire, {required Artist artist}) =>
    Album(
      id: wire.id,
      title: wire.title,
      artistName: artist.name,
      artistId: wire.artistId,
      year: wire.year,
      artworkRef: wire.coverArt,
      trackCount: wire.tracks.isEmpty ? null : wire.tracks.length,
      releaseType: wire.primaryType,
    );

/// An album with its tracks.
AlbumDetail albumDetailFromWire(api.AlbumDetail wire) {
  final tracks = wire.tracks;
  final album = Album(
    id: wire.id,
    title: wire.title,
    artistName: wire.artist.name,
    artistId: wire.artistId,
    year: wire.year,
    artworkRef: wire.coverArt,
    trackCount: tracks?.length,
    preference: preferenceFromWire(wire.preference),
  );
  return AlbumDetail(
    album: album,
    tracks: [
      for (final track in tracks ?? const <api.TrackSummary>[])
        trackFromSummary(track, fallback: album),
    ],
    owned: wire.owned,
  );
}

/// An artist of the artists list.
Artist artistFromSummary(api.ArtistSummary wire) =>
    Artist(id: wire.id, name: wire.name, artworkRef: wire.coverArt);

/// A similar artist; [SimilarArtist.libraryId] is set only when the library
/// holds the artist.
SimilarArtist similarArtistFromWire(api.SimilarArtist wire) => SimilarArtist(
  name: wire.name,
  artworkRef: wire.coverArt,
  libraryId: wire.inLibrary ? wire.id : null,
);

/// An artist with albums, top tracks and similar artists; absent lists are
/// empty.
ArtistDetail artistDetailFromWire(api.ArtistDetail wire) {
  final artist = Artist(
    id: wire.id,
    name: wire.name,
    artworkRef: wire.coverArt,
  );
  return ArtistDetail(
    artist: artist,
    albums: [
      for (final album in wire.albums ?? const <api.ArtistAlbum>[])
        albumFromArtistAlbum(album, artist: artist),
    ],
    topTracks: [
      for (final track in wire.topTracks ?? const <api.ArtistTopTrack>[])
        trackFromTopTrack(track),
    ],
    similarArtists: [
      for (final similar in wire.similarArtists ?? const <api.SimilarArtist>[])
        similarArtistFromWire(similar),
    ],
    biography: wire.bio,
    genres: wire.genres,
  );
}
