// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('without an action shows the icon and the sentence only', (
    tester,
  ) async {
    await tester.pumpApp(
      const EmptyState(
        icon: Icons.library_music_rounded,
        message: 'Nothing here yet',
      ),
    );

    expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.byType(ButtonStyleButton), findsNothing);
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(EmptyState),
              matching: find.byType(Column),
            ),
          )
          .width,
      lessThanOrEqualTo(EmptyState.maxWidth),
    );
    await expectMeetsGuidelines(tester);
  });

  testWidgets('with an action shows a button that calls onAction', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpApp(
      EmptyState(
        icon: Icons.library_music_rounded,
        message: 'Nothing here yet',
        actionLabel: 'Browse',
        onAction: () => actions++,
      ),
    );

    await tester.tap(find.text('Browse'));
    expect(actions, 1);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('is centred in its parent', (tester) async {
    await tester.pumpApp(
      const EmptyState(
        icon: Icons.library_music_rounded,
        message: 'Nothing here yet',
      ),
      size: TestSizes.expanded,
    );

    final centre = tester.getCenter(find.text('Nothing here yet'));
    expect(centre.dx, closeTo(TestSizes.expanded.width / 2, 1));
  });
}
