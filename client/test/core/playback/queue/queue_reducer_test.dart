// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/shared/domain/domain.dart';

import 'queue_test_items.dart';

const _reducer = QueueReducer();

/// A queue of entries [ids] with the cursor at [cursor].
QueueState _queue(
  List<String> ids, {
  int cursor = 0,
  RepeatMode repeat = RepeatMode.off,
  int revision = 3,
}) => QueueState(
  items: trackItems(ids),
  cursor: cursor,
  repeat: repeat,
  context: testContext,
  revision: revision,
);

/// Asserts [transition] left [before] untouched: the identical instance and
/// no effect.
void _expectNoOp(QueueTransition transition, QueueState before) {
  expect(transition.state, same(before));
  expect(transition.effect, QueueEffect.none);
}

void main() {
  group('ReplaceAll', () {
    test('ReplaceAll sets items, context and cursor at startIndex with effect loadCurrent', () {
      const context = QueueContext(kind: QueueContextKind.playlist, id: 'p');
      final before = _queue(['x'], repeat: RepeatMode.all);

      final t = _reducer.reduce(
        before,
        ReplaceAll(
          trackItems(['a', 'b', 'c']),
          startIndex: 1,
          context: context,
        ),
      );

      expect(idsOf(t.state.items), ['a', 'b', 'c']);
      expect(t.state.context, context);
      expect(t.state.cursor, 1);
      expect(t.state.current?.queueItemId, 'b');
      expect(t.state.repeat, RepeatMode.all);
      expect(t.state.shuffleOrder, isNull);
      expect(t.effect, QueueEffect.loadCurrent);
    });

    test('ReplaceAll with an empty list equals Clear', () {
      final before = _queue(['a', 'b'], repeat: RepeatMode.one);

      final replaced = _reducer.reduce(before, const ReplaceAll([]));
      final cleared = _reducer.reduce(before, const Clear());

      expect(replaced.state, cleared.state);
      expect(replaced.effect, cleared.effect);
    });

    test('ReplaceAll clamps an out-of-range startIndex', () {
      final items = trackItems(['a', 'b', 'c']);

      final high = _reducer.reduce(
        QueueState.empty(),
        ReplaceAll(items, startIndex: 9),
      );
      final low = _reducer.reduce(
        QueueState.empty(),
        ReplaceAll(items, startIndex: -4),
      );

      expect(high.state.cursor, 2);
      expect(low.state.cursor, 0);
    });
  });

  group('PlayNext', () {
    test('PlayNext inserts after the current item in the given order', () {
      final before = _queue(['a', 'b', 'c'], cursor: 1);

      final t = _reducer.reduce(before, PlayNext(trackItems(['x', 'y'])));

      expect(idsOf(t.state.items), ['a', 'b', 'x', 'y', 'c']);
      expect(t.state.current?.queueItemId, 'b');
      expect(t.state.upNext?.queueItemId, 'x');
      expect(t.state.context, testContext);
      expect(t.effect, QueueEffect.none);
    });

    test('PlayNext on an empty queue starts a queue at index 0', () {
      final t = _reducer.reduce(
        QueueState.empty(),
        PlayNext(trackItems(['x', 'y'])),
      );

      expect(idsOf(t.state.items), ['x', 'y']);
      expect(t.state.cursor, 0);
      expect(t.state.context, isNull);
      expect(t.effect, QueueEffect.loadCurrent);
    });
  });

  group('Append', () {
    test('Append adds at the end and leaves current unchanged', () {
      final before = _queue(['a', 'b', 'c'], cursor: 1);

      final t = _reducer.reduce(before, Append(trackItems(['x'])));

      expect(idsOf(t.state.items), ['a', 'b', 'c', 'x']);
      expect(t.state.current?.queueItemId, 'b');
      expect(t.effect, QueueEffect.none);
    });

    test('Append on an empty queue starts a queue at index 0', () {
      final t = _reducer.reduce(QueueState.empty(), Append(trackItems(['x'])));

      expect(idsOf(t.state.items), ['x']);
      expect(t.state.cursor, 0);
      expect(t.effect, QueueEffect.loadCurrent);
    });
  });

  group('identity', () {
    test('Adding a duplicate queueItemId throws ArgumentError', () {
      final before = _queue(['a', 'b']);

      expect(
        () => _reducer.reduce(before, Append(trackItems(['b']))),
        throwsArgumentError,
      );
      expect(
        () => _reducer.reduce(before, PlayNext(trackItems(['a']))),
        throwsArgumentError,
      );
      expect(
        () => _reducer.reduce(before, Append(trackItems(['x', 'x']))),
        throwsArgumentError,
      );
      expect(
        () => _reducer.reduce(before, ReplaceAll(trackItems(['y', 'y']))),
        throwsArgumentError,
      );
    });

    test('The same track may appear twice under different queueItemIds', () {
      final t = _reducer.reduce(
        QueueState.empty(),
        ReplaceAll([
          trackItem('a', playbackId: 'pb-same'),
          trackItem('b', playbackId: 'pb-same'),
        ]),
      );
      final removed = _reducer.reduce(t.state, const RemoveAt('b'));

      expect(idsOf(t.state.items), ['a', 'b']);
      expect(idsOf(removed.state.items), ['a']);
    });
  });

  group('RemoveAt', () {
    test('RemoveAt before the cursor keeps the same current entry', () {
      final before = _queue(['a', 'b', 'c'], cursor: 2);

      final t = _reducer.reduce(before, const RemoveAt('a'));

      expect(idsOf(t.state.items), ['b', 'c']);
      expect(t.state.cursor, 1);
      expect(t.state.current?.queueItemId, 'c');
      expect(t.effect, QueueEffect.none);
    });

    test('RemoveAt after the cursor leaves the cursor unchanged', () {
      final before = _queue(['a', 'b', 'c'], cursor: 1);

      final t = _reducer.reduce(before, const RemoveAt('c'));

      expect(idsOf(t.state.items), ['a', 'b']);
      expect(t.state.cursor, 1);
      expect(t.state.current?.queueItemId, 'b');
      expect(t.effect, QueueEffect.none);
    });

    test('RemoveAt current advances to the next entry with loadCurrent', () {
      final before = _queue(['a', 'b', 'c'], cursor: 1);

      final t = _reducer.reduce(before, const RemoveAt('b'));

      expect(idsOf(t.state.items), ['a', 'c']);
      expect(t.state.current?.queueItemId, 'c');
      expect(t.effect, QueueEffect.loadCurrent);
    });

    test(
      'RemoveAt current when last moves to the new last entry with stop',
      () {
        final before = _queue(['a', 'b', 'c'], cursor: 2);

        final t = _reducer.reduce(before, const RemoveAt('c'));

        expect(idsOf(t.state.items), ['a', 'b']);
        expect(t.state.current?.queueItemId, 'b');
        expect(t.effect, QueueEffect.stop);
      },
    );

    test('RemoveAt the only entry equals Clear', () {
      final before = _queue(['a'], repeat: RepeatMode.all);

      final removed = _reducer.reduce(before, const RemoveAt('a'));
      final cleared = _reducer.reduce(before, const Clear());

      expect(removed.state, cleared.state);
      expect(removed.effect, cleared.effect);
    });
  });

  group('Move', () {
    test('Move reorders and current stays the same entry (moving current, across current, behind current)', () {
      final before = _queue(['a', 'b', 'c', 'd'], cursor: 1);

      final movingCurrent = _reducer.reduce(before, const Move('b', 3));
      expect(idsOf(movingCurrent.state.items), ['a', 'c', 'd', 'b']);
      expect(movingCurrent.state.current?.queueItemId, 'b');
      expect(movingCurrent.effect, QueueEffect.none);

      final acrossCurrent = _reducer.reduce(before, const Move('d', 0));
      expect(idsOf(acrossCurrent.state.items), ['d', 'a', 'b', 'c']);
      expect(acrossCurrent.state.current?.queueItemId, 'b');
      expect(acrossCurrent.effect, QueueEffect.none);

      final behindCurrent = _reducer.reduce(before, const Move('a', 2));
      expect(idsOf(behindCurrent.state.items), ['b', 'c', 'a', 'd']);
      expect(behindCurrent.state.current?.queueItemId, 'b');
      expect(behindCurrent.effect, QueueEffect.none);

      final afterCurrent = _reducer.reduce(before, const Move('d', 2));
      expect(idsOf(afterCurrent.state.items), ['a', 'b', 'd', 'c']);
      expect(afterCurrent.state.current?.queueItemId, 'b');
    });

    test('Move clamps toPlayIndex', () {
      final before = _queue(['a', 'b', 'c'], cursor: 1);

      final high = _reducer.reduce(before, const Move('a', 99));
      final low = _reducer.reduce(before, const Move('c', -2));

      expect(idsOf(high.state.items), ['b', 'c', 'a']);
      expect(high.state.current?.queueItemId, 'b');
      expect(idsOf(low.state.items), ['c', 'a', 'b']);
      expect(low.state.current?.queueItemId, 'b');
    });

    test('Move to the index the entry already holds is a no-op', () {
      final before = _queue(['a', 'b', 'c'], cursor: 1);

      _expectNoOp(_reducer.reduce(before, const Move('c', 2)), before);
    });
  });

  group('JumpTo', () {
    test('JumpTo another entry gives loadCurrent; JumpTo the current entry gives restartCurrent', () {
      final before = _queue(['a', 'b', 'c']);

      final other = _reducer.reduce(before, const JumpTo('c'));
      expect(other.state.cursor, 2);
      expect(other.state.current?.queueItemId, 'c');
      expect(other.effect, QueueEffect.loadCurrent);

      final same = _reducer.reduce(before, const JumpTo('a'));
      expect(same.state, before);
      expect(same.effect, QueueEffect.restartCurrent);
    });
  });

  group('Next', () {
    test('Next advances; Next at the end is a no-op that returns the identical instance', () {
      final before = _queue(['a', 'b']);

      final advanced = _reducer.reduce(before, const Next());
      expect(advanced.state.cursor, 1);
      expect(advanced.state.current?.queueItemId, 'b');
      expect(advanced.effect, QueueEffect.loadCurrent);

      _expectNoOp(
        _reducer.reduce(advanced.state, const Next()),
        advanced.state,
      );
    });

    test('Next on an empty queue is a no-op', () {
      final before = QueueState.empty();

      _expectNoOp(_reducer.reduce(before, const Next()), before);
    });
  });

  group('Clear', () {
    test('Clear empties the queue with effect stop', () {
      final before = _queue(['a', 'b'], cursor: 1, repeat: RepeatMode.all);

      final t = _reducer.reduce(before, const Clear());

      expect(t.state.items, isEmpty);
      expect(t.state.cursor, isNull);
      expect(t.state.context, isNull);
      expect(t.state.shuffleOrder, isNull);
      expect(t.state.repeat, RepeatMode.all);
      expect(t.state.revision, before.revision + 1);
      expect(t.effect, QueueEffect.stop);
    });

    test('Clear on an empty queue keeps the identical instance', () {
      final before = QueueState.empty();

      final t = _reducer.reduce(before, const Clear());

      expect(t.state, same(before));
      expect(t.effect, QueueEffect.stop);
    });
  });

  group('ItemFinished', () {
    test('ItemFinished advances with loadCurrent', () {
      final before = _queue(['a', 'b', 'c']);

      final t = _reducer.reduce(before, const ItemFinished('a'));

      expect(t.state.cursor, 1);
      expect(t.state.current?.queueItemId, 'b');
      expect(t.effect, QueueEffect.loadCurrent);
    });

    test('ItemFinished on the last item keeps the cursor and gives stop', () {
      final before = _queue(['a', 'b'], cursor: 1);

      final t = _reducer.reduce(before, const ItemFinished('b'));

      expect(t.state, same(before));
      expect(t.state.cursor, 1);
      expect(t.effect, QueueEffect.stop);
    });

    test('ItemFinished for an entry that is not current is a no-op', () {
      final before = _queue(['a', 'b', 'c'], cursor: 1);

      _expectNoOp(_reducer.reduce(before, const ItemFinished('a')), before);
      _expectNoOp(_reducer.reduce(before, const ItemFinished('zz')), before);
    });
  });

  test('Unknown queueItemId is a no-op for RemoveAt, Move and JumpTo', () {
    final before = _queue(['a', 'b']);

    _expectNoOp(_reducer.reduce(before, const RemoveAt('zz')), before);
    _expectNoOp(_reducer.reduce(before, const Move('zz', 0)), before);
    _expectNoOp(_reducer.reduce(before, const JumpTo('zz')), before);
  });

  test('revision increases by one per change and never on a no-op', () {
    var state = QueueState.empty();
    final revisions = <int>[];

    for (final command in <QueueCommand>[
      ReplaceAll(trackItems(['a', 'b'])),
      Append(trackItems(['c'])),
      PlayNext(trackItems(['d'])),
      const Next(),
      const Move('a', 3),
      const RemoveAt('c'),
      const JumpTo('b'),
      const ItemFinished('zz'),
      const RemoveAt('zz'),
      const Clear(),
      const Clear(),
    ]) {
      state = _reducer.reduce(state, command).state;
      revisions.add(state.revision);
    }

    expect(revisions, [1, 2, 3, 4, 5, 6, 7, 7, 7, 8, 8]);
  });
}
