// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/realtime/clock_sync.dart';

import '../../helpers/fake_clock.dart';

/// A monotonic clock a test moves by hand.
class _FakeMonotonic implements MonotonicClock {
  int now = 0;

  @override
  int nowMs() => now;
}

/// A server whose clock is [offset] ms ahead of [_clock]; each ping takes
/// the next `(up, down)` delays, or fails when they are null.
class _Server {
  new(this._clock, this.offset);

  final _FakeMonotonic _clock;
  int offset;
  final List<(int, int)?> delays = [];
  int pings = 0;

  Future<int> ping() async {
    pings++;
    final delay = delays.isEmpty ? (10, 10) : delays.removeAt(0);
    if (delay == null) throw TimeoutException('lt-ping');
    _clock.now += delay.$1;
    final serverTime = _clock.now + offset;
    _clock.now += delay.$2;
    return serverTime;
  }
}

ClockSync _sync(_FakeMonotonic clock, _Server server) => ClockSync(
  ping: server.ping,
  clock: clock,
  delay: (d) async => clock.now += d.inMilliseconds,
);

void main() {
  test('the sample with the smallest round trip sets the offset', () async {
    final clock = _FakeMonotonic();
    final server = _Server(clock, 5000)
      ..delays.addAll([(80, 20), (40, 40), (5, 5), (100, 0), (30, 90)]);
    final sync = _sync(clock, server);

    await sync.sync();

    expect(server.pings, 5);
    expect(sync.offsetMs, 5000);
    expect(sync.serverNow(), clock.now + 5000);
  });

  test('offset maths for a known offset with asymmetric delays', () {
    // Sent at 0, read by the server at 30 (server clock 1030), answered at
    // 40: the estimate is off by half the asymmetry, (30 − 10) / 2.
    final sample = clockSample(t0: 0, t1: 40, serverTime: 1030);

    expect(sample.rttMs, 40);
    expect(sample.offsetMs, 1010);
    expect(
      bestOffset([sample, clockSample(t0: 100, t1: 110, serverTime: 1105)]),
      1000,
    );
    expect(bestOffset(const []), isNull);
  });

  test(
    'serverNow reads only the monotonic clock, not the wall clock',
    () async {
      final clock = _FakeMonotonic();
      final wall = FakeClock();
      final server = _Server(clock, 2000);
      final sync = _sync(clock, server);
      await sync.sync();
      final before = sync.serverNow();

      wall
        ..advance(const Duration(hours: 3))
        ..set(DateTime.utc(1999));

      expect(sync.serverNow(), before);
      clock.now += 250;
      expect(sync.serverNow(), before + 250);
    },
  );

  test('when every ping fails the previous offset is kept', () async {
    final clock = _FakeMonotonic();
    final server = _Server(clock, 700);
    final sync = _sync(clock, server);
    await sync.sync();
    expect(sync.offsetMs, 700);

    server
      ..offset = 9000
      ..delays.addAll([null, null, null, null, null]);
    await sync.sync();

    expect(server.pings, 10);
    expect(sync.offsetMs, 700);
  });

  test('a failed ping is skipped and the others still count', () async {
    final clock = _FakeMonotonic();
    final server = _Server(clock, 300)
      ..delays.addAll([null, (50, 50), null, (20, 20), null]);
    final sync = _sync(clock, server);

    await sync.sync();

    expect(sync.offsetMs, 300);
  });

  test('a round runs at start, every 30 s and on each reconnect, until '
      'stop', () {
    fakeAsync((async) {
      final clock = _FakeMonotonic();
      final server = _Server(clock, 100);
      final reconnected = StreamController<void>.broadcast(sync: true);
      final sync = ClockSync(ping: server.ping, clock: clock)
        ..start(reconnected.stream);
      async.elapse(const Duration(seconds: 1));
      expect(server.pings, 5);

      server.offset = 400;
      async.elapse(const Duration(seconds: 28));
      expect(server.pings, 5);
      async.elapse(const Duration(seconds: 2));
      expect(server.pings, 10);
      expect(sync.offsetMs, 400);

      server.offset = 800;
      reconnected.add(null);
      async.elapse(const Duration(seconds: 1));
      expect(server.pings, 15);
      expect(sync.offsetMs, 800);

      sync.stop();
      reconnected.add(null);
      async.elapse(const Duration(minutes: 2));
      expect(server.pings, 15);
    });
  });
}
