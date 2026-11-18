// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/outbox_notice_listener.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan_api/soundspan_api.dart' show Conflict, NotFound;

import '../../core/sync/outbox/outbox_test_support.dart';
import '../../helpers/pump_app.dart';

void main() {
  for (final (name, error, message) in [
    (
      'items gone',
      const NotFound(status: 404),
      'Some changes couldn’t be saved because the item no longer exists',
    ),
    (
      'conflict',
      const Conflict(status: 409),
      'A change couldn’t be saved because it was changed elsewhere',
    ),
  ]) {
    testWidgets('a $name notice shows a snackbar', (tester) async {
      final rig = WorkerRig();
      addTearDown(() => tester.runAsync(rig.close));
      rig.handler.script = (_) => throw error;
      await tester.pumpApp(
        const OutboxNoticeListener(child: Scaffold()),
        overrides: [
          outboxProvider.overrideWithValue(Outbox(rig.store, rig.worker)),
        ],
      );

      await tester.runAsync(() async {
        await rig.put(pref('a'));
        await rig.pass();
      });
      await tester.pump();

      expect(find.text(message), findsOneWidget);
    });
  }
}
