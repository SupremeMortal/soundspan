// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/connectivity/reachability.dart';

/// A [ReachabilityController] whose state a test sets with [set], and which
/// records every reported call outcome.
class FakeReachability implements ReachabilityController {
  /// Starts in [initial], [Reachability.online] by default.
  new({Reachability initial = Reachability.online}) : _current = initial;

  Reachability _current;
  final StreamController<Reachability> _changes =
      StreamController<Reachability>.broadcast(sync: true);
  final StreamController<ConnectionType> _connectionTypeChanges =
      StreamController<ConnectionType>.broadcast(sync: true);
  ConnectionType _connectionType = ConnectionType.wifi;

  /// The kind of network reported; tests set it, and a change is emitted on
  /// [connectionTypeChanges]. [ConnectionType.wifi] by default.
  @override
  ConnectionType get connectionType => _connectionType;

  set connectionType(ConnectionType type) {
    if (type == _connectionType) return;
    _connectionType = type;
    _connectionTypeChanges.add(type);
  }

  @override
  Stream<ConnectionType> get connectionTypeChanges =>
      _connectionTypeChanges.stream;

  /// The outcomes passed to [reportCallOutcome], in order.
  final List<bool> outcomes = [];

  @override
  Reachability get current => _current;

  @override
  Stream<Reachability> get changes => _changes.stream;

  @override
  bool get isOnline => _current == Reachability.online;

  @override
  void reportCallOutcome({required bool success}) => outcomes.add(success);

  /// How many times [probeNow] was called.
  int probes = 0;

  @override
  Future<void> probeNow() async => probes++;

  /// Moves to [state] and emits it on [changes] when it differs.
  void set(Reachability state) {
    if (state == _current) return;
    _current = state;
    _changes.add(state);
  }
}
