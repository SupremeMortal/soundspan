// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/realtime/socket_client.dart';

import '../../core/playback/queue/queue_test_items.dart';
import 'listen_together_rig.dart';

/// A rig in a playing group over a, b, c whose applied version is 5.
Future<ListenTogetherRig> _atVersion5() async {
  final rig = ListenTogetherRig();
  await rig.join();
  await rig.push(
    (s) => s.states.add(
      groupState(
        syncState: 'playing',
        serverTime: rig.serverNow,
        stateVersion: 5,
      ),
    ),
  );
  rig.h.calls.clear();
  return rig;
}

PlaybackDelta _pause(ListenTogetherRig rig, int version) => PlaybackDelta(
  isPlaying: false,
  positionMs: 0,
  serverTime: rig.serverNow,
  stateVersion: version,
  currentIndex: 0,
);

void main() {
  test('a lower stateVersion is ignored for state, playback-delta, '
      'queue-delta and play-at', () async {
    final rig = await _atVersion5();

    await rig.push((s) => s.playbackDeltas.add(_pause(rig, 4)));
    await rig.push(
      (s) => s.queueDeltas.add(
        QueueDelta(
          queue: groupEntries(['x']),
          currentIndex: 0,
          stateVersion: 4,
        ),
      ),
    );
    await rig.push(
      (s) => s.playAts.add(
        PlayAtEvent(
          positionMs: 7000,
          serverTime: rig.serverNow,
          stateVersion: 4,
        ),
      ),
    );
    await rig.push(
      (s) => s.states.add(
        groupState(ids: ['y'], serverTime: rig.serverNow, stateVersion: 4),
      ),
    );

    expect(rig.h.calls, isEmpty);
    expect(rig.h.controller.snapshot.playing, isTrue);
    expect(idsOf(rig.h.controller.snapshot.queue.items), [
      groupItem(0, 'a'),
      groupItem(1, 'b'),
      groupItem(2, 'c'),
    ]);
  });

  test('an equal stateVersion is applied', () async {
    final rig = await _atVersion5();

    await rig.push((s) => s.playbackDeltas.add(_pause(rig, 5)));

    expect(rig.h.calls, ['pause']);
    expect(rig.h.controller.snapshot.playing, isFalse);
  });

  test('group:waiting carries no version and is always applied', () async {
    final rig = await _atVersion5();

    await rig.push((s) => s.waits.add(const WaitingEvent(currentIndex: 1)));

    expect(rig.h.controller.snapshot.current?.queueItemId, groupItem(1, 'b'));
  });

  test('the first state after a rejoin is applied even when lower, and '
      'resets the watermark', () async {
    final rig = await _atVersion5();

    await rig.push((s) => s.reconnects.add(null));
    await rig.push(
      (s) => s.states.add(
        groupState(ids: ['y'], serverTime: rig.serverNow, stateVersion: 2),
      ),
    );

    expect(idsOf(rig.h.controller.snapshot.queue.items), [groupItem(0, 'y')]);

    await rig.push((s) => s.playbackDeltas.add(_pause(rig, 3)));
    expect(rig.h.controller.snapshot.playing, isFalse);
  });

  test('the first state after a join is applied even when lower than the '
      'last group', () async {
    final rig = await _atVersion5();
    await rig.controller.leave();
    await rig.join();

    await rig.push(
      (s) => s.states.add(groupState(ids: ['z'], serverTime: rig.serverNow)),
    );

    expect(idsOf(rig.h.controller.snapshot.queue.items), [groupItem(0, 'z')]);
  });
}
