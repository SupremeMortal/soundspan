// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';

import '../../helpers/fake_reachability.dart';

void main() {
  test('the default controller is always online', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final reachability = container.read(reachabilityProvider);
    final changes = <Reachability>[];
    final subscription = reachability.changes.listen(changes.add);
    addTearDown(subscription.cancel);
    reachability
      ..reportCallOutcome(success: false)
      ..reportCallOutcome(success: false);
    await pumpEventQueue();

    expect(reachability, isA<AlwaysOnlineReachability>());
    expect(reachability.current, Reachability.online);
    expect(reachability.isOnline, isTrue);
    expect(changes, isEmpty);
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

    expect(changes, [Reachability.serverUnreachable, Reachability.online]);
    expect(reachability.isOnline, isTrue);
    expect(reachability.outcomes, [true]);
    reachability.set(Reachability.forcedOffline);
    expect(reachability.isOnline, isFalse);
  });
}
