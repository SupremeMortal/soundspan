// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/shared/data/library/library_remote_source.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockLibraryClient extends Mock implements api.LibraryClient;

Map<String, Object?> _trackJson(String id) => {
  'id': id,
  'title': 'Song $id',
  'duration': 100,
  'trackNo': 1,
  'source': 'local',
  'playbackId': 'pb-$id',
  'album': {'id': 'al-1', 'title': 'Record', 'coverArt': null},
};

void main() {
  late _MockLibraryClient client;
  late LibraryRemoteSource source;

  setUp(() {
    client = _MockLibraryClient();
    source = LibraryRemoteSource(client);
  });

  test(
    'artists passes its parameters through and returns the cursor',
    () async {
      when(
        () => client.listArtists(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          filter: any(named: 'filter'),
          sortBy: any(named: 'sortBy'),
          origin: any(named: 'origin'),
          query2: any(named: 'query2'),
        ),
      ).thenAnswer(
        (_) async => api.ArtistListResponse.fromJson({
          'artists': [
            {
              'id': 'ar-1',
              'name': 'Band',
              'coverArt': 'cover-1',
              'mbid': null,
              'albumCount': 1,
              'trackCount': 9,
            },
          ],
          'total': 5,
          'offset': 60,
          'limit': 60,
          'nextCursor': 'next-1',
        }),
      );

      final page = await source.artists(
        offset: 60,
        limit: 60,
        cursor: 'c-0',
        filter: ArtistFilter.owned,
        sortBy: ArtistSort.nameDesc,
        origin: LibraryOrigin.peers,
        query: 'ba',
      );

      verify(
        () => client.listArtists(
          offset: 60,
          limit: 60,
          cursor: 'c-0',
          filter: api.ListArtistsFilter.owned,
          sortBy: api.ListArtistsSortBy.nameDesc,
          origin: api.ListArtistsOrigin.peers,
          query2: 'ba',
        ),
      ).called(1);
      expect(page.items, [
        const Artist(id: 'ar-1', name: 'Band', artworkRef: 'cover-1'),
      ]);
      expect(page.nextCursor, 'next-1');
      expect(page.offset, 60);
      expect(page.limit, 60);
      expect(page.total, 5);
    },
  );

  test('artist asks for discography, top tracks and similar artists', () async {
    when(
      () => client.getArtist(
        id: any(named: 'id'),
        includeDiscography: any(named: 'includeDiscography'),
        includeTopTracks: any(named: 'includeTopTracks'),
        includeSimilarArtists: any(named: 'includeSimilarArtists'),
      ),
    ).thenAnswer(
      (_) async => api.ArtistDetail.fromJson({
        'id': 'ar-1',
        'name': 'Band',
        'bio': null,
        'coverArt': null,
        'mbid': null,
        'discographyComplete': true,
        'genres': <String>[],
        'source': 'local',
      }),
    );

    final detail = await source.artist('ar-1');

    verify(
      () => client.getArtist(
        id: 'ar-1',
        includeDiscography: true,
        includeTopTracks: true,
        includeSimilarArtists: true,
      ),
    ).called(1);
    expect(detail.artist.name, 'Band');
  });

  test('albums passes its parameters through', () async {
    when(
      () => client.listAlbums(
        artistId: any(named: 'artistId'),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        filter: any(named: 'filter'),
        sortBy: any(named: 'sortBy'),
        origin: any(named: 'origin'),
      ),
    ).thenAnswer(
      (_) async => api.AlbumListResponse.fromJson({
        'albums': [
          {
            'id': 'al-1',
            'title': 'Record',
            'artistId': 'ar-1',
            'artist': {'id': 'ar-1', 'name': 'Band'},
            'coverArt': null,
            'rgMbid': null,
            'source': 'local',
            'year': null,
          },
        ],
        'total': 1,
        'offset': 0,
        'limit': 60,
      }),
    );

    final page = await source.albums(
      artistId: 'ar-1',
      offset: 0,
      limit: 60,
      filter: AlbumFilter.discovery,
      sortBy: AlbumSort.recent,
      origin: LibraryOrigin.remote,
    );

    verify(
      () => client.listAlbums(
        artistId: 'ar-1',
        offset: 0,
        limit: 60,
        filter: api.ListAlbumsFilter.discovery,
        sortBy: api.ListAlbumsSortBy.recent,
        origin: api.ListAlbumsOrigin.remote,
      ),
    ).called(1);
    expect(page.items.single.title, 'Record');
    expect(page.hasMore, isFalse);
  });

  test('album asks for its tracks', () async {
    when(
      () => client.getAlbum(
        id: any(named: 'id'),
        includeTracks: any(named: 'includeTracks'),
      ),
    ).thenAnswer(
      (_) async => api.AlbumDetail.fromJson({
        'id': 'al-1',
        'title': 'Record',
        'artistId': 'ar-1',
        'artist': {'id': 'ar-1', 'name': 'Band'},
        'coverArt': null,
        'matchedInLibrary': true,
        'matchedRgMbid': null,
        'owned': false,
        'rgMbid': null,
        'source': 'remote',
        'year': 2001,
        'tracks': <Object?>[],
      }),
    );

    final detail = await source.album('al-1');

    verify(() => client.getAlbum(id: 'al-1', includeTracks: true)).called(1);
    expect(detail.owned, isFalse);
    expect(detail.album.year, 2001);
  });

  test('tracks passes its parameters through', () async {
    when(
      () => client.listTracks(
        albumId: any(named: 'albumId'),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
        sortBy: any(named: 'sortBy'),
        origin: any(named: 'origin'),
      ),
    ).thenAnswer(
      (_) async => api.LibraryTrackListResponse.fromJson({
        'tracks': [_trackJson('t-1'), _trackJson('t-2')],
        'total': 10,
        'offset': 0,
        'limit': 2,
      }),
    );

    final page = await source.tracks(
      albumId: 'al-1',
      offset: 0,
      limit: 2,
      sortBy: TrackSort.name,
      origin: LibraryOrigin.local,
    );

    verify(
      () => client.listTracks(
        albumId: 'al-1',
        offset: 0,
        limit: 2,
        sortBy: api.ListTracksSortBy.name2,
        origin: api.ListTracksOrigin.local,
      ),
    ).called(1);
    expect(page.items.map((t) => t.playbackId), [
      const PlaybackId('pb-t-1'),
      const PlaybackId('pb-t-2'),
    ]);
    expect(page.hasMore, isTrue);
    expect(page.nextOffset, 2);
  });

  group('liked', () {
    void stubLiked({required bool hasMore}) {
      when(
        () => client.listLikedTracks(
          limit: any(named: 'limit'),
          cursorLikedAt: any(named: 'cursorLikedAt'),
          cursorTrackId: any(named: 'cursorTrackId'),
        ),
      ).thenAnswer(
        (_) async => api.LikedTracksResponse.fromJson({
          'playlist': {'id': 'liked', 'name': 'Liked', 'description': ''},
          'tracks': [
            {..._trackJson('t-3'), 'likedAt': '2024-05-06T07:08:09.000Z'},
          ],
          'total': 3,
          'pagination': {
            'hasMore': hasMore,
            'limit': 1,
            'nextCursor': {
              'likedAt': '2024-05-06T07:08:09.000Z',
              'trackId': 't-3',
            },
          },
        }),
      );
    }

    test('builds the keyset page and its next cursor', () async {
      stubLiked(hasMore: true);

      final page = await source.liked(
        limit: 1,
        cursor: LikedCursor(
          likedAt: DateTime.utc(2024, 6, 1, 12),
          trackId: 't-2',
        ),
      );

      verify(
        () => client.listLikedTracks(
          limit: 1,
          cursorLikedAt: '2024-06-01T12:00:00.000Z',
          cursorTrackId: 't-2',
        ),
      ).called(1);
      expect(page.items.single.preference, Preference.liked);
      expect(page.hasMore, isTrue);
      expect(page.total, 3);
      expect(
        page.nextCursor,
        LikedCursor(likedAt: DateTime.utc(2024, 5, 6, 7, 8, 9), trackId: 't-3'),
      );
      expect(page.nextCursor!.likedAt.isUtc, isTrue);
    });

    test('the first page sends no cursor and the last has none', () async {
      stubLiked(hasMore: false);

      final page = await source.liked(limit: 1);

      verify(() => client.listLikedTracks(limit: 1)).called(1);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });

  test('an ApiException propagates unchanged', () async {
    const error = api.NotFound(status: 404, serverMessage: 'Album not found');
    when(
      () => client.getAlbum(
        id: any(named: 'id'),
        includeTracks: any(named: 'includeTracks'),
      ),
    ).thenThrow(error);

    await expectLater(source.album('missing'), throwsA(same(error)));
  });
}
