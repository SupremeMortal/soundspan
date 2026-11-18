// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/persistence.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/storage/state/queue_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

import '../../helpers/fake_clock.dart';
import 'controller/controller_harness.dart';
import 'queue/queue_test_items.dart';

class _RecordingDriver implements RemoteDriver {
  final List<PlaybackCommand> commands = [];

  @override
  Future<void> onCommand(PlaybackCommand command) async =>
      commands.add(command);

  @override
  void onCurrentItemFailed(String queueItemId) {}
}

const _ids = ['a', 'b', 'c', 'x', 'y', 'z'];

void main() {
  test('remote is a StateError without a driver', () {
    final h = ControllerHarness(ids: _ids);

    expect(() => h.controller.remote, throwsStateError);
  });

  test('replaceQueue sets the queue and stops the engine; loadCurrent loads '
      'the current item at the position, paused or playing', () async {
    final h = ControllerHarness(ids: _ids);
    await h.controller.playItems(trackItems(['a', 'b']));
    await h.settle();
    h.controller.attachRemoteDriver(_RecordingDriver());
    h.calls.clear();

    await h.controller.remote.replaceQueue(trackItems(['x', 'y', 'z']), 1);

    expect(idsOf(h.controller.snapshot.queue.items), ['x', 'y', 'z']);
    expect(h.controller.snapshot.current?.queueItemId, 'y');
    expect(h.controller.snapshot.playing, isFalse);
    expect(h.calls, ['stop']);

    await h.controller.remote.loadCurrent(
      position: const Duration(seconds: 4),
      play: false,
    );
    await h.settle();

    expect(
      h.calls.skip(1).first,
      'load(y, autoPlay: false, at: 0:00:04.000000)',
    );
    expect(h.calls, contains('setNext(z)'));
    expect(h.controller.snapshot.playing, isFalse);

    h.calls.clear();
    await h.controller.remote.play();
    await h.controller.remote.seek(const Duration(seconds: 6));
    await h.controller.remote.pause();

    expect(h.calls, ['play', 'seek(0:00:06.000000)', 'pause']);
    expect(h.controller.snapshot.playing, isFalse);
  });

  test('replaceQueue keeps the current entry playing when it stays '
      'current', () async {
    final h = ControllerHarness(ids: _ids);
    h.controller.attachRemoteDriver(_RecordingDriver());
    final items = trackItems(['x', 'y']);
    await h.controller.remote.replaceQueue(items, 0);
    await h.controller.remote.loadCurrent(position: Duration.zero, play: true);
    await h.settle();
    h.calls.clear();

    await h.controller.remote.replaceQueue([
      ...items,
      ...trackItems(['z']),
    ], 0);
    await h.settle();

    expect(h.calls, isNot(contains('stop')));
    expect(h.controller.snapshot.playing, isTrue);
    expect(idsOf(h.controller.snapshot.queue.items), ['x', 'y', 'z']);
  });

  test('shuffle and repeat are off while a driver is attached and restored '
      'after it detaches', () async {
    final h = ControllerHarness(ids: _ids);
    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    await h.controller.setShuffle(true);
    await h.controller.setRepeat(RepeatMode.all);
    await h.settle();

    h.controller.attachRemoteDriver(_RecordingDriver());
    await h.controller.settled;

    expect(h.controller.snapshot.queue.isShuffled, isFalse);
    expect(h.controller.snapshot.queue.repeat, RepeatMode.off);
    await h.controller.remote.replaceQueue(trackItems(['x', 'y']), 0);
    expect(h.controller.snapshot.queue.isShuffled, isFalse);
    expect(h.controller.snapshot.queue.repeat, RepeatMode.off);

    h.controller.detachRemoteDriver();
    await h.controller.settled;

    expect(h.controller.snapshot.queue.isShuffled, isTrue);
    expect(h.controller.snapshot.queue.repeat, RepeatMode.all);
  });

  test('the snapshot says whether a driver is attached and whether this '
      'device may control playback', () async {
    final h = ControllerHarness(ids: _ids);
    expect(h.controller.snapshot.remoteAttached, isFalse);
    expect(h.controller.snapshot.remoteCanControl, isTrue);

    h.controller.attachRemoteDriver(_RecordingDriver());
    h.controller.setRemoteCanControl(false);
    await h.controller.settled;

    expect(h.controller.snapshot.remoteAttached, isTrue);
    expect(h.controller.snapshot.remoteCanControl, isFalse);

    h.controller.detachRemoteDriver();
    await h.controller.settled;

    expect(h.controller.snapshot.remoteAttached, isFalse);
    expect(h.controller.snapshot.remoteCanControl, isTrue);
  });

  test('after detach commands are applied locally again', () async {
    final h = ControllerHarness(ids: _ids);
    final driver = _RecordingDriver();
    h.controller.attachRemoteDriver(driver);
    await h.controller.remote.replaceQueue(trackItems(['x', 'y']), 0);
    h.controller.detachRemoteDriver();

    await h.controller.next();

    expect(driver.commands, isEmpty);
    expect(h.controller.snapshot.current?.queueItemId, 'y');
  });

  test('restoreQueue puts a queue back paused at its position, '
      'unloaded', () async {
    final h = ControllerHarness(ids: _ids);
    final saved = queueOf(['a', 'b', 'c'], cursor: 1);
    h.controller.attachRemoteDriver(_RecordingDriver());
    await h.controller.remote.replaceQueue(trackItems(['x']), 0);
    await h.controller.remote.loadCurrent(position: Duration.zero, play: true);
    h.controller.detachRemoteDriver();
    h.calls.clear();

    await h.controller.restoreQueue(
      saved,
      position: const Duration(seconds: 7),
    );

    expect(h.calls, ['stop']);
    expect(idsOf(h.controller.snapshot.queue.items), ['a', 'b', 'c']);
    expect(h.controller.snapshot.current?.queueItemId, 'b');
    expect(h.controller.snapshot.playing, isFalse);
    expect(h.controller.snapshot.position, const Duration(seconds: 7));

    await h.controller.play();

    expect(h.calls, contains('load(b, autoPlay: true, at: 0:00:07.000000)'));
  });

  test('the queue persistence writes nothing while a driver is '
      'attached', () async {
    final db = StateDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final clock = FakeClock();
    final persistence = QueuePersistence(dao: QueueDao(db), clock: clock);
    final h = ControllerHarness(
      ids: _ids,
      clock: clock,
      persistence: persistence,
    );
    await h.controller.restore();
    await h.controller.playItems(trackItems(['a', 'b']));
    await persistence.flush();

    h.controller.attachRemoteDriver(_RecordingDriver());
    await h.controller.remote.replaceQueue(trackItems(['x', 'y', 'z']), 2);
    await h.controller.remote.loadCurrent(position: Duration.zero, play: true);
    await persistence.flush();

    final stored = await QueuePersistence(
      dao: QueueDao(db),
      clock: clock,
    ).load();
    expect(idsOf(stored!.queue.items), ['a', 'b']);
  });
}
