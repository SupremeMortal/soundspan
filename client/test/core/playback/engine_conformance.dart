// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The engine conformance suite: one parameterized set of cases that every
/// `PlayerEngine` passes, run against `FakeEngine` in unit tests and against
/// the real engine of each platform in `integration_test/`.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

/// The named cases of the suite, in the order of doc 06's list followed by
/// the cases that pin the interface.
enum ConformanceCase {
  /// 1. load and play.
  loadAndPlay('load and play'),

  /// 2. pause and resume keep position.
  pauseAndResume('pause and resume keep position'),

  /// 3. seek within the buffered range.
  seekBuffered('seek within the buffered range'),

  /// 4. seek within an unbuffered range.
  seekUnbuffered('seek within an unbuffered range'),

  /// 5. setNext then natural end produces exactly one AdvancedToNext.
  advanceToNext('setNext then natural end produces exactly one AdvancedToNext'),

  /// 6. the transition has no gap larger than the tolerance.
  gapless('the transition has no gap larger than the tolerance'),

  /// 7. setNext(null) then natural end produces Completed.
  clearNextCompletes('setNext(null) then natural end produces Completed'),

  /// 8. replacing next twice before the transition plays only the last one.
  replaceNextTwice(
    'replacing next twice before the transition plays only the last one',
  ),

  /// 9. a 404 source produces Failed(notFound).
  notFound('a 404 source produces Failed(notFound)'),

  /// 10. a 401 source produces Failed(unauthorized).
  unauthorized('a 401 source produces Failed(unauthorized)'),

  /// 11. headers reach the server.
  headers('headers reach the server'),

  /// 12. a local file plays with the network disabled.
  localFileOffline('a local file plays with the network disabled'),

  /// 13. stop then load works.
  stopThenLoad('stop then load works'),

  /// 14. dispose releases the device.
  disposeReleases('dispose releases the device'),

  /// 15. state replays the latest value to a late listener (interface).
  replayLatest('state replays the latest value to a late listener'),

  /// 16. position updates at least four times per second while playing
  /// (interface).
  positionRate('position updates at least four times per second while playing'),

  /// 17. load with startAt starts at that position (interface).
  startAt('load with startAt starts at that position'),

  /// 18. load with autoPlay false is ready and not playing (interface).
  noAutoPlay('load with autoPlay false is ready and not playing');

  new(this.description);

  /// The test name.
  final String description;
}

/// What the suite needs from a platform: engines, sources and a clock.
abstract class EngineHarness {
  /// Creates an engine; the harness disposes the ones the test leaves open.
  PlayerEngine createEngine();

  /// A served tone of [duration] (about 3 s when omitted) that starts at
  /// [startAt], carrying the headers the server expects.
  EngineSource tone(String queueItemId, {Duration? duration, Duration startAt});

  /// A long tone that buffers slowly, for seeking into an unbuffered range.
  EngineSource slowTone(String queueItemId);

  /// A source the server answers with 404.
  EngineSource missing(String queueItemId);

  /// A source the server answers with 401.
  EngineSource forbidden(String queueItemId);

  /// A tone in a local file.
  EngineSource localFile(String queueItemId);

  /// The headers the server saw on the last request for [queueItemId].
  Map<String, String> headersSeenFor(String queueItemId);

  /// Makes the network unreachable for the rest of the test.
  Future<void> disableNetwork();

  /// Lets [d] pass: virtual for the fake, real time for devices.
  Future<void> elapse(Duration d);

  /// The time that has passed since the harness was created: the sum of
  /// [elapse] for the fake, a stopwatch for devices. Stamps state samples.
  Duration get now;

  /// The largest gap allowed at a transition: 20 ms.
  Duration get gapTolerance;

  /// Cases this platform cannot run; empty for `FakeEngine`.
  Set<ConformanceCase> get skipped;

  /// Disposes engines and anything the harness started.
  Future<void> dispose();
}

/// Registers every [ConformanceCase] in a group called [name], each with a
/// fresh harness from [createHarness].
void runEngineConformance(String name, EngineHarness Function() createHarness) {
  group('engine conformance: $name', () {
    late EngineHarness harness;
    late PlayerEngine engine;
    late _Probe probe;

    setUp(() {
      harness = createHarness();
      engine = harness.createEngine();
      probe = _Probe(engine, harness);
    });

    tearDown(() async {
      await probe.cancel();
      await harness.dispose();
    });

    Future<void> waitFor(
      bool Function(EngineState s) predicate, {
      Duration timeout = const Duration(seconds: 10),
      String? reason,
    }) async {
      final deadline = harness.now + timeout;
      while (!predicate(probe.latest)) {
        if (harness.now > deadline) {
          fail(
            'timed out waiting for ${reason ?? 'a state'}; '
            'last state ${probe.latest}',
          );
        }
        await harness.elapse(const Duration(milliseconds: 20));
      }
    }

    bool isPlaying(EngineState s) =>
        s.playing && s.status == EngineStatus.ready;

    void conformance(ConformanceCase c, Future<void> Function() body) {
      test(c.description, () async {
        if (harness.skipped.contains(c)) {
          markTestSkipped('${c.name} is skipped on $name');
          return;
        }
        await body();
      });
    }

    conformance(ConformanceCase.loadAndPlay, () async {
      await engine.load(harness.tone('a'));
      await waitFor(isPlaying, reason: 'playing');
      final start = probe.latest.position;
      await harness.elapse(const Duration(milliseconds: 500));

      expect(probe.latest.currentQueueItemId, 'a');
      expect(probe.latest.status, EngineStatus.ready);
      expect(probe.latest.playing, isTrue);
      expect(probe.latest.position, greaterThan(start));
      expect(probe.events, isEmpty);
    });

    conformance(ConformanceCase.pauseAndResume, () async {
      await engine.load(harness.tone('a'));
      await waitFor(isPlaying, reason: 'playing');
      await harness.elapse(const Duration(milliseconds: 300));
      await engine.pause();
      await waitFor((s) => !s.playing, reason: 'paused');
      final paused = probe.latest.position;
      await harness.elapse(const Duration(milliseconds: 300));

      expect(probe.latest.playing, isFalse);
      expect(
        (probe.latest.position - paused).abs(),
        lessThanOrEqualTo(harness.gapTolerance),
      );

      await engine.play();
      await waitFor(isPlaying, reason: 'playing again');
      await harness.elapse(const Duration(milliseconds: 300));

      expect(probe.latest.position, greaterThan(paused));
      expect(probe.latest.currentQueueItemId, 'a');
    });

    conformance(ConformanceCase.seekBuffered, () async {
      await engine.load(harness.tone('a'));
      const target = Duration(seconds: 1);
      await waitFor(
        (s) => isPlaying(s) && s.bufferedPosition > target,
        reason: 'buffered past ${target.inMilliseconds} ms',
      );
      await engine.seek(target);
      await waitFor(
        (s) => isPlaying(s) && s.position >= target,
        reason: 'playing from the seek target',
      );
      await harness.elapse(const Duration(milliseconds: 200));

      expect(probe.latest.position, greaterThan(target));
      expect(probe.latest.position, lessThan(probe.latest.duration!));
      expect(probe.events, isEmpty);
    });

    conformance(ConformanceCase.seekUnbuffered, () async {
      await engine.load(harness.slowTone('a'));
      await waitFor(
        (s) => isPlaying(s) && s.duration != null,
        reason: 'playing with a duration',
      );
      final target = probe.latest.duration! * 0.8;
      expect(
        probe.latest.bufferedPosition,
        lessThan(target),
        reason: 'the slow tone must not be buffered to the seek target yet',
      );
      await engine.seek(target);
      await waitFor(
        (s) => isPlaying(s) && s.position > target,
        timeout: const Duration(seconds: 20),
        reason: 'playing past the unbuffered seek target',
      );

      expect(probe.latest.currentQueueItemId, 'a');
      expect(probe.events, isEmpty);
    });

    conformance(ConformanceCase.advanceToNext, () async {
      const length = Duration(seconds: 1);
      await engine.load(harness.tone('a', duration: length));
      await engine.setNext(
        harness.tone('b', duration: const Duration(seconds: 3)),
      );
      await waitFor(
        (s) => s.currentQueueItemId == 'b',
        reason: 'the next item to become current',
      );
      await harness.elapse(const Duration(milliseconds: 500));

      expect(probe.events, [const AdvancedToNext('b')]);
      expect(probe.latest.currentQueueItemId, 'b');
      expect(probe.latest.playing, isTrue);
      expect(probe.latest.position, lessThan(const Duration(seconds: 3)));
    });

    conformance(ConformanceCase.gapless, () async {
      const length = Duration(seconds: 1);
      await engine.load(harness.tone('a', duration: length));
      await engine.setNext(harness.tone('b', duration: length));
      await waitFor(
        (s) => s.currentQueueItemId == 'b' && s.position > Duration.zero,
        reason: 'the next item to play',
      );

      final lastA = probe.samples.lastWhere(
        (s) => s.state.currentQueueItemId == 'a',
      );
      final firstB = probe.samples.firstWhere(
        (s) => s.state.currentQueueItemId == 'b',
      );
      final durationA = lastA.state.duration ?? length;
      final wall = firstB.at - lastA.at;
      final played = (durationA - lastA.state.position) + firstB.state.position;
      final gap = (wall - played).abs();

      expect(
        gap,
        lessThanOrEqualTo(harness.gapTolerance),
        reason: 'last a: $lastA, first b: $firstB',
      );
    });

    conformance(ConformanceCase.clearNextCompletes, () async {
      const length = Duration(seconds: 1);
      await engine.load(harness.tone('a', duration: length));
      await engine.setNext(harness.tone('b'));
      await engine.setNext(null);
      await waitFor(
        (s) => s.status == EngineStatus.ended,
        reason: 'the end of the item',
      );
      await harness.elapse(const Duration(milliseconds: 300));

      expect(probe.events, [const Completed('a')]);
      expect(probe.latest.status, EngineStatus.ended);
      expect(probe.latest.playing, isFalse);
      expect(probe.latest.currentQueueItemId, 'a');
      expect(probe.latest.position, probe.latest.duration);
    });

    conformance(ConformanceCase.replaceNextTwice, () async {
      const length = Duration(seconds: 1);
      await engine.load(harness.tone('a', duration: length));
      await engine.setNext(harness.tone('b'));
      await engine.setNext(harness.tone('c'));
      await waitFor(
        (s) => s.currentQueueItemId != 'a',
        reason: 'the transition',
      );
      await harness.elapse(const Duration(milliseconds: 300));

      expect(probe.events, [const AdvancedToNext('c')]);
      expect(probe.latest.currentQueueItemId, 'c');
      expect(
        probe.samples.where((s) => s.state.currentQueueItemId == 'b'),
        isEmpty,
      );
    });

    conformance(ConformanceCase.notFound, () async {
      await engine.load(harness.missing('a'));
      await harness.elapse(const Duration(milliseconds: 100));

      final failure = probe.events.whereType<Failed>().single;
      expect(failure.queueItemId, 'a');
      expect(failure.error.kind, EngineErrorKind.notFound);
      expect(probe.latest.status, EngineStatus.error);
      expect(probe.latest.error?.kind, EngineErrorKind.notFound);
      expect(probe.latest.playing, isFalse);
    });

    conformance(ConformanceCase.unauthorized, () async {
      await engine.load(harness.forbidden('a'));
      await harness.elapse(const Duration(milliseconds: 100));

      final failure = probe.events.whereType<Failed>().single;
      expect(failure.queueItemId, 'a');
      expect(failure.error.kind, EngineErrorKind.unauthorized);
      expect(probe.latest.status, EngineStatus.error);
      expect(probe.latest.error?.kind, EngineErrorKind.unauthorized);
    });

    conformance(ConformanceCase.headers, () async {
      final source = harness.tone('a');
      expect(
        source.headers,
        isNotEmpty,
        reason: 'the harness tone carries headers to check',
      );
      await engine.load(source);
      await waitFor(isPlaying, reason: 'playing');

      final seen = harness
          .headersSeenFor('a')
          .map((k, v) => MapEntry(k.toLowerCase(), v));
      for (final MapEntry(:key, :value) in source.headers.entries) {
        expect(seen[key.toLowerCase()], value, reason: 'header $key');
      }
    });

    conformance(ConformanceCase.localFileOffline, () async {
      await harness.disableNetwork();
      await engine.load(harness.localFile('a'));
      await waitFor(isPlaying, reason: 'playing');
      final start = probe.latest.position;
      await harness.elapse(const Duration(milliseconds: 300));

      expect(probe.latest.position, greaterThan(start));
      expect(probe.events, isEmpty);
    });

    conformance(ConformanceCase.stopThenLoad, () async {
      await engine.load(harness.tone('a'));
      await waitFor(isPlaying, reason: 'playing a');
      await engine.stop();
      await waitFor(
        (s) => s.status == EngineStatus.idle,
        reason: 'idle after stop',
      );

      expect(probe.latest.playing, isFalse);
      expect(probe.latest.currentQueueItemId, isNull);

      await engine.load(harness.tone('b'));
      await waitFor(
        (s) => isPlaying(s) && s.currentQueueItemId == 'b',
        reason: 'playing b',
      );
      final start = probe.latest.position;
      await harness.elapse(const Duration(milliseconds: 300));

      expect(probe.latest.position, greaterThan(start));
    });

    conformance(ConformanceCase.disposeReleases, () async {
      await engine.load(harness.tone('a'));
      await waitFor(isPlaying, reason: 'playing');
      await engine.dispose();
      await harness.elapse(const Duration(milliseconds: 50));

      expect(probe.stateDone, isTrue, reason: 'state stream is closed');
      expect(probe.eventsDone, isTrue, reason: 'events stream is closed');
      await expectLater(engine.play(), throwsStateError);
      await expectLater(engine.load(harness.tone('x')), throwsStateError);

      final second = harness.createEngine();
      final secondProbe = _Probe(second, harness);
      addTearDown(secondProbe.cancel);
      await second.load(harness.tone('b'));
      final deadline = harness.now + const Duration(seconds: 10);
      while (!isPlaying(secondProbe.latest)) {
        if (harness.now > deadline) fail('second engine never played');
        await harness.elapse(const Duration(milliseconds: 20));
      }
      final start = secondProbe.latest.position;
      await harness.elapse(const Duration(milliseconds: 300));

      expect(secondProbe.latest.position, greaterThan(start));
    });

    conformance(ConformanceCase.replayLatest, () async {
      final fresh = await engine.state.first;
      expect(fresh.status, EngineStatus.idle);
      expect(fresh.playing, isFalse);
      expect(fresh.position, Duration.zero);
      expect(fresh.currentQueueItemId, isNull);

      await engine.load(harness.tone('a'));
      await waitFor(isPlaying, reason: 'playing');
      await engine.pause();
      await waitFor((s) => !s.playing, reason: 'paused');
      await harness.elapse(const Duration(milliseconds: 100));

      final late = await engine.state.first;
      expect(late, probe.latest);
      expect(late.currentQueueItemId, 'a');
    });

    conformance(ConformanceCase.positionRate, () async {
      await engine.load(
        harness.tone('a', duration: const Duration(seconds: 5)),
      );
      await waitFor(isPlaying, reason: 'playing');
      final from = probe.samples.length;
      await harness.elapse(const Duration(seconds: 1));

      final positions = probe.samples
          .skip(from)
          .where((s) => isPlaying(s.state))
          .map((s) => s.state.position)
          .toSet();
      expect(positions.length, greaterThanOrEqualTo(4));
    });

    conformance(ConformanceCase.startAt, () async {
      const startAt = Duration(seconds: 1);
      await engine.load(harness.tone('a', startAt: startAt), autoPlay: false);
      await waitFor((s) => s.status == EngineStatus.ready, reason: 'ready');

      expect(
        (probe.latest.position - startAt).abs(),
        lessThanOrEqualTo(harness.gapTolerance),
      );
    });

    conformance(ConformanceCase.noAutoPlay, () async {
      await engine.load(harness.tone('a'), autoPlay: false);
      await waitFor((s) => s.status == EngineStatus.ready, reason: 'ready');
      final position = probe.latest.position;
      await harness.elapse(const Duration(milliseconds: 300));

      expect(probe.latest.status, EngineStatus.ready);
      expect(probe.latest.playing, isFalse);
      expect(
        (probe.latest.position - position).abs(),
        lessThanOrEqualTo(harness.gapTolerance),
      );
    });
  });
}

/// One state value with the harness time it was received at.
final class StateSample {
  /// Creates a sample.
  const new(this.at, this.state);

  /// The harness time at which the value arrived.
  final Duration at;

  /// The value.
  final EngineState state;

  @override
  String toString() => '@${at.inMilliseconds} ms $state';
}

/// Records everything an engine emits, stamped with the harness clock.
final class _Probe {
  new(PlayerEngine engine, EngineHarness harness) {
    _state = engine.state.listen((s) {
      latest = s;
      samples.add(StateSample(harness.now, s));
    }, onDone: () => stateDone = true);
    _events = engine.events.listen(events.add, onDone: () => eventsDone = true);
  }

  late final StreamSubscription<EngineState> _state;
  late final StreamSubscription<EngineEvent> _events;

  final List<StateSample> samples = [];
  final List<EngineEvent> events = [];
  EngineState latest = EngineState.idle;
  bool stateDone = false;
  bool eventsDone = false;

  Future<void> cancel() async {
    await _state.cancel();
    await _events.cancel();
  }
}
