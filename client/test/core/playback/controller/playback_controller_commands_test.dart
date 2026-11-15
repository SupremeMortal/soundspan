// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';

import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

const _zero = '0:00:00.000000';

List<String> _withoutNext(List<String> calls) => [
  for (final call in calls)
    if (!call.startsWith('setNext')) call,
];

void main() {
  group('queue commands load or seek as the effect says', () {
    test('next loads the following item', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b', 'c']));
      h.calls.clear();

      await h.controller.next();

      expect(h.calls, ['load(b, autoPlay: true, at: $_zero)', 'setNext(c)']);
    });

    test('previous after more than 3 s restarts the current item', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b', 'c']), startIndex: 1);
      await h.play(const Duration(seconds: 4));
      h.calls.clear();

      await h.controller.previous();

      expect(h.calls, ['seek($_zero)', 'play']);
      expect(h.controller.snapshot.current?.queueItemId, 'b');
    });

    test('previous within 3 s loads the item before', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b', 'c']), startIndex: 1);
      await h.play(const Duration(seconds: 1));
      h.calls.clear();

      await h.controller.previous();

      expect(h.calls, ['load(a, autoPlay: true, at: $_zero)', 'setNext(b)']);
    });

    test('jumpTo loads the chosen item and plays it', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b', 'c', 'd']));
      await h.controller.pause();
      h.calls.clear();

      await h.controller.jumpTo('c');

      expect(h.calls, ['load(c, autoPlay: true, at: $_zero)', 'setNext(d)']);
      expect(h.controller.snapshot.playing, isTrue);
    });

    test('removing the current item loads the next one', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b', 'c']));
      h.calls.clear();

      await h.controller.removeAt('a');

      expect(h.calls, ['load(b, autoPlay: true, at: $_zero)', 'setNext(c)']);
      expect(idsOf(h.controller.snapshot.queue.items), ['b', 'c']);
    });
  });

  group('transport', () {
    test('pause, play, togglePlayPause, seek and stop reach the engine and '
        'the snapshot', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b']));
      h.calls.clear();

      await h.controller.pause();
      await h.settle();
      expect(h.calls, ['pause']);
      expect(h.controller.snapshot.playing, isFalse);

      await h.controller.play();
      await h.settle();
      expect(h.calls.last, 'play');
      expect(h.controller.snapshot.playing, isTrue);

      await h.controller.togglePlayPause();
      expect(h.calls.last, 'pause');
      expect(h.controller.snapshot.playing, isFalse);
      await h.controller.togglePlayPause();
      expect(h.calls.last, 'play');
      expect(h.controller.snapshot.playing, isTrue);

      await h.controller.seek(const Duration(seconds: 5));
      await h.settle();
      expect(h.calls.last, 'seek(0:00:05.000000)');
      expect(h.controller.snapshot.position, const Duration(seconds: 5));

      await h.controller.stop();
      await h.settle();
      expect(h.calls.last, 'stop');
      final snapshot = h.controller.snapshot;
      expect(snapshot.status, EngineStatus.idle);
      expect(snapshot.playing, isFalse);
      expect(snapshot.position, Duration.zero);
      expect(snapshot.current?.queueItemId, 'a');
    });

    test('commands issued together are applied in arrival order', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b', 'c']));
      h.calls.clear();

      await Future.wait([
        h.controller.pause(),
        h.controller.next(),
        h.controller.seek(const Duration(seconds: 2)),
      ]);

      expect(_withoutNext(h.calls), [
        'pause',
        'load(b, autoPlay: false, at: $_zero)',
        'seek(0:00:02.000000)',
      ]);
    });

    test('play on an idle engine with a current item loads lazily at '
        'pendingStartAt', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b']));
      await h.controller.stop();
      await h.settle();
      h.calls.clear();

      await h.controller.play();

      expect(h.calls, ['load(a, autoPlay: true, at: $_zero)', 'setNext(b)']);
      expect(h.controller.snapshot.playing, isTrue);
    });
  });

  group('failures', () {
    test('an unplayable current item sets snapshot.error and pauses, with no '
        'engine call', () async {
      final h = ControllerHarness();
      h.resolver.unplayable.add('a');

      await h.controller.playItems(trackItems(['a', 'b']));
      await h.settle();

      expect(h.calls, isEmpty);
      expect(
        h.controller.snapshot.error,
        const PlaybackError(
          PlaybackErrorKind.itemUnavailable,
          queueItemId: 'a',
        ),
      );
      expect(h.controller.snapshot.playing, isFalse);
    });

    test('a failed current item sets snapshot.error and pauses, with no '
        'further engine call', () async {
      final h = ControllerHarness();
      h.fake.sources.remove(uriOf('a'));

      await h.controller.playItems(trackItems(['a', 'b']));
      await h.settle();
      final calls = List.of(h.calls);
      await h.play(const Duration(seconds: 2));

      expect(_withoutNext(calls), ['load(a, autoPlay: true, at: $_zero)']);
      expect(h.calls, calls);
      expect(
        h.controller.snapshot.error,
        const PlaybackError(PlaybackErrorKind.itemFailed, queueItemId: 'a'),
      );
      expect(h.controller.snapshot.playing, isFalse);
    });
  });

  test('dropped items emit itemsDropped', () async {
    final h = ControllerHarness();
    final ids = [for (var i = 0; i < 5001; i++) 'i$i'];

    await h.controller.playItems(trackItems(ids));
    await h.settle();

    expect(h.notices, hasLength(1));
    expect((h.notices.single as ItemsDropped).count, 1);
  });
}
