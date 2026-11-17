// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/realtime/presence_models.dart';
import 'package:soundspan/core/realtime/presence_repository.dart';
import 'package:soundspan/core/realtime/realtime_providers.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// What the Activity panel shows (doc 08, Social Presence).
@immutable
final class PresenceState {
  /// Creates a state.
  const new({
    this.roster,
    this.loading = false,
    this.failed = false,
    this.error,
  });

  /// The last roster read; null before the first one arrives.
  final PresenceRoster? roster;

  /// Whether a roster request is running.
  final bool loading;

  /// Whether the last roster request failed; [roster] keeps the one before.
  final bool failed;

  /// What the last roster request failed with, while [failed].
  final Object? error;
}

/// Social presence of one profile (doc 08, Social Presence).
///
/// Nothing runs until [open] is called the first time. From then until
/// [dispose] a heartbeat is sent at once and every [heartbeatInterval]
/// while the app is in the foreground and the server is reachable, and
/// stops for the session on `FeatureDisabled` or `Forbidden`. Between
/// [open] and [close] a socket lease is held, the roster is read, and each
/// `social:presence-updated` event or reconnection reads it again after
/// [refetchDebounce].
class PresenceController {
  /// Creates the controller.
  new({
    required this._repository,
    required this._socket,
    required this._lifecycle,
    required this._reachability,
    required this._clock,
    void Function(String message)? logFine,
  }) : _logFine = logFine ?? _noLog;

  /// The time between heartbeats.
  static const Duration heartbeatInterval = Duration(seconds: 25);

  /// How long presence events are gathered before the roster is read.
  static const Duration refetchDebounce = Duration(seconds: 1);

  final PresenceRepository _repository;
  final SocketClient _socket;
  final Stream<SocketAppLifecycle> _lifecycle;
  final ReachabilityController _reachability;
  final Clock _clock;
  final void Function(String message) _logFine;

  final StreamController<PresenceState> _states =
      StreamController<PresenceState>.broadcast(sync: true);
  PresenceState _state = const PresenceState();

  bool _started = false;
  bool _heartbeatStopped = false;
  bool _background = false;
  bool _disposed = false;
  DateTime? _lastBeat;
  Timer? _heartbeat;
  Timer? _refetch;
  SocketLease? _lease;
  int _fetch = 0;
  final List<StreamSubscription<Object?>> _sessionSubscriptions = [];
  final List<StreamSubscription<Object?>> _openSubscriptions = [];

  /// The current state.
  PresenceState get state => _state;

  /// Every state change.
  Stream<PresenceState> get states => _states.stream;

  /// When the last heartbeat was sent; null before the first.
  DateTime? get lastHeartbeat => _lastBeat;

  /// Called when the Activity panel or sheet opens.
  void open() {
    if (_disposed || _lease != null) return;
    if (!_started) _start();
    _lease = _socket.acquire('presence');
    _openSubscriptions
      ..add(_socket.presenceUpdated.listen((_) => _scheduleRefetch()))
      ..add(_socket.reconnected.listen((_) => unawaited(_load())));
    unawaited(_load());
  }

  /// Called when the Activity panel or sheet closes. The last roster is
  /// kept for the next [open].
  void close() {
    _lease?.release();
    _lease = null;
    _refetch?.cancel();
    _refetch = null;
    for (final subscription in _openSubscriptions) {
      unawaited(subscription.cancel());
    }
    _openSubscriptions.clear();
  }

  /// Reads the roster again; for Retry.
  Future<void> retry() => _load();

  /// Stops everything; the profile is closing.
  Future<void> dispose() async {
    if (_disposed) return;
    close();
    _disposed = true;
    _heartbeat?.cancel();
    _heartbeat = null;
    for (final subscription in _sessionSubscriptions) {
      await subscription.cancel();
    }
    _sessionSubscriptions.clear();
    await _states.close();
  }

  void _start() {
    _started = true;
    _sessionSubscriptions
      ..add(
        _lifecycle.listen((state) {
          _background = state == SocketAppLifecycle.background;
          _updateHeartbeat();
        }),
      )
      ..add(_reachability.changes.listen((_) => _updateHeartbeat()));
    _updateHeartbeat();
  }

  bool get _beating =>
      !_disposed &&
      !_heartbeatStopped &&
      !_background &&
      _reachability.current == Reachability.online;

  void _updateHeartbeat() {
    if (!_beating) {
      _heartbeat?.cancel();
      _heartbeat = null;
      return;
    }
    if (_heartbeat != null) return;
    _heartbeat = Timer.periodic(heartbeatInterval, (_) => unawaited(_beat()));
    unawaited(_beat());
  }

  Future<void> _beat() async {
    if (!_beating) return;
    _lastBeat = _clock.now();
    try {
      await _repository.heartbeat();
    } on api.FeatureDisabled {
      _stopHeartbeat('presence is disabled on the server');
    } on api.Forbidden {
      _stopHeartbeat('presence is not allowed for this user');
    } on Object catch (error) {
      _logFine('Presence heartbeat failed: ${error.runtimeType}');
    }
  }

  void _stopHeartbeat(String why) {
    _logFine('Presence heartbeat stopped: $why');
    _heartbeatStopped = true;
    _updateHeartbeat();
  }

  void _scheduleRefetch() {
    if (_lease == null || _refetch != null) return;
    _refetch = Timer(refetchDebounce, () {
      _refetch = null;
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    if (_disposed) return;
    final fetch = ++_fetch;
    _emit(PresenceState(roster: _state.roster, loading: true));
    try {
      final roster = await _repository.online();
      if (_disposed || fetch != _fetch) return;
      _emit(PresenceState(roster: roster));
    } on Object catch (error) {
      if (_disposed || fetch != _fetch) return;
      _emit(PresenceState(roster: _state.roster, failed: true, error: error));
    }
  }

  void _emit(PresenceState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  static void _noLog(String _) {}
}

/// The [PresenceController] of the profile scope, disposed with it.
final Provider<PresenceController> presenceControllerProvider =
    Provider<PresenceController>(
      (ref) {
        final logger = ref.read(appLoggerProvider('Presence'));
        final controller = PresenceController(
          repository: PresenceRepository(
            ref.watch(soundspanApiProvider).rest.social,
            currentUserId: ref.watch(profileContextProvider).profile.userId,
          ),
          socket: ref.watch(socketClientProvider),
          lifecycle: ref.watch(socketLifecycleProvider),
          reachability: ref.watch(reachabilityProvider),
          clock: ref.watch(clockProvider),
          logFine: logger.fine,
        );
        ref.watch(profileDisposerProvider).register(controller.dispose);
        ref.onDispose(() => unawaited(controller.dispose()));
        return controller;
      },
      dependencies: [
        soundspanApiProvider,
        profileContextProvider,
        socketClientProvider,
        profileDisposerProvider,
      ],
    );
