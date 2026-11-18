// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/key_expiry_monitor.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/platform/notifications/local_notifications.dart';
import 'package:soundspan/shared/clock.dart';

/// The localized text of the key-expiry notification. Bootstrap overrides
/// it; it throws until then.
final Provider<KeyExpiryNotificationText> keyExpiryNotificationTextProvider =
    Provider<KeyExpiryNotificationText>(
      (ref) => throw UnimplementedError(
        'keyExpiryNotificationTextProvider is set by bootstrap',
      ),
    );

/// The [KeyExpiryMonitor] of the profile scope. It follows the profile's
/// row, so a re-link is seen at once, and evaluates again whenever the app
/// returns to the foreground. [startKeyExpiryMonitor] starts it.
final Provider<KeyExpiryMonitor> keyExpiryMonitorProvider =
    Provider<KeyExpiryMonitor>((ref) {
      final id = ref.watch(profileContextProvider).profile.id;
      final monitor = KeyExpiryMonitor(
        profile: ref
            .watch(profileRepositoryProvider)
            .watchAll()
            .map((all) => all.where((p) => p.id == id).firstOrNull),
        settings: ref.watch(deviceSettingsDaoProvider),
        notifications: ref.watch(localNotificationsProvider),
        clock: ref.watch(clockProvider),
        text: (days) => ref.read(keyExpiryNotificationTextProvider)(days),
      );
      final lifecycle = AppLifecycleListener(
        binding: WidgetsBinding.instance,
        onResume: () => unawaited(monitor.evaluate()),
      );
      ref.onDispose(() {
        lifecycle.dispose();
        monitor.dispose();
      });
      return monitor;
    }, dependencies: [profileContextProvider, deviceSettingsDaoProvider]);

/// The active profile's [KeyExpiryState], now and after every change.
final StreamProvider<KeyExpiryState> keyExpiryStateProvider =
    StreamProvider<KeyExpiryState>((ref) async* {
      final monitor = ref.watch(keyExpiryMonitorProvider);
      yield monitor.current;
      yield* monitor.states;
    }, dependencies: [keyExpiryMonitorProvider]);

/// The post-first-frame task of the key-expiry warning (doc 04, API-Key
/// Expiry): starts the [KeyExpiryMonitor] of every profile container the
/// [ProfileRuntime] under [root] activates, now and later.
Future<void> startKeyExpiryMonitor(ProviderContainer root) async {
  final runtime = root.read(profileRuntimeProvider);
  ProviderContainer? started;
  void onState() {
    final container = runtime.container;
    if (runtime.state.value is! ProfileRuntimeActive ||
        container == null ||
        identical(container, started)) {
      return;
    }
    started = container;
    unawaited(
      container
          .read(keyExpiryMonitorProvider)
          .start(container.read(profileContextProvider).profile),
    );
  }

  runtime.state.addListener(onState);
  onState();
}
