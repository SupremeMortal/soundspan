// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/shared/domain/domain.dart';

import 'queue_test_items.dart';

/// Generates random commands over a queue, with fresh `queueItemId`s for
/// every added entry.
class _CommandGenerator {
  new(this._random);

  final Random _random;
  var _nextId = 0;

  List<QueueItem> _fresh(int max) => [
    for (var i = _random.nextInt(max + 1); i > 0; i--)
      trackItem('q${_nextId++}'),
  ];

  /// An entry id of [state], or one that is not queued.
  String _someId(QueueState state) =>
      state.items.isEmpty || _random.nextInt(8) == 0
      ? 'missing'
      : state.items[_random.nextInt(state.items.length)].queueItemId;

  QueueCommand next(QueueState state) => switch (_random.nextInt(12)) {
    0 => ReplaceAll(_fresh(12), startIndex: _random.nextInt(14) - 1),
    1 => PlayNext(_fresh(4)),
    2 => Append(_fresh(4)),
    3 => RemoveAt(_someId(state)),
    4 => Move(_someId(state), _random.nextInt(16) - 1),
    5 => JumpTo(_someId(state)),
    6 => const Next(),
    7 => Previous(Duration(seconds: _random.nextInt(7))),
    8 => SetShuffle(_random.nextBool()),
    9 => SetRepeat(RepeatMode.values[_random.nextInt(3)]),
    10 => _random.nextInt(4) == 0 ? const Clear() : const Next(),
    _ => ItemFinished(
      state.current == null || _random.nextInt(6) == 0
          ? 'missing'
          : state.current!.queueItemId,
    ),
  };
}

void _expectInvariants(QueueState state, String where) {
  final order = state.shuffleOrder;
  if (order != null) {
    expect(
      [...order]..sort(),
      List<int>.generate(state.items.length, (i) => i),
      reason: '$where: shuffleOrder is a permutation',
    );
  }
  expect(
    state.cursor == null,
    state.items.isEmpty,
    reason: '$where: cursor is null exactly when the queue is empty',
  );
  final cursor = state.cursor;
  if (cursor != null) {
    expect(
      cursor >= 0 && cursor < state.items.length,
      isTrue,
      reason: '$where: cursor in range',
    );
  }
  expect(
    idsOf(state.items).toSet(),
    hasLength(state.items.length),
    reason: '$where: queueItemIds are unique',
  );
  expect(
    state.items.length,
    lessThanOrEqualTo(QueueReducer.maxItems),
    reason: '$where: within the size limit',
  );
}

void main() {
  test('Invariants hold over 1,000 seeded random command sequences', () {
    for (var seed = 0; seed < 1000; seed++) {
      final random = Random(seed);
      final reducer = QueueReducer(random: Random(seed + 7919));
      final generator = _CommandGenerator(random);
      var state = QueueState.empty();
      for (var step = 0; step < 40; step++) {
        final command = generator.next(state);
        final t = reducer.reduce(state, command);
        _expectInvariants(t.state, 'seed $seed step $step ($command)');
        expect(
          t.state.revision,
          identical(t.state, state) ? state.revision : state.revision + 1,
          reason: 'seed $seed step $step: revision',
        );
        state = t.state;
      }
    }
  });

  test('Invariants hold for sequences that reach the size limit', () {
    final random = Random(42);
    final reducer = QueueReducer(random: Random(43));
    var nextId = 0;
    List<QueueItem> fresh(int count) => [
      for (var i = 0; i < count; i++) trackItem('b${nextId++}'),
    ];
    var state = reducer
        .reduce(QueueState.empty(), ReplaceAll(fresh(4900)))
        .state;
    var largest = state.items.length;
    for (var step = 0; step < 30; step++) {
      final command = switch (random.nextInt(4)) {
        0 => Append(fresh(random.nextInt(60))),
        1 => PlayNext(fresh(random.nextInt(60))),
        2 => SetShuffle(random.nextBool()),
        _ => RemoveAt(
          state.items[random.nextInt(state.items.length)].queueItemId,
        ),
      };
      state = reducer.reduce(state, command).state;
      _expectInvariants(state, 'step $step');
      largest = max(largest, state.items.length);
    }
    expect(largest, QueueReducer.maxItems);
  });
}
