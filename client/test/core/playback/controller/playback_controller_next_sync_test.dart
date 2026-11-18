// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';

import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

const _zero = '0:00:00.000000';

void main() {
  test('a queue edit that changes upNext calls setNext once with the new '
      'item; an edit that does not change it makes no engine call', () async {
    final h = ControllerHarness(ids: ['a', 'b', 'c', 'x', 'y']);
    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    h.calls.clear();

    await h.controller.playNext([trackItem('x')]);
    expect(h.calls, ['setNext(x)']);

    await h.controller.append([trackItem('y')]);
    await h.controller.move('c', 3);
    await h.settle();
    expect(h.calls, ['setNext(x)']);
  });

  test('toggling shuffle replaces the preloaded next', () async {
    final h = ControllerHarness(reducer: QueueReducer(random: Random(1)));
    await h.controller.playItems(trackItems(['a', 'b', 'c', 'd']));
    h.calls.clear();

    await h.controller.setShuffle(true);

    final upNext = h.controller.snapshot.queue.upNext!.queueItemId;
    expect(upNext, isNot('b'));
    expect(h.calls, ['setNext($upNext)']);
  });

  test('a stale next resolution is discarded', () async {
    final h = ControllerHarness(ids: ['a', 'b', 'c', 'x']);
    final gate = h.resolver.gates['b'] = Completer<void>();
    unawaited(h.controller.playItems(trackItems(['a', 'b', 'c'])));
    await h.settle();

    await h.controller.playNext([trackItem('x')]);
    gate.complete();
    await h.settle();

    expect(h.calls, ['load(a, autoPlay: true, at: $_zero)', 'setNext(x)']);
    expect(
      [for (final source in h.fake.requested) source.queueItemId],
      ['a', 'x'],
    );
  });

  test('an unresolvable next item clears the slot and does not affect the '
      'current item', () async {
    final h = ControllerHarness();
    h.resolver.unplayable.add('b');

    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    await h.play(const Duration(seconds: 1));

    expect(h.calls, ['load(a, autoPlay: true, at: $_zero)', 'setNext(null)']);
    expect(h.controller.snapshot.error, isNull);
    expect(h.controller.snapshot.playing, isTrue);
    expect(h.controller.snapshot.position, const Duration(seconds: 1));
  });

  test('a failed preloaded next clears the slot and does not affect the '
      'current item', () async {
    final h = ControllerHarness();
    h.fake.sources.remove(uriOf('b'));

    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    await h.play(const Duration(seconds: 1));

    expect(h.calls, [
      'load(a, autoPlay: true, at: $_zero)',
      'setNext(b)',
      'setNext(null)',
    ]);
    expect(h.controller.snapshot.error, isNull);
    expect(h.controller.snapshot.playing, isTrue);
    expect(h.controller.snapshot.status, EngineStatus.ready);
    expect(h.controller.snapshot.position, const Duration(seconds: 1));
  });

  test('the next source is resolved only when it becomes up next', () async {
    final h = ControllerHarness();

    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    expect(h.resolver.resolved, ['a', 'b']);

    await h.play(trackLength + FakeEngine.positionInterval);
    expect(h.resolver.resolved, ['a', 'b', 'c']);
  });
}
