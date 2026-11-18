// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/connectivity/reachability_controller_impl.dart';
import 'package:soundspan/platform/connectivity/connectivity.dart';

import '../../helpers/fake_reachability.dart';

class _NoInterface implements ConnectivitySource {
  @override
  Stream<ConnectivityInfo> watch() => Stream.value(ConnectivityInfo.none);
}

void main() {
  test('the default controller is the real one, over the platform', () async {
    final container = ProviderContainer(
      overrides: [connectivitySourceProvider.overrideWithValue(_NoInterface())],
    );
    addTearDown(container.dispose);

    final reachability = container.read(reachabilityProvider);
    expect(reachability, isA<ReachabilityControllerImpl>());
    expect(reachability, same(container.read(reachabilityControllerProvider)));
    expect(reachability.current, Reachability.online);

    final states = <Reachability>[];
    container.listen(
      reachabilityStateProvider,
      (_, next) => states.add(next.requireValue),
    );
    await container.read(reachabilityControllerProvider).start();
    await pumpEventQueue();

    expect(reachability.current, Reachability.noNetwork);
    expect(states, [Reachability.online, Reachability.noNetwork]);
  });

  test('FakeReachability emits changes and records outcomes', () async {
    final reachability = FakeReachability();
    final changes = <Reachability>[];
    reachability.changes.listen(changes.add);

    reachability
      ..set(Reachability.serverUnreachable)
      ..set(Reachability.serverUnreachable)
      ..set(Reachability.online)
      ..reportCallOutcome(success: true);
    unawaited(reachability.probeNow());

    expect(changes, [Reachability.serverUnreachable, Reachability.online]);
    expect(reachability.isOnline, isTrue);
    expect(reachability.outcomes, [true]);
    expect(reachability.probes, 1);
    reachability.set(Reachability.forcedOffline);
    expect(reachability.isOnline, isFalse);
  });
}
