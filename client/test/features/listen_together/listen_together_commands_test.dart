// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../core/playback/queue/queue_test_items.dart';
import 'listen_together_rig.dart';

/// A rig in a playing group over a, b, c at version 4; with [host] this
/// user may control playback.
Future<ListenTogetherRig> _inGroup({bool host = true}) async {
  final rig = ListenTogetherRig();
  await rig.join(host: host);
  await rig.push(
    (s) => s.states.add(
      groupState(
        syncState: 'playing',
        serverTime: rig.serverNow,
        stateVersion: 4,
        hostUserId: host ? 'me' : 'host',
      ),
    ),
  );
  rig.h.calls.clear();
  return rig;
}

ListenTogetherActive _active(ListenTogetherRig rig) =>
    rig.controller.current as ListenTogetherActive;

QueueItem _episode() => const QueueItem.episode(
  queueItemId: 'ep',
  episode: Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'Episode',
    durationSec: 600,
  ),
  podcast: Podcast(id: 'pod1', title: 'Podcast'),
);

void main() {
  for (final (name, send, expected)
      in <(String, Future<void> Function(ListenTogetherRig rig), List<String>)>[
        ('play', (rig) => rig.h.controller.play(), ['playback:play']),
        ('pause', (rig) => rig.h.controller.pause(), ['playback:pause']),
        ('next', (rig) => rig.h.controller.next(), ['playback:next']),
        (
          'previous',
          (rig) => rig.h.controller.previous(),
          ['playback:previous'],
        ),
        (
          'seek',
          (rig) => rig.h.controller.seek(const Duration(seconds: 3)),
          ['playback:seek@3000#v4'],
        ),
        (
          'jumpTo',
          (rig) => rig.h.controller.jumpTo(groupItem(2, 'c')),
          ['playback:set-track#2'],
        ),
        (
          'append',
          (rig) => rig.h.controller.append(trackItems(['d', 'e'])),
          ['queue:add[pb-d,pb-e]'],
        ),
        (
          'playNext',
          (rig) => rig.h.controller.playNext(trackItems(['d'])),
          ['queue:insert-next[pb-d]'],
        ),
        (
          'removeAt',
          (rig) => rig.h.controller.removeAt(groupItem(1, 'b')),
          ['queue:remove#1'],
        ),
        (
          'move',
          (rig) => rig.h.controller.move(groupItem(0, 'a'), 2),
          ['queue:reorder 0>2'],
        ),
        ('clear', (rig) => rig.h.controller.clear(), ['queue:clear']),
        (
          'replaceAll',
          (rig) => rig.h.controller.playItems(trackItems(['x', 'y'])),
          ['queue:clear', 'queue:add[pb-x,pb-y]'],
        ),
      ]) {
    test(
      '$name sends ${expected.join(', ')} and changes nothing locally',
      () async {
        final rig = await _inGroup();
        final before = rig.h.controller.snapshot;

        await send(rig);
        await rig.h.settle();

        expect(rig.socket.commands, expected);
        expect(rig.h.calls, isEmpty);
        final after = rig.h.controller.snapshot;
        expect(after.queue, same(before.queue));
        expect(after.playing, before.playing);
        expect(_active(rig).pending, isEmpty);
        expect(_active(rig).lastCommandError, isNull);
      },
    );
  }

  test('a command is pending until its ack arrives', () async {
    final rig = await _inGroup();
    final ack = Completer<bool>();
    rig.socket.answer = (_) => ack.future;

    final sent = rig.h.controller.next();
    await rig.h.settle();
    expect(_active(rig).pending.single, isA<NextCommand>());

    ack.complete(true);
    await sent;
    expect(_active(rig).pending, isEmpty);
    expect(_active(rig).lastCommandError, isNull);
  });

  test(
    'an ack error clears the pending command and publishes the error',
    () async {
      final rig = await _inGroup();
      rig.socket.answer = (_) async => throw const SocketCommandException(
        message: 'Queue is empty',
        code: 'INVALID',
      );

      await rig.h.controller.next();

      expect(_active(rig).pending, isEmpty);
      final error = _active(rig).lastCommandError;
      expect(error, isA<GroupCommandRejected>());
      expect((error! as GroupCommandRejected).code, 'INVALID');
    },
  );

  test('a refused ack publishes a rejection', () async {
    final rig = await _inGroup();
    rig.socket.answer = (_) async => false;

    await rig.h.controller.pause();

    expect(_active(rig).lastCommandError, isA<GroupCommandRejected>());
  });

  test('without an ack in 5 s the command leaves the pending set with a '
      'timeout error', () async {
    final rig = await _inGroup();
    rig.socket.answer = (_) => Completer<bool>().future;

    final sent = rig.h.controller.play();
    await rig.h.settle();
    await rig.time.advance(const Duration(milliseconds: 4999));
    expect(_active(rig).pending, hasLength(1));

    await rig.time.advance(const Duration(milliseconds: 1));
    await sent;
    expect(_active(rig).pending, isEmpty);
    expect(_active(rig).lastCommandError, isA<GroupCommandTimedOut>());
  });

  test("a follower's transport commands are refused without an emit; "
      'queue additions are still sent', () async {
    final rig = await _inGroup(host: false);

    await rig.h.controller.play();
    await rig.h.controller.next();
    await rig.h.controller.seek(const Duration(seconds: 1));
    await rig.h.controller.playItems(trackItems(['x']));
    expect(rig.socket.commands, isEmpty);
    expect(_active(rig).lastCommandError, isA<HostControlsPlayback>());

    await rig.h.controller.append(trackItems(['d']));
    expect(rig.socket.commands, ['queue:add[pb-d]']);
  });

  test('shuffle and repeat are rejected locally', () async {
    final rig = await _inGroup();

    await rig.h.controller.setShuffle(true);
    expect(_active(rig).lastCommandError, isA<RemoteCommandUnsupported>());
    await rig.h.controller.setRepeat(RepeatMode.all);

    expect(rig.socket.commands, isEmpty);
    expect(rig.h.controller.snapshot.queue.isShuffled, isFalse);
  });

  test('episodes and tracks without a playback id are dropped from an '
      'addition with an error', () async {
    final rig = await _inGroup();

    await rig.h.controller.append([
      _episode(),
      ...trackItems(['d']),
    ]);

    expect(rig.socket.commands, ['queue:add[pb-d]']);
    final error = _active(rig).lastCommandError;
    expect(error, isA<ItemsNotShareable>());
    expect((error! as ItemsNotShareable).count, 1);
  });

  test('an engine failure emits track:playback-failed with the cursor '
      'index', () async {
    final rig = await _inGroup();
    rig.h.resolver.unplayable.add(groupItem(1, 'b'));

    await rig.push(
      (s) => s.playbackDeltas.add(
        PlaybackDelta(
          isPlaying: true,
          positionMs: 0,
          serverTime: rig.serverNow,
          stateVersion: 5,
          currentIndex: 1,
        ),
      ),
    );

    expect(rig.socket.commands, ['playback-failed:1']);
    expect(rig.h.controller.snapshot.current?.queueItemId, groupItem(1, 'b'));
  });
}
