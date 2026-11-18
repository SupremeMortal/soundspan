// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/connectivity/reachability_controller_impl.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/capability_refresher.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

/// The `device_settings` key of forced offline mode: JSON `true` when the
/// user turned offline mode on.
const String offlineForcedKey = 'offline.forced';

/// The `offline.forced` setting in [database], now and as it changes; a
/// missing or unreadable value is false.
Stream<bool> watchOfflineForced(StateDatabase database) =>
    (database.select(database.deviceSettings)
          ..where((t) => t.key.equals(offlineForcedKey)))
        .watchSingleOrNull()
        .map((row) {
          if (row == null) return false;
          try {
            return jsonDecode(row.value) == true;
          } on FormatException {
            return false;
          }
        })
        .distinct();

/// What the active profile gives the root [ReachabilityControllerImpl]:
/// the probe is the anonymous `GET /api/health` of the profile's API, the
/// forced-offline input its `offline.forced` setting, and a return to
/// online runs its capability refresh when one is due.
final Provider<ReachabilityBinding> reachabilityBindingProvider =
    Provider<ReachabilityBinding>(
      (ref) {
        final api = ref.watch(soundspanApiProvider);
        final refresher = ref.watch(capabilityRefresherProvider);
        return ReachabilityBinding(
          probe: () => api.send((rest) => rest.session.getHealth()),
          forcedOffline: watchOfflineForced(ref.watch(stateDatabaseProvider)),
          onReturnedOnline: () => unawaited(refresher.refreshIfDue()),
        );
      },
      dependencies: [
        soundspanApiProvider,
        capabilityRefresherProvider,
        stateDatabaseProvider,
      ],
    );

/// The post-first-frame task of reachability (doc 02, Bootstrap Sequence,
/// step 8): binds the root [ReachabilityControllerImpl] to each profile the
/// [ProfileRuntime] under [root] activates, now and later, to none between
/// them, and starts it.
Future<void> startReachability(ProviderContainer root) async {
  final controller = root.read(reachabilityControllerProvider);
  final runtime = root.read(profileRuntimeProvider);
  ProviderContainer? bound;
  void onState() {
    final container = runtime.state.value is ProfileRuntimeActive
        ? runtime.container
        : null;
    if (identical(container, bound)) return;
    bound = container;
    controller.bind(container?.read(reachabilityBindingProvider));
  }

  runtime.state.addListener(onState);
  onState();
  await controller.start();
}
