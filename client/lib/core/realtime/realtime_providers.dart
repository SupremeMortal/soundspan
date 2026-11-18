// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/platform/device_info/device_info.dart';

/// The lifetime a JWT must have left when it is sent in a socket handshake;
/// a shorter one is renewed first.
const socketCredentialMinRemaining = Duration(minutes: 1);

/// The app's lifecycle as the socket sees it: hidden and paused are
/// [SocketAppLifecycle.background], resumed is
/// [SocketAppLifecycle.foreground]. Read from an [AppLifecycleListener];
/// tests override it.
final Provider<Stream<SocketAppLifecycle>> socketLifecycleProvider =
    Provider<Stream<SocketAppLifecycle>>((ref) {
      final states = StreamController<SocketAppLifecycle>.broadcast();
      final listener = AppLifecycleListener(
        binding: WidgetsBinding.instance,
        onStateChange: (state) {
          switch (state) {
            case AppLifecycleState.hidden || AppLifecycleState.paused:
              states.add(SocketAppLifecycle.background);
            case AppLifecycleState.resumed:
              states.add(SocketAppLifecycle.foreground);
            case AppLifecycleState.inactive || AppLifecycleState.detached:
              break;
          }
        },
      );
      ref.onDispose(() {
        listener.dispose();
        unawaited(states.close());
      });
      return states.stream;
    });

/// Whether the socket stays connected while the app is in the background:
/// "in a group and playing". Nothing keeps it alive until Listen Together
/// overrides it.
final Provider<bool Function()> socketKeepAliveInBackgroundProvider =
    Provider<bool Function()>(
      (ref) =>
          () => false,
    );

/// The [SocketClient] of the profile scope. It is disposed with the scope,
/// so a profile switch closes the socket.
final Provider<SocketClient> socketClientProvider = Provider<SocketClient>(
  (ref) {
    final session = ref.watch(sessionControllerProvider);
    final api = ref.watch(soundspanApiProvider);
    final reachability = ref.watch(reachabilityProvider);
    final logger = ref.read(appLoggerProvider('Realtime'));
    final client = SocketClient(
      baseUrl: ref.watch(apiConfigProvider).baseUrl,
      credentials: () =>
          session.ensureFresh(minRemaining: socketCredentialMinRemaining),
      refreshCredentials: session.refreshNow,
      onUnauthenticated: session.onUnauthenticated,
      confirmCredential: () =>
          api.send((rest) => rest.session.getCurrentUser()),
      lifecycle: ref.watch(socketLifecycleProvider),
      online: reachability.changes.map((state) => state == Reachability.online),
      initiallyOnline: reachability.isOnline,
      backgroundDisconnect: ref.watch(deviceInfoProvider).isMobile,
      keepAliveInBackground: ref.watch(socketKeepAliveInBackgroundProvider),
      log: (level, message, [error]) => switch (level) {
        SocketLogLevel.fine => logger.fine(message),
        SocketLogLevel.warning => logger.warning(message, const {}, error),
        SocketLogLevel.severe => logger.severe(message, const {}, error),
      },
    );
    ref.watch(profileDisposerProvider).register(client.dispose);
    ref.onDispose(() => unawaited(client.dispose()));
    return client;
  },
  dependencies: [
    sessionControllerProvider,
    soundspanApiProvider,
    apiConfigProvider,
    profileDisposerProvider,
  ],
);
