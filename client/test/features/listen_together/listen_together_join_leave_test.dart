// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/listen_together_controller.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../core/playback/queue/queue_test_items.dart';
import '../../helpers/fake_api.dart';
import 'listen_together_rig.dart';

QueueItem _episode(String id) => QueueItem.episode(
  queueItemId: id,
  episode: const Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'Episode',
    durationSec: 600,
  ),
  podcast: const Podcast(id: 'pod1', title: 'Podcast'),
);

void main() {
  test('join by code: REST, then join-group, then attach; the state becomes '
      'active', () async {
    final rig = ListenTogetherRig();
    await rig.playLocal();
    List<String>? restAtJoin;
    bool? attachedAtJoin;
    rig.socket.onJoin = () {
      restAtJoin = List.of(rig.api.calls);
      attachedAtJoin = rig.h.controller.hasRemoteDriver;
    };

    await rig.controller.joinByCode('ABC123');

    expect(restAtJoin, ['join:ABC123']);
    expect(attachedAtJoin, isFalse);
    expect(rig.socket.log, ['acquire', 'join-group:g1']);
    expect(rig.h.controller.hasRemoteDriver, isTrue);
    await pumpEventQueue();
    expect(rig.states.map((s) => s.runtimeType), [
      ListenTogetherIdle,
      ListenTogetherJoining,
      ListenTogetherActive,
    ]);
    final active = rig.controller.current as ListenTogetherActive;
    expect(active.group.id, 'g1');
    expect(active.canControl, isFalse);
    await rig.h.controller.settled;
    expect(rig.h.controller.snapshot.remoteAttached, isTrue);
    expect(rig.h.controller.snapshot.remoteCanControl, isFalse);
    expect(rig.socket.keepAliveInBackground(), isTrue);
  });

  test('create from the current queue sends playbackId and metadata from the '
      'current track on and leaves episodes out', () async {
    final rig = ListenTogetherRig();
    await rig.h.controller.playItems([
      ...trackItems(['a']),
      _episode('ep'),
      ...trackItems(['b']),
      _episode('ep2'),
      ...trackItems(['c']),
    ], startIndex: 1);
    await rig.h.controller.next();
    await rig.h.play(const Duration(seconds: 2));
    rig.api.group = listenGroupJson(hostUserId: 'me');

    await rig.controller.createGroup(
      visibility: GroupVisibility.private,
      fromCurrentQueue: true,
    );

    final body =
        jsonDecode(jsonEncode(rig.api.creates.single)) as Map<String, Object?>;
    expect(body.keys, isNot(contains('queueTrackIds')));
    expect(body.keys, isNot(contains('currentTrackId')));
    expect(body['isPlaying'], isTrue);
    expect(body['currentTimeMs'], greaterThan(1000));
    final tracks = (body['queueTracks']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(tracks.map((t) => t['playbackId']), ['pb-b', 'pb-c']);
    expect(
      tracks.map((t) => t.keys.toSet()),
      everyElement({'playbackId', 'metadata'}),
    );
    expect((rig.controller.current as ListenTogetherActive).canControl, isTrue);
  });

  test('initialTracksOf follows play order from the cursor and stops at '
      '500', () {
    final queue = queueOf(
      ['a', 'b', 'c', 'd'],
      cursor: 1,
      shuffleOrder: [3, 0, 2, 1],
    );
    expect(initialTracksOf(queue).map((t) => t.playbackId?.value), [
      'pb-a',
      'pb-c',
      'pb-b',
    ]);
    final long = queueOf(numberedIds(600));
    expect(initialTracksOf(long), hasLength(500));
  });

  test('a failing join-group ack releases the lease and leaves the local '
      'queue playing as before', () async {
    final rig = ListenTogetherRig();
    await rig.playLocal();
    final before = rig.h.controller.snapshot;
    rig.socket.joinAck = const Ack();

    await expectLater(rig.controller.joinByCode('ABC123'), throwsA(anything));

    expect(rig.socket.leases, 0);
    expect(rig.socket.log, ['acquire', 'join-group:g1', 'release']);
    expect(rig.api.calls, ['join:ABC123', 'leave:g1']);
    expect(rig.h.controller.hasRemoteDriver, isFalse);
    expect(rig.controller.current, isA<ListenTogetherIdle>());
    expect(rig.h.controller.snapshot.queue, same(before.queue));
    expect(rig.h.controller.snapshot.playing, isTrue);
    expect(rig.socket.keepAliveInBackground(), isFalse);
  });

  test('leave over the socket restores the saved queue at the saved '
      'position, paused, and detaches', () async {
    final rig = ListenTogetherRig();
    await rig.playLocal();
    final saved = rig.h.controller.snapshot;
    await rig.controller.joinByCode('ABC123');
    await rig.h.controller.remote.replaceQueue(trackItems(['x', 'y']), 1);

    await rig.controller.leave();

    expect(rig.socket.log, [
      'acquire',
      'join-group:g1',
      'leave-group',
      'release',
    ]);
    expect(rig.api.calls, ['join:ABC123']);
    expect(rig.h.controller.hasRemoteDriver, isFalse);
    expect(rig.socket.leases, 0);
    expect(rig.controller.current, isA<ListenTogetherIdle>());
    final restored = rig.h.controller.snapshot;
    expect(idsOf(restored.queue.items), ['a', 'b', 'c']);
    expect(restored.current?.queueItemId, 'a');
    expect(restored.playing, isFalse);
    expect(restored.position, saved.position);
    expect(saved.position, greaterThan(Duration.zero));
  });

  test('leave with the socket down uses the REST fallback', () async {
    final rig = ListenTogetherRig();
    await rig.playLocal();
    await rig.controller.joinByCode('ABC123');
    rig.socket.connectionState = SocketConnectionState.disconnected;

    await rig.controller.leave();

    expect(rig.socket.log, isNot(contains('leave-group')));
    expect(rig.api.calls, ['join:ABC123', 'leave:g1']);
    expect(rig.h.controller.hasRemoteDriver, isFalse);
    expect(idsOf(rig.h.controller.snapshot.queue.items), ['a', 'b', 'c']);
  });

  test('a failing leave-group ack also falls back to REST', () async {
    final rig = ListenTogetherRig();
    await rig.controller.joinByCode('ABC123');
    rig.socket.leaveFails = true;

    await rig.controller.leave();

    expect(rig.api.calls, ['join:ABC123', 'leave:g1']);
    expect(rig.controller.current, isA<ListenTogetherIdle>());
  });

  test('joining a second group leaves the first', () async {
    final rig = ListenTogetherRig();
    await rig.playLocal();
    await rig.controller.joinByCode('ABC123');
    rig.api.group = listenGroupJson(id: 'g2', joinCode: 'XYZ789');

    await rig.controller.joinByCode('XYZ789');

    expect(rig.socket.log, [
      'acquire',
      'join-group:g1',
      'leave-group',
      'release',
      'acquire',
      'join-group:g2',
    ]);
    expect(rig.h.controller.hasRemoteDriver, isTrue);
    expect((rig.controller.current as ListenTogetherActive).group.id, 'g2');

    await rig.controller.leave();
    expect(idsOf(rig.h.controller.snapshot.queue.items), ['a', 'b', 'c']);
  });

  test('endGroup calls REST end and restores the queue', () async {
    final rig = ListenTogetherRig();
    await rig.playLocal();
    rig.api.group = listenGroupJson(hostUserId: 'me');
    await rig.controller.createGroup(
      visibility: GroupVisibility.public,
      fromCurrentQueue: false,
    );

    await rig.controller.endGroup();

    expect(rig.api.calls, ['create', 'end:g1']);
    expect(rig.socket.log, isNot(contains('leave-group')));
    expect(rig.socket.leases, 0);
    expect(rig.h.controller.hasRemoteDriver, isFalse);
    expect(idsOf(rig.h.controller.snapshot.queue.items), ['a', 'b', 'c']);
    expect(rig.h.controller.snapshot.playing, isFalse);
    expect(rig.controller.current, isA<ListenTogetherIdle>());
  });

  test('endGroup by a member who is not the host is a StateError', () async {
    final rig = ListenTogetherRig();
    await rig.controller.joinByCode('ABC123');

    await expectLater(rig.controller.endGroup(), throwsStateError);
    expect(rig.api.calls, ['join:ABC123']);
    expect(rig.controller.current, isA<ListenTogetherActive>());
  });

  test('dispose leaves and drops the local state without restoring', () async {
    final rig = ListenTogetherRig();
    await rig.playLocal();
    await rig.controller.joinByCode('ABC123');
    await rig.h.controller.remote.replaceQueue(trackItems(['x']), 0);

    await rig.controller.dispose();

    expect(rig.socket.log.skip(2), ['leave-group', 'release']);
    expect(rig.h.controller.hasRemoteDriver, isFalse);
    await rig.h.controller.settled;
    expect(idsOf(rig.h.controller.snapshot.queue.items), ['x']);
  });
}
