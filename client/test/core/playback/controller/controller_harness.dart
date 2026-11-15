// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

import '../../../helpers/fake_clock.dart';

/// The length of every scripted test source.
const trackLength = Duration(seconds: 10);

/// The stream address the [FakeResolver] gives the entry [queueItemId].
Uri uriOf(String queueItemId) => Uri.parse('https://t.example/$queueItemId');

/// A [PlayerEngine] that records every call made to it and forwards it to
/// a [FakeEngine].
class RecordingEngine implements PlayerEngine {
  /// Wraps [fake].
  new(this.fake);

  /// The engine calls are forwarded to.
  final FakeEngine fake;

  /// Every call, as `load(a, autoPlay: true, at: 0:00:00.000000)`,
  /// `setNext(b)`, `setNext(null)`, `play`, `pause`, `seek(…)`, `stop`,
  /// `setVolume(…)`, `dispose`.
  final List<String> calls = [];

  @override
  Stream<EngineState> get state => fake.state;

  @override
  Stream<EngineEvent> get events => fake.events;

  @override
  Future<void> load(
    EngineSource current, {
    EngineSource? next,
    bool autoPlay = true,
  }) {
    calls.add(
      'load(${current.queueItemId}, autoPlay: $autoPlay, '
      'at: ${current.startAt})',
    );
    return fake.load(current, next: next, autoPlay: autoPlay);
  }

  @override
  Future<void> setNext(EngineSource? next) {
    calls.add('setNext(${next?.queueItemId})');
    return fake.setNext(next);
  }

  @override
  Future<void> play() {
    calls.add('play');
    return fake.play();
  }

  @override
  Future<void> pause() {
    calls.add('pause');
    return fake.pause();
  }

  @override
  Future<void> seek(Duration position) {
    calls.add('seek($position)');
    return fake.seek(position);
  }

  @override
  Future<void> stop() {
    calls.add('stop');
    return fake.stop();
  }

  @override
  Future<void> setVolume(double linear) {
    calls.add('setVolume($linear)');
    return fake.setVolume(linear);
  }

  @override
  Future<void> setSpeed(double speed) {
    calls.add('setSpeed($speed)');
    return fake.setSpeed(speed);
  }

  @override
  Future<void> dispose() {
    calls.add('dispose');
    return fake.dispose();
  }
}

/// A [SourceResolver] that turns an entry into [uriOf] its id, without a
/// server.
class FakeResolver implements SourceResolver {
  /// Entries that throw [NotPlayable].
  final Set<String> unplayable = {};

  /// Entries whose next resolution waits for the completer; each gate is
  /// used once.
  final Map<String, Completer<void>> gates = {};

  /// Every entry resolved, in order.
  final List<String> resolved = [];

  @override
  Future<EngineSource> resolve(
    QueueItem item, {
    Duration startAt = Duration.zero,
  }) async {
    final id = item.queueItemId;
    resolved.add(id);
    if (gates.remove(id) case final gate?) await gate.future;
    if (unplayable.contains(id)) throw NotPlayable(id);
    return EngineSource(queueItemId: id, uri: uriOf(id), startAt: startAt);
  }
}

/// A controller over a [RecordingEngine] whose sources are scripted for the
/// given ids, with a [FakeResolver] and, unless another is given, a
/// [FakeClock].
class ControllerHarness {
  /// Creates the harness; [reducer] defaults to a plain one.
  new({
    List<String> ids = const ['a', 'b', 'c', 'd'],
    QueueReducer reducer = const QueueReducer(),
    Clock? clock,
  }) : clock = clock ?? FakeClock() {
    for (final id in ids) {
      fake.sources[uriOf(id)] = const FakeSource(duration: trackLength);
    }
    controller = PlaybackController(
      engine: engine,
      resolver: resolver,
      clock: this.clock,
      reducer: reducer,
    );
    controller.snapshots.listen(snapshots.add);
    controller.notices.listen(notices.add);
  }

  /// The engine behind [engine].
  final FakeEngine fake = FakeEngine();

  /// The engine the controller drives.
  late final RecordingEngine engine = RecordingEngine(fake);

  /// The resolver the controller uses.
  final FakeResolver resolver = FakeResolver();

  /// The clock the controller reads.
  final Clock clock;

  /// The controller under test.
  late final PlaybackController controller;

  /// Every snapshot the controller emitted.
  final List<PlaybackSnapshot> snapshots = [];

  /// Every notice the controller emitted.
  final List<PlaybackNotice> notices = [];

  /// The engine calls, without the volume calls.
  List<String> get calls => engine.calls;

  /// Lets [d] of playback pass on the engine and the clock, then lets the
  /// controller handle what happened.
  Future<void> play(Duration d) async {
    var left = d;
    const step = FakeEngine.positionInterval;
    while (left > Duration.zero) {
      final move = left < step ? left : step;
      fake.advance(move);
      if (clock case final FakeClock fakeClock) fakeClock.advance(move);
      left -= move;
      await pumpEventQueue();
    }
  }

  /// Lets every pending microtask and event run.
  Future<void> settle() => pumpEventQueue();
}
