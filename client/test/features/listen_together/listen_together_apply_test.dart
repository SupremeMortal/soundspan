// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';

import '../../core/playback/queue/queue_test_items.dart';
import 'listen_together_rig.dart';

/// A rig in the group, its state applied: [syncState] over a, b, c at
/// index 0, position zero, version 1.
Future<ListenTogetherRig> _inGroup({String syncState = 'playing'}) async {
  final rig = ListenTogetherRig();
  await rig.playLocal();
  await rig.join();
  await rig.push(
    (s) => s.states.add(
      groupState(syncState: syncState, serverTime: rig.serverNow),
    ),
  );
  rig.h.calls.clear();
  return rig;
}

void main() {
  group('group:state', () {
    test('group:state replaces the queue, loads paused at the expected '
        'position, then plays when syncState is playing', () async {
      final rig = ListenTogetherRig();
      await rig.playLocal();
      await rig.join();
      rig.h.calls.clear();

      await rig.push(
        (s) => s.states.add(
          groupState(
            ids: ['x', 'y'],
            currentIndex: 1,
            syncState: 'playing',
            positionMs: 2000,
            serverTime: rig.serverNow - 500,
            stateVersion: 3,
          ),
        ),
      );

      final snapshot = rig.h.controller.snapshot;
      expect(idsOf(snapshot.queue.items), [
        groupItem(0, 'x'),
        groupItem(1, 'y'),
      ]);
      expect(snapshot.current?.queueItemId, groupItem(1, 'y'));
      expect(rig.h.calls.where((c) => c.startsWith('load') || c == 'play'), [
        loadPaused(1, 'y', 2500),
        'play',
      ]);
      expect(snapshot.playing, isTrue);
    });

    for (final syncState in ['paused', 'idle']) {
      test('group:state with syncState $syncState loads paused at the '
          'position and stays paused', () async {
        final rig = ListenTogetherRig();
        await rig.join();

        await rig.push(
          (s) => s.states.add(
            groupState(
              syncState: syncState,
              positionMs: 4000,
              serverTime: rig.serverNow - 500,
            ),
          ),
        );

        expect(rig.h.calls, contains(loadPaused(0, 'a', 4000)));
        expect(rig.h.calls, isNot(contains('play')));
        expect(rig.h.controller.snapshot.playing, isFalse);
      });
    }

    test('group:state updates members, host and canControl', () async {
      final rig = ListenTogetherRig();
      await rig.join();
      expect(
        (rig.controller.current as ListenTogetherActive).canControl,
        isFalse,
      );

      await rig.push(
        (s) => s.states.add(
          groupState(
            serverTime: rig.serverNow,
            hostUserId: 'me',
            memberIds: ['me', 'host', 'other'],
          ),
        ),
      );

      final active = rig.controller.current as ListenTogetherActive;
      expect(active.canControl, isTrue);
      expect(active.group.hostUserId, 'me');
      expect(active.group.members.map((m) => m.userId), [
        'me',
        'host',
        'other',
      ]);
      expect(rig.h.controller.snapshot.remoteCanControl, isTrue);
    });

    test('group:state with an empty queue stops playback', () async {
      final rig = await _inGroup();

      await rig.push(
        (s) => s.states.add(
          groupState(ids: [], serverTime: rig.serverNow, stateVersion: 2),
        ),
      );

      expect(rig.h.controller.snapshot.queue.items, isEmpty);
      expect(rig.h.controller.snapshot.playing, isFalse);
    });

    test('member events update the member list and leave playback '
        'alone', () async {
      final rig = await _inGroup();

      await rig.push(
        (s) => s.memberEvents
          ..add(
            const MemberEvent.joined(
              groupId: 'g1',
              userId: 'new',
              username: 'New',
            ),
          )
          ..add(
            const MemberEvent.left(
              groupId: 'g1',
              userId: 'host',
              username: 'Host',
              newHostUserId: 'me',
            ),
          ),
      );

      final active = rig.controller.current as ListenTogetherActive;
      expect(active.group.members.map((m) => m.userId), ['me', 'new']);
      expect(active.group.hostUserId, 'me');
      expect(active.canControl, isTrue);
      expect(rig.h.calls, isEmpty);
    });
  });

  group('group:queue-delta', () {
    test('group:queue-delta with the same current item does not reload and '
        'updates the preloaded next', () async {
      final rig = await _inGroup();

      await rig.push(
        (s) => s.queueDeltas.add(
          QueueDelta(
            queue: groupEntries(['a', 'c', 'b']),
            currentIndex: 0,
            stateVersion: 2,
          ),
        ),
      );

      expect(rig.h.calls.where((c) => c.startsWith('load')), isEmpty);
      expect(rig.h.calls, contains('setNext(${groupItem(1, 'c')})'));
      expect(rig.h.controller.snapshot.playing, isTrue);
      expect(idsOf(rig.h.controller.snapshot.queue.items), [
        groupItem(0, 'a'),
        groupItem(1, 'c'),
        groupItem(2, 'b'),
      ]);
    });

    test('group:queue-delta with a different current item loads it', () async {
      final rig = await _inGroup();

      await rig.push(
        (s) => s.queueDeltas.add(
          QueueDelta(
            queue: groupEntries(['x', 'a']),
            currentIndex: 0,
            stateVersion: 2,
          ),
        ),
      );

      expect(rig.h.calls.where((c) => c.startsWith('load')), [
        'load(${groupItem(0, 'x')}, autoPlay: true, at: 0:00:00.000000)',
      ]);
      expect(rig.h.controller.snapshot.current?.queueItemId, groupItem(0, 'x'));
    });
  });

  group('group:waiting', () {
    test('group:waiting loads paused at zero and emits ready when the '
        'engine is ready', () async {
      final rig = await _inGroup();

      await rig.push((s) => s.waits.add(const WaitingEvent(currentIndex: 1)));

      expect(rig.h.calls, contains(loadPaused(1, 'b', 0)));
      expect(rig.h.controller.snapshot.current?.queueItemId, groupItem(1, 'b'));
      expect(rig.h.controller.snapshot.playing, isFalse);
      expect(rig.socket.commands, ['ready']);
    });

    test('group:waiting emits playback-failed when the load fails', () async {
      final rig = await _inGroup();
      rig.h.resolver.unplayable.add(groupItem(2, 'c'));

      await rig.push((s) => s.waits.add(const WaitingEvent(currentIndex: 2)));

      expect(rig.socket.commands, ['playback-failed:2']);
    });

    test(
      'group:state with syncState waiting behaves as group:waiting',
      () async {
        final rig = ListenTogetherRig();
        await rig.join();

        await rig.push(
          (s) => s.states.add(
            groupState(
              syncState: 'waiting',
              currentIndex: 1,
              positionMs: 3000,
              serverTime: rig.serverNow,
            ),
          ),
        );

        expect(rig.h.calls, contains(loadPaused(1, 'b', 0)));
        expect(rig.socket.commands, ['ready']);
      },
    );
  });

  group('group:play-at', () {
    test('group:play-at in the future starts exactly at serverTime − '
        'offset', () async {
      final rig = await _inGroup(syncState: 'paused');

      await rig.push(
        (s) => s.playAts.add(
          PlayAtEvent(
            positionMs: 1000,
            serverTime: rig.serverNow + 2000,
            stateVersion: 2,
          ),
        ),
      );
      expect(rig.h.calls, ['seek(0:00:01.000000)']);

      await rig.time.advance(const Duration(milliseconds: 1999));
      expect(rig.h.calls, isNot(contains('play')));

      await rig.time.advance(const Duration(milliseconds: 1));
      expect(rig.h.calls, ['seek(0:00:01.000000)', 'play']);
      expect(rig.h.controller.snapshot.playing, isTrue);
    });

    test('group:play-at in the past seeks to the expected position and '
        'plays now', () async {
      final rig = await _inGroup(syncState: 'paused');

      await rig.push(
        (s) => s.playAts.add(
          PlayAtEvent(
            positionMs: 1000,
            serverTime: rig.serverNow - 700,
            stateVersion: 2,
          ),
        ),
      );

      expect(rig.h.calls, ['seek(0:00:01.700000)', 'play']);
    });

    test('a later pause cancels the scheduled start', () async {
      final rig = await _inGroup(syncState: 'paused');

      await rig.push(
        (s) => s.playAts.add(
          PlayAtEvent(
            positionMs: 0,
            serverTime: rig.serverNow + 2000,
            stateVersion: 2,
          ),
        ),
      );
      await rig.push(
        (s) => s.playbackDeltas.add(
          PlaybackDelta(
            isPlaying: false,
            positionMs: 0,
            serverTime: rig.serverNow,
            stateVersion: 3,
            currentIndex: 0,
          ),
        ),
      );
      await rig.time.advance(const Duration(seconds: 3));

      expect(rig.h.calls, isNot(contains('play')));
      expect(rig.h.controller.snapshot.playing, isFalse);
    });
  });

  test('group:playback-delta applies pause and play and moves to a new '
      'index', () async {
    final rig = await _inGroup();
    Future<void> delta({
      required bool playing,
      required int index,
      required int version,
    }) => rig.push(
      (s) => s.playbackDeltas.add(
        PlaybackDelta(
          isPlaying: playing,
          positionMs: 0,
          serverTime: rig.serverNow,
          stateVersion: version,
          currentIndex: index,
        ),
      ),
    );

    await delta(playing: false, index: 0, version: 2);
    expect(rig.h.calls, ['pause']);
    expect(rig.h.controller.snapshot.playing, isFalse);

    await delta(playing: true, index: 0, version: 3);
    expect(rig.h.calls, ['pause', 'play']);
    expect(rig.h.controller.snapshot.playing, isTrue);

    await delta(playing: true, index: 2, version: 4);
    expect(rig.h.calls.where((c) => c.startsWith('load')), [
      'load(${groupItem(2, 'c')}, autoPlay: true, at: 0:00:00.000000)',
    ]);
    expect(rig.h.controller.snapshot.current?.queueItemId, groupItem(2, 'c'));
  });

  for (final (event, reason) in [
    (const GroupEnded.ended(reason: 'closed'), GroupEndReason.ended),
    (
      const GroupEnded.revoked(reason: 'kicked'),
      GroupEndReason.membershipRevoked,
    ),
  ]) {
    test(
      '${event.runtimeType} detaches and restores the saved queue paused',
      () async {
        final rig = await _inGroup();

        await rig.push((s) => s.ends.add(event));

        expect(rig.h.controller.hasRemoteDriver, isFalse);
        expect(rig.socket.leases, 0);
        final snapshot = rig.h.controller.snapshot;
        expect(idsOf(snapshot.queue.items), ['a', 'b', 'c']);
        expect(snapshot.playing, isFalse);
        expect(snapshot.position, greaterThan(Duration.zero));
        expect(rig.controller.current, isA<ListenTogetherEnded>());
        expect((rig.controller.current as ListenTogetherEnded).reason, reason);
        expect(rig.socket.keepAliveInBackground(), isFalse);
      },
    );
  }

  test(
    'after the group ends, server events no longer touch playback',
    () async {
      final rig = await _inGroup();
      await rig.push((s) => s.ends.add(const GroupEnded.ended()));
      rig.h.calls.clear();

      await rig.push(
        (s) => s.states.add(groupState(serverTime: rig.serverNow)),
      );

      expect(rig.h.calls, isEmpty);
      expect(idsOf(rig.h.controller.snapshot.queue.items), ['a', 'b', 'c']);
    },
  );
}
