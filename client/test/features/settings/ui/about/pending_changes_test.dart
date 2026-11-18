// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/features/settings/ui/about/about_section.dart';

import '../../../../core/sync/outbox/outbox_test_support.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('the About row shows the pending count and updates', (
    tester,
  ) async {
    final rig = WorkerRig();
    addTearDown(() => tester.runAsync(rig.close));
    rig.reachability.set(Reachability.noNetwork);
    await tester.pumpApp(
      const Scaffold(body: PendingChangesTile()),
      overrides: [
        outboxProvider.overrideWithValue(Outbox(rig.store, rig.worker)),
      ],
    );
    expect(find.textContaining('Pending changes'), findsNothing);

    await tester.runAsync(() async {
      await rig.worker.start();
      await rig.settle();
    });
    await tester.pump();
    expect(find.text('Pending changes: 0'), findsOneWidget);

    await tester.runAsync(() async {
      for (final id in ['a', 'b', 'c']) {
        await rig.put(pref(id));
      }
      await rig.settle();
    });
    await tester.pump();
    expect(find.text('Pending changes: 3'), findsOneWidget);
  });
}
