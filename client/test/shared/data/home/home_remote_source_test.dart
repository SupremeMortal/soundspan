// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/shared/data/home/home_remote_source.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockLibraryClient extends Mock implements api.LibraryClient;

class _MockDiscoveryClient extends Mock implements api.DiscoveryClient;

class _MockPodcastsClient extends Mock implements api.PodcastsClient;

void main() {
  late _MockLibraryClient library;
  late _MockDiscoveryClient discovery;
  late _MockPodcastsClient podcasts;
  late HomeRemoteSource source;

  setUp(() {
    library = _MockLibraryClient();
    discovery = _MockDiscoveryClient();
    podcasts = _MockPodcastsClient();
    source = HomeRemoteSource(
      libraryClient: library,
      discoveryClient: discovery,
      podcastsClient: podcasts,
    );
  });

  test('recently listened passes the limit through', () async {
    when(() => library.listRecentlyListened(limit: any(named: 'limit')))
        .thenAnswer(
          (_) async => api.RecentlyListenedResponse.fromJson({
            'items': [
              {
                'type': 'artist',
                'id': 'ar-1',
                'name': 'Band',
                'coverArt': null,
                'lastPlayedAt': '2024-05-06T07:08:09.000Z',
              },
            ],
          }),
        );

    final items = await source.recentlyListened(limit: 8);

    verify(() => library.listRecentlyListened(limit: 8)).called(1);
    expect(items, [
      const RecentItem.artist(
        artist: Artist(id: 'ar-1', name: 'Band'),
      ),
    ]);
  });

  test('recently added passes the limit through', () async {
    when(() => library.listRecentlyAdded(limit: any(named: 'limit')))
        .thenAnswer(
          (_) async =>
              api.RecentlyAddedResponse.fromJson({'artists': <Object?>[]}),
        );

    expect(await source.recentlyAdded(limit: 12), isEmpty);
    verify(() => library.listRecentlyAdded(limit: 12)).called(1);
  });

  test('mixes maps every mix', () async {
    when(() => discovery.listMixes()).thenAnswer(
      (_) async => [
        api.MixSummary.fromJson({
          'id': 'mix-1',
          'type': 'era',
          'name': 'Mix',
          'description': 'About',
          'color': '#000000',
          'coverUrls': <Object?>[],
          'trackCount': 0,
          'trackIds': <Object?>[],
        }),
      ],
    );

    expect(await source.mixes(), [
      const MixSummary(id: 'mix-1', name: 'Mix', description: 'About'),
    ]);
  });

  test('FeatureDisabled from mixes propagates', () async {
    const error = api.FeatureDisabled(
      status: 404,
      code: 'FEATURE_DISABLED',
      serverMessage: 'feature disabled',
    );
    when(() => discovery.listMixes()).thenThrow(error);

    await expectLater(source.mixes(), throwsA(same(error)));
  });

  test('top podcasts passes the limit through', () async {
    when(() => podcasts.listTopPodcasts(limit: any(named: 'limit')))
        .thenAnswer((_) async => []);

    expect(await source.topPodcasts(limit: 6), isEmpty);
    verify(() => podcasts.listTopPodcasts(limit: 6)).called(1);
  });
}
