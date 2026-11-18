// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';

import 'queue_test_items.dart';

QueueReducer _seeded([int seed = 42]) => QueueReducer(random: Random(seed));

/// Asserts [order] is a permutation of `0..length - 1`.
void _expectPermutation(List<int>? order, int length) {
  expect(order, isNotNull);
  expect([...order!]..sort(), List<int>.generate(length, (i) => i));
}

void main() {
  final ids = numberedIds(20);

  group('Shuffle on', () {
    test('Shuffle on keeps the current entry at the cursor', () {
      final before = queueOf(ids, cursor: 7);

      final t = _seeded().reduce(before, const SetShuffle(true));

      expect(t.state.cursor, 7);
      expect(t.state.current?.queueItemId, 'p7');
      expect(t.effect, QueueEffect.none);
      expect(t.state.revision, before.revision + 1);
      _expectPermutation(t.state.shuffleOrder, 20);
    });

    test(
      'Shuffle on keeps already-played entries in order behind the cursor',
      () {
        final t = _seeded().reduce(
          queueOf(ids, cursor: 7),
          const SetShuffle(true),
        );

        expect(t.state.shuffleOrder!.sublist(0, 8), [0, 1, 2, 3, 4, 5, 6, 7]);
      },
    );

    test('Shuffle on permutes only the entries after the cursor and is deterministic for a seed', () {
      final before = queueOf(ids, cursor: 7);

      final first = _seeded().reduce(before, const SetShuffle(true));
      final second = _seeded().reduce(before, const SetShuffle(true));

      final after = first.state.shuffleOrder!.sublist(8);
      expect([...after]..sort(), List<int>.generate(12, (i) => i + 8));
      expect(after, isNot(List<int>.generate(12, (i) => i + 8)));
      expect(second.state.shuffleOrder, first.state.shuffleOrder);
      expect(idsOf(first.state.items), ids);
    });

    test('Shuffle on an empty queue sets an empty order', () {
      final t = _seeded().reduce(QueueState.empty(), const SetShuffle(true));

      expect(t.state.shuffleOrder, isEmpty);
      expect(t.state.cursor, isNull);
      expect(t.effect, QueueEffect.none);
    });
  });

  group('Shuffle off', () {
    test("Shuffle off drops the order and points the cursor at the current entry's canonical index", () {
      final before = queueOf(
        ['a', 'b', 'c', 'd'],
        cursor: 1,
        shuffleOrder: [2, 0, 3, 1],
      );

      final t = _seeded().reduce(before, const SetShuffle(false));

      expect(t.state.shuffleOrder, isNull);
      expect(t.state.cursor, 0);
      expect(t.state.current?.queueItemId, 'a');
      expect(t.effect, QueueEffect.none);
    });

    test('SetShuffle with the current value is a no-op', () {
      final plain = queueOf(['a', 'b']);
      final shuffled = queueOf(['a', 'b'], shuffleOrder: [1, 0]);

      final off = _seeded().reduce(plain, const SetShuffle(false));
      final on = _seeded().reduce(shuffled, const SetShuffle(true));

      expect(off.state, same(plain));
      expect(off.effect, QueueEffect.none);
      expect(on.state, same(shuffled));
      expect(on.effect, QueueEffect.none);
    });
  });

  group('Commands while shuffled', () {
    test('ReplaceAll while shuffled starts at startIndex with all other entries shuffled', () {
      final before = queueOf(['x'], shuffleOrder: [0]);

      final t = _seeded().reduce(
        before,
        ReplaceAll(trackItems(ids), startIndex: 5),
      );

      expect(t.state.cursor, 0);
      expect(t.state.current?.queueItemId, 'p5');
      expect(t.state.shuffleOrder!.first, 5);
      _expectPermutation(t.state.shuffleOrder, 20);
      expect(t.effect, QueueEffect.loadCurrent);
    });

    test('PlayNext while shuffled is next in play order and directly after current in canonical order', () {
      final before = queueOf(
        ['a', 'b', 'c', 'd'],
        cursor: 1,
        shuffleOrder: [2, 0, 3, 1],
      );

      final t = _seeded().reduce(before, PlayNext(trackItems(['n1', 'n2'])));

      expect(idsOf(t.state.items), ['a', 'n1', 'n2', 'b', 'c', 'd']);
      expect(playIdsOf(t.state), ['c', 'a', 'n1', 'n2', 'd', 'b']);
      expect(t.state.current?.queueItemId, 'a');
      expect(t.state.upNext?.queueItemId, 'n1');
      expect(t.effect, QueueEffect.none);
    });

    test('Append while shuffled lands at the canonical end and after the cursor in play order', () {
      final before = queueOf(
        ['a', 'b', 'c', 'd'],
        cursor: 1,
        shuffleOrder: [2, 0, 3, 1],
      );

      final t = _seeded().reduce(before, Append(trackItems(['n1', 'n2'])));

      expect(idsOf(t.state.items), ['a', 'b', 'c', 'd', 'n1', 'n2']);
      _expectPermutation(t.state.shuffleOrder, 6);
      final play = playIdsOf(t.state);
      expect(play.sublist(0, 2), ['c', 'a']);
      expect(play.indexOf('n1'), greaterThan(1));
      expect(play.indexOf('n2'), greaterThan(1));
      expect(t.state.current?.queueItemId, 'a');
      expect(t.effect, QueueEffect.none);
    });

    test('RemoveAt while shuffled renumbers the permutation', () {
      final before = queueOf(
        ['a', 'b', 'c', 'd'],
        cursor: 2,
        shuffleOrder: [2, 0, 3, 1],
      );

      final t = _seeded().reduce(before, const RemoveAt('a'));

      expect(idsOf(t.state.items), ['b', 'c', 'd']);
      expect(t.state.shuffleOrder, [1, 2, 0]);
      expect(playIdsOf(t.state), ['c', 'd', 'b']);
      expect(t.state.current?.queueItemId, 'd');
      expect(t.effect, QueueEffect.none);
    });

    test(
      'Move while shuffled changes the play order and not the canonical order',
      () {
        final before = queueOf(
          ['a', 'b', 'c', 'd'],
          cursor: 1,
          shuffleOrder: [2, 0, 3, 1],
        );

        final t = _seeded().reduce(before, const Move('b', 0));

        expect(idsOf(t.state.items), ['a', 'b', 'c', 'd']);
        expect(playIdsOf(t.state), ['b', 'c', 'a', 'd']);
        expect(t.state.current?.queueItemId, 'a');
        expect(t.state.cursor, 2);
        expect(t.effect, QueueEffect.none);
      },
    );

    test('JumpTo while shuffled addresses the play order', () {
      final before = queueOf(['a', 'b', 'c', 'd'], shuffleOrder: [2, 0, 3, 1]);

      final t = _seeded().reduce(before, const JumpTo('d'));

      expect(t.state.cursor, 2);
      expect(t.state.current?.queueItemId, 'd');
      expect(t.state.shuffleOrder, [2, 0, 3, 1]);
      expect(t.effect, QueueEffect.loadCurrent);
    });

    test('Clear while shuffled leaves shuffle on', () {
      final before = queueOf(['a', 'b'], shuffleOrder: [1, 0]);

      final t = _seeded().reduce(before, const Clear());

      expect(t.state.items, isEmpty);
      expect(t.state.shuffleOrder, isEmpty);
      expect(t.state.isShuffled, isTrue);
      expect(t.state.cursor, isNull);
      expect(t.effect, QueueEffect.stop);
    });
  });
}
