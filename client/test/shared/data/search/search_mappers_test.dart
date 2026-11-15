// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/data/search/search_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

Map<String, Object?> _searchTrack(String id) => {
  'id': id,
  'title': 'Song $id',
  'duration': 200,
  'trackNo': 2,
  'albumId': 'al-$id',
  'source': 'local',
  'playbackId': 'pb-$id',
  'album': {'id': 'al-$id', 'title': 'Album $id', 'coverArt': 'cover-$id'},
  'artist': {'id': 'ar-$id', 'name': 'Artist $id'},
};

Map<String, Object?> _remoteTrack(String id) => {
  'id': id,
  'title': 'Remote $id',
  'duration': 210,
  'trackNo': null,
  'albumId': null,
  'artistId': null,
  'playbackId': 'pb-$id',
  'album': {'id': null, 'title': 'Remote album', 'coverArt': 'http://x/$id'},
  'artist': {'id': null, 'name': 'Remote artist'},
};

Map<String, Object?> _searchAlbum(String id) => {
  'id': id,
  'title': 'Album $id',
  'artistId': 'ar-$id',
  'artist': {'id': 'ar-$id', 'name': 'Artist $id'},
  'year': 2001,
  'coverUrl': 'cover-$id',
  'source': 'local',
};

Map<String, Object?> _remoteAlbum(String id) => {
  'id': id,
  'title': 'Remote album $id',
  'artistId': 'ar-$id',
  'artist': {'id': 'ar-$id', 'name': 'Remote artist'},
  'year': null,
  'coverUrl': 'http://x/$id',
  'source': 'tidal',
  'remoteSources': ['tidal'],
};

api.SearchResponse _response({
  List<Map<String, Object?>> tracks = const [],
  List<Map<String, Object?>> remoteTracks = const [],
  List<Map<String, Object?>> albums = const [],
  List<Map<String, Object?>> remoteAlbums = const [],
}) => api.SearchResponse.fromJson({
  'artists': [
    {
      'id': 'ar-1',
      'name': 'Band',
      'heroUrl': 'hero-1',
      'mbid': null,
      'rank': 1,
      'source': 'local',
    },
  ],
  'albums': albums,
  'tracks': tracks,
  'podcasts': [
    {
      'id': 'p-1',
      'title': 'Show',
      'author': 'Host',
      'description': null,
      'episodeCount': 3,
      'imageUrl': 'http://img/p-1',
    },
  ],
  'episodes': <Object?>[],
  'remoteTracks': remoteTracks,
  'remoteAlbums': remoteAlbums,
});

Map<String, Object?> _discoverJson({Map<String, Object?>? aliasInfo}) => {
  'aliasInfo': aliasInfo,
  'results': [
    {
      'type': 'track',
      'id': 'deezer:1',
      'name': 'Found song',
      'artist': 'Found band',
      'album': 'Found album',
      'image': 'http://img/t',
      'durationSec': 199.6,
      'source': 'deezer',
    },
    {
      'type': 'music',
      'id': 'deezer:2',
      'name': 'Found artist',
      'image': 'http://img/a',
      'source': 'deezer',
    },
    {
      'type': 'podcast',
      'id': 42,
      'name': 'Found show',
      'artist': 'Found host',
      'coverUrl': 'http://img/p',
    },
    {
      'type': 'track',
      'id': 'tidal:3',
      'name': 'Playable song',
      'artist': 'Band',
      'album': null,
      'playbackId': 'td.3',
      'source': 'tidal',
    },
  ],
};

void main() {
  test('remote tracks and albums merge after library ones in server order', () {
    final results = librarySearchResultsFromWire(
      _response(
        tracks: [_searchTrack('t-1'), _searchTrack('t-2')],
        remoteTracks: [_remoteTrack('r-2'), _remoteTrack('r-1')],
        albums: [_searchAlbum('al-1')],
        remoteAlbums: [_remoteAlbum('ra-2'), _remoteAlbum('ra-1')],
      ),
    );

    expect(
      [for (final track in results.tracks) track.meta.title],
      ['Song t-1', 'Song t-2', 'Remote r-2', 'Remote r-1'],
    );
    expect(
      [for (final album in results.albums) album.id],
      ['al-1', 'ra-2', 'ra-1'],
    );
    expect(results.tracks[2].playbackId, const PlaybackId('pb-r-2'));
    expect(results.tracks[2].meta.artworkRef, 'http://x/r-2');
    expect(results.tracks.first.meta.artist, 'Artist t-1');
    expect(results.albums.last.artistName, 'Remote artist');
    expect(results.artists, [
      const Artist(id: 'ar-1', name: 'Band', artworkRef: 'hero-1'),
    ]);
    expect(results.podcasts, [
      const PodcastSummary(
        id: 'p-1',
        title: 'Show',
        author: 'Host',
        artworkRef: 'http://img/p-1',
      ),
    ]);
  });

  test('a library track without a playbackId is not playable', () {
    final results = librarySearchResultsFromWire(
      _response(
        tracks: [
          {..._searchTrack('t-1')}..remove('playbackId'),
        ],
      ),
    );

    expect(results.tracks.single.playbackId, isNull);
  });

  test('discover hits keep server order across kinds', () {
    final results = discoverResultsFromWire(
      api.DiscoverSearchResponse.fromJson(_discoverJson()),
    );

    expect(results.hits, hasLength(4));
    final first = results.hits[0] as TrackHit;
    expect(first.track.meta.title, 'Found song');
    expect(first.track.meta.artist, 'Found band');
    expect(first.track.meta.album, 'Found album');
    expect(first.track.meta.durationSec, 200);
    expect(first.track.meta.artworkRef, 'http://img/t');
    expect(first.track.playbackId, isNull);
    expect(
      results.hits[1],
      const SearchHit.artist(
        artist: Artist(
          id: 'deezer:2',
          name: 'Found artist',
          artworkRef: 'http://img/a',
        ),
      ),
    );
    expect(
      results.hits[2],
      const SearchHit.podcast(
        podcast: PodcastSummary(
          id: '42',
          title: 'Found show',
          author: 'Found host',
          artworkRef: 'http://img/p',
        ),
      ),
    );
    final last = results.hits[3] as TrackHit;
    expect(last.track.playbackId, const PlaybackId('td.3'));
    expect(last.track.meta.album, '');
    expect(results.aliasInfo, isNull);
  });

  test('mapped values expose no source field', () {
    final library = librarySearchResultsFromWire(
      _response(
        tracks: [_searchTrack('t-1')],
        remoteTracks: [_remoteTrack('r-1')],
        albums: [_searchAlbum('al-1')],
        remoteAlbums: [_remoteAlbum('ra-1')],
      ),
    );
    final discover = discoverResultsFromWire(
      api.DiscoverSearchResponse.fromJson(_discoverJson()),
    );

    Set<String> keys(Object? json) => switch (json) {
      final Map<String, Object?> map => {
        ...map.keys,
        for (final value in map.values) ...keys(value),
      },
      final List<Object?> list => {for (final item in list) ...keys(item)},
      _ => const {},
    };
    final json = jsonDecode(
      jsonEncode({'library': library.toJson(), 'discover': discover.toJson()}),
    );
    final found = keys(json);

    for (final forbidden in [
      'source',
      'remoteSources',
      'provider',
      'streamSource',
      'peer',
      'mediaSource',
    ]) {
      expect(found, isNot(contains(forbidden)));
    }
  });

  test('alias info maps', () {
    final results = discoverResultsFromWire(
      api.DiscoverSearchResponse.fromJson(
        _discoverJson(
          aliasInfo: {
            'original': 'beatles',
            'canonical': 'The Beatles',
            'mbid': 'mb-1',
          },
        ),
      ),
    );

    expect(
      results.aliasInfo,
      const AliasInfo(original: 'beatles', canonical: 'The Beatles'),
    );
  });
}
