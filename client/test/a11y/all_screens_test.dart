// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'screen_registry.dart';

void main() {
  const variants = [
    PumpOptions(size: TestSizes.compact, theme: ThemeMode.dark),
    PumpOptions(size: TestSizes.compact, theme: ThemeMode.light),
    PumpOptions(size: TestSizes.expanded, theme: ThemeMode.dark),
    PumpOptions(size: TestSizes.expanded, theme: ThemeMode.light),
  ];

  for (final screen in registry) {
    for (final options in variants) {
      testWidgets('$screen is accessible at $options', (tester) async {
        await screen.pump(tester, options);
        if (screen.name.endsWith('dialog')) {
          expect(find.byType(Dialog), findsOneWidget);
        }
        await expectAccessible(
          tester,
          skip: {?screen.exemptGuideline},
          contrastSamplingExempt:
              screen.contrastSamplingExempt?.call(options) ?? const [],
        );
        final untitled = [
          for (final button in tester.widgetList<IconButton>(
            find.byType(IconButton),
          ))
            if (button.tooltip?.isNotEmpty != true) button,
        ];
        expect(
          untitled,
          isEmpty,
          reason: 'every IconButton has a tooltip: $untitled',
        );
      });
    }
  }

  testWidgets('every route path of the router has a registry case', (
    tester,
  ) async {
    final routes = await appRoutes(tester);
    expect(uncoveredRoutePatterns(routes, registry), isEmpty);
  });
}
