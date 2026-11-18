// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/realtime/presence_controller.dart';
import 'package:soundspan/core/realtime/presence_repository.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_api.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';

/// A [SocketLease] of a [_FakeSocket].
final class _Lease implements SocketLease {
  new(this._socket, this.reason);

  final _FakeSocket _socket;
  bool _released = false;

  @override
  final String reason;

  @override
  void release() {
    if (_released) return;
    _released = true;
    _socket.leases--;
  }
}

/// A [SocketClient] that counts leases and lets a test push presence and
/// reconnection events.
final class _FakeSocket implements SocketClient {
  int leases = 0;

  final StreamController<PresenceUpdated> presence =
      StreamController<PresenceUpdated>.broadcast(sync: true);

  final StreamController<void> reconnects = StreamController<void>.broadcast(
    sync: true,
  );

  @override
  Stream<PresenceUpdated> get presenceUpdated => presence.stream;

  @override
  Stream<void> get reconnected => reconnects.stream;

  @override
  SocketLease acquire(String reason) {
    leases++;
    return _Lease(this, reason);
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final class _Rig {
  new() {
    server.users.add(onlineUserJson('a', displayName: 'Ana'));
    controller = PresenceController(
      repository: PresenceRepository(server, currentUserId: 'me'),
      socket: socket,
      lifecycle: lifecycle.stream,
      reachability: reachability,
      clock: clock,
    );
  }

  final FakeSocialClient server = FakeApi().social;
  final _FakeSocket socket = _FakeSocket();
  final StreamController<SocketAppLifecycle> lifecycle =
      StreamController<SocketAppLifecycle>.broadcast(sync: true);
  final FakeReachability reachability = FakeReachability();
  final FakeClock clock = FakeClock();
  late final PresenceController controller;

  void elapse(FakeAsync async, Duration duration) {
    clock.advance(duration);
    async.elapse(duration);
  }
}

void main() {
  test('before the first open no request is made and no lease is held, '
      'even after 60 s', () {
    fakeAsync((async) {
      final rig = _Rig()..elapse(async, const Duration(seconds: 60));

      expect(rig.server.calls, isEmpty);
      expect(rig.socket.leases, 0);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('first open sends a heartbeat at once, then one every 25 s', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();
      expect(rig.server.heartbeats, 1);

      rig.elapse(async, const Duration(seconds: 24));
      expect(rig.server.heartbeats, 1);
      rig.elapse(async, const Duration(seconds: 1));
      expect(rig.server.heartbeats, 2);
      rig.elapse(async, const Duration(seconds: 50));
      expect(rig.server.heartbeats, 4);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('background stops the heartbeat; foreground sends one at once and '
      'resumes the cadence', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();
      rig.lifecycle.add(SocketAppLifecycle.background);
      rig.elapse(async, const Duration(seconds: 100));
      expect(rig.server.heartbeats, 1);

      rig.lifecycle.add(SocketAppLifecycle.foreground);
      async.flushMicrotasks();
      expect(rig.server.heartbeats, 2);
      rig.elapse(async, const Duration(seconds: 25));
      expect(rig.server.heartbeats, 3);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('offline stops it; online resumes it', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();
      rig.reachability.set(Reachability.noNetwork);
      rig.elapse(async, const Duration(seconds: 100));
      expect(rig.server.heartbeats, 1);

      rig.reachability.set(Reachability.online);
      async.flushMicrotasks();
      expect(rig.server.heartbeats, 2);
      rig.elapse(async, const Duration(seconds: 25));
      expect(rig.server.heartbeats, 3);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('the heartbeat continues after close; the socket lease does not', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();
      expect(rig.socket.leases, 1);

      rig.controller.close();
      expect(rig.socket.leases, 0);
      rig.elapse(async, const Duration(seconds: 50));
      expect(rig.server.heartbeats, 3);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('open fetches the roster, without the current user', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.server.users.add(onlineUserJson('me'));
      final states = <PresenceState>[];
      rig.controller.states.listen(states.add);

      rig.controller.open();
      async.flushMicrotasks();

      expect(states.first.loading, isTrue);
      expect(rig.controller.state.loading, isFalse);
      expect(rig.controller.state.roster?.users.map((u) => u.id), ['a']);
      expect(rig.controller.state.failed, isFalse);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('five presenceUpdated events within 1 s cause one refetch; an event '
      'after close causes none', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();
      expect(rig.server.onlineCalls, 1);

      for (var i = 0; i < 5; i++) {
        rig.socket.presence.add(PresenceUpdated(userId: 'u$i'));
        rig.elapse(async, const Duration(milliseconds: 150));
      }
      expect(rig.server.onlineCalls, 1);
      rig.elapse(async, const Duration(seconds: 1));
      expect(rig.server.onlineCalls, 2);

      rig.socket.presence.add(const PresenceUpdated(userId: 'u9'));
      rig.controller.close();
      rig.socket.presence.add(const PresenceUpdated(userId: 'u9'));
      rig.elapse(async, const Duration(seconds: 2));
      expect(rig.server.onlineCalls, 2);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('re-opening shows the last roster at once and fetches again', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();
      rig.controller.close();

      rig.server.gate = Completer<void>();
      rig.controller.open();
      expect(rig.controller.state.roster?.users.map((u) => u.id), ['a']);
      expect(rig.server.onlineCalls, 2);
      rig.server.gate!.complete();
      async.flushMicrotasks();
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('reconnected refetches', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();

      rig.socket.reconnects.add(null);
      async.flushMicrotasks();
      expect(rig.server.onlineCalls, 2);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('a refetch failure keeps the previous roster and flags the error', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();
      rig.server.failures['online'] = const api.ServerError(status: 500);

      rig.socket.reconnects.add(null);
      async.flushMicrotasks();

      expect(rig.controller.state.roster?.users.map((u) => u.id), ['a']);
      expect(rig.controller.state.failed, isTrue);
      expect(rig.controller.state.error, isA<api.ServerError>());

      rig.server.failures.remove('online');
      unawaited(rig.controller.retry());
      async.flushMicrotasks();
      expect(rig.controller.state.failed, isFalse);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  test('a failed heartbeat is not shown and the cadence goes on', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.server.failures['heartbeat'] = const api.ServerError(status: 503);
      rig.controller.open();
      async.flushMicrotasks();
      rig.elapse(async, const Duration(seconds: 25));

      expect(rig.server.heartbeats, 2);
      expect(rig.controller.state.failed, isFalse);
      unawaited(rig.controller.dispose());
      async.flushMicrotasks();
    });
  });

  for (final (name, error) in [
    ('FeatureDisabled', const api.FeatureDisabled(status: 404)),
    ('Forbidden', const api.Forbidden(status: 403)),
  ]) {
    test('$name on the heartbeat stops it for the session', () {
      fakeAsync((async) {
        final rig = _Rig();
        rig.server.failures['heartbeat'] = error;
        rig.controller.open();
        async.flushMicrotasks();
        rig.elapse(async, const Duration(seconds: 100));
        rig.lifecycle
          ..add(SocketAppLifecycle.background)
          ..add(SocketAppLifecycle.foreground);
        rig.reachability
          ..set(Reachability.noNetwork)
          ..set(Reachability.online);
        rig.controller
          ..close()
          ..open();
        rig.elapse(async, const Duration(seconds: 100));

        expect(rig.server.heartbeats, 1);
        unawaited(rig.controller.dispose());
        async.flushMicrotasks();
      });
    });
  }

  test('dispose cancels every timer and releases the lease', () {
    fakeAsync((async) {
      final rig = _Rig();
      rig.controller.open();
      async.flushMicrotasks();
      rig.socket.presence.add(const PresenceUpdated(userId: 'u1'));

      unawaited(rig.controller.dispose());
      async.flushMicrotasks();

      expect(async.pendingTimers, isEmpty);
      expect(rig.socket.leases, 0);
    });
  });
}
