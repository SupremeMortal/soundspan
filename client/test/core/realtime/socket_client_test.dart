// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/session/sign_out_participant.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/realtime/realtime_providers.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/socket_test_server.dart';
import '../profile/profile_harness.dart';

/// Timers that fire only when the test moves [clock].
class _ManualTimers {
  final FakeClock clock = FakeClock();
  final List<_ManualTimer> _timers = [];

  Timer call(Duration duration, void Function() callback) {
    final timer = _ManualTimer(clock.now().add(duration), callback);
    _timers.add(timer);
    return timer;
  }

  /// Moves the clock by [duration] and fires every timer that came due.
  void advance(Duration duration) {
    clock.advance(duration);
    final due = _timers
        .where((timer) => timer.isActive && !timer.due.isAfter(clock.now()))
        .toList();
    for (final timer in due) {
      timer.fire();
    }
    _timers.removeWhere((timer) => !timer.isActive);
  }
}

class _ManualTimer implements Timer {
  new(this.due, this._callback);

  final DateTime due;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

const _jwt = JwtCredentials(accessToken: 'access-1', refreshToken: 'r-1');
const _key = ApiKeyCredentials(apiKey: 'key-1');

/// Waits until [check] holds, polling; fails after [timeout].
Future<void> _eventually(
  FutureOr<bool> Function() check, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await check()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// A client wired to the test server with recording fakes.
class _Harness {
  new(this.server, {this._credential = _jwt});

  final SocketTestServer server;
  Credentials _credential;
  final _ManualTimers timers = _ManualTimers();
  final List<UnauthenticatedReason> unauthenticated = [];
  final List<String> logs = [];
  int refreshes = 0;
  int confirmations = 0;
  Future<void> Function() confirm = () async {};
  final StreamController<SocketAppLifecycle> lifecycle =
      StreamController<SocketAppLifecycle>.broadcast();
  final StreamController<bool> online = StreamController<bool>.broadcast();
  bool keepAlive = false;
  late SocketClient client;

  SocketClient build({bool backgroundDisconnect = true}) {
    client = SocketClient(
      baseUrl: server.baseUrl,
      credentials: () async => _credential,
      refreshCredentials: () async {
        refreshes++;
        return _credential = JwtCredentials(
          accessToken: 'access-${refreshes + 1}',
          refreshToken: 'r-${refreshes + 1}',
        );
      },
      onUnauthenticated: unauthenticated.add,
      confirmCredential: () {
        confirmations++;
        return confirm();
      },
      lifecycle: lifecycle.stream,
      online: online.stream,
      backgroundDisconnect: backgroundDisconnect,
      keepAliveInBackground: () => keepAlive,
      timers: timers.call,
      log: (level, message, [error]) => logs.add('${level.name}: $message'),
    );
    addTearDown(client.dispose);
    return client;
  }

  Future<void> connected() => _eventually(
    () => client.connectionState == SocketConnectionState.connected,
  );

  Future<void> disconnected() => _eventually(
    () => client.connectionState == SocketConnectionState.disconnected,
  );

  /// Connects with a lease and returns it.
  Future<SocketLease> connect() async {
    build();
    final lease = client.acquire('test');
    await connected();
    return lease;
  }

  Future<List<Map<String, Object?>>> eventsNamed(String name) async => [
    for (final event in await server.events())
      if (event['event'] == name) event,
  ];
}

void main() {
  late SocketTestServer server;

  setUpAll(() async {
    server = await SocketTestServer.start();
  });

  tearDownAll(() => server.close());

  setUp(() => server.reset());

  group('handshake', () {
    test('a JWT session sends only the token', () async {
      await _Harness(server).connect();

      expect(await server.handshakes(), [
        {'token': 'access-1'},
      ]);
    });

    test('an API key session sends only the key', () async {
      await _Harness(server, credential: _key).connect();

      expect(await server.handshakes(), [
        {'apiKey': 'key-1'},
      ]);
    });

    test('the path keeps a reverse-proxy prefix', () async {
      final prefixed = await SocketTestServer.start(pathPrefix: '/music');
      addTearDown(prefixed.close);
      expect(prefixed.baseUrl.path, '/music');

      await _Harness(prefixed).connect();

      expect(await prefixed.handshakes(), hasLength(1));
      expect(
        SocketClient.socketPath(Uri.parse('https://h.example/music/')),
        '/music/socket.io/listen-together',
      );
      expect(
        SocketClient.namespaceUrl(Uri.parse('https://h.example/music')),
        'https://h.example/listen-together',
      );
    });

    test('Token expired refreshes once and the next handshake carries the '
        'new token', () async {
      await server.rejectHandshake('Token expired');
      final h = _Harness(server);

      await h.connect();

      expect(h.refreshes, 1);
      expect(await server.handshakes(), [
        {'token': 'access-1'},
        {'token': 'access-2'},
      ]);
      expect(h.unauthenticated, isEmpty);
    });

    test('a second rejection signs out and stops', () async {
      await server.rejectHandshake('Invalid token');
      await server.rejectHandshake('Token expired');
      final h = _Harness(server)..build();
      h.client.acquire('test');

      await _eventually(() => h.unauthenticated.isNotEmpty);
      await h.disconnected();
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(h.refreshes, 1);
      expect(h.unauthenticated, [UnauthenticatedReason.sessionExpired]);
      expect(await server.handshakes(), hasLength(2));
    });

    test('User not found signs out at once and stops', () async {
      await server.rejectHandshake('User not found');
      final h = _Harness(server)..build();
      h.client.acquire('test');

      await _eventually(() => h.unauthenticated.isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(h.refreshes, 0);
      expect(h.unauthenticated, [UnauthenticatedReason.sessionExpired]);
      expect(await server.handshakes(), hasLength(1));
      expect(h.client.connectionState, SocketConnectionState.disconnected);
    });

    test('Invalid API key signs out with keyRejected', () async {
      await server.rejectHandshake('Invalid API key');
      final h = _Harness(server, credential: _key)..build();
      h.client.acquire('test');

      await _eventually(() => h.unauthenticated.isNotEmpty);

      expect(h.unauthenticated, [UnauthenticatedReason.keyRejected]);
    });

    test(
      'Authentication required is logged as a client bug and stops',
      () async {
        await server.rejectHandshake('Authentication required');
        final h = _Harness(server)..build();
        h.client.acquire('test');

        await _eventually(
          () => h.logs.any((line) => line.startsWith('severe')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1500));

        expect(h.unauthenticated, isEmpty);
        expect(await server.handshakes(), hasLength(1));
      },
    );
  });

  group('server disconnect of an API-key socket', () {
    test('auth/me 401 signs out with keyRejected', () async {
      final h = _Harness(server, credential: _key)
        ..confirm = () async => throw const Unauthenticated(status: 401);
      await h.connect();

      await server.disconnectAll();

      await _eventually(() => h.unauthenticated.isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(h.confirmations, 1);
      expect(h.unauthenticated, [UnauthenticatedReason.keyRejected]);
      expect(await server.handshakes(), hasLength(1));
    });

    test('auth/me 200 reconnects', () async {
      final h = _Harness(server, credential: _key);
      await h.connect();

      await server.disconnectAll();

      await _eventually(() async => (await server.handshakes()).length == 2);
      await h.connected();
      expect(h.confirmations, 1);
      expect(h.unauthenticated, isEmpty);
    });
  });

  group('events', () {
    const entry = {
      'id': 't1',
      'playbackId': 'pb-1',
      'title': 'Song',
      'duration': 201.5,
      'artist': {'id': 'ar1', 'name': 'Artist'},
      'album': {
        'id': 'al1',
        'title': 'Album',
        'coverArt': 'c1',
        'albumLoudnessLufs': -9.5,
      },
      'loudnessLufs': -8.25,
      'truePeakDb': -0.5,
      'streamSource': 'tidal',
      'tidalTrackId': 7,
    };
    const snapshot = {
      'id': 'g1',
      'name': 'Group',
      'joinCode': 'ABC123',
      'groupType': 'host-follower',
      'visibility': 'private',
      'isActive': true,
      'hostUserId': 'u1',
      'syncState': 'a-new-state',
      'readyUserIds': <String>[],
      'playback': {
        'queue': [
          entry,
          {
            'id': 't2',
            'title': 'Remote',
            'duration': 3,
            'artist': {'id': 'ar2', 'name': 'Other'},
            'album': {'id': 'al2', 'title': 'Other', 'coverArt': null},
          },
        ],
        'currentIndex': 0,
        'isPlaying': true,
        'positionMs': 1200,
        'serverTime': 1700000000000,
        'stateVersion': 4,
        'trackId': 't1',
      },
      'members': [
        {
          'userId': 'u1',
          'username': 'host',
          'isHost': true,
          'joinedAt': '2026-01-01T00:00:00.000Z',
          'isConnected': true,
        },
      ],
    };

    late _Harness h;

    setUp(() async {
      h = _Harness(server);
      await h.connect();
    });

    Future<T> next<T>(Stream<T> stream, String event, Object? payload) async {
      final value = stream.first;
      await server.emit(event, payload);
      return await value.timeout(const Duration(seconds: 5));
    }

    test(
      'group:state decodes, ignoring extra keys and unknown enums',
      () async {
        final state = await next(h.client.groupState, 'group:state', snapshot);

        expect(state.id, 'g1');
        expect(state.groupType, GroupType.hostFollower);
        expect(state.syncState, GroupSyncState.unknown);
        expect(state.playback.stateVersion, 4);
        expect(state.playback.queue.first.playbackId, 'pb-1');
        expect(state.playback.queue.first.isPlayable, isTrue);
        expect(state.playback.queue.first.loudnessLufs, -8.25);
        expect(state.playback.queue.first.album.albumLoudnessLufs, -9.5);
        expect(state.playback.queue.last.isPlayable, isFalse);
        expect(state.members.single.joinedAt, DateTime.utc(2026));
        expect(state.playback.queue.first.toJson().keys, isNot(contains('id')));
      },
    );

    test('an unknown groupType decodes to unknown', () async {
      final state = await next(h.client.groupState, 'group:state', {
        ...snapshot,
        'groupType': 'something-else',
      });

      expect(state.groupType, GroupType.unknown);
    });

    test('group:playback-delta', () async {
      final delta = await next(h.client.playbackDelta, 'group:playback-delta', {
        'isPlaying': false,
        'positionMs': 5000,
        'serverTime': 1700000001000,
        'stateVersion': 5,
        'currentIndex': 1,
        'trackId': null,
      });

      expect(
        delta,
        const PlaybackDelta(
          isPlaying: false,
          positionMs: 5000,
          serverTime: 1700000001000,
          stateVersion: 5,
          currentIndex: 1,
        ),
      );
    });

    test('group:queue-delta', () async {
      final delta = await next(h.client.queueDelta, 'group:queue-delta', {
        'queue': [entry],
        'currentIndex': 0,
        'stateVersion': 6,
        'trackId': 't1',
      });

      expect(delta.queue.single.title, 'Song');
      expect(delta.stateVersion, 6);
    });

    test('group:waiting', () async {
      final waiting = await next(h.client.waiting, 'group:waiting', {
        'currentIndex': 2,
        'trackId': null,
      });

      expect(waiting.currentIndex, 2);
    });

    test('group:play-at', () async {
      final playAt = await next(h.client.playAt, 'group:play-at', {
        'positionMs': 0,
        'serverTime': 1700000002000,
        'stateVersion': 7,
      });

      expect(playAt.serverTime, 1700000002000);
    });

    test('the three member events arrive on one stream', () async {
      final events = h.client.members.take(3).toList();
      await server.emit('group:member-joined', {
        'userId': 'u2',
        'username': 'guest',
        'groupId': 'g1',
        'membershipVersion': 2,
      });
      await server.emit('group:member-presence', {
        'userId': 'u2',
        'isConnected': false,
        'groupId': 'g1',
      });
      await server.emit('group:member-left', {
        'userId': 'u1',
        'username': 'host',
        'newHostUserId': 'u2',
        'groupId': 'g1',
      });

      expect(await events.timeout(const Duration(seconds: 5)), [
        const MemberEvent.joined(
          groupId: 'g1',
          userId: 'u2',
          username: 'guest',
        ),
        const MemberEvent.presence(
          groupId: 'g1',
          userId: 'u2',
          isConnected: false,
        ),
        const MemberEvent.left(
          groupId: 'g1',
          userId: 'u1',
          username: 'host',
          newHostUserId: 'u2',
        ),
      ]);
    });

    test(
      'group:ended and group:membership-revoked arrive on one stream',
      () async {
        final events = h.client.ended.take(2).toList();
        await server.emit('group:ended', {'reason': 'host ended'});
        await server.emit('group:membership-revoked', {'groupId': 'g1'});

        expect(await events.timeout(const Duration(seconds: 5)), [
          const GroupEnded.ended(reason: 'host ended'),
          const GroupEnded.revoked(groupId: 'g1'),
        ]);
      },
    );

    test('social:presence-updated', () async {
      final update = await next(
        h.client.presenceUpdated,
        'social:presence-updated',
        {'userId': 'u3', 'reason': 'heartbeat', 'timestampMs': 1},
      );

      expect(update.userId, 'u3');
    });

    test('a malformed payload is logged and dropped', () async {
      final delivered = <PlaybackDelta>[];
      final subscription = h.client.playbackDelta.listen(delivered.add);
      addTearDown(subscription.cancel);
      final next = h.client.playbackDelta.first;

      await server.emit('group:playback-delta', {'isPlaying': 'yes'});
      await server.emit('group:playback-delta', {
        'isPlaying': true,
        'positionMs': 1,
        'serverTime': 2,
        'stateVersion': 3,
        'currentIndex': 0,
      });
      await next.timeout(const Duration(seconds: 5));

      expect(delivered, hasLength(1));
      expect(
        h.logs,
        contains('warning: Dropped a malformed group:playback-delta'),
      );
    });
  });

  group('emitters', () {
    late _Harness h;

    setUp(() async {
      h = _Harness(server);
      await h.connect();
    });

    Future<Map<String, Object?>> lastEvent(String name) async =>
        (await h.eventsNamed(name)).last;

    test('each emitter sends its event and payload and completes from the '
        'ack', () async {
      expect(await h.client.joinGroup('g1'), const Ack(ok: true));
      expect((await lastEvent('join-group'))['payload'], {'groupId': 'g1'});
      expect(h.client.groupId, 'g1');

      expect(
        await h.client.playback(
          PlaybackAction.seek,
          positionMs: 1000,
          stateVersion: 3,
        ),
        const Ack(ok: true),
      );
      expect((await lastEvent('playback'))['payload'], {
        'action': 'seek',
        'positionMs': 1000,
        'stateVersion': 3,
      });

      await h.client.playback(PlaybackAction.setTrack, index: 2);
      expect((await lastEvent('playback'))['payload'], {
        'action': 'set-track',
        'index': 2,
      });

      await h.client.queue(QueueAction.reorder, fromIndex: 1, toIndex: 0);
      expect((await lastEvent('queue'))['payload'], {
        'action': 'reorder',
        'fromIndex': 1,
        'toIndex': 0,
      });

      expect(await h.client.ready(), const Ack(ok: true));
      expect((await lastEvent('ready'))['payload'], isNull);

      expect(await h.client.playbackFailed(3), const Ack(ok: true));
      expect((await lastEvent('track:playback-failed'))['payload'], {
        'queueIndex': 3,
      });

      final before = DateTime.now().millisecondsSinceEpoch;
      final serverTime = await h.client.ping();
      expect(serverTime, greaterThanOrEqualTo(before - 5000));
      expect(await h.eventsNamed('lt-ping'), hasLength(1));

      expect(await h.client.leaveGroup(), const Ack(ok: true));
      expect((await lastEvent('leave-group'))['payload'], isNull);
      expect(h.client.groupId, isNull);
    });

    test('queue add sends only playbackId and metadata per track', () async {
      await server.scriptAcks('queue', [
        {'ok': true, 'acceptedCount': 1, 'skippedCount': 1, 'truncated': true},
      ]);

      final ack = await h.client.queue(
        QueueAction.add,
        tracks: const [
          PlaybackRef(
            playbackId: 'pb-1',
            metadata: PlaybackMetadata(
              title: 'Song',
              artist: 'Artist',
              album: 'Album',
              durationSec: 200,
            ),
            additionalProperties: {'trackId': 'legacy'},
          ),
          PlaybackRef(playbackId: 'pb-2'),
        ],
      );

      expect(
        ack,
        const QueueAck(
          ok: true,
          acceptedCount: 1,
          skippedCount: 1,
          truncated: true,
        ),
      );
      expect((await lastEvent('queue'))['payload'], {
        'action': 'add',
        'tracks': [
          {
            'playbackId': 'pb-1',
            'metadata': {
              'album': 'Album',
              'artist': 'Artist',
              'durationSec': 200,
              'title': 'Song',
            },
          },
          {'playbackId': 'pb-2'},
        ],
      });
    });

    test('no ack within 5 s fails with SocketAckTimeout', () async {
      await server.scriptAcks('ready', [
        {'drop': true},
      ]);

      final result = h.client.ready();
      await _eventually(() async => (await h.eventsNamed('ready')).isNotEmpty);
      h.timers.advance(const Duration(seconds: 4));
      var settled = false;
      unawaited(result.then((_) => settled = true, onError: (_) {}));
      await Future<void>.delayed(Duration.zero);
      expect(settled, isFalse);
      h.timers.advance(const Duration(seconds: 1));

      await expectLater(result, throwsA(isA<SocketAckTimeout>()));
    });

    test('an error ack maps to SocketCommandException', () async {
      await server.scriptAcks('playback', [
        {'error': 'Not in a group'},
      ]);

      await expectLater(
        h.client.playback(PlaybackAction.play),
        throwsA(
          isA<SocketCommandException>()
              .having((e) => e.message, 'message', 'Not in a group')
              .having((e) => e.retryable, 'retryable', isFalse),
        ),
      );
      expect(await h.eventsNamed('playback'), hasLength(1));
    });

    test('a retryable conflict is sent once more after retryAfterMs', () async {
      const conflict = {
        'error': 'Busy',
        'code': 'CONFLICT',
        'transient': true,
        'retryable': true,
        'retryAfterMs': 400,
      };
      await server.scriptAcks('playback', [conflict]);

      final result = h.client.playback(PlaybackAction.pause);
      await _eventually(
        () async => (await h.eventsNamed('playback')).length == 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      h.timers.advance(const Duration(milliseconds: 399));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(await h.eventsNamed('playback'), hasLength(1));
      h.timers.advance(const Duration(milliseconds: 1));

      expect(await result, const Ack(ok: true));
      expect(await h.eventsNamed('playback'), hasLength(2));
    });

    test('a second retryable conflict is thrown', () async {
      const conflict = {
        'error': 'Busy',
        'code': 'CONFLICT',
        'transient': true,
        'retryable': true,
      };
      await server.scriptAcks('playback', [conflict, conflict]);

      final result = h.client.playback(PlaybackAction.pause);
      await _eventually(
        () async => (await h.eventsNamed('playback')).length == 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      h.timers.advance(SocketClient.defaultRetryAfter);

      await expectLater(
        result,
        throwsA(
          isA<SocketCommandException>()
              .having((e) => e.code, 'code', 'CONFLICT')
              .having((e) => e.transient, 'transient', isTrue),
        ),
      );
      expect(await h.eventsNamed('playback'), hasLength(2));
    });

    test('emitting while disconnected fails at once', () async {
      final idle = _Harness(server)..build();

      await expectLater(
        idle.client.ready(),
        throwsA(isA<SocketNotConnected>()),
      );
    });
  });

  group('leases', () {
    test('nothing connects before the first acquire; the last release '
        'disconnects', () async {
      final h = _Harness(server)..build();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(await server.handshakes(), isEmpty);
      expect(h.client.connectionState, SocketConnectionState.disconnected);

      final a = h.client.acquire('presence');
      final b = h.client.acquire('group');
      await h.connected();
      a.release();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(h.client.connectionState, SocketConnectionState.connected);
      b.release();

      await h.disconnected();
      await _eventually(() async => (await server.sockets()).isEmpty);
    });
  });

  group('lifecycle', () {
    test('30 s in the background without a group disconnects', () async {
      final h = _Harness(server);
      await h.connect();

      h.lifecycle.add(SocketAppLifecycle.background);
      await Future<void>.delayed(Duration.zero);
      h.timers.advance(const Duration(seconds: 29));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(h.client.connectionState, SocketConnectionState.connected);
      h.timers.advance(const Duration(seconds: 1));

      await h.disconnected();
      await _eventually(() async => (await server.sockets()).isEmpty);
    });

    test('in a group and playing it stays connected', () async {
      final h = _Harness(server);
      await h.connect();
      await h.client.joinGroup('g1');
      h.keepAlive = true;

      h.lifecycle.add(SocketAppLifecycle.background);
      await Future<void>.delayed(Duration.zero);
      h.timers.advance(const Duration(seconds: 60));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(h.client.connectionState, SocketConnectionState.connected);
      expect(await server.sockets(), hasLength(1));
    });

    test('a keep-alive predicate set after creation is the one '
        'asked', () async {
      final h = _Harness(server);
      await h.connect();
      await h.client.joinGroup('g1');
      h.client.keepAliveInBackground = () => true;

      h.lifecycle.add(SocketAppLifecycle.background);
      await Future<void>.delayed(Duration.zero);
      h.timers.advance(const Duration(seconds: 60));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(h.keepAlive, isFalse);
      expect(h.client.connectionState, SocketConnectionState.connected);
    });

    test('desktop and web ignore the background rule', () async {
      final h = _Harness(server)..build(backgroundDisconnect: false);
      h.client.acquire('test');
      await h.connected();

      h.lifecycle.add(SocketAppLifecycle.background);
      await Future<void>.delayed(Duration.zero);
      h.timers.advance(const Duration(seconds: 60));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(h.client.connectionState, SocketConnectionState.connected);
    });

    test('resume reconnects, joins the group again and publishes '
        'reconnected', () async {
      final h = _Harness(server);
      await h.connect();
      await h.client.joinGroup('g1');
      h.lifecycle.add(SocketAppLifecycle.background);
      await Future<void>.delayed(Duration.zero);
      h.timers.advance(SocketClient.backgroundGrace);
      await h.disconnected();
      final reconnected = h.client.reconnected.first;

      h.lifecycle.add(SocketAppLifecycle.foreground);

      await reconnected.timeout(const Duration(seconds: 10));
      await h.connected();
      final joins = await h.eventsNamed('join-group');
      expect(joins, hasLength(2));
      expect(joins.last['payload'], {'groupId': 'g1'});
      expect(await server.handshakes(), hasLength(2));
    });

    test(
      'reachability offline pauses reconnection; online resumes it',
      () async {
        final h = _Harness(server);
        await h.connect();

        h.online.add(false);
        await h.disconnected();
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        expect(await server.handshakes(), hasLength(1));
        expect(await server.sockets(), isEmpty);

        h.online.add(true);

        await h.connected();
        expect(await server.handshakes(), hasLength(2));
      },
    );
  });

  group('dispose and sign-out', () {
    test('dispose closes the socket and every stream', () async {
      final h = _Harness(server);
      await h.connect();
      final streams = <Stream<Object?>>[
        h.client.connectionStates,
        h.client.groupState,
        h.client.playbackDelta,
        h.client.queueDelta,
        h.client.waiting,
        h.client.playAt,
        h.client.members,
        h.client.ended,
        h.client.presenceUpdated,
        h.client.reconnected,
      ];

      await h.client.dispose();

      for (final stream in streams) {
        await expectLater(stream, emitsDone);
      }
      await _eventually(() async => (await server.sockets()).isEmpty);
      expect(() => h.client.acquire('late'), throwsStateError);
    });

    test('onSignOut leaves the group, disconnects, releases every lease and '
        'nothing reconnects', () async {
      final h = _Harness(server);
      await h.connect();
      h.client.acquire('second');
      await h.client.joinGroup('g1');

      await SocketSignOutParticipant(h.client)
          .onSignOut(removeDownloads: false);

      expect(await h.eventsNamed('leave-group'), hasLength(1));
      expect(h.client.leaseCount, 0);
      expect(h.client.connectionState, SocketConnectionState.disconnected);
      h.timers.advance(const Duration(seconds: 60));
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      expect(await server.handshakes(), hasLength(1));
      expect(await server.sockets(), isEmpty);
    });

    test('onSignOut completes when the socket was never opened', () async {
      final h = _Harness(server)..build();

      await SocketSignOutParticipant(h.client)
          .onSignOut(removeDownloads: false);

      expect(await server.handshakes(), isEmpty);
    });

    test('a failing leave-group ack does not make onSignOut throw', () async {
      final h = _Harness(server);
      await h.connect();
      await h.client.joinGroup('g1');
      await server.scriptAcks('leave-group', [
        {'error': 'Failed to leave group'},
      ]);

      await SocketSignOutParticipant(h.client)
          .onSignOut(removeDownloads: false);

      expect(h.client.connectionState, SocketConnectionState.disconnected);
    });

    test('a leave-group without an ack is cut off by the 2 s budget', () async {
      final h = _Harness(server);
      await h.connect();
      await h.client.joinGroup('g1');
      await server.scriptAcks('leave-group', [
        {'drop': true},
      ]);

      final signOut = SocketSignOutParticipant(h.client)
          .onSignOut(removeDownloads: false);
      await _eventually(
        () async => (await h.eventsNamed('leave-group')).isNotEmpty,
      );
      h.timers.advance(SocketClient.signOutLeaveBudget);

      await signOut.timeout(const Duration(seconds: 5));
      expect(h.client.connectionState, SocketConnectionState.disconnected);
    });

    test('beforeRemove does nothing', () async {
      final h = _Harness(server)..build();

      await SocketSignOutParticipant(h.client).beforeRemove();

      expect(h.client.connectionState, SocketConnectionState.disconnected);
    });
  });

  group('providers', () {
    test('a profile switch disposes the socket client; the sign-out '
        'participant wraps it', () async {
      final harness = await ProfileHarness.create(
        overrides: [
          socketLifecycleProvider.overrideWithValue(
            const Stream<SocketAppLifecycle>.empty(),
          ),
          reachabilityProvider.overrideWithValue(FakeReachability()),
          deviceInfoProvider.overrideWithValue(
            const DeviceInfo(osLabel: 'Test', isMobile: false),
          ),
        ],
      );
      final runtime = harness.root.read(profileRuntimeProvider);
      addTearDown(runtime.dispose);

      await runtime.switchTo(harness.a);
      final a = runtime.container!;
      final client = a.read(socketClientProvider);
      expect(a.read(socketClientProvider), same(client));
      expect(a.read(signOutParticipantsProvider), [
        isA<PlaybackSignOutParticipant>(),
        isA<SocketSignOutParticipant>(),
      ]);
      expect(client.connectionState, SocketConnectionState.disconnected);

      await runtime.switchTo(harness.b);

      await expectLater(client.connectionStates, emitsDone);
      expect(() => client.acquire('late'), throwsStateError);
      expect(
        runtime.container!.read(socketClientProvider),
        isNot(same(client)),
      );
    });
  });
}
