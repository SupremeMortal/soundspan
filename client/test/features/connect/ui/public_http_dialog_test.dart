// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';

import '../../../helpers/guidelines.dart';
import '../connect_harness.dart';

void main() {
  Future<ConnectHarness> submitPublicHttp(WidgetTester tester) async {
    final harness = await tester.pumpConnect(
      capabilities: PlatformCapabilities.forTarget(TargetPlatform.iOS),
    );
    await tester.enterText(find.byType(TextField), 'http://music.example.com');
    await tester.tap(find.text('Connect'));
    await tester.settle();
    return harness;
  }

  testWidgets(
    'on iOS the dialog says the connection is blocked and has no continue '
    'action',
    (tester) async {
      final harness = await submitPublicHttp(tester);

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining(
            'blocks unencrypted connections to public servers',
          ),
        ),
        findsOneWidget,
      );
      final actions = find.descendant(
        of: dialog,
        matching: find.byType(TextButton),
      );
      expect(actions, findsOneWidget);
      expect(
        find.descendant(of: actions, matching: find.text('Cancel')),
        findsOneWidget,
      );
      expect(find.text('Connect anyway'), findsNothing);
      await expectMeetsGuidelines(tester);

      await tester.tap(find.text('Cancel'));
      await tester.settle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.router.state.uri.path, RoutePaths.connect);
      expect(harness.probe.started, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
