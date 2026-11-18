// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';

import 'queue_test_items.dart';

final _reducer = QueueReducer(random: Random(7));

void main() {
  test('InsertAt in the middle puts the items at that play index', () {
    final before = queueOf(['a', 'b', 'c', 'd'], cursor: 1);

    final t = _reducer.reduce(before, InsertAt(trackItems(['n1', 'n2']), 3));

    expect(idsOf(t.state.items), ['a', 'b', 'c', 'n1', 'n2', 'd']);
    expect(t.state.cursor, 1);
    expect(t.state.current?.queueItemId, 'b');
    expect(t.state.revision, before.revision + 1);
    expect(t.effect, QueueEffect.none);
    expect(t.dropped, 0);
  });

  test('InsertAt the end appends', () {
    final before = queueOf(['a', 'b', 'c']);

    final t = _reducer.reduce(before, InsertAt(trackItems(['n1']), 3));

    expect(idsOf(t.state.items), ['a', 'b', 'c', 'n1']);
    expect(t.state.current?.queueItemId, 'a');
  });

  test('InsertAt directly after the cursor makes the items up next', () {
    final before = queueOf(['a', 'b', 'c'], cursor: 1);

    final t = _reducer.reduce(before, InsertAt(trackItems(['n1', 'n2']), 2));

    expect(idsOf(t.state.items), ['a', 'b', 'n1', 'n2', 'c']);
    expect(t.state.cursor, 1);
    expect(t.state.upNext?.queueItemId, 'n1');
  });

  test('InsertAt before the cursor keeps the current item', () {
    final before = queueOf(['a', 'b', 'c'], cursor: 2);

    final t = _reducer.reduce(before, InsertAt(trackItems(['n1']), 0));

    expect(idsOf(t.state.items), ['n1', 'a', 'b', 'c']);
    expect(t.state.cursor, 3);
    expect(t.state.current?.queueItemId, 'c');
  });

  test('InsertAt clamps the index into the play order', () {
    final before = queueOf(['a', 'b']);

    final t = _reducer.reduce(before, InsertAt(trackItems(['n1']), 99));

    expect(idsOf(t.state.items), ['a', 'b', 'n1']);
  });

  test('InsertAt while shuffled appends canonically and places the items at the play position', () {
    final before = queueOf(
      ['a', 'b', 'c', 'd'],
      cursor: 1,
      shuffleOrder: [2, 0, 3, 1],
    );

    final t = _reducer.reduce(before, InsertAt(trackItems(['n1', 'n2']), 3));

    expect(idsOf(t.state.items), ['a', 'b', 'c', 'd', 'n1', 'n2']);
    expect(playIdsOf(t.state), ['c', 'a', 'd', 'n1', 'n2', 'b']);
    expect(t.state.cursor, 1);
    expect(t.state.current?.queueItemId, 'a');
    expect(t.effect, QueueEffect.none);
  });

  test(
    'InsertAt while shuffled directly after the cursor is next in play order',
    () {
      final before = queueOf(
        ['a', 'b', 'c', 'd'],
        cursor: 1,
        shuffleOrder: [2, 0, 3, 1],
      );

      final t = _reducer.reduce(before, InsertAt(trackItems(['n1']), 2));

      expect(playIdsOf(t.state), ['c', 'a', 'n1', 'd', 'b']);
      expect(t.state.upNext?.queueItemId, 'n1');
    },
  );

  test('InsertAt on an empty queue starts a queue with the items', () {
    final t = _reducer.reduce(
      QueueState.empty(),
      InsertAt(trackItems(['n1', 'n2']), 5),
    );

    expect(idsOf(t.state.items), ['n1', 'n2']);
    expect(t.state.current?.queueItemId, 'n1');
    expect(t.effect, QueueEffect.loadCurrent);
  });

  test('InsertAt with nothing to insert changes nothing', () {
    final before = queueOf(['a', 'b']);

    final t = _reducer.reduce(before, const InsertAt([], 1));

    expect(t.state, same(before));
  });

  test('InsertAt over 5,000 inserts what fits and reports the rest', () {
    final before = queueOf(numberedIds(4999));

    final t = _reducer.reduce(
      before,
      InsertAt(trackItems(['n1', 'n2', 'n3']), 1),
    );

    expect(t.state.items, hasLength(5000));
    expect(t.state.items[1].queueItemId, 'n1');
    expect(t.state.current?.queueItemId, 'p0');
    expect(t.dropped, 2);
  });

  test('InsertAt of an already queued id throws', () {
    expect(
      () =>
          _reducer.reduce(queueOf(['a', 'b']), InsertAt(trackItems(['a']), 1)),
      throwsArgumentError,
    );
  });
}
