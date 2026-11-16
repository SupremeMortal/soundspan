// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/shared/clock.dart';

import '../../../helpers/memory_device_settings.dart';
import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

/// A [Clock] that reads the virtual time of [_async].
class _FakeAsyncClock implements Clock {
  new(this._async);

  final FakeAsync _async;

  @override
  DateTime now() => _async.getClock(DateTime.utc(2025)).now().toUtc();
}

void main() {
  test('position-only updates are emitted at most 4 times per second; a '
      'pause is emitted immediately', () {
    fakeAsync((async) {
      final h = ControllerHarness(clock: _FakeAsyncClock(async));
      unawaited(h.controller.playItems(trackItems(['a', 'b'])));
      async.flushMicrotasks();
      h.snapshots.clear();

      const step = FakeEngine.positionInterval;
      for (var i = 0; i < 10; i++) {
        h.fake.advance(step);
        async.elapse(step);
      }

      // Two seconds of 5 Hz engine positions reach listeners at 4 Hz.
      expect(h.snapshots, hasLength(8));
      expect(h.snapshots.last.position, const Duration(seconds: 2));
      expect(h.snapshots.every((s) => s.playing), isTrue);

      h.snapshots.clear();
      unawaited(h.controller.pause());
      async.flushMicrotasks();
      expect(h.snapshots, isNotEmpty);
      expect(h.snapshots.first.playing, isFalse);
    });
  });

  test('a late listener receives the latest snapshot', () async {
    final h = ControllerHarness();
    await h.controller.playItems(trackItems(['a', 'b']));
    await h.play(const Duration(seconds: 1));

    final first = await h.controller.snapshots.first;

    expect(first.current?.queueItemId, 'a');
    expect(first.position, const Duration(seconds: 1));
    expect(first.playing, isTrue);
  });

  test('engine volume is user volume times the factors, clamped', () async {
    final h = ControllerHarness();

    await h.controller.setVolume(0.5);
    expect(h.fake.volume, 0.5);
    expect(h.controller.volume, 0.5);

    h.controller
      ..setVolumeFactor('loudness', 1.5)
      ..setVolumeFactor('duck', 0.3);
    await h.settle();
    expect(h.fake.volume, closeTo(0.225, 1e-9));

    h.controller.setVolumeFactor('duck', 1);
    await h.controller.setVolume(1);
    expect(h.fake.volume, 1.0);

    await h.controller.setVolume(-2);
    expect(h.controller.volume, 0.0);
    expect(h.fake.volume, 0.0);
  });

  test('volumeListenable follows the set and the stored volume', () async {
    final stored = MemoryDeviceSettings()..values[playbackVolumeKey] = '0.25';
    final h = ControllerHarness(deviceSettings: stored);
    final heard = <double>[];
    h.controller.volumeListenable.addListener(
      () => heard.add(h.controller.volumeListenable.value),
    );

    await h.settle();
    expect(h.controller.volumeListenable.value, 0.25);

    await h.controller.setVolume(0.75);
    expect(heard, [0.25, 0.75]);
    expect(stored.values[playbackVolumeKey], '0.75');
  });
}
