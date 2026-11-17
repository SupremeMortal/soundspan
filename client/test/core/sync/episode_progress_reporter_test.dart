// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/play_reporter_input.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/episode_progress_reporter.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/core/sync/play_reporter.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../playback/controller/controller_harness.dart';
import '../playback/queue/queue_test_items.dart';
import 'outbox/outbox_test_support.dart' as outbox_support;

const Duration _episodeLength = Duration(minutes: 10);

Duration _s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

QueueItem _episode(String id) => QueueItem.episode(
  queueItemId: id,
  episode: Episode(
    id: 'ep-$id',
    podcastId: 'pod-1',
    title: 'Episode $id',
    durationSec: _episodeLength.inSeconds,
  ),
  podcast: const Podcast(id: 'pod-1', title: 'Show'),
);

/// A controller over a [FakeEngine], a reporter following it, and the real
/// [OutboxStore] over an in-memory `state.db`. The server is unreachable,
/// so every enqueued op stays pending.
final class _Rig {
  new() : db = StateDatabase(NativeDatabase.memory()), clock = FakeClock() {
    h = ControllerHarness(ids: const ['a'], clock: clock);
    h.fake.sources[uriOf('e')] = const FakeSource(duration: _episodeLength);
    h.fake.sources[uriOf('f')] = const FakeSource(duration: _episodeLength);
    store = OutboxStore(db, clock);
    final worker = OutboxWorker(
      store,
      OutboxHandlerRegistry(const []),
      FakeReachability(initial: Reachability.noNetwork),
      clock,
      AppLogger.scope('EpisodeProgressTest'),
      rewriter: TempIdRewriter(
        db,
        () async => CacheDatabase(NativeDatabase.memory()),
      ),
      periodicTimer: outbox_support.ManualTimer.new,
    );
    outbox = Outbox(store, worker);
    reporter = EpisodeProgressReporter(
      ControllerListeningSource(h.controller),
      (op) {
        history.add(op as EpisodeProgressOp);
        return outbox.enqueue(op);
      },
      clock,
    );
  }

  final StateDatabase db;
  final FakeClock clock;
  late final ControllerHarness h;
  late final OutboxStore store;
  late final Outbox outbox;
  late final EpisodeProgressReporter reporter;

  /// Every op enqueued so far, oldest first, including those a later op
  /// of the same episode replaced.
  final List<EpisodeProgressOp> history = [];

  Future<void> play(Duration d) async {
    await h.play(d);
    await settle();
  }

  Future<void> settle() async {
    await h.settle();
    await reporter.flush();
    await h.settle();
  }

  Future<List<EpisodeProgressOp>> pending() async => [
    for (final entry in await store.pending())
      if (entry.op case final EpisodeProgressOp op) op,
  ];

  Future<void> start(List<QueueItem> items) async {
    await h.controller.playItems(items);
    await settle();
  }
}

/// The position each op of [ops] carries, in seconds.
List<num> _times(List<EpisodeProgressOp> ops) => [
  for (final op in ops) op.currentTime,
];

void main() {
  late _Rig r;

  setUp(() => r = _Rig());

  tearDown(() async {
    await r.reporter.dispose();
    await r.h.controller.dispose();
    await r.db.close();
  });

  test('saves every 15 s while playing', () async {
    await r.start([_episode('e')]);
    await r.play(_s(14));
    expect(await r.pending(), isEmpty);

    await r.play(_s(2));
    expect(_times(await r.pending()), [15]);

    await r.play(_s(15));
    expect(_times(await r.pending()), [30]);
    final op = (await r.pending()).single;
    expect(op.podcastId, 'pod-1');
    expect(op.episodeId, 'ep-e');
    expect(op.duration, _episodeLength.inSeconds);
    expect(op.isFinished, isFalse);
  });

  test('saves nothing while paused and once on pause', () async {
    await r.start([_episode('e')]);
    await r.play(_s(7));
    await r.h.controller.pause();
    await r.settle();
    expect(_times(await r.pending()), [7]);

    final count = r.history.length;
    r.clock.advance(const Duration(minutes: 2));
    await r.settle();
    expect(r.history.length, count);
    expect(_times(await r.pending()), [7]);
  });

  test('saves once when the episode is replaced', () async {
    await r.start([_episode('e')]);
    await r.play(_s(9));
    await r.h.controller.playItems([_episode('f')]);
    await r.settle();

    final ops = await r.pending();
    expect(ops.map((op) => op.episodeId), ['ep-e']);
    expect(ops.single.currentTime, 9);
    expect(ops.single.isFinished, isFalse);
  });

  test('a natural end saves the episode finished', () async {
    await r.start([_episode('e')]);
    await r.h.controller.seek(_episodeLength - _s(5));
    await r.settle();
    await r.play(_s(6));

    final op = (await r.pending()).single;
    expect(op.isFinished, isTrue);
    expect(op.currentTime, _episodeLength.inSeconds);
  });

  test('29 s before the end is finished, 31 s is not', () async {
    await r.start([_episode('e')]);
    await r.h.controller.seek(_episodeLength - _s(31));
    await r.settle();
    await r.play(_s(0.5));
    await r.h.controller.pause();
    await r.settle();
    expect((await r.pending()).single.isFinished, isFalse);

    await r.h.controller.seek(_episodeLength - _s(29));
    await r.h.controller.play();
    await r.settle();
    await r.play(_s(0.5));
    await r.h.controller.pause();
    await r.settle();
    expect((await r.pending()).single.isFinished, isTrue);
  });

  test('ten saves offline leave one pending op with the latest '
      'position', () async {
    await r.start([_episode('e')]);
    await r.play(_s(151));

    expect(r.history.length, 10);
    expect(_times(await r.pending()), [150]);
  });

  test('an unknown duration saves nothing', () async {
    final states = StreamController<ListeningState>();
    final saved = <OutboxOp>[];
    final reporter = EpisodeProgressReporter(
      _ScriptedSource(states.stream),
      (op) async => saved.add(op),
      r.clock,
    );
    final episode = _episode('e');
    for (var second = 0; second <= 20; second++) {
      states.add(
        ListeningState(
          current: episode,
          audible: true,
          playing: true,
          position: _s(second),
        ),
      );
      r.clock.advance(_s(1));
      await pumpEventQueue();
    }
    states.add(
      ListeningState(current: episode, audible: false, playing: false),
    );
    await pumpEventQueue();
    await reporter.dispose();
    await states.close();

    expect(saved, isEmpty);
  });

  test('a track as current item saves nothing', () async {
    await r.start([trackItem('a')]);
    await r.play(_s(8));
    await r.h.controller.pause();
    await r.settle();

    expect(await r.pending(), isEmpty);
  });
}

/// An [EpisodeListeningSource] over scripted [states] and no ended entries.
final class _ScriptedSource implements EpisodeListeningSource {
  const new(this.states);

  @override
  final Stream<ListeningState> states;

  @override
  Stream<EndedEntry> get ended => const Stream.empty();
}
