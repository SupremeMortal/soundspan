// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the active profile's server can be reached (doc 07, Reachability
/// and Offline Mode).
enum Reachability {
  /// The server answers.
  online,

  /// The network is up but the server does not answer.
  serverUnreachable,

  /// No network interface is up.
  noNetwork,

  /// The user turned offline mode on.
  forcedOffline,
}

/// The kind of network the device is on; stream quality follows it (doc 06,
/// Source Resolution).
enum ConnectionType {
  /// Wi-Fi.
  wifi,

  /// A mobile data connection.
  cellular,

  /// Ethernet, VPN or another kind the platform reports.
  other,

  /// No network interface is up.
  none,
}

/// Tracks [Reachability] for the active profile. In any state but
/// [Reachability.online], repositories serve the cache and skip refreshes.
abstract interface class ReachabilityController {
  /// The current state.
  Reachability get current;

  /// Every change of [current].
  Stream<Reachability> get changes;

  /// Whether [current] is [Reachability.online].
  bool get isOnline;

  /// The kind of network the device is on now.
  ConnectionType get connectionType;

  /// Reports the outcome of a real API call: any response is a success, an
  /// `Offline` exception a failure.
  void reportCallOutcome({required bool success});
}

/// A [ReachabilityController] that is always [Reachability.online] and
/// ignores call outcomes.
class AlwaysOnlineReachability implements ReachabilityController {
  /// Creates the controller.
  const new();

  @override
  Reachability get current => Reachability.online;

  @override
  Stream<Reachability> get changes => const Stream<Reachability>.empty();

  @override
  bool get isOnline => true;

  /// Always [ConnectionType.wifi].
  @override
  ConnectionType get connectionType => ConnectionType.wifi;

  @override
  void reportCallOutcome({required bool success}) {}
}

/// The root-scope [ReachabilityController]; [AlwaysOnlineReachability]
/// unless overridden.
final Provider<ReachabilityController> reachabilityProvider =
    Provider<ReachabilityController>((ref) => const AlwaysOnlineReachability());
