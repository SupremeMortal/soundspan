// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/realtime/clock_sync.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/features/listen_together/data/listen_together_repository.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/listen_together_controller.dart';

import '../../core/playback/controller/controller_harness.dart';
import '../../core/playback/queue/queue_test_items.dart';
import '../../helpers/fake_api.dart';

/// A [SocketLease] of a [FakeSocket].
final class FakeLease implements SocketLease {
  /// A lease of [_socket] for [reason].
  new(this._socket, this.reason);

  final FakeSocket _socket;
  bool _released = false;

  @override
  final String reason;

  @override
  void release() {
    if (_released) return;
    _released = true;
    _socket.leases--;
    _socket.log.add('release');
  }
}

/// A [SocketClient] that connects on the first lease, records every
/// command in [log], answers each with [answer] and lets a test push
/// server events.
final class FakeSocket implements SocketClient {
  /// Every lease and command, as `acquire`, `join-group:g1`,
  /// `playback:play`, `playback:seek@1500#v3`, `playback:set-track#2`,
  /// `queue:add[pb-a,pb-b]`, `queue:remove#1`, `queue:reorder 0>2`,
  /// `ready`, `playback-failed:1`.
  final List<String> log = [];

  /// How many leases are held.
  int leases = 0;

  /// The answer to `join-group`.
  Ack joinAck = const Ack(ok: true);

  /// Whether `leave-group` fails.
  bool leaveFails = false;

  /// The server clock minus the test's monotonic clock.
  int offsetMs = 100000;

  /// The monotonic clock [ping] reads.
  MonotonicClock? clock;

  /// Answers every `playback` and `queue` command; an ok ack by default.
  Future<bool> Function(String command) answer = (_) async => true;

  /// Called when `join-group` arrives, before it is answered.
  void Function()? onJoin;

  final StreamController<SocketConnectionState> _states =
      StreamController<SocketConnectionState>.broadcast();

  /// Server `reconnected` notices.
  final StreamController<void> reconnects = StreamController<void>.broadcast(
    sync: true,
  );

  /// Server `group:state` events.
  final StreamController<GroupSnapshot> states =
      StreamController<GroupSnapshot>.broadcast(sync: true);

  /// Server `group:playback-delta` events.
  final StreamController<PlaybackDelta> playbackDeltas =
      StreamController<PlaybackDelta>.broadcast(sync: true);

  /// Server `group:queue-delta` events.
  final StreamController<QueueDelta> queueDeltas =
      StreamController<QueueDelta>.broadcast(sync: true);

  /// Server `group:waiting` events.
  final StreamController<WaitingEvent> waits =
      StreamController<WaitingEvent>.broadcast(sync: true);

  /// Server `group:play-at` events.
  final StreamController<PlayAtEvent> playAts =
      StreamController<PlayAtEvent>.broadcast(sync: true);

  /// Server member events.
  final StreamController<MemberEvent> memberEvents =
      StreamController<MemberEvent>.broadcast(sync: true);

  /// Server `group:ended` and `group:membership-revoked` events.
  final StreamController<GroupEnded> ends =
      StreamController<GroupEnded>.broadcast(sync: true);

  @override
  SocketConnectionState connectionState = SocketConnectionState.disconnected;

  @override
  bool Function() keepAliveInBackground = () => false;

  @override
  Stream<SocketConnectionState> get connectionStates => _states.stream;

  @override
  Stream<void> get reconnected => reconnects.stream;

  @override
  Stream<GroupSnapshot> get groupState => states.stream;

  @override
  Stream<PlaybackDelta> get playbackDelta => playbackDeltas.stream;

  @override
  Stream<QueueDelta> get queueDelta => queueDeltas.stream;

  @override
  Stream<WaitingEvent> get waiting => waits.stream;

  @override
  Stream<PlayAtEvent> get playAt => playAts.stream;

  @override
  Stream<MemberEvent> get members => memberEvents.stream;

  @override
  Stream<GroupEnded> get ended => ends.stream;

  @override
  SocketLease acquire(String reason) {
    leases++;
    log.add('acquire');
    if (connectionState != SocketConnectionState.connected) {
      scheduleMicrotask(() {
        connectionState = SocketConnectionState.connected;
        _states.add(connectionState);
      });
    }
    return FakeLease(this, reason);
  }

  @override
  Future<Ack> joinGroup(String groupId) async {
    log.add('join-group:$groupId');
    onJoin?.call();
    return joinAck;
  }

  @override
  Future<Ack> leaveGroup() async {
    log.add('leave-group');
    if (leaveFails) throw const SocketNotConnected('leave-group');
    return const Ack(ok: true);
  }

  @override
  Future<int> ping() async => (clock?.nowMs() ?? 0) + offsetMs;

  @override
  Future<Ack> playback(
    PlaybackAction action, {
    int? positionMs,
    int? index,
    int? stateVersion,
  }) async {
    final command = [
      'playback:${action.wireName}',
      if (positionMs != null) '@$positionMs',
      if (stateVersion != null) '#v$stateVersion',
      if (index != null) '#$index',
    ].join();
    log.add(command);
    return Ack(ok: await answer(command));
  }

  @override
  Future<QueueAck> queue(
    QueueAction action, {
    List<PlaybackRef>? tracks,
    int? index,
    int? fromIndex,
    int? toIndex,
  }) async {
    final command = [
      'queue:${action.wireName}',
      if (tracks != null) '[${tracks.map((t) => t.playbackId).join(',')}]',
      if (index != null) '#$index',
      if (fromIndex != null) ' $fromIndex>$toIndex',
    ].join();
    log.add(command);
    return QueueAck(ok: await answer(command));
  }

  @override
  Future<Ack> ready() async {
    log.add('ready');
    return const Ack(ok: true);
  }

  @override
  Future<Ack> playbackFailed(int queueIndex) async {
    log.add('playback-failed:$queueIndex');
    return const Ack(ok: true);
  }

  /// The commands sent after joining: [log] without leases and joins.
  List<String> get commands => [
    for (final entry in log)
      if (entry != 'acquire' &&
          entry != 'release' &&
          !entry.startsWith('join-group') &&
          entry != 'leave-group')
        entry,
  ];

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A timer of [FakeTime].
final class _FakeTimer implements Timer {
  new(this._time, this.dueMs, this.period, this.callback);

  final FakeTime _time;
  int dueMs;
  final Duration? period;
  final void Function(Timer timer) callback;
  bool _active = true;
  int _tick = 0;

  @override
  void cancel() {
    _active = false;
    _time._timers.remove(this);
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;

  void _fire() {
    _tick++;
    if (period case final period?) {
      dueMs += period.inMilliseconds;
    } else {
      _active = false;
      _time._timers.remove(this);
    }
    callback(this);
  }
}

/// A [MonotonicClock] whose time and timers move only when a test moves
/// them.
final class FakeTime implements MonotonicClock {
  int _nowMs = 1000;
  final List<_FakeTimer> _timers = [];

  @override
  int nowMs() => _nowMs;

  /// A one-shot timer of [duration].
  Timer timer(Duration duration, void Function() callback) {
    final timer = _FakeTimer(
      this,
      _nowMs + duration.inMilliseconds,
      null,
      (_) => callback(),
    );
    _timers.add(timer);
    return timer;
  }

  /// A periodic timer of [period].
  Timer periodic(Duration period, void Function(Timer timer) callback) {
    final timer = _FakeTimer(
      this,
      _nowMs + period.inMilliseconds,
      period,
      callback,
    );
    _timers.add(timer);
    return timer;
  }

  /// Moves the time forward by [duration], firing each timer that falls
  /// due in order and letting what it started run.
  Future<void> advance(Duration duration) async {
    final end = _nowMs + duration.inMilliseconds;
    while (true) {
      _FakeTimer? next;
      for (final timer in _timers) {
        if (timer.dueMs <= end && (next == null || timer.dueMs < next.dueMs)) {
          next = timer;
        }
      }
      if (next == null) break;
      _nowMs = next.dueMs;
      next._fire();
      await pumpEventQueue();
    }
    _nowMs = end;
    await pumpEventQueue();
  }
}

/// A controller of the user `me` over a [ControllerHarness], a
/// [FakeSocket] and fake time.
final class ListenTogetherRig {
  /// Creates the rig.
  new() {
    socket.clock = time;
    controller = ListenTogetherController(
      playback: h.controller,
      socket: socket,
      repository: ListenTogetherRepository(api),
      userId: 'me',
      clockSync: ClockSync(
        ping: socket.ping,
        clock: time,
        delay: (_) async {},
        periodic: (_, _) => Timer(const Duration(days: 1), () {}),
      ),
      clock: time,
      timer: time.timer,
      periodic: time.periodic,
    );
    addTearDown(controller.dispose);
    controller.state.listen(states.add);
  }

  /// The playback controller and its fakes.
  final ControllerHarness h = ControllerHarness(playAny: true);

  /// The socket.
  final FakeSocket socket = FakeSocket();

  /// The REST API.
  final FakeListenTogetherClient api = FakeApi().listenTogether;

  /// The monotonic clock and timers of the controller.
  final FakeTime time = FakeTime();

  /// The controller under test.
  late final ListenTogetherController controller;

  /// Every state emitted.
  final List<ListenTogetherState> states = [];

  /// The server clock now, in milliseconds.
  int get serverNow => time.nowMs() + socket.offsetMs;

  /// Plays a, b, c from the start for three seconds.
  Future<void> playLocal() async {
    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    await h.play(const Duration(seconds: 3));
  }

  /// Joins the group the API answers; with [host] this user is its host.
  Future<void> join({bool host = false}) async {
    if (host) api.group = listenGroupJson(hostUserId: 'me');
    await controller.joinByCode('ABC123');
    await h.settle();
  }

  /// Pushes [event] from the server and lets it apply.
  Future<void> push(void Function(FakeSocket socket) event) async {
    event(socket);
    await h.settle();
    await h.controller.settled;
    await h.settle();
  }
}

/// A `group:state` snapshot of a group hosted by [hostUserId] over the
/// queue [ids] (each with playback id `pb-<id>`, or none when listed in
/// [placeholders]).
GroupSnapshot groupState({
  required int serverTime,
  List<String> ids = const ['a', 'b', 'c'],
  Set<String> placeholders = const {},
  int currentIndex = 0,
  String syncState = 'paused',
  bool? isPlaying,
  int positionMs = 0,
  int stateVersion = 1,
  String hostUserId = 'host',
  List<String> memberIds = const ['host', 'me'],
  String groupType = 'host-follower',
}) {
  final json = listenGroupJson(
    hostUserId: hostUserId,
    memberIds: memberIds,
    groupType: groupType,
    queue: [
      for (final id in ids) (id, placeholders.contains(id) ? null : 'pb-$id'),
    ],
    currentIndex: currentIndex,
    isPlaying: isPlaying ?? syncState == 'playing',
    positionMs: positionMs,
    serverTime: serverTime,
    stateVersion: stateVersion,
  );
  json['syncState'] = syncState;
  return GroupSnapshot.fromJson(json);
}

/// The entries of a queue of [ids], as in [groupState].
List<SocketQueueEntry> groupEntries(List<String> ids) =>
    groupState(ids: ids, serverTime: 0).playback.queue;

/// The queue entry id of [id] at [index] of a group queue.
String groupItem(int index, String id) => 'lt-$index-pb-$id';

/// The engine call loading the group entry [id] at [index] paused at
/// [atMs].
String loadPaused(int index, String id, int atMs) =>
    'load(${groupItem(index, id)}, autoPlay: false, '
    'at: ${Duration(milliseconds: atMs)})';
