// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';

import 'queue_test_items.dart';

final _reducer = QueueReducer(random: Random(42));

void main() {
  group('upNext', () {
    test('upNext wraps with repeat all; equals current with repeat one; is null at the end with repeat off', () {
      final ids = ['a', 'b', 'c'];

      expect(
        queueOf(ids, cursor: 2, repeat: RepeatMode.all).upNext?.queueItemId,
        'a',
      );
      expect(
        queueOf(
          ids,
          cursor: 2,
          shuffleOrder: [1, 2, 0],
          repeat: RepeatMode.all,
        ).upNext?.queueItemId,
        'b',
      );
      expect(
        queueOf(ids, cursor: 1, repeat: RepeatMode.one).upNext?.queueItemId,
        'b',
      );
      expect(queueOf(ids, cursor: 2).upNext, isNull);
      expect(queueOf(ids, cursor: 1).upNext?.queueItemId, 'c');
      expect(queueOf(['a'], repeat: RepeatMode.all).upNext?.queueItemId, 'a');
      expect(
        QueueState.empty().copyWith(repeat: RepeatMode.all).upNext,
        isNull,
      );
    });
  });

  group('Repeat all', () {
    test('Next at the end wraps with repeat all', () {
      final before = queueOf(
        ['a', 'b', 'c'],
        cursor: 2,
        shuffleOrder: [2, 0, 1],
        repeat: RepeatMode.all,
      );

      final t = _reducer.reduce(before, const Next());

      expect(t.state.cursor, 0);
      expect(t.state.current?.queueItemId, 'c');
      expect(t.state.shuffleOrder, [2, 0, 1]);
      expect(t.effect, QueueEffect.loadCurrent);
    });

    test('ItemFinished at the end wraps with repeat all', () {
      final before = queueOf(
        ['a', 'b', 'c'],
        cursor: 2,
        repeat: RepeatMode.all,
      );

      final t = _reducer.reduce(before, const ItemFinished('c'));

      expect(t.state.cursor, 0);
      expect(t.state.current?.queueItemId, 'a');
      expect(t.effect, QueueEffect.loadCurrent);
    });

    test('ItemFinished with one entry and repeat all restarts it', () {
      final before = queueOf(['a'], repeat: RepeatMode.all);

      final t = _reducer.reduce(before, const ItemFinished('a'));

      expect(t.state, same(before));
      expect(t.effect, QueueEffect.restartCurrent);
      expect(before.upNext?.queueItemId, 'a');
    });

    test(
      'RemoveAt the current, last entry wraps to the first with repeat all',
      () {
        final before = queueOf(
          ['a', 'b', 'c'],
          cursor: 2,
          repeat: RepeatMode.all,
        );

        final t = _reducer.reduce(before, const RemoveAt('c'));

        expect(idsOf(t.state.items), ['a', 'b']);
        expect(t.state.cursor, 0);
        expect(t.state.current?.queueItemId, 'a');
        expect(t.effect, QueueEffect.loadCurrent);
      },
    );
  });

  group('Repeat one', () {
    test('ItemFinished with repeat one restarts the current entry', () {
      final before = queueOf(
        ['a', 'b', 'c'],
        cursor: 1,
        repeat: RepeatMode.one,
      );

      final t = _reducer.reduce(before, const ItemFinished('b'));

      expect(t.state, same(before));
      expect(t.effect, QueueEffect.restartCurrent);
    });

    test('Next with repeat one advances to the following entry', () {
      final before = queueOf(
        ['a', 'b', 'c'],
        cursor: 1,
        repeat: RepeatMode.one,
      );

      final t = _reducer.reduce(before, const Next());

      expect(t.state.current?.queueItemId, 'c');
      expect(t.effect, QueueEffect.loadCurrent);

      final atEnd = _reducer.reduce(t.state, const Next());
      expect(atEnd.state, same(t.state));
      expect(atEnd.effect, QueueEffect.none);
    });
  });

  group('SetRepeat', () {
    test(
      'SetRepeat sets the mode with no effect; the same mode is a no-op',
      () {
        final before = queueOf(['a', 'b']);

        final t = _reducer.reduce(before, const SetRepeat(RepeatMode.all));
        final same_ = _reducer.reduce(before, const SetRepeat(RepeatMode.off));

        expect(t.state.repeat, RepeatMode.all);
        expect(t.state.revision, before.revision + 1);
        expect(t.effect, QueueEffect.none);
        expect(same_.state, same(before));
        expect(same_.effect, QueueEffect.none);
      },
    );
  });
}
