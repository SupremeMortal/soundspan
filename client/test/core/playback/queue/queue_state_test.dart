// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';

import 'queue_test_items.dart';

void main() {
  group('QueueState', () {
    test('empty has no items, no cursor, repeat off and revision zero', () {
      final state = QueueState.empty();

      expect(state.items, isEmpty);
      expect(state.shuffleOrder, isNull);
      expect(state.cursor, isNull);
      expect(state.repeat, RepeatMode.off);
      expect(state.context, isNull);
      expect(state.revision, 0);
      expect(state.current, isNull);
      expect(state.upNext, isNull);
      expect(state.isShuffled, isFalse);
      expect(state.playOrder, isEmpty);
    });

    test('playOrder is the identity without a shuffle order', () {
      final state = QueueState(items: trackItems(['a', 'b', 'c']), cursor: 0);

      expect(state.playOrder, [0, 1, 2]);
      expect(state.isShuffled, isFalse);
    });

    test('playOrder is the shuffle order when one is set', () {
      final state = QueueState(
        items: trackItems(['a', 'b', 'c']),
        shuffleOrder: const [2, 0, 1],
        cursor: 0,
      );

      expect(state.playOrder, [2, 0, 1]);
      expect(state.isShuffled, isTrue);
      expect(state.current?.queueItemId, 'c');
    });

    test('current is the item at the cursor', () {
      final state = QueueState(items: trackItems(['a', 'b', 'c']), cursor: 1);

      expect(state.current?.queueItemId, 'b');
    });

    test(
      'upNext is the following item and null at the end and for an empty queue',
      () {
        final items = trackItems(['a', 'b', 'c']);

        expect(QueueState(items: items, cursor: 0).upNext?.queueItemId, 'b');
        expect(QueueState(items: items, cursor: 1).upNext?.queueItemId, 'c');
        expect(QueueState(items: items, cursor: 2).upNext, isNull);
        expect(QueueState.empty().upNext, isNull);
      },
    );
  });
}
