// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/features/podcasts/data/podcast_mappers.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

Map<String, Object?> _progressJson({
  num currentTime = 125.5,
  bool isFinished = false,
}) => {
  'currentTime': currentTime,
  'isFinished': isFinished,
  'lastPlayedAt': '2024-03-01T10:00:00.000Z',
  'progress': 40,
};

Map<String, Object?> _episodeJson(
  String id, {
  Map<String, Object?>? progress,
  String? description = 'About the episode',
  String? imageUrl = '/podcasts/pc-1/episodes/e/cover',
}) => {
  'id': id,
  'title': 'Episode $id',
  'description': description,
  'duration': 1800,
  'publishedAt': '2024-02-01T08:30:00.000+02:00',
  'episodeNumber': null,
  'season': null,
  'imageUrl': imageUrl,
  'isDownloaded': false,
  'progress': progress,
};

Map<String, Object?> _subscribedJson({
  String? author = 'Host',
  String? description = 'A show',
  String? coverUrl = '/podcasts/pc-1/cover',
}) => {
  'id': 'pc-1',
  'title': 'The Show',
  'author': author,
  'description': description,
  'coverUrl': coverUrl,
  'autoDownloadEpisodes': false,
  'episodeCount': 12,
  'episodes': <Object?>[],
};

Map<String, Object?> _detailJson(List<Map<String, Object?>> episodes) => {
  'id': 'pc-1',
  'title': 'The Show',
  'author': 'Host',
  'description': 'A show',
  'coverUrl': '/podcasts/pc-1/cover',
  'feedUrl': 'https://example.com/feed.xml',
  'genres': <Object?>['Tech'],
  'isSubscribed': true,
  'autoDownloadEpisodes': false,
  'episodes': episodes,
};

void main() {
  group('podcastFromSubscribed', () {
    test('maps a subscribed podcast', () {
      final podcast = podcastFromSubscribed(
        api.SubscribedPodcast.fromJson(_subscribedJson()),
      );

      expect(
        podcast,
        const Podcast(
          id: 'pc-1',
          title: 'The Show',
          author: 'Host',
          description: 'A show',
          artworkRef: '/podcasts/pc-1/cover',
          episodeCount: 12,
        ),
      );
    });

    test('missing optional fields are null', () {
      final podcast = podcastFromSubscribed(
        api.SubscribedPodcast.fromJson(
          _subscribedJson(author: null, description: null, coverUrl: null),
        ),
      );

      expect(podcast.author, isNull);
      expect(podcast.description, isNull);
      expect(podcast.artworkRef, isNull);
    });

    test('unknown extra keys are ignored', () {
      final podcast = podcastFromSubscribed(
        api.SubscribedPodcast.fromJson({
          ..._subscribedJson(),
          'somethingNew': {'nested': true},
        }),
      );

      expect(podcast.id, 'pc-1');
      expect(podcast.episodeCount, 12);
    });
  });

  group('podcastDetailFromWire', () {
    test('maps the podcast and its episodes in server order', () {
      final detail = podcastDetailFromWire(
        api.PodcastDetail.fromJson(
          _detailJson([_episodeJson('e2'), _episodeJson('e1')]),
        ),
      );

      expect(
        detail.podcast,
        const Podcast(
          id: 'pc-1',
          title: 'The Show',
          author: 'Host',
          description: 'A show',
          artworkRef: '/podcasts/pc-1/cover',
          episodeCount: 2,
        ),
      );
      expect([for (final e in detail.episodes) e.id], ['e2', 'e1']);
      expect(
        detail.episodes.first,
        Episode(
          id: 'e2',
          podcastId: 'pc-1',
          title: 'Episode e2',
          description: 'About the episode',
          durationSec: 1800,
          publishedAt: DateTime.utc(2024, 2, 1, 6, 30),
          artworkRef: '/podcasts/pc-1/episodes/e/cover',
        ),
      );
      expect(detail.episodes.first.publishedAt!.isUtc, isTrue);
    });

    test('an episode with progress carries it', () {
      final detail = podcastDetailFromWire(
        api.PodcastDetail.fromJson(
          _detailJson([
            _episodeJson('e1', progress: _progressJson()),
            _episodeJson(
              'e2',
              progress: _progressJson(currentTime: 1800, isFinished: true),
            ),
          ]),
        ),
      );

      expect(
        detail.episodes[0].progress,
        const EpisodeProgress(currentTimeSec: 125.5, isFinished: false),
      );
      expect(
        detail.episodes[1].progress,
        const EpisodeProgress(currentTimeSec: 1800, isFinished: true),
      );
    });

    test('an episode without progress has none', () {
      final detail = podcastDetailFromWire(
        api.PodcastDetail.fromJson(_detailJson([_episodeJson('e1')])),
      );

      expect(detail.episodes.single.progress, isNull);
    });

    test('missing optional episode fields are null', () {
      final detail = podcastDetailFromWire(
        api.PodcastDetail.fromJson(
          _detailJson([_episodeJson('e1', description: null, imageUrl: null)]),
        ),
      );

      expect(detail.episodes.single.description, isNull);
      expect(detail.episodes.single.artworkRef, isNull);
    });

    test('unknown extra keys are ignored', () {
      final detail = podcastDetailFromWire(
        api.PodcastDetail.fromJson({
          ..._detailJson([
            {..._episodeJson('e1'), 'transcriptUrl': 'x'},
          ]),
          'extra': 1,
        }),
      );

      expect(detail.episodes.single.id, 'e1');
    });
  });

  group('subscribeRequestFromRef', () {
    test('a feed reference sends feedUrl only', () {
      final request = subscribeRequestFromRef(
        const PodcastRef.feed('https://example.com/feed.xml'),
      );

      expect(request.toJson(), {'feedUrl': 'https://example.com/feed.xml'});
    });

    test('an iTunes reference sends itunesId only', () {
      final request = subscribeRequestFromRef(const PodcastRef.itunes('42'));

      expect(request.toJson(), {'itunesId': '42'});
    });
  });

  group('PodcastRef.fromSummary', () {
    test('prefers the feed URL, then the iTunes id', () {
      expect(
        PodcastRef.fromSummary(
          const PodcastSummary(
            id: '42',
            title: 'Top',
            feedUrl: 'https://example.com/top.xml',
            itunesId: '42',
          ),
        ),
        const PodcastRef.feed('https://example.com/top.xml'),
      );
      expect(
        PodcastRef.fromSummary(
          const PodcastSummary(id: '42', title: 'Top', itunesId: '42'),
        ),
        const PodcastRef.itunes('42'),
      );
      expect(
        PodcastRef.fromSummary(const PodcastSummary(id: '42', title: 'Top')),
        isNull,
      );
    });
  });
}
