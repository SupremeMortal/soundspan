// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/like_button.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  Icon icon(WidgetTester tester) => tester.widget<Icon>(find.byType(Icon));

  testWidgets('not liked: outlined heart, "Like"', (tester) async {
    await tester.pumpApp(
      Center(child: LikeButton(liked: false, onToggle: () {})),
    );

    expect(icon(tester).icon, Icons.favorite_border_rounded);
    final context = tester.element(find.byType(LikeButton));
    expect(icon(tester).color, context.colors.contentSecondary);
    expect(find.byTooltip('Like'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LikeButton)),
      matchesSemantics(
        label: 'Like',
        tooltip: 'Like',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasToggledState: true,
      ),
    );
    await expectMeetsGuidelines(tester);
  });

  testWidgets('liked: heart filled in brand, "Remove like"', (tester) async {
    await tester.pumpApp(
      Center(child: LikeButton(liked: true, onToggle: () {})),
    );

    expect(icon(tester).icon, Icons.favorite_rounded);
    final context = tester.element(find.byType(LikeButton));
    expect(icon(tester).color, context.colors.brand);
    expect(find.byTooltip('Remove like'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LikeButton)),
      isSemantics(label: 'Remove like', isToggled: true),
    );
    await expectMeetsGuidelines(tester);
  });

  testWidgets('a tap calls onToggle', (tester) async {
    var toggles = 0;
    await tester.pumpApp(
      Center(child: LikeButton(liked: false, onToggle: () => toggles++)),
    );

    await tester.tap(find.byType(LikeButton));

    expect(toggles, 1);
  });

  testWidgets('a null onToggle disables it', (tester) async {
    await tester.pumpApp(
      const Center(child: LikeButton(liked: false, onToggle: null)),
    );

    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    expect(
      tester.getSemantics(find.byType(LikeButton)),
      isSemantics(isEnabled: false, hasTapAction: false),
    );
    await expectMeetsGuidelines(tester);
  });
}
