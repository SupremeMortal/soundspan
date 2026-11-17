// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/features/podcasts/data/cached_podcast_repository.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/podcast/episode_progress_outbox.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../core/sync/outbox/outbox_test_support.dart' as support;
import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';

FakePodcast _show() => FakePodcast(
  id: 'pc-1',
  title: 'The Show',
  feedUrl: 'https://example.com/show.xml',
  episodes: [
    (id: 'e1', title: 'One', durationSec: 600, publishedAt: DateTime.utc(2024)),
  ],
);

EpisodeProgressOp _op({
  String episodeId = 'e1',
  num currentTime = 42,
  bool isFinished = false,
}) => EpisodeProgressOp(
  podcastId: 'pc-1',
  episodeId: episodeId,
  currentTime: currentTime,
  duration: 600,
  isFinished: isFinished,
);

/// The real worker and stores over a [FakePodcastsClient], with the
/// podcast's episodes cached through the repository.
final class _Rig {
  new() {
    server = FakeApi().podcasts..addSubscribed(_show());
    cache = CacheStore(cacheDb, clock);
    repository = CachedPodcastRepository(
      server,
      cache,
      Swr(clock: clock, reachability: reachability),
      pending: (types) => store.watchPending(opTypes: types),
    );
    store = OutboxStore(stateDb, clock);
    worker = OutboxWorker(
      store,
      OutboxHandlerRegistry(
        episodeProgressOutboxHandlers(server, () async => cache),
      ),
      reachability,
      clock,
      AppLogger.scope('EpisodeProgressOutboxTest'),
      rewriter: TempIdRewriter(stateDb, () async => cacheDb),
      periodicTimer: support.ManualTimer.new,
    );
    outbox = Outbox(store, worker);
  }

  final FakeClock clock = FakeClock();
  final FakeReachability reachability = FakeReachability();
  final StateDatabase stateDb = StateDatabase(NativeDatabase.memory());
  final CacheDatabase cacheDb = CacheDatabase(NativeDatabase.memory());
  late final FakePodcastsClient server;
  late final CacheStore cache;
  late final CachedPodcastRepository repository;
  late final OutboxStore store;
  late final OutboxWorker worker;
  late final Outbox outbox;

  Future<PodcastDetail> detail() async {
    final values = <PodcastDetail>[];
    final subscription = repository
        .detail('pc-1')
        .listen((cached) => values.add(cached.value));
    await pumpEventQueue();
    await subscription.cancel();
    return values.last;
  }

  Future<void> drain() async {
    await pumpEventQueue();
    await worker.idle;
    await pumpEventQueue();
  }

  Future<void> close() async {
    await worker.dispose();
    await stateDb.close();
    await cacheDb.close();
  }
}

void main() {
  late _Rig r;

  setUp(() async {
    r = _Rig();
    await r.detail();
  });

  tearDown(() => r.close());

  test('sends the op to the progress endpoint with the three fields and '
      'updates the cached episode', () async {
    await r.worker.start();
    await r.outbox.enqueue(_op());
    await r.drain();

    final sent = r.server.progress['e1']!;
    expect(sent.currentTime, 42);
    expect(sent.duration, 600);
    expect(sent.isFinished, isFalse);
    expect(await r.store.pending(), isEmpty);
    expect(
      (await r.detail()).episodes.single.progress,
      const EpisodeProgress(currentTimeSec: 42, isFinished: false),
    );
  });

  test('a 404 drops the op and removes the episode from the cache', () async {
    await r.worker.start();
    await r.outbox.enqueue(_op(episodeId: 'gone'));
    await r.cache.upsertEpisodes([
      const Episode(id: 'gone', podcastId: 'pc-1', title: 'Gone'),
    ]);
    await r.drain();

    expect(await r.store.pending(), isEmpty);
    expect(r.server.progress, isEmpty);
    expect(await r.cache.updateEpisode('gone', (e) => e), isFalse);
  });

  test('offline keeps the op and sends it on return to online', () async {
    r.reachability.set(Reachability.noNetwork);
    await r.worker.start();
    await r.outbox.enqueue(_op(currentTime: 10));
    await r.outbox.enqueue(_op(currentTime: 25));
    await r.drain();

    expect(r.server.calls['updateEpisodeProgress'], isNull);
    expect((await r.store.pending()).length, 1);
    expect(
      (await r.detail()).episodes.single.progress,
      const EpisodeProgress(currentTimeSec: 25, isFinished: false),
      reason: 'a pending op overrides the cached progress',
    );

    r.reachability.set(Reachability.online);
    await r.drain();

    expect(r.server.calls['updateEpisodeProgress'], 1);
    expect(r.server.progress['e1']!.currentTime, 25);
    expect(await r.store.pending(), isEmpty);
  });

  test('overlayEpisodeProgress applies the latest pending op of each '
      'episode', () {
    const episodes = [
      Episode(id: 'e1', podcastId: 'pc-1', title: 'One'),
      Episode(id: 'e2', podcastId: 'pc-1', title: 'Two'),
    ];
    final ops = [
      for (final (seq, op) in [
        (1, _op(currentTime: 5)),
        (2, _op(currentTime: 600, isFinished: true)),
      ])
        OutboxEntry(
          seq: seq,
          op: op,
          createdAt: DateTime.utc(2026),
          attempts: 0,
        ),
    ];

    final overlaid = overlayEpisodeProgress(episodes, ops);

    expect(
      overlaid.first.progress,
      const EpisodeProgress(currentTimeSec: 600, isFinished: true),
    );
    expect(overlaid.last.progress, isNull);
  });
}
