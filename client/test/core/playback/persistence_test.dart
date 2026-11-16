// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/persistence.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/storage/state/queue_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/domain.dart';

import 'controller/controller_harness.dart';
import 'queue/queue_test_items.dart';

/// A [Clock] that reads the virtual time of [_async].
class _FakeAsyncClock implements Clock {
  new(this._async);

  final FakeAsync _async;

  @override
  DateTime now() => _async.getClock(DateTime.utc(2025)).now().toUtc();
}

/// Counts the transactions and the writes that reach the database.
class _Counter extends QueryInterceptor {
  int transactions = 0;
  int writes = 0;

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    transactions++;
    return super.beginTransaction(parent);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    writes++;
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    writes++;
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    writes++;
    return super.runDelete(executor, statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    writes++;
    return super.runBatched(executor, statements);
  }
}

/// An in-memory `state.db` shared by the controllers of one test.
class _Store {
  final _Counter counter = _Counter();
  late final StateDatabase db = StateDatabase(
    NativeDatabase.memory().interceptWith(counter),
  );
  late final QueueDao dao = QueueDao(db);
}

class _Driver implements RemoteDriver {
  @override
  Future<void> onCommand(PlaybackCommand command) async {}
}

/// The ids every rig can play, each five minutes long.
const _playable = ['a', 'b', 'c', 'd', 'e', 'f', 'x1', 'x2', 'ep', 'p0'];

/// A controller persisting to [store], driven in fake time.
class _Rig {
  new(this.async, this.store) {
    persistence = QueuePersistence(dao: store.dao, clock: clock);
    h = ControllerHarness(clock: clock, persistence: persistence);
    for (final id in _playable) {
      h.fake.sources[uriOf(id)] = const FakeSource(
        duration: Duration(minutes: 5),
      );
    }
  }

  final FakeAsync async;
  final _Store store;
  late final Clock clock = _FakeAsyncClock(async);
  late final QueuePersistence persistence;
  late final ControllerHarness h;

  PlaybackController get controller => h.controller;

  /// Settles [future] in fake time without letting time pass.
  T settle<T>(Future<T> future) {
    late T value;
    var done = false;
    unawaited(
      future.then((v) {
        value = v;
        done = true;
      }),
    );
    async.flushMicrotasks();
    expect(done, isTrue, reason: 'the future did not complete');
    return value;
  }

  /// Lets [d] of playback pass on the engine and in fake time.
  void play(Duration d) {
    var left = d;
    const step = FakeEngine.positionInterval;
    while (left > Duration.zero) {
      final move = left < step ? left : step;
      h.fake.advance(move);
      async.elapse(move);
      left -= move;
    }
  }

  /// The stored queue now.
  StoredQueue? stored() => settle(store.dao.read());

  /// The ids of the stored rows, in canonical order.
  List<String> storedIds() => [
    for (final row in stored()?.items ?? const <QueueSnapshotData>[])
      row.queueItemId,
  ];

  /// The stored position, in milliseconds.
  int? storedPositionMs() => stored()?.meta.positionMs;
}

/// Runs [body] in fake time with a fresh store.
void _inFakeTime(void Function(FakeAsync async, _Store store) body) {
  fakeAsync((async) {
    final store = _Store();
    body(async, store);
    async.flushMicrotasks();
    unawaited(store.db.close());
    async.flushMicrotasks();
  });
}

/// An episode entry with id [queueItemId].
QueueItem _episode(String queueItemId) => QueueItem.episode(
  queueItemId: queueItemId,
  episode: const Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'Episode',
    durationSec: 600,
  ),
  podcast: const Podcast(id: 'pod1', title: 'Podcast'),
);

/// A rig on [store] whose controller restored and played [ids], with every
/// write of that start done.
_Rig _playing(FakeAsync async, _Store store, List<String> ids) {
  final rig = _Rig(async, store);
  rig.settle(rig.controller.restore());
  rig.settle(rig.controller.playItems(trackItems(ids), context: testContext));
  async.elapse(const Duration(seconds: 1));
  return rig;
}

void main() {
  test('a queue edit is written 500 ms after the last change and not '
      'before', () {
    _inFakeTime((async, store) {
      final rig = _playing(async, store, ['a', 'b']);
      expect(rig.storedIds(), ['a', 'b']);

      rig.settle(rig.controller.append(trackItems(['c'])));
      async.elapse(const Duration(milliseconds: 499));
      expect(rig.storedIds(), ['a', 'b']);

      async.elapse(const Duration(milliseconds: 1));
      expect(rig.storedIds(), ['a', 'b', 'c']);
    });
  });

  test('several edits inside 500 ms cause one transaction', () {
    _inFakeTime((async, store) {
      final rig = _playing(async, store, ['a', 'b']);
      final before = store.counter.transactions;

      rig.settle(rig.controller.append(trackItems(['c'])));
      async.elapse(const Duration(milliseconds: 200));
      rig.settle(rig.controller.append(trackItems(['d'])));
      async.elapse(const Duration(milliseconds: 200));
      rig.settle(rig.controller.removeAt('b'));
      async.elapse(const Duration(seconds: 2));

      expect(store.counter.transactions - before, 1);
      expect(rig.storedIds(), ['a', 'c', 'd']);
    });
  });

  test('position is written every 5 s while playing and not while '
      'paused', () {
    _inFakeTime((async, store) {
      final rig = _playing(async, store, ['a', 'b']);
      rig.settle(rig.controller.pause());
      rig.settle(rig.controller.play());
      final start = rig.storedPositionMs()!;

      rig.play(const Duration(milliseconds: 4800));
      expect(rig.storedPositionMs(), start);
      rig.play(const Duration(milliseconds: 400));
      expect(rig.storedPositionMs(), inInclusiveRange(4500, 5200));
      rig.play(const Duration(seconds: 5));
      expect(rig.storedPositionMs(), inInclusiveRange(9500, 10200));

      rig.settle(rig.controller.pause());
      async.elapse(const Duration(seconds: 1));
      final writes = store.counter.writes;
      async.elapse(const Duration(seconds: 30));
      expect(store.counter.writes, writes);
    });
  });

  test('pause writes the position immediately', () {
    _inFakeTime((async, store) {
      final rig = _playing(async, store, ['a', 'b'])
        ..play(const Duration(seconds: 3));
      expect(rig.storedPositionMs(), lessThan(3000));

      rig.settle(rig.controller.pause());

      expect(rig.storedPositionMs(), inInclusiveRange(2800, 3200));
    });
  });

  test('going to the background flushes a pending structural write at '
      'once', () {
    _inFakeTime((async, store) {
      final rig = _playing(async, store, ['a', 'b']);
      rig.settle(rig.controller.append(trackItems(['c'])));
      expect(rig.storedIds(), ['a', 'b']);

      rig.persistence.handleLifecycle(AppLifecycleState.paused);
      async.flushMicrotasks();

      expect(rig.storedIds(), ['a', 'b', 'c']);
    });
  });

  test('Clear removes the stored queue', () {
    _inFakeTime((async, store) {
      final rig = _playing(async, store, ['a', 'b']);
      expect(rig.stored(), isNotNull);

      rig.settle(rig.controller.clear());
      async.elapse(const Duration(seconds: 1));

      expect(rig.stored(), isNull);
      expect(
        rig.settle(store.db.select(store.db.queueSnapshot).get()),
        isEmpty,
      );
    });
  });

  test('kill and restore rebuilds the same queue, paused at the stored '
      'position', () {
    _inFakeTime((async, store) {
      final first = _playing(async, store, ['a', 'b', 'c', 'd', 'e']);
      first.settle(first.controller.setShuffle(true));
      first.settle(first.controller.setRepeat(RepeatMode.all));
      first.settle(first.controller.seek(Duration.zero));
      first.play(const Duration(seconds: 42));
      async.elapse(const Duration(seconds: 6));
      final queue = first.controller.snapshot.queue;

      final second = _Rig(async, store);
      second.settle(second.controller.restore());

      final restored = second.controller.snapshot;
      expect(restored.queue.items, queue.items);
      expect(restored.queue.shuffleOrder, queue.shuffleOrder);
      expect(restored.queue.shuffleOrder, isNotNull);
      expect(restored.queue.cursor, queue.cursor);
      expect(restored.queue.repeat, RepeatMode.all);
      expect(restored.queue.context, testContext);
      expect(restored.queue.revision, 0);
      expect(restored.current, queue.current);
      expect(restored.playing, isFalse);
      expect(restored.status.name, 'idle');
      expect(restored.position.inMilliseconds, inInclusiveRange(41800, 42200));
    });
  });

  test('restore makes no engine call and no resolver call', () {
    _inFakeTime((async, store) {
      _playing(async, store, ['a', 'b']).play(const Duration(seconds: 6));

      final second = _Rig(async, store);
      second.settle(second.controller.restore());
      async.elapse(const Duration(seconds: 10));

      expect(second.controller.snapshot.current?.queueItemId, 'a');
      expect(second.h.calls, isEmpty);
      expect(second.h.resolver.resolved, isEmpty);
      expect(second.h.infoRequests, isEmpty);
    });
  });

  test('play after restore loads the current item at the stored position '
      'with autoPlay', () {
    _inFakeTime((async, store) {
      final first = _playing(async, store, ['a', 'b']);
      first.settle(first.controller.seek(Duration.zero));
      first.play(const Duration(seconds: 7));
      first.settle(first.controller.pause());

      final second = _Rig(async, store);
      second.settle(second.controller.restore());
      final position = second.controller.snapshot.position;
      second.settle(second.controller.play());

      expect(position.inMilliseconds, inInclusiveRange(6800, 7200));
      expect(second.h.calls.first, 'load(a, autoPlay: true, at: $position)');
    });
  });

  test('the same track queued twice restores as two entries with their own '
      'ids', () {
    _inFakeTime((async, store) {
      final first = _Rig(async, store);
      first.settle(first.controller.restore());
      first.settle(
        first.controller.playItems([
          trackItem('x1', playbackId: 'same'),
          trackItem('x2', playbackId: 'same'),
        ]),
      );
      async.elapse(const Duration(seconds: 1));

      final second = _Rig(async, store);
      second.settle(second.controller.restore());

      final items = second.controller.snapshot.queue.items;
      expect(idsOf(items), ['x1', 'x2']);
      expect(items[0], trackItem('x1', playbackId: 'same'));
      expect(items[1], trackItem('x2', playbackId: 'same'));
    });
  });

  test('an episode item round-trips', () {
    _inFakeTime((async, store) {
      final first = _Rig(async, store);
      first.settle(first.controller.restore());
      first.settle(
        first.controller.playItems([_episode('ep'), trackItem('a')]),
      );
      async.elapse(const Duration(seconds: 1));

      final second = _Rig(async, store);
      second.settle(second.controller.restore());

      expect(second.controller.snapshot.queue.items, [
        _episode('ep'),
        trackItem('a'),
      ]);
      expect(second.controller.snapshot.current, _episode('ep'));
    });
  });

  test('a corrupt item row discards the snapshot and starts empty', () {
    _inFakeTime((async, store) {
      _playing(async, store, ['a', 'b']);
      final db = store.db;
      _Rig(async, store).settle(
        (db.update(db.queueSnapshot)..where((t) => t.queueItemId.equals('b')))
            .write(const QueueSnapshotCompanion(itemJson: Value('{not json'))),
      );

      final second = _Rig(async, store);
      second.settle(second.controller.restore());

      expect(second.controller.snapshot.queue.items, isEmpty);
      expect(second.controller.snapshot.current, isNull);
      expect(second.stored(), isNull);
      expect(second.settle(db.select(db.queueSnapshot).get()), isEmpty);
    });
  });

  test('a stored current id missing from the items discards the '
      'snapshot', () {
    _inFakeTime((async, store) {
      _playing(async, store, ['a', 'b']);
      final db = store.db;
      _Rig(async, store).settle(
        db
            .update(db.queueMeta)
            .write(const QueueMetaCompanion(currentQueueItemId: Value('zz'))),
      );

      final second = _Rig(async, store);
      second.settle(second.controller.restore());

      expect(second.controller.snapshot.queue.items, isEmpty);
      expect(second.stored(), isNull);
    });
  });

  test('nothing is written while a RemoteDriver is attached', () {
    _inFakeTime((async, store) {
      final rig = _playing(async, store, ['a', 'b']);
      final writes = store.counter.writes;

      rig.controller.attachRemoteDriver(_Driver());
      rig.play(const Duration(seconds: 12));
      rig.settle(rig.controller.pause());
      rig.persistence.handleLifecycle(AppLifecycleState.paused);
      async.elapse(const Duration(seconds: 6));

      expect(store.counter.writes, writes);
    });
  });

  test('a 5,000-item queue is written in one transaction and restored in '
      'order', () {
    _inFakeTime((async, store) {
      final ids = numberedIds(5000);
      final first = _Rig(async, store);
      first.settle(first.controller.restore());
      final before = store.counter.transactions;

      first.settle(first.controller.playItems(trackItems(ids)));
      async.elapse(const Duration(seconds: 1));

      expect(store.counter.transactions - before, 1);
      final second = _Rig(async, store);
      second.settle(second.controller.restore());
      expect(idsOf(second.controller.snapshot.queue.items), ids);
    });
  });
}
