// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

/// A clock that only moves forward, in milliseconds from an arbitrary
/// start; device wall-clock changes do not move it (doc 08, Clock
/// Synchronisation).
abstract interface class MonotonicClock {
  /// Milliseconds since this clock's start.
  int nowMs();
}

/// The production [MonotonicClock], over a running [Stopwatch].
final class StopwatchMonotonicClock implements MonotonicClock {
  /// Starts the clock.
  new() {
    _stopwatch.start();
  }

  final Stopwatch _stopwatch = Stopwatch();

  @override
  int nowMs() => _stopwatch.elapsedMilliseconds;
}

/// One `lt-ping` measurement: the round trip and the offset it implies.
typedef ClockSample = ({int rttMs, int offsetMs});

/// The sample of a ping sent at [t0] and answered at [t1] (both
/// [MonotonicClock] readings) with the server clock [serverTime]: the
/// server read its clock half a round trip before [t1], so
/// `offset = (serverTime + rtt / 2) − t1`.
ClockSample clockSample({
  required int t0,
  required int t1,
  required int serverTime,
}) {
  final rtt = t1 - t0;
  return (rttMs: rtt, offsetMs: (serverTime + rtt / 2 - t1).round());
}

/// The offset of the sample with the smallest round trip; null when
/// [samples] is empty.
int? bestOffset(Iterable<ClockSample> samples) {
  ClockSample? best;
  for (final sample in samples) {
    if (best == null || sample.rttMs < best.rttMs) best = sample;
  }
  return best?.offsetMs;
}

/// Creates a periodic timer; [Timer.periodic] outside tests.
typedef PeriodicTimerFactory = Timer Function(
  Duration period,
  void Function(Timer timer) callback,
);

/// Keeps the offset between a [MonotonicClock] and the server clock while
/// in a Listen Together group (doc 08, Clock Synchronisation).
///
/// A round is [pingsPerRound] pings, [pingSpacing] apart; the sample with
/// the smallest round trip sets the offset. A ping that fails or times out
/// is skipped; when every ping of a round fails the previous offset stays.
/// [start] runs a round at once, every [resyncInterval] after, and on each
/// value of its `reconnected` stream.
class ClockSync {
  /// Measures with [_ping] (`SocketClient.ping`) against [_clock].
  new({
    required this._ping,
    required this._clock,
    Future<void> Function(Duration delay)? delay,
    PeriodicTimerFactory? periodic,
  }) : _delay = delay ?? Future<void>.delayed,
       _periodic = periodic ?? Timer.periodic;

  /// How many pings one round sends.
  static const int pingsPerRound = 5;

  /// The pause between the pings of a round.
  static const Duration pingSpacing = Duration(milliseconds: 200);

  /// How often a round runs while in a group.
  static const Duration resyncInterval = Duration(seconds: 30);

  final Future<int> Function() _ping;
  final MonotonicClock _clock;
  final Future<void> Function(Duration delay) _delay;
  final PeriodicTimerFactory _periodic;

  int? _offsetMs;
  Timer? _timer;
  StreamSubscription<void>? _reconnects;
  Future<void>? _round;

  /// The server clock minus the monotonic clock, in milliseconds; null
  /// before the first round with an answered ping.
  int? get offsetMs => _offsetMs;

  /// The server clock now: the monotonic clock plus the offset (zero
  /// before the first measurement).
  int serverNow() => _clock.nowMs() + (_offsetMs ?? 0);

  /// Runs one round; a round already running is shared.
  Future<void> sync() => _round ??= _runRound().whenComplete(() {
    _round = null;
  });

  Future<void> _runRound() async {
    final samples = <ClockSample>[];
    for (var i = 0; i < pingsPerRound; i++) {
      if (i > 0) await _delay(pingSpacing);
      final t0 = _clock.nowMs();
      try {
        final serverTime = await _ping();
        samples.add(
          clockSample(t0: t0, t1: _clock.nowMs(), serverTime: serverTime),
        );
      } on Object {
        // A ping that fails or times out is skipped.
        continue;
      }
    }
    _offsetMs = bestOffset(samples) ?? _offsetMs;
  }

  /// Runs a round now, then every [resyncInterval] and on every value of
  /// [reconnected], until [stop].
  void start(Stream<void> reconnected) {
    stop();
    unawaited(sync());
    _timer = _periodic(resyncInterval, (_) => unawaited(sync()));
    _reconnects = reconnected.listen((_) => unawaited(sync()));
  }

  /// Stops the periodic and reconnect rounds; the offset is kept.
  void stop() {
    _timer?.cancel();
    _timer = null;
    unawaited(_reconnects?.cancel());
    _reconnects = null;
  }
}
