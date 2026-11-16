// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability_controller_impl.dart';
import 'package:soundspan/platform/connectivity/connectivity.dart';
import 'package:soundspan/shared/clock.dart';

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

  /// Every change of [connectionType], from the same connectivity listener.
  Stream<ConnectionType> get connectionTypeChanges;

  /// Reports the outcome of a real API call: any response is a success, an
  /// `Offline` exception a failure.
  void reportCallOutcome({required bool success});

  /// Asks the server at once whether it answers, outside the probe
  /// schedule; an answer returns the state to [Reachability.online] from
  /// [Reachability.serverUnreachable].
  Future<void> probeNow();
}

/// The process-wide [ReachabilityControllerImpl] over the platform's
/// connectivity. `startReachability` starts it after the first frame and
/// binds it to the active profile.
final Provider<ReachabilityControllerImpl> reachabilityControllerProvider =
    Provider<ReachabilityControllerImpl>((ref) {
      final controller = ReachabilityControllerImpl(
        connectivity: ref.watch(connectivitySourceProvider),
        clock: ref.watch(clockProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

/// The root-scope [ReachabilityController]: the
/// [reachabilityControllerProvider] unless overridden.
final Provider<ReachabilityController> reachabilityProvider =
    Provider<ReachabilityController>(
      (ref) => ref.watch(reachabilityControllerProvider),
    );

/// The current [Reachability] and every change of it, for widgets.
final StreamProvider<Reachability> reachabilityStateProvider =
    StreamProvider<Reachability>((ref) {
      final controller = ref.watch(reachabilityProvider);
      final states = StreamController<Reachability>()..add(controller.current);
      final subscription = controller.changes.listen(states.add);
      ref.onDispose(() {
        unawaited(subscription.cancel());
        unawaited(states.close());
      });
      return states.stream;
    });
