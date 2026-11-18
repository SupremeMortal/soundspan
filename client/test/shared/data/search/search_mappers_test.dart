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

/// Catalogue payloads, in provider order.
const List<Map<String, Object?>> _catalogue = [
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
    'id': '42',
    'itunesId': 42,
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
];

const Map<String, Object?> _artist = {
  'id': 'ar-1',
  'name': 'Band',
  'heroUrl': 'hero-1',
  'mbid': null,
  'rank': 1,
  'source': 'local',
};

const Map<String, Object?> _podcast = {
  'id': 'p-1',
  'title': 'Show',
  'author': 'Host',
  'description': null,
  'episodeCount': 3,
  'imageUrl': 'http://img/p-1',
};

const Map<String, Object?> _playlist = {
  'id': 'pl-1',
  'name': 'Road trip',
  'trackCount': 6,
  'isOwner': true,
  'isPublic': false,
  'isHidden': false,
  'items': [
    {
      'id': 'i-1',
      'track': {
        'album': {'coverArt': 'cover-a'},
      },
    },
  ],
  'createdAt': '2024-01-01T00:00:00.000Z',
  'updatedAt': '2024-01-02T00:00:00.000Z',
  'user': {'id': 'u-1', 'username': 'owner'},
  'userId': 'u-1',
};

/// A unified search item of [kind] carrying [payload] under [field].
Map<String, Object?> _item(
  String kind,
  String field,
  Map<String, Object?> payload, {
  double score = 1,
  String source = 'library',
}) => {'kind': kind, 'score': score, 'source': source, field: payload};

SearchPage _page(List<Map<String, Object?>> items, {bool hasMore = false}) =>
    searchPageFromWire(
      api.UnifiedSearchResponse.fromJson({'items': items, 'hasMore': hasMore}),
    );

void main() {
  test('every kind maps in server order with its score and source', () {
    final page = _page([
      _item('artist', 'artist', _artist, score: 4.0004),
      _item('album', 'album', _searchAlbum('al-1'), score: 3.5),
      _item('track', 'track', _searchTrack('t-1'), score: 3.2),
      _item('playlist', 'playlist', _playlist, score: 2.1),
      _item('podcast', 'podcast', _podcast, score: 1.4),
      _item('track', 'remoteTrack', _remoteTrack('r-1'), score: 1.3),
      _item('album', 'remoteAlbum', _remoteAlbum('ra-1'), score: 1.2),
      _item(
        'track',
        'catalogue',
        _catalogue[0],
        score: 1.1,
        source: 'catalogue',
      ),
    ], hasMore: true);

    expect(page.hasMore, isTrue);
    expect(
      [for (final item in page.items) item.score],
      [4.0004, 3.5, 3.2, 2.1, 1.4, 1.3, 1.2, 1.1],
    );
    expect(
      [for (final item in page.items) item.source],
      [
        for (var i = 0; i < 7; i++) SearchResultSource.library,
        SearchResultSource.catalogue,
      ],
    );
    expect(
      page.items[0].hit,
      const SearchHit.artist(
        artist: Artist(id: 'ar-1', name: 'Band', artworkRef: 'hero-1'),
      ),
    );
    expect((page.items[1].hit as AlbumHit).album.title, 'Album al-1');
    final track = (page.items[2].hit as TrackHit).track;
    expect(track.meta.title, 'Song t-1');
    expect(track.playbackId, const PlaybackId('pb-t-1'));
    final playlist = (page.items[3].hit as PlaylistHit).playlist;
    expect(playlist.name, 'Road trip');
    expect(playlist.trackCount, 6);
    expect(playlist.coverRefs, ['cover-a']);
    expect(
      page.items[4].hit,
      const SearchHit.podcast(
        podcast: PodcastSummary(
          id: 'p-1',
          title: 'Show',
          author: 'Host',
          artworkRef: 'http://img/p-1',
        ),
      ),
    );
    expect((page.items[5].hit as TrackHit).track.meta.title, 'Remote r-1');
    expect((page.items[6].hit as AlbumHit).album.title, 'Remote album ra-1');
    expect((page.items[7].hit as TrackHit).track.meta.title, 'Found song');
  });

  test('a library track without a playbackId is not playable', () {
    final page = _page([
      _item('track', 'track', {..._searchTrack('t-1')}..remove('playbackId')),
    ]);

    expect((page.items.single.hit as TrackHit).track.playbackId, isNull);
  });

  test('catalogue payloads map by their type', () {
    final page = _page([
      for (final payload in _catalogue)
        _item('track', 'catalogue', payload, source: 'catalogue'),
    ]);

    expect(page.items, hasLength(4));
    final first = page.items[0].hit as TrackHit;
    expect(first.track.meta.title, 'Found song');
    expect(first.track.meta.artist, 'Found band');
    expect(first.track.meta.album, 'Found album');
    expect(first.track.meta.durationSec, 200);
    expect(first.track.meta.artworkRef, 'http://img/t');
    expect(first.track.playbackId, isNull);
    expect(
      page.items[1].hit,
      const SearchHit.artist(
        artist: Artist(
          id: 'deezer:2',
          name: 'Found artist',
          artworkRef: 'http://img/a',
        ),
      ),
    );
    expect(
      page.items[2].hit,
      const SearchHit.podcast(
        podcast: PodcastSummary(
          id: '42',
          title: 'Found show',
          author: 'Found host',
          artworkRef: 'http://img/p',
        ),
      ),
    );
    final last = page.items[3].hit as TrackHit;
    expect(last.track.playbackId, const PlaybackId('td.3'));
    expect(last.track.meta.album, '');
  });

  test('an item of an unknown kind or without a known payload is left out', () {
    final page = _page([
      {'kind': 'episode', 'score': 2, 'source': 'library', 'episode': {}},
      _item('artist', 'artist', _artist),
      _item('track', 'catalogue', {
        ..._catalogue[0],
        'type': 'audiobook',
      }, source: 'catalogue'),
    ]);

    expect(page.items, hasLength(1));
    expect(page.items.single.hit, isA<ArtistHit>());
  });

  test('mapped hits expose no source field', () {
    final page = _page([
      _item('track', 'track', _searchTrack('t-1')),
      _item('track', 'remoteTrack', _remoteTrack('r-1')),
      _item('album', 'album', _searchAlbum('al-1')),
      _item('album', 'remoteAlbum', _remoteAlbum('ra-1')),
      for (final payload in _catalogue)
        _item('track', 'catalogue', payload, source: 'catalogue'),
    ]);

    Set<String> keys(Object? json) => switch (json) {
      final Map<String, Object?> map => {
        ...map.keys,
        for (final value in map.values) ...keys(value),
      },
      final List<Object?> list => {for (final item in list) ...keys(item)},
      _ => const {},
    };
    final json = jsonDecode(
      jsonEncode([for (final item in page.items) item.hit.toJson()]),
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
}
