// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/play_reporter_input.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/core/sync/play_reporter.dart';
import 'package:soundspan/core/sync/play_session_store.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../playback/controller/controller_harness.dart';
import '../playback/queue/queue_test_items.dart';
import 'outbox/outbox_test_support.dart' as outbox_support;

/// The length of every source in these tests.
const Duration _long = Duration(minutes: 5);

Duration _s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

/// A controller over a [FakeEngine], a reporter following it, and the real
/// [OutboxStore] over an in-memory `state.db`. The server is unreachable,
/// so every enqueued play stays pending.
final class _Rig {
  new() : db = StateDatabase(NativeDatabase.memory()), clock = FakeClock() {
    h = ControllerHarness(clock: clock);
    for (final id in const ['a', 'b', 'c', 'd']) {
      h.fake.sources[uriOf(id)] = const FakeSource(duration: _long);
    }
    store = OutboxStore(db, clock);
    final worker = OutboxWorker(
      store,
      OutboxHandlerRegistry(const []),
      FakeReachability(initial: Reachability.noNetwork),
      clock,
      AppLogger.scope('PlayReporterTest'),
      rewriter: TempIdRewriter(
        db,
        () async => CacheDatabase(NativeDatabase.memory()),
      ),
      periodicTimer: outbox_support.ManualTimer.new,
    );
    outbox = Outbox(store, worker);
    sessions = PlaySessionStore(db);
    reporter = newReporter();
  }

  final StateDatabase db;
  final FakeClock clock;
  late final ControllerHarness h;
  late final OutboxStore store;
  late final Outbox outbox;
  late final PlaySessionStore sessions;
  late PlayReporter reporter;
  final StreamController<AppLifecycleState> lifecycle =
      StreamController<AppLifecycleState>.broadcast();

  PlayReporter newReporter() => PlayReporter(
    ControllerListeningSource(h.controller),
    sessions,
    outbox,
    clock,
    lifecycle.stream,
  );

  /// Lets [d] of playback pass, then waits for the reporter's writes.
  Future<void> play(Duration d) async {
    await h.play(d);
    await settle();
  }

  /// Lets [d] pass on the clock alone (the engine is paused or stuck).
  Future<void> wait(Duration d) async {
    clock.advance(d);
    await settle();
  }

  Future<void> settle() async {
    await h.settle();
    await reporter.flush();
    await h.settle();
  }

  /// The plays waiting in the outbox, in order.
  Future<List<PlayOp>> plays() async => [
    for (final entry in await store.pending())
      if (entry.op case final PlayOp op) op,
  ];

  Future<List<PlaySession>> rows() => db.select(db.playSessions).get();

  Future<void> start(List<String> ids, {int startIndex = 0}) async {
    await h.controller.playItems(trackItems(ids), startIndex: startIndex);
    await settle();
  }
}

void main() {
  late _Rig r;

  setUp(() => r = _Rig());
  tearDown(() async {
    await r.reporter.dispose();
    await r.db.close();
  });

  group('starts at first audible output', () {
    test('a current entry that never plays produces nothing', () async {
      r.h.controller.beforePlay = () async => false;
      await r.start(['a', 'b']);
      await r.wait(_s(30));
      await r.h.controller.next();
      await r.wait(_s(30));
      await r.h.controller.clear();
      await r.settle();

      expect(await r.plays(), isEmpty);
      expect(await r.rows(), isEmpty);
    });

    test('a preloaded next entry produces nothing', () async {
      await r.start(['a', 'b']);
      await r.play(_s(6));
      expect(r.h.calls, contains('setNext(b)'));
      await r.h.controller.stop();
      await r.settle();

      final plays = await r.plays();
      expect(plays.map((p) => p.playbackId), ['pb-a']);
    });
  });

  test('playedAt is the start instant, not the end', () async {
    final start = r.clock.now();
    await r.start(['a', 'b']);
    await r.play(_s(20));
    await r.h.controller.next();
    await r.settle();

    final plays = await r.plays();
    expect(plays.single.playedAt, start);
    expect(plays.single.playedAt.isUtc, isTrue);
  });

  test('accumulates only while ready and playing: 10 s played, 60 s paused, '
      '10 s played', () async {
    await r.start(['a', 'b']);
    await r.play(_s(10));
    await r.h.controller.pause();
    await r.settle();
    await r.wait(_s(60));
    await r.h.controller.play();
    await r.settle();
    await r.play(_s(10));
    await r.h.controller.next();
    await r.settle();

    expect((await r.plays()).single.listenedMs, 20000);
  });

  test('buffering adds nothing', () async {
    r.h.fake.sources[uriOf('a')] = const FakeSource(
      duration: _long,
      bufferedAhead: Duration(seconds: 2),
    );
    await r.start(['a', 'b']);
    await r.play(_s(4));
    await r.h.controller.seek(_s(60));
    await r.settle();
    // The engine stays buffering while only the clock moves.
    await r.wait(_s(30));
    await r.play(_s(4));
    await r.h.controller.next();
    await r.settle();

    // 4 s, then one engine step spent buffering, then the rest.
    final listened = (await r.plays()).single.listenedMs;
    expect(listened, inInclusiveRange(7800, 8000));
  });

  test('seek forward: 3 s, seek, 3 s gives one play of 6000', () async {
    await r.start(['a', 'b']);
    await r.play(_s(3));
    await r.h.controller.seek(_s(120));
    await r.settle();
    await r.play(_s(3));
    await r.h.controller.next();
    await r.settle();

    final plays = await r.plays();
    expect(plays, hasLength(1));
    expect(plays.single.listenedMs, 6000);
  });

  test('seek back and re-hear: the total exceeds the track length and is '
      'reported as is', () async {
    r.h.fake.sources[uriOf('a')] = const FakeSource(
      duration: Duration(seconds: 10),
    );
    await r.start(['a', 'b']);
    await r.play(_s(8));
    await r.h.controller.seek(Duration.zero);
    await r.settle();
    await r.play(_s(8));
    await r.h.controller.next();
    await r.settle();

    expect((await r.plays()).single.listenedMs, 16000);
  });

  test(
    '4.9 s then next enqueues nothing and leaves no play_sessions row',
    () async {
      await r.start(['a', 'b']);
      await r.play(_s(4.9));
      await r.h.controller.pause();
      await r.settle();
      expect(await r.rows(), hasLength(1));
      await r.h.controller.next();
      await r.settle();

      expect(await r.plays(), isEmpty);
      expect(await r.rows(), isEmpty);
    },
  );

  test('exactly 5.0 s is enqueued', () async {
    await r.start(['a', 'b']);
    await r.play(_s(5));
    await r.h.controller.next();
    await r.settle();

    expect((await r.plays()).single.listenedMs, 5000);
    expect(await r.rows(), isEmpty);
  });

  test('20 s then skip reports listenedMs 20000', () async {
    await r.start(['a', 'b']);
    await r.play(_s(20));
    await r.h.controller.next();
    await r.settle();

    expect((await r.plays()).single.listenedMs, 20000);
  });

  test('a long pause does not end the play', () async {
    await r.start(['a', 'b']);
    await r.play(_s(6));
    await r.h.controller.pause();
    await r.settle();
    await r.wait(const Duration(hours: 5));

    expect(await r.plays(), isEmpty);
    await r.h.controller.play();
    await r.settle();
    await r.play(_s(2));
    await r.h.controller.next();
    await r.settle();
    expect((await r.plays()).single.listenedMs, 8000);
  });

  group('each end cause enqueues once', () {
    Future<void> expectOnePlay(String playbackId) async {
      final plays = await r.plays();
      expect(plays.map((p) => p.playbackId), [playbackId]);
      expect(plays.single.listenedMs, 6000);
      expect(await r.rows(), isEmpty);
    }

    test('next', () async {
      await r.start(['a', 'b']);
      await r.play(_s(6));
      await r.h.controller.next();
      await r.settle();
      await expectOnePlay('pb-a');
    });

    test('previous that moves the cursor', () async {
      await r.start(['a', 'b'], startIndex: 1);
      await r.play(_s(6));
      await r.h.controller.pause();
      await r.h.controller.seek(_s(2));
      await r.settle();
      await r.h.controller.previous();
      await r.settle();
      expect(r.h.controller.snapshot.current?.queueItemId, 'a');
      await expectOnePlay('pb-b');
    });

    test('jump', () async {
      await r.start(['a', 'b', 'c']);
      await r.play(_s(6));
      await r.h.controller.jumpTo('c');
      await r.settle();
      await expectOnePlay('pb-a');
    });

    test('replace queue', () async {
      await r.start(['a', 'b']);
      await r.play(_s(6));
      await r.h.controller.playItems(trackItems(['c', 'd']));
      await r.settle();
      await expectOnePlay('pb-a');
    });

    test('clear', () async {
      await r.start(['a', 'b']);
      await r.play(_s(6));
      await r.h.controller.clear();
      await r.settle();
      await expectOnePlay('pb-a');
    });

    test('stop', () async {
      await r.start(['a', 'b']);
      await r.play(_s(6));
      await r.h.controller.stop();
      await r.settle();
      await expectOnePlay('pb-a');
    });

    test('natural end', () async {
      r.h.fake.sources[uriOf('b')] = const FakeSource(
        duration: Duration(seconds: 6),
      );
      await r.start(['a', 'b'], startIndex: 1);
      await r.play(_s(8));
      expect(r.h.controller.snapshot.playing, isFalse);
      await expectOnePlay('pb-b');
    });

    test('natural end into a preloaded next entry', () async {
      r.h.fake.sources[uriOf('a')] = const FakeSource(
        duration: Duration(seconds: 6),
      );
      await r.start(['a', 'b']);
      await r.play(_s(6));
      await r.play(_s(1));
      expect(r.h.controller.snapshot.current?.queueItemId, 'b');
      await expectOnePlay('pb-a');
    });
  });

  test('previous that only seeks to zero does not end the play', () async {
    await r.start(['a', 'b', 'c'], startIndex: 1);
    await r.play(_s(6));
    await r.h.controller.previous();
    await r.settle();
    expect(r.h.controller.snapshot.current?.queueItemId, 'b');
    await r.play(_s(2));
    expect(await r.plays(), isEmpty);

    await r.h.controller.next();
    await r.settle();
    expect((await r.plays()).single.listenedMs, 8000);
  });

  test('repeat-one: two consecutive full listens give two plays with '
      'different sessionIds', () async {
    r.h.fake.sources[uriOf('a')] = const FakeSource(
      duration: Duration(seconds: 10),
    );
    await r.start(['a', 'b']);
    await r.h.controller.setRepeat(RepeatMode.one);
    await r.settle();
    await r.play(_s(10));
    await r.play(_s(10));
    await r.h.controller.stop();
    await r.settle();

    final plays = await r.plays();
    expect(plays, hasLength(2));
    expect(plays.map((p) => p.playbackId), ['pb-a', 'pb-a']);
    expect(plays[0].sessionId, isNot(plays[1].sessionId));
    for (final play in plays) {
      expect(play.listenedMs, inInclusiveRange(9600, 10000));
    }
    expect(plays[1].playedAt.isAfter(plays[0].playedAt), isTrue);
  });

  test('the same track queued twice gives two plays', () async {
    for (final id in const ['x1', 'x2']) {
      r.h.fake.sources[uriOf(id)] = const FakeSource(
        duration: Duration(seconds: 10),
      );
    }
    await r.h.controller.playItems([
      trackItem('x1', playbackId: 'pb-same'),
      trackItem('x2', playbackId: 'pb-same'),
    ]);
    await r.settle();
    await r.play(_s(10));
    await r.play(_s(8));
    await r.h.controller.stop();
    await r.settle();

    final plays = await r.plays();
    expect(plays.map((p) => p.playbackId), ['pb-same', 'pb-same']);
    expect(plays[0].sessionId, isNot(plays[1].sessionId));
  });

  test('one report per play: after the end, further state changes enqueue '
      'nothing more', () async {
    await r.start(['a', 'b']);
    await r.play(_s(6));
    await r.h.controller.stop();
    await r.settle();
    await r.h.controller.pause();
    await r.h.controller.seek(_s(3));
    await r.h.controller.setRepeat(RepeatMode.all);
    await r.settle();
    r.lifecycle.add(AppLifecycleState.paused);
    await r.settle();

    expect(await r.plays(), hasLength(1));
    expect(await r.rows(), isEmpty);
  });

  test('an EpisodeQueueItem produces no play', () async {
    const episode = QueueItem.episode(
      queueItemId: 'ep',
      episode: Episode(
        id: 'e1',
        podcastId: 'pod1',
        title: 'Episode',
        durationSec: 600,
      ),
      podcast: Podcast(id: 'pod1', title: 'Podcast'),
    );
    r.h.fake.sources[uriOf('ep')] = const FakeSource(duration: _long);
    await r.h.controller.playItems(const [episode]);
    await r.settle();
    await r.play(_s(20));
    await r.h.controller.pause();
    await r.settle();
    await r.h.controller.stop();
    await r.settle();

    expect(await r.plays(), isEmpty);
    expect(await r.rows(), isEmpty);
  });

  group('persistence', () {
    test(
      'the row is written at 10 s and 20 s with the running total',
      () async {
        await r.start(['a', 'b']);
        await r.play(_s(9.6));
        expect(await r.rows(), isEmpty);

        await r.play(_s(1));
        final first = (await r.rows()).single;
        expect(first.listenedMs, inInclusiveRange(10000, 10600));
        expect(first.playbackId, 'pb-a');
        expect(first.queueItemId, 'a');

        await r.play(_s(10));
        expect(
          (await r.rows()).single.listenedMs,
          inInclusiveRange(20000, 20600),
        );
        expect((await r.rows()).single.sessionId, first.sessionId);
      },
    );

    test('the row is written on pause', () async {
      await r.start(['a', 'b']);
      await r.play(_s(3));
      await r.h.controller.pause();
      await r.settle();

      expect((await r.rows()).single.listenedMs, 3000);
    });

    test('the row is written when the app goes to the background', () async {
      await r.start(['a', 'b']);
      await r.play(_s(4));
      r.lifecycle.add(AppLifecycleState.paused);
      await r.settle();

      expect((await r.rows()).single.listenedMs, 4000);
    });
  });

  group('recovery', () {
    test('after a kill the row persisted at 20 s is enqueued once with the '
        'original playedAt', () async {
      final start = r.clock.now();
      await r.start(['a', 'b']);
      await r.play(_s(25));
      final stored = (await r.rows()).single;
      expect(stored.listenedMs, inInclusiveRange(20000, 20600));

      // The process dies: nothing more is written. A new reporter opens
      // the same database.
      final second = PlayReporter(
        _NoPlayback(),
        PlaySessionStore(r.db),
        r.outbox,
        r.clock,
        const Stream.empty(),
      );
      await second.flush();

      final plays = await r.plays();
      expect(plays.single.listenedMs, stored.listenedMs);
      expect(plays.single.playedAt, start);
      expect(plays.single.sessionId, stored.sessionId);
      expect(await r.rows(), isEmpty);
      await second.dispose();
    });

    test('a recovered row of 3 s is deleted unsent', () async {
      await r.start(['a', 'b']);
      await r.play(_s(3));
      await r.h.controller.pause();
      await r.settle();
      expect(await r.rows(), hasLength(1));

      final second = PlayReporter(
        _NoPlayback(),
        PlaySessionStore(r.db),
        r.outbox,
        r.clock,
        const Stream.empty(),
      );
      await second.flush();

      expect(await r.plays(), isEmpty);
      expect(await r.rows(), isEmpty);
      await second.dispose();
    });

    test('recovery run twice enqueues once', () async {
      await r.start(['a', 'b']);
      await r.play(_s(12));
      expect(await r.rows(), hasLength(1));

      for (var i = 0; i < 2; i++) {
        final next = PlayReporter(
          _NoPlayback(),
          PlaySessionStore(r.db),
          r.outbox,
          r.clock,
          const Stream.empty(),
        );
        await next.flush();
        await next.dispose();
      }

      expect(await r.plays(), hasLength(1));
    });

    test('dispose mid-play then recovery enqueues once', () async {
      await r.start(['a', 'b']);
      await r.play(_s(7));
      await r.reporter.dispose();
      expect((await r.rows()).single.listenedMs, 7000);
      expect(await r.plays(), isEmpty);

      r.reporter = r.newReporter();
      await r.reporter.flush();

      final plays = await r.plays();
      expect(plays.single.listenedMs, 7000);
      expect(await r.rows(), isEmpty);

      // The entry the new reporter sees still playing starts a new play.
      await r.play(_s(6));
      await r.h.controller.next();
      await r.settle();
      expect(await r.plays(), hasLength(2));
    });
  });

  test('the payload carries the playbackId and the TrackMeta; offline, the '
      'op stays pending with its real playedAt', () async {
    final start = r.clock.now();
    await r.start(['a', 'b']);
    await r.play(_s(6));
    await r.h.controller.next();
    await r.settle();
    await r.wait(const Duration(hours: 3));

    final entry = (await r.store.pending()).single;
    final op = entry.op as PlayOp;
    expect(op.playbackId, 'pb-a');
    final meta = (trackItem('a') as TrackQueueItem).track.meta;
    expect(op.metadata, meta.toJson());
    expect(TrackMeta.fromJson(op.metadata), meta);
    expect(op.playedAt, start);
    expect(op.entityKey, 'play:${op.sessionId}');
    expect(entry.createdAt, start.add(_s(6)));
  });

  test('minListened is five seconds', () {
    expect(PlayReporter.minListened, const Duration(seconds: 5));
  });
}

/// A source with no playback at all, as a fresh process sees before the
/// first command.
final class _NoPlayback implements ListeningSource {
  @override
  Stream<ListeningState> get states => const Stream.empty();

  @override
  Stream<String> get entryEnded => const Stream.empty();
}
