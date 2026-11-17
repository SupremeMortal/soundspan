// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';

import 'controller/controller_harness.dart';
import 'queue/queue_test_items.dart';

class _RecordingDriver implements RemoteDriver {
  final List<PlaybackCommand> commands = [];
  final List<String> failed = [];

  @override
  Future<void> onCommand(PlaybackCommand command) async =>
      commands.add(command);

  @override
  void onCurrentItemFailed(String queueItemId) => failed.add(queueItemId);
}

void main() {
  test('with a RemoteDriver attached, queue and transport commands go to the '
      'driver and local state is unchanged', () async {
    final h = ControllerHarness();
    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    await h.settle();
    final before = h.controller.snapshot;
    h.calls.clear();
    final driver = _RecordingDriver();

    h.controller.attachRemoteDriver(driver);
    await h.controller.next();
    await h.controller.pause();
    await h.controller.seek(const Duration(seconds: 3));
    await h.controller.append(trackItems(['d']));
    await h.controller.playItems(trackItems(['x']));
    await h.controller.clear();
    await h.settle();

    expect(h.controller.hasRemoteDriver, isTrue);
    expect(driver.commands.map((c) => c.runtimeType), [
      NextCommand,
      PauseCommand,
      SeekCommand,
      AppendCommand,
      PlayItemsCommand,
      ClearCommand,
    ]);
    expect(h.calls, isEmpty);
    expect(h.controller.snapshot.queue, same(before.queue));
    expect(h.controller.snapshot.current?.queueItemId, 'a');
    expect(h.controller.snapshot.playing, isTrue);
  });

  test('setVolume stays local while a driver is attached', () async {
    final h = ControllerHarness();
    final driver = _RecordingDriver();
    h.controller.attachRemoteDriver(driver);

    await h.controller.setVolume(0.5);

    expect(driver.commands, isEmpty);
    expect(h.controller.volume, 0.5);
    expect(h.calls, ['setVolume(0.5)']);
  });

  test('after detach commands apply locally again', () async {
    final h = ControllerHarness();
    await h.controller.playItems(trackItems(['a', 'b']));
    final driver = _RecordingDriver();
    h.controller.attachRemoteDriver(driver);
    h.controller.detachRemoteDriver();
    h.calls.clear();

    await h.controller.next();

    expect(h.controller.hasRemoteDriver, isFalse);
    expect(driver.commands, isEmpty);
    expect(h.controller.snapshot.current?.queueItemId, 'b');
    expect(h.calls.first, 'load(b, autoPlay: true, at: 0:00:00.000000)');
  });

  test('attaching a second driver throws StateError', () {
    final h = ControllerHarness();
    h.controller.attachRemoteDriver(_RecordingDriver());

    expect(
      () => h.controller.attachRemoteDriver(_RecordingDriver()),
      throwsStateError,
    );
  });

  test('while a driver is attached, a current item that cannot play is '
      'reported to the driver and nothing is skipped', () async {
    final h = ControllerHarness();
    final driver = _RecordingDriver();
    h.controller.attachRemoteDriver(driver);
    await h.controller.remote.replaceQueue(trackItems(['a', 'b', 'c']), 0);
    h.resolver.unplayable.add('a');

    await h.controller.remote.loadCurrent(position: Duration.zero, play: true);
    await h.settle();

    expect(driver.failed, ['a']);
    expect(h.controller.snapshot.current?.queueItemId, 'a');
    expect(h.controller.snapshot.error?.queueItemId, 'a');
    expect(h.resolver.resolved, isNot(contains('b')));
  });

  test('while a driver is attached, three failed items in a row do not '
      'stop playback by the local rule', () async {
    final h = ControllerHarness();
    final driver = _RecordingDriver();
    h.controller.attachRemoteDriver(driver);
    await h.controller.remote.replaceQueue(trackItems(['a', 'b', 'c', 'd']), 0);
    h.resolver.unplayable.addAll(['a', 'b', 'c', 'd']);

    for (final cursor in [0, 1, 2, 3]) {
      await h.controller.remote.replaceQueue(
        trackItems(['a', 'b', 'c', 'd']),
        cursor,
      );
      await h.controller.remote.loadCurrent(
        position: Duration.zero,
        play: true,
      );
    }
    await h.settle();

    expect(driver.failed, ['a', 'b', 'c', 'd']);
    expect(h.notices.whereType<PlaybackStopped>(), isEmpty);
    expect(h.notices.whereType<ItemSkipped>(), isEmpty);
  });
}
