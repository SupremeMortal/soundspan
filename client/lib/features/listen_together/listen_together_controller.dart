// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/realtime/clock_sync.dart';
import 'package:soundspan/core/realtime/realtime_providers.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/features/listen_together/data/listen_together_repository.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/shared/domain/domain.dart';

final AppLogger _log = AppLogger.scope('ListenTogether');

/// The user's own queue, position and playing flag, kept while in a group
/// so leaving can restore them.
typedef SavedLocalQueue = ({QueueState queue, Duration position, bool playing});

/// What a joined group holds on this device.
final class _Membership {
  new(this.group, this.saved, this.lease);

  final Group group;
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
/// Applying the group's state and sending commands are not part of this
/// class yet: [onCommand] completes without sending anything.
class ListenTogetherController implements RemoteDriver {
  /// Creates the controller of the user [_userId], driving [_playback] over
  /// [_socket] and [_repository]; [clockSync] defaults to one over
  /// `SocketClient.ping` and a [StopwatchMonotonicClock].
  new({
    required this._playback,
    required this._socket,
    required this._repository,
    required this._userId,
    ClockSync? clockSync,
  }) : _clockSync =
           clockSync ??
           ClockSync(ping: _socket.ping, clock: StopwatchMonotonicClock()) {
    _socket.keepAliveInBackground = () =>
        _membership != null && _playback.snapshot.playing;
  }

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
  final StreamController<ListenTogetherState> _states =
      StreamController<ListenTogetherState>.broadcast(sync: true);

  ListenTogetherState _current = const ListenTogetherIdle();
  _Membership? _membership;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

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
      _emitActive(membership.group);
      rethrow;
    }
    await _dropLocal(membership, restore: true);
    _emit(const ListenTogetherIdle());
  });

  @override
  Future<void> onCommand(PlaybackCommand command) async {}

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
    try {
      await _connected();
      final ack = await _socket.joinGroup(group.id);
      if (!ack.ok) {
        throw const SocketCommandException(message: 'join-group was refused');
      }
    } on Object catch (error) {
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
    _emitActive(group);
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
    _playback.detachRemoteDriver();
    membership.lease.release();
    if (restore) {
      await _playback.restoreQueue(
        membership.saved.queue,
        position: membership.saved.position,
      );
    }
  }

  void _emitActive(Group group) => _emit(
    ListenTogetherActive(
      group: group,
      offsetMs: _clockSync.offsetMs,
      canControl: group.canControl(_userId),
    ),
  );

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
