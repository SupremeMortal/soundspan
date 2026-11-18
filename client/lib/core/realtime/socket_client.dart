// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile's socket to the server's `/listen-together` namespace (doc
/// 08, Socket Client).
///
/// This file imports nothing from Flutter, so the contract suite can use
/// it: the app lifecycle, reachability, time and logging arrive injected.
library;

import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:soundspan_api/soundspan_api.dart';

// Relative, so the contract suite (which cannot depend on the Flutter app
// package) can import this file by path.
// ignore: always_use_package_imports
import 'socket_exceptions.dart';
// Relative, for the same reason.
// ignore: always_use_package_imports
import 'socket_models.dart';

export 'socket_exceptions.dart';
export 'socket_models.dart';

/// Whether the app is in front, as the socket's lifecycle rules see it.
enum SocketAppLifecycle {
  /// The app is visible.
  foreground,

  /// The app is hidden or paused.
  background,
}

/// The state of the socket's connection, for the UI.
enum SocketConnectionState {
  /// Not connected and not trying.
  disconnected,

  /// A connection or reconnection is in progress.
  connecting,

  /// Connected and authenticated.
  connected,
}

/// The level of a [SocketLog] line.
enum SocketLogLevel {
  /// Diagnostic detail.
  fine,

  /// Recovered failures.
  warning,

  /// Failures that stop the socket.
  severe,
}

/// Where [SocketClient] writes its log lines; the app passes its
/// `AppLogger`.
typedef SocketLog = void Function(
  SocketLogLevel level,
  String message, [
  Object? error,
]);

/// Starts a one-shot timer; `Timer.new` in the app, a fake in tests.
typedef SocketTimerFactory = Timer Function(
  Duration duration,
  void Function() callback,
);

/// Asks the server who the credential belongs to (`GET /auth/me`); throws
/// `Unauthenticated` when the server rejects it.
typedef ConfirmCredential = Future<void> Function();

/// One reason to keep the socket connected; see [SocketClient.acquire].
/// Not final, so tests of its holders can fake it.
class SocketLease {
  new _(this._client, this.reason);

  final SocketClient _client;
  bool _released = false;

  /// Why the lease was taken, for logs.
  final String reason;

  /// Gives the lease back. The socket disconnects when the last lease is
  /// released. Calls after the first do nothing.
  void release() {
    if (_released) return;
    _released = true;
    _client._release(this);
  }
}

/// The socket of one profile.
///
/// It connects lazily, while at least one [SocketLease] is held, and
/// follows the lifecycle rules of doc 08: on mobile it disconnects 30 s
/// after the app goes to the background unless `keepAliveInBackground`
/// says otherwise; it pauses reconnection while the server is not
/// reachable; on reconnecting it joins the group it was in again and
/// publishes [reconnected].
class SocketClient {
  /// Creates the client of the server at [baseUrl], which may carry a
  /// reverse-proxy path prefix.
  ///
  /// - `credentials` returns the credential for the handshake; for a JWT
  ///   session it is `SessionController.ensureFresh`.
  /// - `refreshCredentials` renews a JWT session after the server rejected
  ///   its token (`SessionController.refreshNow`).
  /// - `onUnauthenticated` is `SessionController.onUnauthenticated`.
  /// - `confirmCredential` calls `GET /auth/me`.
  /// - `lifecycle` and `online` feed the background and reachability
  ///   rules; `initiallyOnline` is the reachability at creation, and
  ///   `backgroundDisconnect` is true on mobile only.
  /// - `keepAliveInBackground` says whether to stay connected in the
  ///   background ("in a group and playing").
  new({
    required Uri baseUrl,
    required this._credentials,
    required this._refreshCredentials,
    required this._onUnauthenticated,
    required this._confirmCredential,
    Stream<SocketAppLifecycle>? lifecycle,
    Stream<bool>? online,
    bool initiallyOnline = true,
    this._backgroundDisconnect = false,
    bool Function()? keepAliveInBackground,
    SocketTimerFactory? timers,
    SocketLog? log,
  }) : keepAliveInBackground = keepAliveInBackground ?? _never,
       _timers = timers ?? Timer.new,
       _log = log ?? _silent,
       _online = initiallyOnline {
    _zone = Zone.current.fork(
      specification: ZoneSpecification(
        handleUncaughtError: (self, parent, zone, error, stackTrace) {
          // socket_io_client leaves some futures unawaited, such as closing
          // a WebSocket the server has already closed; their errors are
          // logged here instead of reaching the app's error handler.
          _log(SocketLogLevel.fine, 'Socket library error', error);
        },
      ),
    );
    _zone.run(() => _create(baseUrl));
    _subscriptions
      ..add(lifecycle?.listen(_onLifecycle))
      ..add(online?.listen(_onReachability));
  }

  void _create(Uri baseUrl) {
    _socket = io.io(
      namespaceUrl(baseUrl),
      io.OptionBuilder()
          .setPath(socketPath(baseUrl))
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setRandomizationFactor(0.5)
          .setAuthFn(_authenticate)
          .build(),
    );
    _listen();
  }

  /// How long an emitter waits for its acknowledgement.
  static const ackTimeout = Duration(seconds: 5);

  /// How long a retryable command waits when the server does not say.
  static const defaultRetryAfter = Duration(milliseconds: 250);

  /// How long the app may stay in the background before the socket
  /// disconnects, on mobile.
  static const backgroundGrace = Duration(seconds: 30);

  /// How long sign-out waits for `leave-group`.
  static const signOutLeaveBudget = Duration(seconds: 2);

  /// The namespace URL: the server's origin and `/listen-together`, because
  /// socket.io reads the URL path as the namespace.
  static String namespaceUrl(Uri baseUrl) =>
      '${baseUrl.origin}/listen-together';

  /// The socket.io path: the base URL's path prefix and
  /// `/socket.io/listen-together`.
  static String socketPath(Uri baseUrl) {
    final prefix = baseUrl.path.endsWith('/')
        ? baseUrl.path.substring(0, baseUrl.path.length - 1)
        : baseUrl.path;
    return '$prefix/socket.io/listen-together';
  }

  final Future<Credentials> Function() _credentials;
  final Future<Credentials> Function() _refreshCredentials;
  final void Function(UnauthenticatedReason reason) _onUnauthenticated;
  final ConfirmCredential _confirmCredential;
  final bool _backgroundDisconnect;

  /// Says whether to stay connected in the background ("in a group and
  /// playing"); Listen Together replaces it.
  bool Function() keepAliveInBackground;
  final SocketTimerFactory _timers;
  final SocketLog _log;
  late final io.Socket _socket;
  late final Zone _zone;
  final List<StreamSubscription<Object?>?> _subscriptions = [];
  final Set<SocketLease> _leases = {};
  final Set<Timer> _pendingTimers = {};

  final _state = StreamController<SocketConnectionState>.broadcast();
  final _groupState = StreamController<GroupSnapshot>.broadcast();
  final _playbackDelta = StreamController<PlaybackDelta>.broadcast();
  final _queueDelta = StreamController<QueueDelta>.broadcast();
  final _waiting = StreamController<WaitingEvent>.broadcast();
  final _playAt = StreamController<PlayAtEvent>.broadcast();
  final _members = StreamController<MemberEvent>.broadcast();
  final _ended = StreamController<GroupEnded>.broadcast();
  final _presenceUpdated = StreamController<PresenceUpdated>.broadcast();
  final _reconnected = StreamController<void>.broadcast();

  SocketConnectionState _current = SocketConnectionState.disconnected;
  Credentials? _handshakeCredential;
  String? _groupId;
  bool _online;
  bool _background = false;
  bool _backgroundDisconnected = false;
  bool _stopped = false;
  bool _disposed = false;
  bool _authRetried = false;
  bool _everConnected = false;
  Timer? _backgroundTimer;

  /// The connection state now.
  SocketConnectionState get connectionState => _current;

  /// Every change of [connectionState].
  Stream<SocketConnectionState> get connectionStates => _state.stream;

  /// The group this socket joined, if any.
  String? get groupId => _groupId;

  /// The number of leases held.
  int get leaseCount => _leases.length;

  /// `group:state`.
  Stream<GroupSnapshot> get groupState => _groupState.stream;

  /// `group:playback-delta`.
  Stream<PlaybackDelta> get playbackDelta => _playbackDelta.stream;

  /// `group:queue-delta`.
  Stream<QueueDelta> get queueDelta => _queueDelta.stream;

  /// `group:waiting`.
  Stream<WaitingEvent> get waiting => _waiting.stream;

  /// `group:play-at`.
  Stream<PlayAtEvent> get playAt => _playAt.stream;

  /// `group:member-joined`, `group:member-presence` and
  /// `group:member-left`.
  Stream<MemberEvent> get members => _members.stream;

  /// `group:ended` and `group:membership-revoked`.
  Stream<GroupEnded> get ended => _ended.stream;

  /// `social:presence-updated`.
  Stream<PresenceUpdated> get presenceUpdated => _presenceUpdated.stream;

  /// The socket connected again after a connection was lost; callers
  /// refetch what they show over REST. The group, if any, has been joined
  /// again by then.
  Stream<void> get reconnected => _reconnected.stream;

  /// Takes a lease; the first one connects the socket.
  SocketLease acquire(String reason) {
    if (_disposed) throw StateError('SocketClient was disposed');
    final lease = SocketLease._(this, reason);
    _leases.add(lease);
    _log(SocketLogLevel.fine, 'Socket lease taken: $reason');
    _connectIfWanted();
    return lease;
  }

  void _release(SocketLease lease) {
    if (!_leases.remove(lease)) return;
    _log(SocketLogLevel.fine, 'Socket lease released: ${lease.reason}');
    if (_leases.isEmpty) _disconnect();
  }

  /// `join-group { groupId }`; remembered so a reconnection joins again.
  Future<Ack> joinGroup(String groupId) async {
    final ack = Ack.fromJson(
      await _command('join-group', {'groupId': groupId}),
    );
    if (ack.ok) _groupId = groupId;
    return ack;
  }

  /// `leave-group`.
  Future<Ack> leaveGroup() async {
    final ack = Ack.fromJson(await _command('leave-group', null));
    if (ack.ok) _groupId = null;
    return ack;
  }

  /// `playback { action, positionMs?, index?, stateVersion? }`.
  Future<Ack> playback(
    PlaybackAction action, {
    int? positionMs,
    int? index,
    int? stateVersion,
  }) async => Ack.fromJson(
    await _command('playback', {
      'action': action.wireName,
      'positionMs': ?positionMs,
      'index': ?index,
      'stateVersion': ?stateVersion,
    }),
  );

  /// `queue { action, tracks?, index?, fromIndex?, toIndex? }`; additions
  /// send each track as `{ playbackId, metadata }` only.
  Future<QueueAck> queue(
    QueueAction action, {
    List<PlaybackRef>? tracks,
    int? index,
    int? fromIndex,
    int? toIndex,
  }) async => QueueAck.fromJson(
    await _command('queue', {
      'action': action.wireName,
      if (tracks != null)
        'tracks': [
          for (final track in tracks)
            {
              'playbackId': track.playbackId,
              if (track.metadata case final metadata?)
                'metadata': metadata.toJson(),
            },
        ],
      'index': ?index,
      'fromIndex': ?fromIndex,
      'toIndex': ?toIndex,
    }),
  );

  /// `ready`: the current item is loaded.
  Future<Ack> ready() async => Ack.fromJson(await _command('ready', null));

  /// `track:playback-failed { queueIndex }`.
  Future<Ack> playbackFailed(int queueIndex) async => Ack.fromJson(
    await _command('track:playback-failed', {'queueIndex': queueIndex}),
  );

  /// `lt-ping`: the server's clock, in milliseconds.
  Future<int> ping() async {
    final ack = await _command('lt-ping', null);
    return switch (ack['serverTime']) {
      final num serverTime => serverTime.toInt(),
      _ => throw const SocketCommandException(
        message: 'lt-ping acknowledgement without serverTime',
      ),
    };
  }

  /// The sign-out step of the socket (doc 04, Sign-Out, step 1): leaves the
  /// joined group within [signOutLeaveBudget], ignoring failures, then
  /// drops every lease and disposes the client, so nothing reconnects with
  /// a credential that is about to be revoked.
  Future<void> signOut() async {
    if (_disposed) return;
    if (_groupId != null && _socket.connected) {
      try {
        await _withBudget(leaveGroup(), signOutLeaveBudget);
      } on Object catch (error) {
        _log(SocketLogLevel.warning, 'leave-group on sign-out failed', error);
      }
    }
    _leases.clear();
    await dispose();
  }

  /// Closes the socket and every stream; pending commands fail with
  /// [SocketNotConnected].
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopped = true;
    _leases.clear();
    _backgroundTimer?.cancel();
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    for (final subscription in _subscriptions) {
      await subscription?.cancel();
    }
    _socket.io.reconnection = false;
    _zone.run(_socket.dispose);
    _setState(SocketConnectionState.disconnected);
    for (final pending in _pendingCommands.toList()) {
      if (!pending.isCompleted) {
        pending.completeError(const SocketNotConnected('dispose'));
      }
    }
    await Future.wait([
      _state.close(),
      _groupState.close(),
      _playbackDelta.close(),
      _queueDelta.close(),
      _waiting.close(),
      _playAt.close(),
      _members.close(),
      _ended.close(),
      _presenceUpdated.close(),
      _reconnected.close(),
    ]);
  }

  // Connection.

  bool get _wanted =>
      !_stopped && _leases.isNotEmpty && _online && !_backgroundDisconnected;

  void _connectIfWanted() {
    if (!_wanted || _socket.connected || _socket.active) return;
    _setState(SocketConnectionState.connecting);
    _socket.io.reconnection = true;
    _zone.run(_socket.connect);
  }

  void _disconnect() {
    _socket.io.reconnection = false;
    _zone.run(_socket.disconnect);
    _setState(SocketConnectionState.disconnected);
  }

  /// Stops for good: the credential was rejected or the client is broken.
  void _stop() {
    _stopped = true;
    _disconnect();
  }

  void _authenticate(void Function(Map<dynamic, dynamic> auth) send) {
    unawaited(
      _credentials().then(
        (credential) {
          _handshakeCredential = credential;
          send(switch (credential) {
            JwtCredentials(:final accessToken) => {'token': accessToken},
            ApiKeyCredentials(:final apiKey) => {'apiKey': apiKey},
          });
        },
        onError: (Object error) {
          // ensureFresh has signed the profile out when it throws
          // Unauthenticated; any other failure waits for reachability.
          _log(SocketLogLevel.warning, 'No credential for the socket', error);
          if (error is Unauthenticated) {
            _stop();
          } else {
            _disconnect();
          }
        },
      ),
    );
  }

  void _listen() {
    _socket
      ..onConnect((_) => _onConnected())
      ..onConnectError(_onConnectError)
      ..onDisconnect(_onDisconnected)
      ..on('group:state', (data) {
        _decode(data, 'group:state', GroupSnapshot.fromJson, _groupState);
      })
      ..on('group:playback-delta', (data) {
        _decode(
          data,
          'group:playback-delta',
          PlaybackDelta.fromJson,
          _playbackDelta,
        );
      })
      ..on('group:queue-delta', (data) {
        _decode(data, 'group:queue-delta', QueueDelta.fromJson, _queueDelta);
      })
      ..on('group:waiting', (data) {
        _decode(data, 'group:waiting', WaitingEvent.fromJson, _waiting);
      })
      ..on('group:play-at', (data) {
        _decode(data, 'group:play-at', PlayAtEvent.fromJson, _playAt);
      })
      ..on('social:presence-updated', (data) {
        _decode(
          data,
          'social:presence-updated',
          PresenceUpdated.fromJson,
          _presenceUpdated,
        );
      });
    for (final event in const [
      'group:member-joined',
      'group:member-presence',
      'group:member-left',
    ]) {
      _socket.on(event, (data) {
        _decode(data, event, MemberEvent.fromJson, _members, unionKey: true);
      });
    }
    for (final event in const ['group:ended', 'group:membership-revoked']) {
      _socket.on(event, (data) {
        final decoded = _decode(
          data,
          event,
          GroupEnded.fromJson,
          _ended,
          unionKey: true,
        );
        if (decoded != null) _groupId = null;
      });
    }
  }

  T? _decode<T>(
    Object? data,
    String event,
    T Function(Map<String, Object?> json) fromJson,
    StreamController<T> sink, {
    bool unionKey = false,
  }) {
    try {
      if (data is! Map) throw FormatException('$event payload is not a map');
      final json = Map<String, Object?>.from(data);
      if (unionKey) json['event'] = event;
      final value = fromJson(json);
      if (!sink.isClosed) sink.add(value);
      return value;
    } on Object catch (error) {
      _log(SocketLogLevel.warning, 'Dropped a malformed $event', error);
      return null;
    }
  }

  void _onConnected() {
    final reconnecting = _everConnected;
    _everConnected = true;
    _authRetried = false;
    _setState(SocketConnectionState.connected);
    if (!reconnecting) return;
    unawaited(_rejoin());
  }

  Future<void> _rejoin() async {
    final groupId = _groupId;
    if (groupId != null) {
      try {
        await joinGroup(groupId);
      } on Object catch (error) {
        _log(SocketLogLevel.warning, 'Joining the group again failed', error);
      }
    }
    if (!_reconnected.isClosed) _reconnected.add(null);
  }

  void _onDisconnected(Object? reason) {
    if (_disposed) return;
    if (reason == 'io server disconnect') {
      _setState(SocketConnectionState.disconnected);
      unawaited(_onServerDisconnect());
      return;
    }
    _setState(
      _wanted && _socket.io.reconnection == true
          ? SocketConnectionState.connecting
          : SocketConnectionState.disconnected,
    );
  }

  /// A server-initiated disconnect: an API key may have been revoked, so
  /// one `GET /auth/me` decides between signing out and reconnecting.
  Future<void> _onServerDisconnect() async {
    if (_handshakeCredential is ApiKeyCredentials) {
      try {
        await _confirmCredential();
      } on Unauthenticated {
        _onUnauthenticated(UnauthenticatedReason.keyRejected);
        _stop();
        return;
      } on Object catch (error) {
        _log(SocketLogLevel.warning, 'Confirming the API key failed', error);
      }
    }
    if (!_disposed) _connectIfWanted();
  }

  void _onConnectError(Object? data) {
    if (_disposed || _stopped) return;
    final message = switch (data) {
      {'message': final String message} => message,
      final String message => message,
      _ => null,
    };
    switch (message) {
      case 'Invalid token' || 'Token expired':
        if (_authRetried) {
          _rejected(message!);
        } else {
          _authRetried = true;
          unawaited(_refreshAndReconnect());
        }
      case 'User not found' || 'User deletion is pending' || 'Invalid API key':
        _rejected(message!);
      case 'Authentication required':
        _log(
          SocketLogLevel.severe,
          'The server saw no credential in the socket handshake',
        );
        _stop();
      default:
        // A transport failure: socket.io reconnects with its backoff.
        _log(SocketLogLevel.fine, 'Socket connection failed', data);
        _setState(
          _socket.io.reconnection == true && _wanted
              ? SocketConnectionState.connecting
              : SocketConnectionState.disconnected,
        );
    }
  }

  void _rejected(String message) {
    _log(SocketLogLevel.warning, 'The server rejected the socket: $message');
    _onUnauthenticated(
      _handshakeCredential is ApiKeyCredentials
          ? UnauthenticatedReason.keyRejected
          : UnauthenticatedReason.sessionExpired,
    );
    _stop();
  }

  Future<void> _refreshAndReconnect() async {
    try {
      await _refreshCredentials();
    } on Object catch (error) {
      _log(
        SocketLogLevel.warning,
        'Renewing the socket credential failed',
        error,
      );
      if (error is Unauthenticated) _stop();
      return;
    }
    if (_disposed || _stopped) return;
    _connectIfWanted();
  }

  // Lifecycle.

  void _onLifecycle(SocketAppLifecycle state) {
    switch (state) {
      case SocketAppLifecycle.background:
        _background = true;
        if (!_backgroundDisconnect || _backgroundTimer != null) return;
        _backgroundTimer = _timers(backgroundGrace, () {
          _backgroundTimer = null;
          if (!_background || keepAliveInBackground()) return;
          _backgroundDisconnected = true;
          _log(SocketLogLevel.fine, 'Socket closed in the background');
          _disconnect();
        });
      case SocketAppLifecycle.foreground:
        _background = false;
        _backgroundTimer?.cancel();
        _backgroundTimer = null;
        if (!_backgroundDisconnected) return;
        _backgroundDisconnected = false;
        _connectIfWanted();
    }
  }

  void _onReachability(bool online) {
    if (online == _online) return;
    _online = online;
    if (online) {
      _connectIfWanted();
    } else {
      _disconnect();
    }
  }

  void _setState(SocketConnectionState state) {
    if (state == _current) return;
    _current = state;
    if (!_state.isClosed) _state.add(state);
  }

  // Commands.

  final Set<Completer<Map<String, Object?>>> _pendingCommands = {};

  Future<Map<String, Object?>> _command(
    String event,
    Map<String, Object?>? payload, {
    bool retry = true,
  }) async {
    final ack = await _emit(event, payload);
    if (!ack.containsKey('error')) return ack;
    final failure = SocketCommandException.fromAck(ack);
    if (!retry || !failure.retryable) throw failure;
    await _delay(
      failure.retryAfterMs == null
          ? defaultRetryAfter
          : Duration(milliseconds: failure.retryAfterMs!),
    );
    return await _command(event, payload, retry: false);
  }

  Future<Map<String, Object?>> _emit(
    String event,
    Map<String, Object?>? payload,
  ) {
    if (_disposed || !_socket.connected) {
      return Future.error(SocketNotConnected(event));
    }
    final completer = Completer<Map<String, Object?>>();
    _pendingCommands.add(completer);
    late final Timer timer;
    timer = _timers(ackTimeout, () {
      _pendingTimers.remove(timer);
      if (!completer.isCompleted) {
        completer.completeError(SocketAckTimeout(event, ackTimeout));
      }
    });
    _pendingTimers.add(timer);
    _zone.run(
      () => _socket.emitWithAck(
        event,
        payload,
        ack: ([Object? data]) {
          timer.cancel();
          _pendingTimers.remove(timer);
          if (completer.isCompleted) return;
          completer.complete(
            data is Map ? Map<String, Object?>.from(data) : <String, Object?>{},
          );
        },
      ),
    );
    return completer.future.whenComplete(
      () => _pendingCommands.remove(completer),
    );
  }

  Future<void> _delay(Duration duration) {
    final completer = Completer<void>();
    late final Timer timer;
    timer = _timers(duration, () {
      _pendingTimers.remove(timer);
      completer.complete();
    });
    _pendingTimers.add(timer);
    return completer.future;
  }

  Future<T> _withBudget<T>(Future<T> future, Duration budget) {
    final completer = Completer<T>();
    late final Timer timer;
    timer = _timers(budget, () {
      _pendingTimers.remove(timer);
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('budget', budget));
      }
    });
    _pendingTimers.add(timer);
    unawaited(
      future.then(
        (value) {
          timer.cancel();
          _pendingTimers.remove(timer);
          if (!completer.isCompleted) completer.complete(value);
        },
        onError: (Object error, StackTrace stackTrace) {
          timer.cancel();
          _pendingTimers.remove(timer);
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
      ),
    );
    return completer.future;
  }

  static bool _never() => false;

  static void _silent(SocketLogLevel level, String message, [Object? error]) {}
}
