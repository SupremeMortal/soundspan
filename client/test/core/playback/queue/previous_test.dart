// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';

import 'queue_test_items.dart';

const _reducer = QueueReducer();

void main() {
  test('Previous above 3 s restarts the current entry', () {
    final before = queueOf(['a', 'b', 'c'], cursor: 1);

    final t = _reducer.reduce(
      before,
      const Previous(Duration(seconds: 3, milliseconds: 1)),
    );

    expect(t.state, same(before));
    expect(t.effect, QueueEffect.restartCurrent);
  });

  test('Previous at exactly 3 s and below moves back', () {
    final before = queueOf(['a', 'b', 'c'], cursor: 2);

    final atThreshold = _reducer.reduce(
      before,
      const Previous(QueueReducer.previousRestartThreshold),
    );
    final below = _reducer.reduce(before, const Previous(Duration.zero));

    expect(QueueReducer.previousRestartThreshold, const Duration(seconds: 3));
    expect(atThreshold.state.current?.queueItemId, 'b');
    expect(atThreshold.state.revision, before.revision + 1);
    expect(atThreshold.effect, QueueEffect.loadCurrent);
    expect(below.state.current?.queueItemId, 'b');
    expect(below.effect, QueueEffect.loadCurrent);
  });

  test('Previous moves back in play order while shuffled', () {
    final before = queueOf(['a', 'b', 'c'], cursor: 1, shuffleOrder: [2, 0, 1]);

    final t = _reducer.reduce(before, const Previous(Duration.zero));

    expect(t.state.current?.queueItemId, 'c');
    expect(t.effect, QueueEffect.loadCurrent);
  });

  test('Previous at the first entry restarts with repeat off and wraps with repeat all', () {
    final off = queueOf(['a', 'b', 'c']);
    final one = queueOf(['a', 'b', 'c'], repeat: RepeatMode.one);
    final all = queueOf(['a', 'b', 'c'], repeat: RepeatMode.all);

    final fromOff = _reducer.reduce(off, const Previous(Duration.zero));
    final fromOne = _reducer.reduce(one, const Previous(Duration.zero));
    final fromAll = _reducer.reduce(all, const Previous(Duration.zero));

    expect(fromOff.state, same(off));
    expect(fromOff.effect, QueueEffect.restartCurrent);
    expect(fromOne.state, same(one));
    expect(fromOne.effect, QueueEffect.restartCurrent);
    expect(fromAll.state.cursor, 2);
    expect(fromAll.state.current?.queueItemId, 'c');
    expect(fromAll.effect, QueueEffect.loadCurrent);
  });

  test('Previous on an empty queue is a no-op', () {
    final before = QueueState.empty();

    final t = _reducer.reduce(before, const Previous(Duration.zero));

    expect(t.state, same(before));
    expect(t.effect, QueueEffect.none);
  });
}
