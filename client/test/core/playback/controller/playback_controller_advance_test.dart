// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';

import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

/// How far into the next item playback runs; the fake engine reports the
/// position every [FakeEngine.positionInterval].
const Duration _past = FakeEngine.positionInterval;

void main() {
  test('playItems loads the start item with autoPlay and preloads the '
      'following item', () async {
    final h = ControllerHarness();

    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    await h.settle();

    expect(h.calls, [
      'load(a, autoPlay: true, at: 0:00:00.000000)',
      'setNext(b)',
    ]);
    final snapshot = h.controller.snapshot;
    expect(snapshot.current?.queueItemId, 'a');
    expect(snapshot.playing, isTrue);
    expect(snapshot.status, EngineStatus.ready);
    expect(snapshot.duration, trackLength);
  });

  test('natural end advances: one ItemFinished, no reload, next is '
      'preloaded again', () async {
    final h = ControllerHarness();
    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    h.calls.clear();

    await h.play(trackLength + _past);

    expect(h.calls, ['setNext(c)']);
    final snapshot = h.controller.snapshot;
    expect(snapshot.queue.cursor, 1);
    expect(snapshot.current?.queueItemId, 'b');
    expect(snapshot.playing, isTrue);
    expect(snapshot.position, _past);
  });

  test('Completed with no preloaded next loads the following item', () async {
    final h = ControllerHarness();
    h.resolver.gates['b'] = Completer<void>();
    unawaited(h.controller.playItems(trackItems(['a', 'b', 'c'])));
    await h.settle();
    h.calls.clear();

    await h.play(trackLength + _past);

    expect(h.calls, [
      'load(b, autoPlay: true, at: 0:00:00.000000)',
      'setNext(c)',
    ]);
    expect(h.controller.snapshot.current?.queueItemId, 'b');
    expect(h.controller.snapshot.playing, isTrue);
  });

  test('end of queue with repeat off stops with the cursor on the last item '
      'at position zero', () async {
    final h = ControllerHarness();
    await h.controller.playItems(trackItems(['a', 'b']), startIndex: 1);
    h.calls.clear();

    await h.play(trackLength + _past);

    expect(h.calls, ['stop']);
    final snapshot = h.controller.snapshot;
    expect(snapshot.queue.cursor, 1);
    expect(snapshot.current?.queueItemId, 'b');
    expect(snapshot.position, Duration.zero);
    expect(snapshot.playing, isFalse);
    expect(snapshot.status, EngineStatus.idle);
  });

  test('repeat one replays without a reload', () async {
    final h = ControllerHarness();
    await h.controller.playItems(trackItems(['a', 'b']));
    await h.controller.setRepeat(RepeatMode.one);
    expect(h.calls.last, 'setNext(a)');
    h.calls.clear();

    await h.play(trackLength + _past);

    expect(h.calls, ['setNext(a)']);
    expect(h.controller.snapshot.current?.queueItemId, 'a');
    expect(h.controller.snapshot.position, _past);
    expect(h.controller.snapshot.playing, isTrue);
  });

  test('repeat all wraps to the first item without a reload', () async {
    final h = ControllerHarness();
    await h.controller.playItems(trackItems(['a', 'b']), startIndex: 1);
    await h.controller.setRepeat(RepeatMode.all);
    expect(h.calls.last, 'setNext(a)');
    h.calls.clear();

    await h.play(trackLength + _past);

    expect(h.calls, ['setNext(b)']);
    expect(h.controller.snapshot.queue.cursor, 0);
    expect(h.controller.snapshot.current?.queueItemId, 'a');
  });
}
