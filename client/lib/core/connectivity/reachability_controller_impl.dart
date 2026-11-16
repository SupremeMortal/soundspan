// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/platform/connectivity/connectivity.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// What the active profile contributes to its [ReachabilityControllerImpl].
final class ReachabilityBinding {
  /// Creates the binding.
  const new({
    required this.probe,
    required this.forcedOffline,
    this.onReturnedOnline,
  });

  /// Asks the profile's server whether it answers: completes on any HTTP
  /// response (an [ApiException] other than [Offline] is a response too) and
  /// throws [Offline] when nothing answers.
  final Future<void> Function() probe;

  /// The `offline.forced` setting of the profile, as it changes.
  final Stream<bool> forcedOffline;

  /// Called each time the state returns to [Reachability.online].
  final void Function()? onReturnedOnline;
}

/// The [ReachabilityController] of the app (doc 07, Reachability and
/// Offline Mode).
///
/// It decides, in priority order: `offline.forced` set is
/// [Reachability.forcedOffline]; no network interface is
/// [Reachability.noNetwork]; two failed calls less than [failureWindow]
/// apart, with no success between them, are
/// [Reachability.serverUnreachable]; anything else is
/// [Reachability.online]. Connectivity alone never moves a state to
/// online: only a response does.
///
/// While the server is unreachable the bound profile's probe runs after
/// each delay of [probeDelays] in turn, repeating the last, and at once on
/// every connectivity change and on [probeNow].
///
/// One controller lives for the whole process; [bind] attaches it to the
/// active profile and starts it afresh for that profile.
class ReachabilityControllerImpl implements ReachabilityController {
  /// Creates the controller over a [ConnectivitySource], reading time from
  /// a [Clock].
  new({required this._connectivity, required this._clock});

  /// How close together two failures must be to make the server
  /// unreachable.
  static const Duration failureWindow = Duration(seconds: 30);

  /// The waits before successive probes; the last repeats.
  static const List<Duration> probeDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  final ConnectivitySource _connectivity;
  final Clock _clock;
  final StreamController<Reachability> _changes =
      StreamController<Reachability>.broadcast();
  final StreamController<ConnectionType> _connectionTypeChanges =
      StreamController<ConnectionType>.broadcast();

  Reachability _current = Reachability.online;
  bool _hasInterface = true;
  ConnectionType _connectionType = ConnectionType.wifi;
  bool _forced = false;
  bool _started = false;
  bool _disposed = false;
  DateTime? _lastFailure;
  ReachabilityBinding? _binding;
  StreamSubscription<ConnectivityInfo>? _connectivitySubscription;
  StreamSubscription<bool>? _forcedSubscription;
  Timer? _probeTimer;
  int _probeStep = 0;
  Future<void>? _probing;

  @override
  Reachability get current => _current;

  @override
  Stream<Reachability> get changes => _changes.stream;

  @override
  bool get isOnline => _current == Reachability.online;

  /// The kind of the last reported interface; [ConnectionType.wifi] until
  /// the platform reports one.
  @override
  ConnectionType get connectionType => _connectionType;

  @override
  Stream<ConnectionType> get connectionTypeChanges =>
      _connectionTypeChanges.stream;

  /// Starts following connectivity (doc 02, Bootstrap Sequence, step 8).
  /// Later calls do nothing.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _connectivitySubscription = _connectivity.watch().listen(_onConnectivity);
  }

  /// Attaches the controller to the active profile's [binding], or to none,
  /// and starts it afresh: online when an interface is up, failures
  /// forgotten, probing stopped until the new profile needs it.
  void bind(ReachabilityBinding? binding) {
    if (_disposed) return;
    unawaited(_forcedSubscription?.cancel());
    _forcedSubscription = null;
    _stopProbing();
    _binding = binding;
    _forced = false;
    _lastFailure = null;
    _set(_hasInterface ? Reachability.online : Reachability.noNetwork);
    _forcedSubscription = binding?.forcedOffline.listen(_onForced);
  }

  @override
  void reportCallOutcome({required bool success}) {
    if (_disposed) return;
    if (_current == Reachability.forcedOffline ||
        _current == Reachability.noNetwork) {
      return;
    }
    if (success) {
      _lastFailure = null;
      if (_current == Reachability.serverUnreachable) _returnOnline();
      return;
    }
    if (_current != Reachability.online) return;
    final now = _clock.now();
    final last = _lastFailure;
    if (last != null && now.difference(last) < failureWindow) {
      _enterUnreachable(probeAtOnce: false);
    } else {
      _lastFailure = now;
    }
  }

  @override
  Future<void> probeNow() => _probe();

  /// Stops probing and following connectivity and the setting.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stopProbing();
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_forcedSubscription?.cancel());
    unawaited(_changes.close());
    unawaited(_connectionTypeChanges.close());
  }

  void _onConnectivity(ConnectivityInfo info) {
    _hasInterface = info.hasInterface;
    final type = !info.hasInterface
        ? ConnectionType.none
        : switch (info.type) {
            ConnectivityType.wifi => ConnectionType.wifi,
            ConnectivityType.cellular => ConnectionType.cellular,
            ConnectivityType.other => ConnectionType.other,
          };
    if (type != _connectionType) {
      _connectionType = type;
      _connectionTypeChanges.add(type);
    }
    if (_forced) return;
    if (!info.hasInterface) {
      _stopProbing();
      _lastFailure = null;
      _set(Reachability.noNetwork);
      return;
    }
    switch (_current) {
      case Reachability.noNetwork:
        _enterUnreachable(probeAtOnce: true);
      case Reachability.serverUnreachable:
        unawaited(_probe());
      case Reachability.online || Reachability.forcedOffline:
        break;
    }
  }

  void _onForced(bool forced) {
    if (forced == _forced) return;
    _forced = forced;
    if (forced) {
      _stopProbing();
      _lastFailure = null;
      _set(Reachability.forcedOffline);
    } else if (!_hasInterface) {
      _set(Reachability.noNetwork);
    } else {
      _enterUnreachable(probeAtOnce: true);
    }
  }

  void _enterUnreachable({required bool probeAtOnce}) {
    _stopProbing();
    _lastFailure = null;
    _set(Reachability.serverUnreachable);
    if (probeAtOnce) {
      unawaited(_probe());
    } else {
      _scheduleProbe();
    }
  }

  void _returnOnline() {
    _stopProbing();
    _lastFailure = null;
    _set(Reachability.online);
    _binding?.onReturnedOnline?.call();
  }

  void _scheduleProbe() {
    _probeTimer?.cancel();
    if (_binding == null || _disposed) return;
    final delay = probeDelays[_probeStep.clamp(0, probeDelays.length - 1)];
    _probeStep++;
    _probeTimer = Timer(delay, () => unawaited(_probe()));
  }

  void _stopProbing() {
    _probeTimer?.cancel();
    _probeTimer = null;
    _probeStep = 0;
  }

  /// Runs the bound profile's probe, or joins the one in flight.
  Future<void> _probe() {
    final binding = _binding;
    if (binding == null || _disposed) return Future<void>.value();
    return _probing ??= () async {
      _probeTimer?.cancel();
      bool answered;
      try {
        await binding.probe();
        answered = true;
      } on Offline {
        answered = false;
      } on ApiException {
        answered = true;
      } on Object {
        answered = false;
      } finally {
        _probing = null;
      }
      if (_disposed || !identical(binding, _binding)) return;
      if (answered) {
        _lastFailure = null;
        if (_current == Reachability.serverUnreachable) _returnOnline();
      } else if (_current == Reachability.serverUnreachable) {
        _scheduleProbe();
      }
    }();
  }

  void _set(Reachability state) {
    if (state == _current) return;
    _current = state;
    if (!_changes.isClosed) _changes.add(state);
  }
}
