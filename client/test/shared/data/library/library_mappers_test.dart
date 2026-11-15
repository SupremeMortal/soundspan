// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/data/library/library_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

Map<String, Object?> _libraryTrackJson({
  String id = 't-1',
  String? playbackId = 'pb-1',
  Map<String, Object?> extra = const {},
}) => {
  'id': id,
  'title': 'Song',
  'duration': 215,
  'trackNo': 3,
  'discNo': 1,
  'source': 'local',
  'albumId': 'al-1',
  'isrc': 'USRC17607839',
  'artist': {'id': 'ar-1', 'name': 'Band'},
  'album': {
    'id': 'al-1',
    'title': 'Record',
    'coverArt': 'cover-1',
    'artist': {'id': 'ar-1', 'name': 'Band'},
  },
  'playbackId': ?playbackId,
  ...extra,
};

void main() {
  group('tracks', () {
    test('track with playbackId', () {
      final track = trackFromLibraryTrack(
        api.LibraryTrack.fromJson(_libraryTrackJson()),
      );
      expect(track.playbackId, const PlaybackId('pb-1'));
      expect(
        track.meta,
        const TrackMeta(
          title: 'Song',
          artist: 'Band',
          album: 'Record',
          durationSec: 215,
          artworkRef: 'cover-1',
          isrc: 'USRC17607839',
        ),
      );
      expect(track.albumId, 'al-1');
      expect(track.artistId, 'ar-1');
      expect(track.discNumber, 1);
      expect(track.trackNumber, 3);
    });

    test('track without playbackId is not playable', () {
      final track = trackFromLibraryTrack(
        api.LibraryTrack.fromJson(_libraryTrackJson(playbackId: null)),
      );
      expect(track.playbackId, isNull);
      expect(track.meta.title, 'Song');
    });

    test('libraryTrackId is carried when present and null otherwise', () {
      final withId = trackFromLibraryTrack(
        api.LibraryTrack.fromJson(_libraryTrackJson()),
      );
      expect(withId.libraryTrackId, 't-1');

      final withoutId = trackFromLibraryTrack(
        api.LibraryTrack.fromJson(_libraryTrackJson(id: '')),
      );
      expect(withoutId.libraryTrackId, isNull);
    });

    test('loudness fields map', () {
      final track = trackFromLibraryTrack(
        api.LibraryTrack.fromJson(
          _libraryTrackJson(
            extra: {
              'loudnessLufs': -9.5,
              'truePeakDb': -1,
              'album': {
                'id': 'al-1',
                'title': 'Record',
                'coverArt': null,
                'albumLoudnessLufs': -10.25,
                'albumTruePeakDb': -0.5,
              },
            },
          ),
        ),
      );
      expect(
        track.loudness,
        const Loudness(
          loudnessLufs: -9.5,
          truePeakDb: -1,
          albumLoudnessLufs: -10.25,
          albumTruePeakDb: -0.5,
        ),
      );

      final none = trackFromLibraryTrack(
        api.LibraryTrack.fromJson(_libraryTrackJson()),
      );
      expect(none.loudness, isNull);
    });

    test('preference liked, disliked and absent', () {
      expect(preferenceFromWire(api.PreferenceState.liked), Preference.liked);
      expect(
        preferenceFromWire(api.PreferenceState.disliked),
        Preference.disliked,
      );
      expect(
        preferenceFromWire(api.PreferenceState.neutral),
        Preference.neutral,
      );
      expect(preferenceFromWire(null), Preference.neutral);
      expect(
        preferenceFromWire(api.PreferenceState.fromJson('loved')),
        Preference.neutral,
      );

      final listed = trackFromLibraryTrack(
        api.LibraryTrack.fromJson(_libraryTrackJson()),
      );
      expect(listed.preference, Preference.neutral);

      final liked = trackFromLikedTrack(
        api.LikedTrack.fromJson({
          ..._libraryTrackJson(),
          'likedAt': '2024-05-06T07:08:09.000Z',
        }),
      );
      expect(liked.preference, Preference.liked);
      expect(liked.playbackId, const PlaybackId('pb-1'));
    });

    test('a track summary takes missing album fields from its album', () {
      const album = Album(
        id: 'al-9',
        title: 'Record',
        artistName: 'Band',
        artistId: 'ar-9',
        artworkRef: 'cover-9',
      );
      final track = trackFromSummary(
        api.TrackSummary.fromJson({
          'id': 't-9',
          'title': 'Song',
          'duration': 60,
        }),
        fallback: album,
      );
      expect(track.meta.album, 'Record');
      expect(track.meta.artist, 'Band');
      expect(track.meta.artworkRef, 'cover-9');
      expect(track.albumId, 'al-9');
      expect(track.artistId, 'ar-9');
      expect(track.playbackId, isNull);
    });
  });

  group('albums and artists', () {
    test('album and artist fields', () {
      final album = albumFromSummary(
        api.AlbumSummary.fromJson({
          'id': 'al-1',
          'title': 'Record',
          'artistId': 'ar-1',
          'artist': {'id': 'ar-1', 'name': 'Band'},
          'coverArt': 'cover-1',
          'rgMbid': null,
          'source': 'local',
          'year': 1999,
        }),
      );
      expect(
        album,
        const Album(
          id: 'al-1',
          title: 'Record',
          artistName: 'Band',
          artistId: 'ar-1',
          year: 1999,
          artworkRef: 'cover-1',
        ),
      );

      final artist = artistFromSummary(
        api.ArtistSummary.fromJson({
          'id': 'ar-1',
          'name': 'Band',
          'coverArt': null,
          'mbid': null,
          'albumCount': 2,
          'trackCount': 20,
        }),
      );
      expect(artist, const Artist(id: 'ar-1', name: 'Band'));

      final detail = albumDetailFromWire(
        api.AlbumDetail.fromJson({
          'id': 'al-1',
          'title': 'Record',
          'artistId': 'ar-1',
          'artist': {'id': 'ar-1', 'name': 'Band'},
          'coverArt': 'cover-1',
          'matchedInLibrary': true,
          'matchedRgMbid': null,
          'owned': true,
          'rgMbid': null,
          'source': 'local',
          'year': 1999,
          'tracks': [
            {
              'id': 't-1',
              'title': 'One',
              'duration': 100,
              'playbackId': 'pb-1',
            },
            {'id': 't-2', 'title': 'Two', 'duration': 200},
          ],
        }),
      );
      expect(detail.owned, isTrue);
      expect(detail.album.trackCount, 2);
      expect(detail.tracks.map((t) => t.meta.title), ['One', 'Two']);
      expect(detail.tracks.first.meta.artworkRef, 'cover-1');
      expect(detail.tracks.last.playbackId, isNull);
    });

    Album artistAlbum(Map<String, Object?> extra) => albumFromArtistAlbum(
      api.ArtistAlbum.fromJson({
        'id': 'al-1',
        'title': 'Record',
        'artistId': 'ar-1',
        'coverArt': null,
        'rgMbid': null,
        'year': 2015,
        'source': 'database',
        'owned': true,
        'tracks': <Object?>[],
        ...extra,
      }),
      artist: const Artist(id: 'ar-1', name: 'Band'),
    );

    test("an artist album's release type is mapped", () {
      expect(artistAlbum({'primaryType': 'EP'}).releaseType, 'EP');
    });

    test('an artist album without a release type maps to null', () {
      expect(artistAlbum({}).releaseType, isNull);
      expect(artistAlbum({'primaryType': null}).releaseType, isNull);
    });

    test('artist detail with empty optional lists', () {
      final detail = artistDetailFromWire(
        api.ArtistDetail.fromJson({
          'id': 'ar-1',
          'name': 'Band',
          'bio': null,
          'coverArt': null,
          'mbid': null,
          'discographyComplete': false,
          'genres': <String>[],
          'source': 'local',
        }),
      );
      expect(detail.artist, const Artist(id: 'ar-1', name: 'Band'));
      expect(detail.albums, isEmpty);
      expect(detail.topTracks, isEmpty);
      expect(detail.similarArtists, isEmpty);
      expect(detail.biography, isNull);
      expect(detail.genres, isEmpty);
    });

    test('artist detail with albums, top tracks and similar artists', () {
      final detail = artistDetailFromWire(
        api.ArtistDetail.fromJson({
          'id': 'ar-1',
          'name': 'Band',
          'bio': 'A band.',
          'coverArt': 'cover-a',
          'mbid': null,
          'discographyComplete': true,
          'genres': ['rock'],
          'source': 'local',
          'albums': [
            {
              'id': 'al-1',
              'title': 'Record',
              'artistId': 'ar-1',
              'coverArt': 'cover-1',
              'owned': true,
              'rgMbid': null,
              'source': 'database',
              'tracks': <Object?>[],
              'year': 1999,
            },
          ],
          'topTracks': [
            {
              'id': 't-1',
              'title': 'Hit',
              'duration': 180,
              'playbackId': 'pb-1',
            },
          ],
          'similarArtists': [
            {
              'id': 'ar-2',
              'name': 'Friends',
              'coverArt': null,
              'mbid': null,
              'albumCount': 1,
              'ownedAlbumCount': 1,
              'inLibrary': true,
              'weight': 0.8,
            },
          ],
        }),
      );
      expect(detail.albums.single.artistName, 'Band');
      expect(detail.albums.single.trackCount, isNull);
      expect(detail.topTracks.single.playbackId, const PlaybackId('pb-1'));
      expect(detail.similarArtists.single.libraryId, 'ar-2');
      expect(detail.biography, 'A band.');
      expect(detail.genres, ['rock']);
    });

    test('similar artist without a library id', () {
      final similar = similarArtistFromWire(
        api.SimilarArtist.fromJson({
          'id': 'mbid-or-name',
          'name': 'Stranger',
          'coverArt': 'https://img.example.com/s.jpg',
          'mbid': 'mbid-or-name',
          'albumCount': 0,
          'ownedAlbumCount': 0,
          'inLibrary': false,
          'weight': 0.4,
        }),
      );
      expect(
        similar,
        const SimilarArtist(
          name: 'Stranger',
          artworkRef: 'https://img.example.com/s.jpg',
        ),
      );
    });
  });
}
