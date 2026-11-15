// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';

import 'queue_test_items.dart';

final _reducer = QueueReducer(random: Random(42));

void main() {
  test('maxItems is 5,000', () {
    expect(QueueReducer.maxItems, 5000);
  });

  test('ReplaceAll with 5,001 items keeps 5,000 and reports dropped 1', () {
    final ids = numberedIds(5001);

    final t = _reducer.reduce(
      QueueState.empty(),
      ReplaceAll(trackItems(ids), startIndex: 10),
    );

    expect(t.state.items, hasLength(5000));
    expect(idsOf(t.state.items), ids.sublist(0, 5000));
    expect(t.state.current?.queueItemId, 'p10');
    expect(t.dropped, 1);
    expect(t.effect, QueueEffect.loadCurrent);
  });

  test('ReplaceAll with startIndex 6,000 of 7,000 keeps a window that contains the start item', () {
    final ids = numberedIds(7000);

    final t = _reducer.reduce(
      QueueState.empty(),
      ReplaceAll(trackItems(ids), startIndex: 6000),
    );

    expect(t.state.items, hasLength(5000));
    expect(idsOf(t.state.items), ids.sublist(1001, 6001));
    expect(t.state.cursor, 4999);
    expect(t.state.current?.queueItemId, 'p6000');
    expect(t.dropped, 2000);
  });

  test('ReplaceAll over the limit while shuffled starts at the start item', () {
    final ids = numberedIds(5003);

    final t = _reducer.reduce(
      queueOf(['x'], shuffleOrder: [0]),
      ReplaceAll(trackItems(ids), startIndex: 5002),
    );

    expect(t.state.items, hasLength(5000));
    expect(t.state.cursor, 0);
    expect(t.state.current?.queueItemId, 'p5002');
    expect(t.state.shuffleOrder, hasLength(5000));
    expect(t.dropped, 3);
  });

  test(
    'Append that would exceed 5,000 takes what fits and reports the rest',
    () {
      final before = queueOf(numberedIds(4998));

      final t = _reducer.reduce(
        before,
        Append(trackItems(['n1', 'n2', 'n3', 'n4'])),
      );

      expect(t.state.items, hasLength(5000));
      expect(idsOf(t.state.items).sublist(4998), ['n1', 'n2']);
      expect(t.dropped, 2);
      expect(t.effect, QueueEffect.none);
    },
  );

  test('PlayNext that would exceed 5,000 takes the leading items that fit', () {
    final before = queueOf(numberedIds(4999));

    final t = _reducer.reduce(before, PlayNext(trackItems(['n1', 'n2'])));

    expect(t.state.items, hasLength(5000));
    expect(t.state.upNext?.queueItemId, 'n1');
    expect(t.dropped, 1);
  });

  test('Append to a full queue is a no-op with dropped equal to the count', () {
    final before = queueOf(numberedIds(5000));

    final append = _reducer.reduce(before, Append(trackItems(['n1', 'n2'])));
    final playNext = _reducer.reduce(before, PlayNext(trackItems(['n1'])));

    expect(append.state, same(before));
    expect(append.effect, QueueEffect.none);
    expect(append.dropped, 2);
    expect(playNext.state, same(before));
    expect(playNext.dropped, 1);
  });

  test('A command within the limit reports dropped 0', () {
    final t = _reducer.reduce(
      QueueState.empty(),
      ReplaceAll(trackItems(['a', 'b'])),
    );

    expect(t.dropped, 0);
  });
}
