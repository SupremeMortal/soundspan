// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Whether the probe runs in a browser, where transport failures are
/// `corsOrNetwork`.
final Provider<bool> probeIsWebProvider = Provider<bool>((ref) => kIsWeb);

/// Creates the [ProbeClient] of each probe run.
final Provider<ProbeClient Function()> probeClientFactoryProvider =
    Provider<ProbeClient Function()>((ref) => ProbeClient.new);

/// Creates the anonymous session client of a probed server.
final Provider<ProbeSessionFactory> probeSessionFactoryProvider =
    Provider<ProbeSessionFactory>((ref) => anonymousProbeSession);

/// Runs [ServerProbe] for the connect screens and holds its latest state.
///
/// The state is loading until the first [start]. It does not decide whether
/// public cleartext is allowed: the UI confirms before calling [start].
class ProbeController extends AsyncNotifier<ProbeState> {
  StreamSubscription<ProbeState>? _run;
  ServerAddress? _last;

  @override
  Future<ProbeState> build() {
    ref.onDispose(cancel);
    return Completer<ProbeState>().future;
  }

  /// Probes [address], cancelling any run in progress.
  void start(ServerAddress address) {
    cancel();
    _last = address;
    state = const AsyncLoading<ProbeState>();
    final probe = ServerProbe(
      client: ref.read(probeClientFactoryProvider),
      session: ref.read(probeSessionFactoryProvider),
      clock: ref.read(clockProvider),
      isWeb: ref.read(probeIsWebProvider),
    );
    _run = probe.run(address).listen((next) => state = AsyncData(next));
  }

  /// Probes the last started address again; does nothing before a [start].
  void retry() {
    final last = _last;
    if (last != null) start(last);
  }

  /// Stops the run in progress, including pending retries.
  void cancel() {
    unawaited(_run?.cancel());
    _run = null;
  }
}

/// The [ProbeController] of the connect flow.
final AsyncNotifierProvider<ProbeController, ProbeState>
probeControllerProvider = AsyncNotifierProvider<ProbeController, ProbeState>(
  ProbeController.new,
);
