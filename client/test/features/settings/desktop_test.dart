// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';
import 'package:soundspan/features/settings/settings.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

void main() {
  Future<void> openDesktop(
    WidgetTester tester, {
    Size size = TestSizes.expanded,
  }) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: size,
    );
    root.container.read(routerProvider).go(SettingsSection.desktop.path);
    await tester.pumpAndSettle();
  }

  /// The keys shown on the line of the binding labelled [label].
  String keysOf(WidgetTester tester, String label) {
    final line = find.ancestor(
      of: find.text(label),
      matching: find.byType(ListTile),
    );
    final texts = tester.widgetList<Text>(
      find.descendant(of: line, matching: find.byType(Text)),
    );
    return texts.last.data!;
  }

  testWidgets('lists one line per binding with Ctrl names', (tester) async {
    await openDesktop(tester);

    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    for (final binding in shortcutBindings) {
      await tester.scrollUntilVisible(
        find.byKey(DesktopSection.lineKey(binding)),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(DesktopSection.lineKey(binding)), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text('Next track'),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(keysOf(tester, 'Next track'), 'Ctrl+→');
    expect(keysOf(tester, 'Play or pause'), 'Space');
    expect(keysOf(tester, 'Search'), 'Ctrl+K / /');
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  Future<void> openList(WidgetTester tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    root.container.read(routerProvider).go(RoutePaths.settings);
    await tester.pumpAndSettle();
  }

  testWidgets('is hidden on Android', (tester) async {
    await openList(tester);

    expect(find.widgetWithText(ListTile, 'Appearance'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Desktop'), findsNothing);
  });

  testWidgets('is listed on Linux', (tester) async {
    await openList(tester);

    expect(find.widgetWithText(ListTile, 'Desktop'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
