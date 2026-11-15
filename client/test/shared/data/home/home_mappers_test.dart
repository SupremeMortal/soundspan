// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/data/home/home_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

api.RecentlyListenedResponse _recent(List<Map<String, Object?>> items) =>
    api.RecentlyListenedResponse.fromJson({'items': items});

void main() {
  group('recently listened', () {
    test('an artist item maps to an artist', () {
      final items = recentItemsFromWire(
        _recent([
          {
            'type': 'artist',
            'id': 'ar-1',
            'name': 'Band',
            'coverArt': 'cover-ar-1',
            'mbid': null,
            'albumCount': 2,
            'lastPlayedAt': '2024-05-06T07:08:09.000Z',
          },
        ]),
      );

      expect(items, [
        const RecentItem.artist(
          artist: Artist(id: 'ar-1', name: 'Band', artworkRef: 'cover-ar-1'),
        ),
      ]);
    });

    test('a podcast item maps to a podcast', () {
      final items = recentItemsFromWire(
        _recent([
          {
            'type': 'podcast',
            'id': 'p-1',
            'name': 'Show',
            'author': 'Host',
            'coverArt': '/podcasts/p-1/cover',
            'episodeId': 'e-1',
            'progress': 40,
            'lastPlayedAt': '2024-05-06T07:08:09.000Z',
          },
        ]),
      );

      expect(items, [
        const RecentItem.podcast(
          podcast: Podcast(
            id: 'p-1',
            title: 'Show',
            author: 'Host',
            artworkRef: '/podcasts/p-1/cover',
          ),
        ),
      ]);
    });

    test('audiobook and unknown items are left out, order is kept', () {
      final items = recentItemsFromWire(
        _recent([
          {
            'type': 'audiobook',
            'id': 'b-1',
            'name': 'Book',
            'coverArt': null,
            'lastPlayedAt': '2024-05-06T07:08:09.000Z',
          },
          {
            'type': 'artist',
            'id': 'ar-2',
            'name': 'Second',
            'coverArt': null,
            'lastPlayedAt': '2024-05-05T07:08:09.000Z',
          },
          {
            'type': 'video',
            'id': 'v-1',
            'name': 'Clip',
            'coverArt': null,
            'lastPlayedAt': '2024-05-04T07:08:09.000Z',
          },
          {
            'type': 'artist',
            'id': 'ar-3',
            'name': 'Third',
            'coverArt': null,
            'lastPlayedAt': '2024-05-03T07:08:09.000Z',
          },
        ]),
      );

      expect(
        [for (final item in items) (item as RecentArtist).artist.id],
        ['ar-2', 'ar-3'],
      );
    });

    test('an empty list maps to an empty list', () {
      expect(recentItemsFromWire(_recent(const [])), isEmpty);
    });
  });

  group('recently added', () {
    test('artists map in server order', () {
      final artists = recentlyAddedFromWire(
        api.RecentlyAddedResponse.fromJson({
          'artists': [
            {
              'id': 'ar-2',
              'name': 'Newer',
              'coverArt': 'c-2',
              'mbid': null,
              'albumCount': 1,
            },
            {
              'id': 'ar-1',
              'name': 'Older',
              'coverArt': null,
              'mbid': 'mb-1',
              'albumCount': 3,
            },
          ],
        }),
      );

      expect(artists, const [
        Artist(id: 'ar-2', name: 'Newer', artworkRef: 'c-2'),
        Artist(id: 'ar-1', name: 'Older'),
      ]);
    });

    test('an empty list maps to an empty list', () {
      expect(
        recentlyAddedFromWire(
          api.RecentlyAddedResponse.fromJson({'artists': <Object?>[]}),
        ),
        isEmpty,
      );
    });
  });

  group('mixes', () {
    test('a mix maps its name, description and covers', () {
      final mix = mixSummaryFromWire(
        api.MixSummary.fromJson({
          'id': 'mix-1',
          'type': 'era',
          'name': 'Your 2000s',
          'description': 'Songs from the 2000s',
          'color': '#112233',
          'coverUrls': ['c-1', 'c-2'],
          'trackCount': 20,
          'trackIds': ['t-1'],
        }),
      );

      expect(
        mix,
        const MixSummary(
          id: 'mix-1',
          name: 'Your 2000s',
          description: 'Songs from the 2000s',
          coverRefs: ['c-1', 'c-2'],
        ),
      );
    });
  });

  group('top podcasts', () {
    test('a directory podcast maps to a podcast summary', () {
      final podcast = podcastSummaryFromWire(
        api.PodcastSummary.fromJson({
          'id': '1234',
          'title': 'Top show',
          'author': 'Network',
          'coverUrl': 'http://img/top',
          'episodeCount': 0,
          'genres': ['News'],
          'isExternal': true,
          'itunesId': 1234,
        }),
      );

      expect(
        podcast,
        const PodcastSummary(
          id: '1234',
          title: 'Top show',
          author: 'Network',
          artworkRef: 'http://img/top',
        ),
      );
    });
  });
}
