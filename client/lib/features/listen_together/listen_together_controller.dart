// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/remote_playback.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/realtime/clock_sync.dart';
import 'package:soundspan/core/realtime/realtime_providers.dart';
import 'package:soundspan/core/realtime/socket_client.dart'
    hide GroupPlayback, GroupType;
import 'package:soundspan/core/sync/data/playback_metadata.dart';
import 'package:soundspan/features/listen_together/data/group_socket_mapping.dart';
import 'package:soundspan/features/listen_together/data/listen_together_repository.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/group_sync.dart';
import 'package:soundspan/shared/domain/domain.dart';

final AppLogger _log = AppLogger.scope('ListenTogether');

/// The user's own queue, position and playing flag, kept while in a group
/// so leaving can restore them.
typedef SavedLocalQueue = ({QueueState queue, Duration position, bool playing});

/// Creates a one-shot timer; [Timer.new] outside tests.
typedef OneShotTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// The group's playback as last applied: playing or not, at `positionMs`
/// when the server clock read `serverTime`.
typedef _GroupPosition = ({bool isPlaying, int positionMs, int serverTime});

/// What a joined group holds on this device.
final class _Membership {
  new(this.group, this.saved, this.lease);

  /// The group as the server last described it.
  Group group;
  final SavedLocalQueue saved;
  final SocketLease lease;
}

/// Creates, joins and leaves Listen Together groups, attached to the
/// profile's [PlaybackController] as its [RemoteDriver] while in one
/// (doc 08, Listen Together).
///
/// Joining is four steps: REST create or join, save the local queue,
/// `join-group` over the socket, attach. A failing step undoes the earlier
/// ones. Leaving sends `leave-group` (or the REST leave when the socket is
/// down), detaches, and restores the saved queue paused. While in a group
/// the server clock offset is kept by a [ClockSync].
///
/// While attached, the device follows the server (doc 08, Applying State):
/// each server message is applied through [PlaybackController.remote] in
/// arrival order, one older than the last applied `stateVersion` is
/// ignored, and the position is kept within the drift thresholds of
/// [driftCorrectionFor]. Commands from this device go to the server
/// instead of changing playback locally; they are
/// [ListenTogetherActive.pending] until acknowledged.
class ListenTogetherController implements RemoteDriver {
  /// Creates the controller of the user [_userId], driving [_playback] over
  /// [_socket] and [_repository]; [clockSync] defaults to one over
  /// `SocketClient.ping` and a [StopwatchMonotonicClock]. [clock] times
  /// seeks and corrections, and [timer] and [periodic] create the timers
  /// of scheduled starts, acknowledgement waits and drift checks.
  new({
    required this._playback,
    required this._socket,
    required this._repository,
    required this._userId,
    ClockSync? clockSync,
    MonotonicClock? clock,
    OneShotTimerFactory? timer,
    PeriodicTimerFactory? periodic,
  }) : _clock = clock ?? StopwatchMonotonicClock(),
       _timer = timer ?? Timer.new,
       _periodic = periodic ?? Timer.periodic,
       _clockSync =
           clockSync ??
           ClockSync(
             ping: _socket.ping,
             clock: clock ?? StopwatchMonotonicClock(),
           ) {
    _socket.keepAliveInBackground = () =>
        _membership != null && _playback.snapshot.playing;
  }

  /// How long a command waits for its acknowledgement.
  static const Duration commandTimeout = Duration(seconds: 5);

  /// How often the drift is checked while the group plays.
  static const Duration driftCheckInterval = Duration(seconds: 5);

  /// How long after a seek this controller issued no drift is corrected.
  static const Duration seekSettle = Duration(seconds: 1);

  /// At most this many tracks of the local queue start a created group.
  static const int maxInitialTracks = 500;

  /// How long joining waits for the socket to connect.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// How long leaving may take when the profile closes or signs out.
  static const Duration closeLeaveBudget = Duration(seconds: 2);

  final PlaybackController _playback;
  final SocketClient _socket;
  final ListenTogetherRepository _repository;
  final String _userId;
  final ClockSync _clockSync;
  final MonotonicClock _clock;
  final OneShotTimerFactory _timer;
  final PeriodicTimerFactory _periodic;
  final StreamController<ListenTogetherState> _states =
      StreamController<ListenTogetherState>.broadcast(sync: true);

  ListenTogetherState _current = const ListenTogetherIdle();
  _Membership? _membership;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

  /// The server messages of the joined group, applied one after another.
  Future<void> _applyTail = Future<void>.value();
  List<StreamSubscription<Object?>> _subscriptions = const [];

  /// The highest `stateVersion` applied; null before the first.
  int? _version;

  /// Whether the next `group:state` is applied whatever its version: the
  /// first one after a join or a reconnection.
  bool _acceptNextState = true;

  _GroupPosition? _last;
  Timer? _scheduledStart;
  Timer? _driftTimer;
  StreamSubscription<Object?>? _awaitingReady;
  int? _lastSeekAtMs;
  int? _lastMidBandAtMs;

  final List<PlaybackCommand> _pending = [];
  GroupCommandError? _lastCommandError;

  /// The current state.
  ListenTogetherState get current => _current;

  /// The states; a new listener receives the current one first.
  Stream<ListenTogetherState> get state =>
      Stream<ListenTogetherState>.multi((listener) {
        listener.add(_current);
        final subscription = _states.stream.listen(
          listener.add,
          onDone: listener.close,
        );
        listener.onCancel = subscription.cancel;
      });

  /// The server clock now, in milliseconds: the monotonic clock plus the
  /// measured offset.
  int serverNow() => _clockSync.serverNow();

  /// Creates a group hosted by the user and joins it. With
  /// [fromCurrentQueue] the tracks of the local queue from the current item
  /// on, in play order (at most [maxInitialTracks]; episodes and tracks
  /// without a playback id are left out), start the group at the current
  /// position and playing flag. Leaves the group the user is in first.
  Future<void> createGroup({
    required GroupVisibility visibility,
    required bool fromCurrentQueue,
    String? name,
  }) => _serial(
    () => _join(() {
      final snapshot = _playback.snapshot;
      if (!fromCurrentQueue) {
        return _repository.create(name: name, visibility: visibility);
      }
      return _repository.create(
        name: name,
        visibility: visibility,
        queueTracks: initialTracksOf(snapshot.queue),
        currentTimeMs: snapshot.position.inMilliseconds,
        isPlaying: snapshot.playing,
      );
    }),
  );

  /// Joins the group with [joinCode], leaving the group the user is in
  /// first.
  Future<void> joinByCode(String joinCode) =>
      _serial(() => _join(() => _repository.join(joinCode)));

  /// Leaves the group and restores the saved local queue, paused.
  Future<void> leave() => _serial(_leave);

  /// Ends the group for every member (host only), then restores the saved
  /// local queue, paused. Throws [StateError] when the user is not the
  /// host; a failed REST call leaves the group joined.
  Future<void> endGroup() => _serial(() async {
    final membership = _membership;
    if (membership == null) return;
    if (membership.group.hostUserId != _userId) {
      throw StateError('Only the host ends a group');
    }
    _emit(const ListenTogetherLeaving());
    try {
      await _repository.end(membership.group.id);
    } on Object {
      _emitActive();
      rethrow;
    }
    await _dropLocal(membership, restore: true);
    _emit(const ListenTogetherIdle());
  });

  /// Sends [command] to the group instead of applying it (doc 08,
  /// Commands From This Device). Completes when the command is
  /// acknowledged, refused, or timed out; a failure is published as
  /// [ListenTogetherActive.lastCommandError], never thrown.
  @override
  Future<void> onCommand(PlaybackCommand command) {
    if (_membership == null) return Future<void>.value();
    switch (command) {
      case PlayCommand():
        return _transport(command, PlaybackAction.play);
      case PauseCommand() || StopCommand():
        return _transport(command, PlaybackAction.pause);
      case TogglePlayPauseCommand():
        return _transport(
          command,
          (_last?.isPlaying ?? false)
              ? PlaybackAction.pause
              : PlaybackAction.play,
        );
      case NextCommand():
        return _transport(command, PlaybackAction.next);
      case PreviousCommand():
        return _transport(command, PlaybackAction.previous);
      case SeekCommand(:final position):
        return _transport(
          command,
          PlaybackAction.seek,
          positionMs: position.inMilliseconds,
          stateVersion: _version,
        );
      case JumpToCommand(:final queueItemId):
        final index = _indexOf(queueItemId);
        if (index == null) return Future<void>.value();
        return _transport(command, PlaybackAction.setTrack, index: index);
      case AppendCommand(:final items):
        return _add(command, QueueAction.add, items);
      case PlayNextCommand(:final items):
        return _add(command, QueueAction.insertNext, items);
      case RemoveAtCommand(:final queueItemId):
        final index = _indexOf(queueItemId);
        if (index == null) return Future<void>.value();
        return _send(
          command,
          () async =>
              (await _socket.queue(QueueAction.remove, index: index)).ok,
        );
      case MoveCommand(:final queueItemId, :final toPlayIndex):
        final from = _indexOf(queueItemId);
        if (from == null) return Future<void>.value();
        return _send(
          command,
          () async => (await _socket.queue(
            QueueAction.reorder,
            fromIndex: from,
            toIndex: toPlayIndex,
          )).ok,
        );
      case ClearCommand():
        return _send(
          command,
          () async => (await _socket.queue(QueueAction.clear)).ok,
        );
      case PlayItemsCommand(:final items, :final startIndex):
        if (!_canControl) return _reject(const HostControlsPlayback());
        final refs = _shareable(items);
        final start = _shareable(items.take(startIndex), report: false).length;
        return _send(command, () async {
          if (!(await _socket.queue(QueueAction.clear)).ok) return false;
          if (refs.isEmpty) return true;
          if (!(await _socket.queue(QueueAction.add, tracks: refs)).ok) {
            return false;
          }
          if (start == 0 || start >= refs.length) return true;
          return (await _socket.playback(
            PlaybackAction.setTrack,
            index: start,
          )).ok;
        });
      case SetShuffleCommand() || SetRepeatCommand():
        return _reject(const RemoteCommandUnsupported());
      case SetVolumeCommand():
        // Never routed to a driver: the volume stays local.
        return Future<void>.value();
    }
  }

  /// Reports a current item this device cannot play to the server with
  /// `track:playback-failed`, then waits for the server's next message.
  @override
  void onCurrentItemFailed(String queueItemId) {
    if (_membership == null) return;
    _cancelAwaitingReady();
    final index = _indexOf(queueItemId);
    if (index == null) return;
    unawaited(
      _socket
          .playbackFailed(index)
          .then<void>(
            (_) {},
            onError: (Object error) =>
                _log.info('track:playback-failed failed', {'error': '$error'}),
          ),
    );
  }

  /// Leaves the group within [closeLeaveBudget], ignoring failures, then
  /// drops the local state without restoring the queue; for a profile
  /// switch or sign-out. Safe to call more than once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final membership = _membership;
    if (membership != null) {
      try {
        await _leaveRemotely(membership).timeout(closeLeaveBudget);
      } on Object catch (error) {
        _log.info('Leaving the group on close failed', {'error': '$error'});
      }
      await _dropLocal(membership, restore: false);
    }
    _clockSync.stop();
    _socket.keepAliveInBackground = () => false;
    await _states.close();
  }

  Future<void> _serial(Future<void> Function() step) {
    final result = _tail.then((_) {
      if (_disposed) throw StateError('ListenTogetherController was disposed');
      return step();
    });
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _join(Future<Group> Function() rest) async {
    if (_membership != null) await _leave();
    _emit(const ListenTogetherJoining());
    final Group group;
    try {
      group = await rest();
    } on Object {
      _emit(const ListenTogetherIdle());
      rethrow;
    }
    final snapshot = _playback.snapshot;
    final saved = (
      queue: snapshot.queue,
      position: snapshot.position,
      playing: snapshot.playing,
    );
    final lease = _socket.acquire('listen-together');
    final gate = Completer<void>();
    _applyTail = gate.future;
    _version = null;
    _last = null;
    _acceptNextState = true;
    _pending.clear();
    _lastCommandError = null;
    _subscribe();
    try {
      await _connected();
      final ack = await _socket.joinGroup(group.id);
      if (!ack.ok) {
        throw const SocketCommandException(message: 'join-group was refused');
      }
    } on Object catch (error) {
      _unsubscribe();
      gate.complete();
      lease.release();
      _log.warning('Joining the group over the socket failed', {
        'error': '$error',
      });
      try {
        await _repository.leave(group.id);
      } on Object catch (leaveError) {
        _log.info('Undoing the REST join failed', {'error': '$leaveError'});
      }
      _emit(const ListenTogetherIdle());
      rethrow;
    }
    final membership = _Membership(group, saved, lease);
    _membership = membership;
    _playback.attachRemoteDriver(this);
    _playback.setRemoteCanControl(group.canControl(_userId));
    _clockSync.start(_socket.reconnected);
    _driftTimer = _periodic(driftCheckInterval, (_) {
      if (_last?.isPlaying ?? false) _apply(_correctDrift);
    });
    _emitActive();
    gate.complete();
  }

  Future<void> _connected() async {
    if (_socket.connectionState == SocketConnectionState.connected) return;
    await _socket.connectionStates
        .firstWhere((state) => state == SocketConnectionState.connected)
        .timeout(connectTimeout);
  }

  Future<void> _leave() async {
    final membership = _membership;
    if (membership == null) return;
    _emit(const ListenTogetherLeaving());
    await _leaveRemotely(membership);
    await _dropLocal(membership, restore: true);
    _emit(const ListenTogetherIdle());
  }

  /// `leave-group` over the socket; the REST leave when the socket is not
  /// connected or the acknowledgement fails.
  Future<void> _leaveRemotely(_Membership membership) async {
    if (_socket.connectionState == SocketConnectionState.connected) {
      try {
        if ((await _socket.leaveGroup()).ok) return;
      } on Object catch (error) {
        _log.info('leave-group failed', {'error': '$error'});
      }
    }
    try {
      await _repository.leave(membership.group.id);
    } on Object catch (error, stackTrace) {
      _log.warning('Leaving the group failed', const {}, error, stackTrace);
    }
  }

  Future<void> _dropLocal(
    _Membership membership, {
    required bool restore,
  }) async {
    _membership = null;
    _clockSync.stop();
    _unsubscribe();
    _driftTimer?.cancel();
    _driftTimer = null;
    _cancelScheduledStart();
    _cancelAwaitingReady();
    _last = null;
    _playback.detachRemoteDriver();
    membership.lease.release();
    if (restore) {
      await _playback.restoreQueue(
        membership.saved.queue,
        position: membership.saved.position,
      );
    }
  }

  bool get _canControl => _membership?.group.canControl(_userId) ?? false;

  /// Emits the active state of the joined group, if any.
  void _emitActive() {
    final membership = _membership;
    if (membership == null) return;
    _emit(
      ListenTogetherActive(
        group: membership.group,
        offsetMs: _clockSync.offsetMs,
        canControl: membership.group.canControl(_userId),
        pending: Set.unmodifiable(_pending),
        lastCommandError: _lastCommandError,
      ),
    );
  }

  // Applying state (doc 08, Applying State).

  RemotePlayback get _remote => _playback.remote;

  void _subscribe() {
    _subscriptions = [
      _socket.groupState.listen((event) => _apply(() => _onState(event))),
      _socket.queueDelta.listen((event) => _apply(() => _onQueue(event))),
      _socket.waiting.listen((event) => _apply(() => _onWaiting(event))),
      _socket.playAt.listen((event) => _apply(() => _onPlayAt(event))),
      _socket.playbackDelta.listen(
        (event) => _apply(() => _onPlaybackDelta(event)),
      ),
      _socket.members.listen(_onMember),
      _socket.ended.listen(_onEnded),
      _socket.reconnected.listen((_) => _acceptNextState = true),
    ];
  }

  void _unsubscribe() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions = const [];
  }

  /// Runs [step] after every message that arrived before it, while in a
  /// group; a failing step is logged.
  void _apply(Future<void> Function() step) {
    _applyTail = _applyTail.then((_) async {
      if (_membership == null || _disposed) return;
      try {
        await step();
      } on Object catch (error, stackTrace) {
        _log.warning(
          'Applying group state failed',
          const {},
          error,
          stackTrace,
        );
      }
    });
  }

  /// Whether [version] is older than the last applied one; when it is not,
  /// it becomes the last applied one.
  bool _stale(int version) {
    final applied = _version;
    if (applied != null && version < applied) return true;
    _version = version;
    return false;
  }

  /// Where the group is expected now in the current item, in milliseconds.
  int _expected() {
    final last = _last;
    if (last == null) return 0;
    final durationMs = switch (_playback.snapshot.current) {
      TrackQueueItem(:final track) when track.meta.durationSec > 0 =>
        track.meta.durationSec * 1000,
      _ => null,
    };
    return expectedPositionMs(
      isPlaying: last.isPlaying,
      positionMs: last.positionMs,
      serverTime: last.serverTime,
      serverNow: serverNow(),
      durationMs: durationMs,
    );
  }

  Future<void> _onState(GroupSnapshot snapshot) async {
    final playback = snapshot.playback;
    if (_acceptNextState) {
      _acceptNextState = false;
      _version = playback.stateVersion;
    } else if (_stale(playback.stateVersion)) {
      return;
    }
    _cancelScheduledStart();
    _cancelAwaitingReady();
    _membership!.group = groupOfSocket(snapshot);
    _playback.setRemoteCanControl(_canControl);
    _emitActive();
    _last = (
      isPlaying: playback.isPlaying,
      positionMs: playback.positionMs,
      serverTime: playback.serverTime,
    );
    final items = queueItemsOf(playback.queue);
    await _remote.replaceQueue(items, playback.currentIndex);
    if (items.isEmpty) {
      await _remote.pause();
      return;
    }
    if (snapshot.syncState == GroupSyncState.waiting) {
      _last = (isPlaying: false, positionMs: 0, serverTime: serverNow());
      await _loadAndReady();
      return;
    }
    await _load(_expected(), play: false);
    if (snapshot.syncState == GroupSyncState.playing) await _remote.play();
  }

  Future<void> _onQueue(QueueDelta delta) async {
    if (_stale(delta.stateVersion)) return;
    final items = queueItemsOf(delta.queue);
    final before = _playback.snapshot;
    final kept =
        items.isNotEmpty &&
        before.current?.queueItemId ==
            items[delta.currentIndex.clamp(0, items.length - 1)].queueItemId &&
        before.status != EngineStatus.idle &&
        before.status != EngineStatus.error;
    await _remote.replaceQueue(items, delta.currentIndex);
    if (items.isEmpty) {
      await _remote.pause();
      return;
    }
    if (!kept) await _load(_expected(), play: _last?.isPlaying ?? false);
  }

  Future<void> _onWaiting(WaitingEvent event) async {
    _cancelScheduledStart();
    _cancelAwaitingReady();
    _last = (isPlaying: false, positionMs: 0, serverTime: serverNow());
    final items = _playback.snapshot.queue.items;
    if (items.isEmpty) return;
    await _remote.replaceQueue(items, event.currentIndex);
    await _loadAndReady();
  }

  /// Loads the current item paused at zero and sends `ready` once the
  /// engine reports it ready; a failed load is reported by
  /// [onCurrentItemFailed] instead.
  Future<void> _loadAndReady() async {
    final id = _playback.snapshot.current?.queueItemId;
    if (id == null) return;
    await _load(0, play: false);
    bool isReady(PlaybackSnapshot snapshot) =>
        snapshot.current?.queueItemId == id &&
        snapshot.status == EngineStatus.ready;
    final now = _playback.snapshot;
    if (now.error?.queueItemId == id) return;
    if (isReady(now)) {
      _sendReady();
      return;
    }
    _awaitingReady = _playback.snapshots.listen((snapshot) {
      if (snapshot.error?.queueItemId == id) {
        _cancelAwaitingReady();
      } else if (isReady(snapshot)) {
        _cancelAwaitingReady();
        _sendReady();
      }
    });
  }

  void _sendReady() => unawaited(
    _socket.ready().then<void>(
      (_) {},
      onError: (Object error) => _log.info('ready failed', {'error': '$error'}),
    ),
  );

  void _cancelAwaitingReady() {
    unawaited(_awaitingReady?.cancel());
    _awaitingReady = null;
  }

  Future<void> _onPlayAt(PlayAtEvent event) async {
    if (_stale(event.stateVersion)) return;
    _cancelScheduledStart();
    _cancelAwaitingReady();
    _last = (
      isPlaying: true,
      positionMs: event.positionMs,
      serverTime: event.serverTime,
    );
    final delayMs = event.serverTime - serverNow();
    if (delayMs <= 0) {
      await _seekTo(_expected());
      await _remote.play();
      return;
    }
    await _seekTo(event.positionMs);
    _scheduledStart = _timer(Duration(milliseconds: delayMs), () {
      _scheduledStart = null;
      _apply(_remote.play);
    });
  }

  void _cancelScheduledStart() {
    _scheduledStart?.cancel();
    _scheduledStart = null;
  }

  Future<void> _onPlaybackDelta(PlaybackDelta delta) async {
    if (_stale(delta.stateVersion)) return;
    _last = (
      isPlaying: delta.isPlaying,
      positionMs: delta.positionMs,
      serverTime: delta.serverTime,
    );
    if (!delta.isPlaying) _cancelScheduledStart();
    final snapshot = _playback.snapshot;
    final items = snapshot.queue.items;
    if (items.isNotEmpty && snapshot.queue.cursor != delta.currentIndex) {
      _cancelScheduledStart();
      _cancelAwaitingReady();
      await _remote.replaceQueue(items, delta.currentIndex);
      await _load(_expected(), play: delta.isPlaying);
      return;
    }
    if (delta.isPlaying && !snapshot.playing && _scheduledStart == null) {
      await _remote.play();
    } else if (!delta.isPlaying && snapshot.playing) {
      await _remote.pause();
    }
    await _correctDrift();
  }

  void _onMember(MemberEvent event) {
    final membership = _membership;
    if (membership == null) return;
    membership.group = groupWithMemberEvent(membership.group, event);
    _playback.setRemoteCanControl(_canControl);
    _emitActive();
  }

  void _onEnded(GroupEnded event) {
    final reason = switch (event) {
      GroupClosed() => GroupEndReason.ended,
      MembershipRevoked() => GroupEndReason.membershipRevoked,
    };
    unawaited(
      _serial(() async {
        final membership = _membership;
        if (membership == null) return;
        await _dropLocal(membership, restore: true);
        _emit(ListenTogetherEnded(reason));
      }).then<void>(
        (_) {},
        onError: (Object error) =>
            _log.info('Ending the group failed', {'error': '$error'}),
      ),
    );
  }

  /// Loads the current item at [positionMs], playing when [play].
  Future<void> _load(int positionMs, {required bool play}) {
    _lastSeekAtMs = _clock.nowMs();
    return _remote.loadCurrent(
      position: Duration(milliseconds: positionMs),
      play: play,
    );
  }

  /// Moves to [positionMs] in the current item, loading it paused there
  /// when nothing is loaded.
  Future<void> _seekTo(int positionMs) {
    if (_playback.snapshot.status == EngineStatus.idle) {
      return _load(positionMs, play: false);
    }
    _lastSeekAtMs = _clock.nowMs();
    return _remote.seek(Duration(milliseconds: positionMs));
  }

  // Drift correction (doc 08, Drift Correction).

  Future<void> _correctDrift() async {
    if (_scheduledStart != null) return;
    final snapshot = _playback.snapshot;
    if (snapshot.current == null || snapshot.status != EngineStatus.ready) {
      return;
    }
    final now = _clock.nowMs();
    if (_lastSeekAtMs case final at?
        when now - at < seekSettle.inMilliseconds) {
      return;
    }
    final expected = _expected();
    switch (driftCorrectionFor(snapshot.position.inMilliseconds - expected)) {
      case DriftCorrection.none:
        return;
      case DriftCorrection.throttledSeek:
        if (_lastMidBandAtMs case final at?
            when now - at < midBandCorrectionInterval.inMilliseconds) {
          return;
        }
        _lastMidBandAtMs = now;
      case DriftCorrection.immediateSeek:
        break;
    }
    await _seekTo(expected);
  }

  // Commands (doc 08, Commands From This Device).

  /// The index of [queueItemId] in the group queue; null when absent.
  int? _indexOf(String queueItemId) {
    final index = _playback.snapshot.queue.items.indexWhere(
      (item) => item.queueItemId == queueItemId,
    );
    return index < 0 ? null : index;
  }

  Future<void> _transport(
    PlaybackCommand command,
    PlaybackAction action, {
    int? positionMs,
    int? index,
    int? stateVersion,
  }) {
    if (!_canControl) return _reject(const HostControlsPlayback());
    return _send(
      command,
      () async => (await _socket.playback(
        action,
        positionMs: positionMs,
        index: index,
        stateVersion: stateVersion,
      )).ok,
    );
  }

  Future<void> _add(
    PlaybackCommand command,
    QueueAction action,
    List<QueueItem> items,
  ) {
    final refs = _shareable(items);
    if (refs.isEmpty) return Future<void>.value();
    return _send(
      command,
      () async => (await _socket.queue(action, tracks: refs)).ok,
    );
  }

  /// The playback refs of the tracks of [items] that have a playback id;
  /// with [report], the others are published as [ItemsNotShareable].
  List<PlaybackRef> _shareable(
    Iterable<QueueItem> items, {
    bool report = true,
  }) {
    final refs = [
      for (final item in items)
        if (item case TrackQueueItem(:final track)
            when track.playbackId != null)
          PlaybackRef(
            playbackId: track.playbackId!.value,
            metadata: playbackMetadataFromMeta(track.meta),
          ),
    ];
    final dropped = items.length - refs.length;
    if (report && dropped > 0) unawaited(_reject(ItemsNotShareable(dropped)));
    return refs;
  }

  Future<void> _reject(GroupCommandError error) {
    _lastCommandError = error;
    _emitActive();
    return Future<void>.value();
  }

  /// Sends [command] with [call] (true when acknowledged); pending until
  /// the acknowledgement, an error or [commandTimeout].
  Future<void> _send(PlaybackCommand command, Future<bool> Function() call) {
    final done = Completer<void>();
    _pending.add(command);
    _emitActive();
    late final Timer timeout;
    void finish(GroupCommandError? error) {
      if (done.isCompleted) return;
      timeout.cancel();
      _pending.remove(command);
      if (error != null) _lastCommandError = error;
      _emitActive();
      done.complete();
    }

    timeout = _timer(
      commandTimeout,
      () => finish(const GroupCommandTimedOut()),
    );
    unawaited(
      call().then(
        (ok) => finish(ok ? null : const GroupCommandRejected()),
        onError: (Object error) => finish(_commandError(error)),
      ),
    );
    return done.future;
  }

  void _emit(ListenTogetherState state) {
    _current = state;
    if (!_states.isClosed) _states.add(state);
  }
}

/// The tracks a group created from [queue] starts with: the track entries
/// from the current one on, in play order, that have a playback id, at
/// most [ListenTogetherController.maxInitialTracks].
List<Track> initialTracksOf(QueueState queue) {
  final cursor = queue.cursor;
  if (cursor == null) return const [];
  final order = queue.playOrder;
  return [
    for (final index in order.skip(cursor))
      if (queue.items[index] case TrackQueueItem(:final track)
          when track.playbackId != null)
        track,
  ].take(ListenTogetherController.maxInitialTracks).toList();
}

/// The profile's [ListenTogetherController]. Closing the profile leaves the
/// group within two seconds and drops the local state.
final Provider<ListenTogetherController> listenTogetherControllerProvider =
    Provider<ListenTogetherController>(
      (ref) {
        final controller = ListenTogetherController(
          playback: ref.watch(playbackControllerProvider),
          socket: ref.watch(socketClientProvider),
          repository: ListenTogetherRepository(
            ref.watch(soundspanApiProvider).rest.listenTogether,
          ),
          userId: ref.watch(profileContextProvider).profile.userId,
        );
        ref.watch(profileDisposerProvider).register(controller.dispose);
        ref.onDispose(() => unawaited(controller.dispose()));
        return controller;
      },
      dependencies: [
        playbackControllerProvider,
        socketClientProvider,
        soundspanApiProvider,
        profileContextProvider,
        profileDisposerProvider,
      ],
    );

/// The [GroupCommandError] of a failed socket command.
GroupCommandError _commandError(Object error) => switch (error) {
  SocketCommandException(:final message, :final code) => GroupCommandRejected(
    message: message,
    code: code,
  ),
  SocketNotConnected() => const GroupCommandOffline(),
  SocketAckTimeout() => const GroupCommandTimedOut(),
  _ => GroupCommandRejected(message: '$error'),
};
