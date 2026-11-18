// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Podcasts" of doc 03's endpoint inventory: every
/// operation of that table but the directory's top list (which reaches an
/// external directory) through the generated client, and the episode stream
/// through a plain HTTP client with `StreamUrls`, against the podcast the
/// seed subscribes `listener` to from the fixture feed.
@Tags(['contract'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

/// The feed `seed.ts` subscribes to, served by compose.yaml's podcast-feed.
const _feedUrl = 'http://podcast-feed/feed.xml';

/// The title of the fixture podcast in `fixtures/podcast/feed.xml`.
const _title = 'Contract Cast';

/// One answer of a plain HTTP request.
typedef _Answer = ({int status, HttpHeaders headers, Uint8List body});

/// GETs [uri] with [headers] through a plain HTTP client.
Future<_Answer> _get(Uri uri, [Map<String, String> headers = const {}]) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    headers.forEach(request.headers.set);
    final response = await request.close();
    final builder = await response.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );
    return (
      status: response.statusCode,
      headers: response.headers,
      body: builder.takeBytes(),
    );
  } finally {
    client.close(force: true);
  }
}

void main() {
  late ContractCredentials credentials;
  late JwtCredentials session;
  late SoundspanApi api;

  setUp(() async {
    credentials = ContractCredentials.load();
    final login = await logIn(credentials, credentials.listener);
    session = JwtCredentials(
      accessToken: login.token,
      refreshToken: login.refreshToken,
    );
    api = credentialedApi(credentials, InMemoryCredentialProvider(session));
  });

  Future<SubscribedPodcast> seeded() async {
    final podcasts = await api.send((rest) => rest.podcasts.listPodcasts());
    return podcasts.singleWhere((podcast) => podcast.title == _title);
  }

  Future<PodcastDetail> detailOf(String id) =>
      api.send((rest) => rest.podcasts.getPodcast(id: id));

  test('the list holds the seeded podcast; its detail lists the episodes '
      'newest first with durations', () async {
    final podcast = await seeded();
    expect(podcast.episodeCount, 2);

    final detail = await detailOf(podcast.id);
    expect(detail.title, _title);
    expect(detail.feedUrl, _feedUrl);
    expect(detail.episodes.map((e) => e.title), [
      'Second Signal',
      'First Signal',
    ]);
    expect(detail.episodes.map((e) => e.duration), [8, 6]);
  });

  test(
    'the episode stream answers 200 with audio and 206 for a Range',
    () async {
      final podcast = await seeded();
      final episode = (await detailOf(podcast.id)).episodes.last;
      final uri = StreamUrls(credentials.baseUrl)
          .episode(podcast.id, episode.id);
      final headers = StreamUrls(credentials.baseUrl).authHeaders(session);

      final full = await _get(uri, headers);
      expect(full.status, 200);
      expect(full.headers.contentType?.primaryType, 'audio');
      expect(full.body.length, greaterThan(1000));

      final range = await _get(uri, {...headers, 'Range': 'bytes=0-99'});
      expect(range.status, 206);
      expect(range.body, full.body.sublist(0, 100));
    },
  );

  test('posted progress shows on the episode, then finished', () async {
    final podcast = await seeded();
    final episode = (await detailOf(podcast.id)).episodes.first;

    final saved = await api.send(
      (rest) => rest.podcasts.updateEpisodeProgress(
        podcastId: podcast.id,
        episodeId: episode.id,
        body: const UpdateEpisodeProgressRequest(
          currentTime: 3,
          duration: 8,
          isFinished: false,
        ),
      ),
    );
    expect(saved.success, isTrue);
    var progress = (await detailOf(podcast.id)).episodes
        .singleWhere((e) => e.id == episode.id)
        .progress;
    expect(progress?.currentTime, 3);
    expect(progress?.isFinished, isFalse);

    await api.send(
      (rest) => rest.podcasts.updateEpisodeProgress(
        podcastId: podcast.id,
        episodeId: episode.id,
        body: const UpdateEpisodeProgressRequest(
          currentTime: 8,
          duration: 8,
          isFinished: true,
        ),
      ),
    );
    progress = (await detailOf(podcast.id)).episodes
        .singleWhere((e) => e.id == episode.id)
        .progress;
    expect(progress?.isFinished, isTrue);
  });

  test('unsubscribe removes the podcast from the list; subscribing with '
      'its feed restores it', () async {
    final podcast = await seeded();

    final removed = await api.send(
      (rest) => rest.podcasts.unsubscribePodcast(id: podcast.id),
    );
    expect(removed.success, isTrue);
    final afterRemove = await api.send((rest) => rest.podcasts.listPodcasts());
    expect(afterRemove.where((p) => p.id == podcast.id), isEmpty);

    final added = await api.send(
      (rest) => rest.podcasts.subscribePodcast(
        body: const SubscribePodcastRequest(feedUrl: _feedUrl),
      ),
    );
    expect(added.success, isTrue);
    expect(added.podcast.id, podcast.id);
    expect((await seeded()).id, podcast.id);
  });

  test('an unauthenticated list is 401', () async {
    await expectLater(
      anonymousApi(credentials).send((rest) => rest.podcasts.listPodcasts()),
      throwsA(isA<Unauthenticated>().having((e) => e.status, 'status', 401)),
    );
  });
}
