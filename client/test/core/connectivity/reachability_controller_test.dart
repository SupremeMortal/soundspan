// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/connectivity/reachability_controller_impl.dart';
import 'package:soundspan/platform/connectivity/connectivity.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

const ConnectivityInfo _wifi = ConnectivityInfo(
  hasInterface: true,
  type: ConnectivityType.wifi,
);
const ConnectivityInfo _cellular = ConnectivityInfo(
  hasInterface: true,
  type: ConnectivityType.cellular,
);

/// A [ConnectivitySource] a test drives with [emit].
class _FakeConnectivity implements ConnectivitySource {
  new(this.initial);

  final ConnectivityInfo initial;
  final StreamController<ConnectivityInfo> _changes =
      StreamController<ConnectivityInfo>.broadcast();

  void emit(ConnectivityInfo info) => _changes.add(info);

  @override
  Stream<ConnectivityInfo> watch() async* {
    yield initial;
    yield* _changes.stream;
  }
}

/// A [Clock] that reads the elapsed time of a [FakeAsync] zone.
class _AsyncClock implements Clock {
  new(this._async);

  final FakeAsync _async;
  static final DateTime _start = DateTime.utc(2025);

  @override
  DateTime now() => _start.add(_async.elapsed);
}

/// The server behind the probe: it answers while [up], and records the
/// elapsed time of every probe.
class _Server {
  new(this._async);

  final FakeAsync _async;
  bool up = false;
  final List<Duration> probes = [];

  Future<void> probe() async {
    probes.add(_async.elapsed);
    if (!up) throw const Offline();
  }
}

/// One test's controller with its inputs.
class _Rig {
  new(this.async, {ConnectivityInfo initial = _wifi, bool bind = true})
    : connectivity = _FakeConnectivity(initial) {
    server = _Server(async);
    controller = ReachabilityControllerImpl(
      connectivity: connectivity,
      clock: _AsyncClock(async),
    );
    controller.changes.listen(emitted.add);
    if (bind) {
      controller.bind(
        ReachabilityBinding(
          probe: server.probe,
          forcedOffline: forced.stream,
          onReturnedOnline: () => returnedOnline++,
        ),
      );
    }
    unawaited(controller.start());
    async.flushMicrotasks();
  }

  final FakeAsync async;
  final _FakeConnectivity connectivity;
  late final _Server server;
  late final ReachabilityControllerImpl controller;
  final StreamController<bool> forced = StreamController<bool>.broadcast();
  final List<Reachability> emitted = [];
  int returnedOnline = 0;

  Reachability get state => controller.current;

  void fail() => controller.reportCallOutcome(success: false);

  void succeed() => controller.reportCallOutcome(success: true);

  void elapse(Duration duration) => async.elapse(duration);

  void setForced(bool value) {
    forced.add(value);
    async.flushMicrotasks();
  }

  void emit(ConnectivityInfo info) {
    connectivity.emit(info);
    async.flushMicrotasks();
  }

  /// Two failures 10 s apart.
  void goUnreachable() {
    fail();
    elapse(const Duration(seconds: 10));
    fail();
    async.flushMicrotasks();
  }
}

const Duration _s = Duration(seconds: 1);

void main() {
  group('initial state', () {
    test('starts online with an interface', () {
      fakeAsync((async) {
        final rig = _Rig(async);
        expect(rig.state, Reachability.online);
        expect(rig.controller.isOnline, isTrue);
      });
    });

    test('starts noNetwork without an interface', () {
      fakeAsync((async) {
        final rig = _Rig(async, initial: ConnectivityInfo.none);
        expect(rig.state, Reachability.noNetwork);
        expect(rig.server.probes, isEmpty);
      });
    });

    test('starts forcedOffline when the setting is set', () {
      fakeAsync((async) {
        final rig = _Rig(async)..setForced(true);
        expect(rig.state, Reachability.forcedOffline);
        expect(rig.controller.isOnline, isFalse);
      });
    });
  });

  group('call outcomes', () {
    test('one failure stays online', () {
      fakeAsync((async) {
        final rig = _Rig(async)..fail();
        expect(rig.state, Reachability.online);
      });
    });

    test('two failures 10 s apart become serverUnreachable', () {
      fakeAsync((async) {
        final rig = _Rig(async)..goUnreachable();
        expect(rig.state, Reachability.serverUnreachable);
      });
    });

    test('two failures 31 s apart stay online', () {
      fakeAsync((async) {
        final rig = _Rig(async)
          ..fail()
          ..elapse(_s * 31)
          ..fail();
        expect(rig.state, Reachability.online);
      });
    });

    test('failure, success, failure stays online', () {
      fakeAsync((async) {
        final rig = _Rig(async)
          ..fail()
          ..elapse(_s * 5)
          ..succeed()
          ..elapse(_s * 5)
          ..fail();
        expect(rig.state, Reachability.online);
      });
    });

    test('an ordinary API success while serverUnreachable is online', () {
      fakeAsync((async) {
        final rig = _Rig(async)
          ..goUnreachable()
          ..succeed();
        expect(rig.state, Reachability.online);
        final probes = rig.server.probes.length;
        rig.elapse(_s * 300);
        expect(rig.server.probes, hasLength(probes));
      });
    });
  });

  group('probe', () {
    test('runs 5, 15, 30, 60 and 60 s apart after serverUnreachable', () {
      fakeAsync((async) {
        final rig = _Rig(async)..goUnreachable();
        final entered = async.elapsed;
        rig.elapse(_s * 170);
        expect(
          rig.server.probes.map((at) => (at - entered).inSeconds).toList(),
          [5, 20, 50, 110, 170],
        );
        expect(rig.state, Reachability.serverUnreachable);
      });
    });

    test('a probe success is online and the schedule stops', () {
      fakeAsync((async) {
        final rig = _Rig(async)..goUnreachable();
        rig.server.up = true;
        rig.elapse(_s * 5);
        expect(rig.state, Reachability.online);
        rig.elapse(_s * 300);
        expect(rig.server.probes, hasLength(1));
      });
    });

    test('a connectivity change while serverUnreachable probes at once', () {
      fakeAsync((async) {
        final rig = _Rig(async)
          ..goUnreachable()
          ..emit(_cellular);
        expect(rig.server.probes, hasLength(1));
        expect(rig.state, Reachability.serverUnreachable);
      });
    });

    test('a connectivity change while online does not probe', () {
      fakeAsync((async) {
        final rig = _Rig(async)..emit(_cellular);
        expect(rig.server.probes, isEmpty);
        expect(rig.state, Reachability.online);
      });
    });

    test('probeNow probes outside the schedule', () {
      fakeAsync((async) {
        final rig = _Rig(async)..goUnreachable();
        unawaited(rig.controller.probeNow());
        async.flushMicrotasks();
        expect(rig.server.probes, [async.elapsed]);
        rig.server.up = true;
        unawaited(rig.controller.probeNow());
        async.flushMicrotasks();
        expect(rig.server.probes, hasLength(2));
        expect(rig.state, Reachability.online);
      });
    });

    test('without a bound profile nothing is probed', () {
      fakeAsync((async) {
        final rig = _Rig(async, bind: false)
          ..goUnreachable()
          ..elapse(_s * 100);
        expect(rig.server.probes, isEmpty);
      });
    });
  });

  group('interface', () {
    test('lost is noNetwork from any state and probing stops', () {
      fakeAsync((async) {
        final online = _Rig(async)..emit(ConnectivityInfo.none);
        expect(online.state, Reachability.noNetwork);

        final unreachable = _Rig(async)
          ..goUnreachable()
          ..emit(ConnectivityInfo.none);
        expect(unreachable.state, Reachability.noNetwork);
        unreachable.elapse(_s * 300);
        expect(unreachable.server.probes, isEmpty);
      });
    });

    test('back is serverUnreachable, probes at once, then online', () {
      fakeAsync((async) {
        final rig = _Rig(async, initial: ConnectivityInfo.none);
        rig.server.up = true;
        rig.emit(_wifi);
        expect(rig.emitted, [
          Reachability.noNetwork,
          Reachability.serverUnreachable,
          Reachability.online,
        ]);
        expect(rig.server.probes, [async.elapsed]);
      });
    });

    test('back with the server down stays serverUnreachable', () {
      fakeAsync((async) {
        final rig = _Rig(async, initial: ConnectivityInfo.none)..emit(_wifi);
        expect(rig.state, Reachability.serverUnreachable);
        expect(rig.server.probes, hasLength(1));
        rig.elapse(_s * 5);
        expect(rig.server.probes, hasLength(2));
      });
    });

    test('outcomes are ignored without an interface', () {
      fakeAsync((async) {
        final rig = _Rig(async, initial: ConnectivityInfo.none)..succeed();
        expect(rig.state, Reachability.noNetwork);
      });
    });
  });

  group('forced offline', () {
    test('wins over everything and stops probing', () {
      fakeAsync((async) {
        final rig = _Rig(async)
          ..goUnreachable()
          ..setForced(true);
        expect(rig.state, Reachability.forcedOffline);
        rig
          ..emit(_cellular)
          ..emit(ConnectivityInfo.none)
          ..emit(_wifi)
          ..succeed()
          ..elapse(_s * 300);
        expect(rig.state, Reachability.forcedOffline);
        expect(rig.server.probes, isEmpty);
      });
    });

    test('clearing it probes and returns to online', () {
      fakeAsync((async) {
        final rig = _Rig(async)..setForced(true);
        rig.server.up = true;
        rig.setForced(false);
        expect(rig.server.probes, hasLength(1));
        expect(rig.state, Reachability.online);
      });
    });

    test('clearing it without an interface is noNetwork', () {
      fakeAsync((async) {
        final rig = _Rig(async)
          ..setForced(true)
          ..emit(ConnectivityInfo.none)
          ..setForced(false);
        expect(rig.state, Reachability.noNetwork);
        expect(rig.server.probes, isEmpty);
      });
    });
  });

  group('changes', () {
    test('emit each state once per change', () {
      fakeAsync((async) {
        final rig = _Rig(async)
          ..fail()
          ..goUnreachable()
          ..elapse(_s * 5)
          ..fail()
          ..succeed()
          ..succeed()
          ..emit(_cellular);
        expect(rig.emitted, [
          Reachability.serverUnreachable,
          Reachability.online,
        ]);
      });
    });

    test('returning to online triggers the due capability refresh once', () {
      fakeAsync((async) {
        final rig = _Rig(async)
          ..succeed()
          ..goUnreachable();
        expect(rig.returnedOnline, 0);
        rig
          ..succeed()
          ..succeed();
        expect(rig.returnedOnline, 1);
      });
    });

    test('binding another profile starts it afresh', () {
      fakeAsync((async) {
        final rig = _Rig(async)..goUnreachable();
        final other = _Server(async)..up = false;
        rig.controller.bind(
          ReachabilityBinding(
            probe: other.probe,
            forcedOffline: const Stream<bool>.empty(),
          ),
        );
        async.flushMicrotasks();
        expect(rig.state, Reachability.online);
        rig.fail();
        expect(rig.state, Reachability.online);
        rig.elapse(_s * 300);
        expect(rig.server.probes, isEmpty);
        expect(other.probes, isEmpty);
      });
    });
  });

  test('connectionType follows the last reported interface', () {
    fakeAsync((async) {
      final rig = _Rig(async);
      expect(rig.controller.connectionType, ConnectionType.wifi);
      rig.emit(_cellular);
      expect(rig.controller.connectionType, ConnectionType.cellular);
      rig.emit(
        const ConnectivityInfo(
          hasInterface: true,
          type: ConnectivityType.other,
        ),
      );
      expect(rig.controller.connectionType, ConnectionType.other);
      rig.emit(ConnectivityInfo.none);
      expect(rig.controller.connectionType, ConnectionType.none);
    });
  });

  test(
    'connectionTypeChanges emits each change of the interface kind once',
    () {
      fakeAsync((async) {
        final rig = _Rig(async);
        final types = <ConnectionType>[];
        rig.controller.connectionTypeChanges.listen(types.add);
        rig
          ..emit(_cellular)
          ..emit(_cellular)
          ..emit(ConnectivityInfo.none);
        async.flushMicrotasks();
        expect(types, [ConnectionType.cellular, ConnectionType.none]);
      });
    },
  );

  test('dispose cancels the pending probe', () {
    fakeAsync((async) {
      final rig = _Rig(async)..goUnreachable();
      rig.controller.dispose();
      rig.elapse(_s * 300);
      expect(rig.server.probes, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });
}
