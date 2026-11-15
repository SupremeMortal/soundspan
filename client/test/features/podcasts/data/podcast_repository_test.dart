// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/features/podcasts/data/cached_podcast_repository.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';

FakePodcast _show() => FakePodcast(
  id: 'pc-1',
  title: 'The Show',
  feedUrl: 'https://example.com/show.xml',
  itunesId: '101',
  author: 'Host',
  episodes: [
    (
      id: 'e2',
      title: 'Two',
      durationSec: 1200,
      publishedAt: DateTime.utc(2024, 2),
    ),
    (id: 'e1', title: 'One', durationSec: 600, publishedAt: DateTime.utc(2024)),
  ],
);

FakePodcast _other() => FakePodcast(
  id: 'pc-2',
  title: 'Other Show',
  feedUrl: 'https://example.com/other.xml',
  itunesId: '202',
);

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late FakeReachability reachability;
  late FakePodcastsClient server;
  late CachedPodcastRepository repository;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    reachability = FakeReachability();
    server = FakeApi().podcasts..addSubscribed(_show());
    repository = CachedPodcastRepository(
      server,
      CacheStore(db, clock),
      Swr(clock: clock, reachability: reachability),
    );
  });

  tearDown(() => db.close());

  /// Listens to [stream] until the event queue is empty and returns what it
  /// emitted and the errors it raised.
  Future<(List<Cached<T>>, List<Object>)> listenOnce<T>(
    Stream<Cached<T>> stream,
  ) async {
    final values = <Cached<T>>[];
    final errors = <Object>[];
    final subscription = stream.listen(values.add, onError: errors.add);
    await pumpEventQueue();
    await subscription.cancel();
    return (values, errors);
  }

  int calls(String name) => server.calls[name] ?? 0;

  group('subscribed', () {
    test('fetches with nothing cached and maps the podcasts', () async {
      final (values, errors) = await listenOnce(repository.subscribed());

      expect(errors, isEmpty);
      expect(values.single.value, const [
        Podcast(
          id: 'pc-1',
          title: 'The Show',
          author: 'Host',
          artworkRef: '/podcasts/pc-1/cover',
          episodeCount: 2,
        ),
      ]);
      expect(values.single.refreshing, isFalse);
      expect(calls('listPodcasts'), 1);
    });

    test(
      'a cache hit emits first and refreshes only after 10 minutes',
      () async {
        await listenOnce(repository.subscribed());
        server.podcasts['pc-1']!.title = 'Renamed';

        clock.advance(const Duration(minutes: 10) - const Duration(seconds: 1));
        final (fresh, _) = await listenOnce(repository.subscribed());
        expect(calls('listPodcasts'), 1);
        expect(fresh.single.value.single.title, 'The Show');

        clock.advance(const Duration(seconds: 2));
        final (stale, _) = await listenOnce(repository.subscribed());
        expect(calls('listPodcasts'), 2);
        expect(stale.first.refreshing, isTrue);
        expect(stale.first.value.single.title, 'The Show');
        expect(stale.last.refreshing, isFalse);
        expect(stale.last.value.single.title, 'Renamed');
      },
    );

    test('a failed refresh re-emits the cache with refreshError', () async {
      await listenOnce(repository.subscribed());
      clock.advance(const Duration(hours: 1));
      server.failures['listPodcasts'] = const api.ServerError(status: 500);

      final (values, errors) = await listenOnce(repository.subscribed());

      expect(errors, isEmpty);
      expect(values.last.value.single.id, 'pc-1');
      expect(values.last.refreshing, isFalse);
      expect(values.last.refreshError, isA<api.ServerError>());
    });

    test('nothing cached and a failure errors the stream', () async {
      server.failures['listPodcasts'] = const api.ServerError(status: 500);

      final (values, errors) = await listenOnce(repository.subscribed());

      expect(values, isEmpty);
      expect(errors, [isA<api.ServerError>()]);
    });

    test('offline serves the cache whatever its age', () async {
      await listenOnce(repository.subscribed());
      clock.advance(const Duration(days: 3));
      reachability.set(Reachability.serverUnreachable);

      final (values, errors) = await listenOnce(repository.subscribed());

      expect(errors, isEmpty);
      expect(values.single.value.single.id, 'pc-1');
      expect(calls('listPodcasts'), 1);
    });

    test('offline with nothing cached errors with Offline', () async {
      reachability.set(Reachability.serverUnreachable);

      final (values, errors) = await listenOnce(repository.subscribed());

      expect(values, isEmpty);
      expect(errors, [isA<api.Offline>()]);
      expect(calls('listPodcasts'), 0);
    });

    test('refreshSubscribed fetches whatever the age', () async {
      await listenOnce(repository.subscribed());

      await repository.refreshSubscribed();

      expect(calls('listPodcasts'), 2);
    });
  });

  group('detail', () {
    test('fetches with nothing cached; episodes newest first', () async {
      final (values, errors) = await listenOnce(repository.detail('pc-1'));

      expect(errors, isEmpty);
      final detail = values.single.value;
      expect(detail.podcast.id, 'pc-1');
      expect(detail.podcast.title, 'The Show');
      expect([for (final e in detail.episodes) e.id], ['e2', 'e1']);
      expect(detail.episodes.first.durationSec, 1200);
      expect(detail.episodes.first.podcastId, 'pc-1');
    });

    test(
      'a cache hit emits first and refreshes only after 10 minutes',
      () async {
        await listenOnce(repository.detail('pc-1'));
        server.podcasts['pc-1']!.title = 'Renamed';

        clock.advance(const Duration(minutes: 10) - const Duration(seconds: 1));
        await listenOnce(repository.detail('pc-1'));
        expect(calls('getPodcast'), 1);

        clock.advance(const Duration(seconds: 2));
        final (stale, _) = await listenOnce(repository.detail('pc-1'));
        expect(calls('getPodcast'), 2);
        expect(stale.first.refreshing, isTrue);
        expect(stale.last.value.podcast.title, 'Renamed');
      },
    );

    test('a failed refresh re-emits the cache with refreshError', () async {
      await listenOnce(repository.detail('pc-1'));
      clock.advance(const Duration(hours: 1));
      server.failures['getPodcast'] = const api.ServerError(status: 503);

      final (values, errors) = await listenOnce(repository.detail('pc-1'));

      expect(errors, isEmpty);
      expect(values.last.value.episodes, hasLength(2));
      expect(values.last.refreshError, isA<api.ServerError>());
    });

    test('nothing cached and a failure errors the stream', () async {
      final (values, errors) = await listenOnce(repository.detail('pc-9'));

      expect(values, isEmpty);
      expect(errors, [isA<api.NotFound>()]);
    });

    test('offline serves the cache whatever its age', () async {
      await listenOnce(repository.detail('pc-1'));
      clock.advance(const Duration(days: 3));
      reachability.set(Reachability.serverUnreachable);

      final (values, errors) = await listenOnce(repository.detail('pc-1'));

      expect(errors, isEmpty);
      expect(values.single.value.episodes, hasLength(2));
      expect(calls('getPodcast'), 1);
    });

    test('a cached episode that fails to decode is a cache miss', () async {
      await listenOnce(repository.detail('pc-1'));
      await (db.update(db.episodes)..where((e) => e.id.equals('e1'))).write(
        const EpisodesCompanion(json: Value('{"not": "an episode"}')),
      );

      final (values, errors) = await listenOnce(repository.detail('pc-1'));

      expect(errors, isEmpty);
      expect(calls('getPodcast'), 2);
      expect([for (final e in values.last.value.episodes) e.id], ['e2', 'e1']);
    });

    test('refreshDetail fetches whatever the age', () async {
      await listenOnce(repository.detail('pc-1'));

      await repository.refreshDetail('pc-1');

      expect(calls('getPodcast'), 2);
    });
  });

  group('subscribe and unsubscribe', () {
    test('subscribe sends the reference and invalidates the subscribed '
        'list', () async {
      server.podcasts['pc-2'] = _other();
      await listenOnce(repository.subscribed());

      final id = await repository.subscribe(
        const PodcastRef.feed('https://example.com/other.xml'),
      );

      expect(id, 'pc-2');
      expect(server.subscriptions, ['pc-2', 'pc-1']);
      final (values, _) = await listenOnce(repository.subscribed());
      expect(calls('listPodcasts'), 2);
      expect([for (final p in values.last.value) p.id], ['pc-2', 'pc-1']);
    });

    test('subscribe by iTunes id', () async {
      server.podcasts['pc-2'] = _other();

      await repository.subscribe(const PodcastRef.itunes('202'));

      expect(server.subscriptions.first, 'pc-2');
    });

    test('unsubscribe invalidates the subscribed list', () async {
      await listenOnce(repository.subscribed());

      await repository.unsubscribe('pc-1');

      expect(server.subscriptions, isEmpty);
      final (values, _) = await listenOnce(repository.subscribed());
      expect(calls('listPodcasts'), 2);
      expect(values.last.value, isEmpty);
    });

    test(
      'subscribe offline throws Offline without calling the server',
      () async {
        server.podcasts['pc-2'] = _other();
        reachability.set(Reachability.serverUnreachable);

        await expectLater(
          repository.subscribe(const PodcastRef.itunes('202')),
          throwsA(isA<api.Offline>()),
        );
        expect(calls('subscribePodcast'), 0);
      },
    );

    test(
      'unsubscribe offline throws Offline without calling the server',
      () async {
        reachability.set(Reachability.serverUnreachable);

        await expectLater(
          repository.unsubscribe('pc-1'),
          throwsA(isA<api.Offline>()),
        );
        expect(calls('unsubscribePodcast'), 0);
      },
    );

    test('a failed subscribe propagates and leaves the list fresh', () async {
      await listenOnce(repository.subscribed());

      await expectLater(
        repository.subscribe(const PodcastRef.itunes('999')),
        throwsA(isA<api.NotFound>()),
      );

      await listenOnce(repository.subscribed());
      expect(calls('listPodcasts'), 1);
    });
  });

  group('postProgress', () {
    test('posts the progress and updates the cached episode', () async {
      final cached = <Cached<PodcastDetail>>[];
      final subscription = repository.detail('pc-1').listen(cached.add);
      await pumpEventQueue();
      expect(cached.last.value.episodes.last.progress, isNull);

      await repository.postProgress(
        podcastId: 'pc-1',
        episodeId: 'e1',
        currentTimeSec: 42.5,
        durationSec: 600,
        isFinished: false,
      );
      await pumpEventQueue();

      final sent = server.progress['e1']!;
      expect(sent.currentTime, 42.5);
      expect(sent.duration, 600);
      expect(sent.isFinished, isFalse);
      expect(
        cached.last.value.episodes.last.progress,
        const EpisodeProgress(currentTimeSec: 42.5, isFinished: false),
      );
      expect(cached.last.value.episodes.first.progress, isNull);
      expect(calls('getPodcast'), 1);
      await subscription.cancel();

      await repository.postProgress(
        podcastId: 'pc-1',
        episodeId: 'e1',
        currentTimeSec: 600,
        durationSec: 600,
        isFinished: true,
      );
      final (values, _) = await listenOnce(repository.detail('pc-1'));
      expect(
        values.single.value.episodes.last.progress,
        const EpisodeProgress(currentTimeSec: 600, isFinished: true),
      );
    });

    test('a failed post leaves the cached episode as it was', () async {
      await listenOnce(repository.detail('pc-1'));
      server.failures['updateEpisodeProgress'] = const api.Offline();

      await expectLater(
        repository.postProgress(
          podcastId: 'pc-1',
          episodeId: 'e1',
          currentTimeSec: 10,
          durationSec: 600,
          isFinished: false,
        ),
        throwsA(isA<api.Offline>()),
      );

      final (values, _) = await listenOnce(repository.detail('pc-1'));
      expect(values.single.value.episodes.last.progress, isNull);
    });

    test('posting for an episode that is not cached only posts', () async {
      await repository.postProgress(
        podcastId: 'pc-1',
        episodeId: 'e2',
        currentTimeSec: 5,
        durationSec: 1200,
        isFinished: false,
      );

      expect(server.progress.keys, ['e2']);
      expect(await db.select(db.episodes).get(), isEmpty);
    });
  });
}
