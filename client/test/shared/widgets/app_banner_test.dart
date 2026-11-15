// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  Widget banner(
    AppBannerKind kind, {
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) => Align(
    alignment: Alignment.topCenter,
    child: AppBanner(
      kind: kind,
      message: 'A message',
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
    ),
  );

  Color? fill(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(AppBanner),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return (box.decoration as BoxDecoration).color;
  }

  testWidgets('offline kind is neutral on surfaceActive', (tester) async {
    await tester.pumpApp(banner(AppBannerKind.offline));
    final colors = tester.element(find.byType(AppBanner)).colors;

    expect(find.text('A message'), findsOneWidget);
    expect(fill(tester), colors.surfaceActive);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('linkExpiring kind uses the warning colour', (tester) async {
    await tester.pumpApp(banner(AppBannerKind.linkExpiring));
    final colors = tester.element(find.byType(AppBanner)).colors;

    final icon = tester.widget<Icon>(
      find.descendant(of: find.byType(AppBanner), matching: find.byType(Icon)),
    );
    expect(icon.color, colors.warning);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('serverNotice kind is neutral', (tester) async {
    await tester.pumpApp(banner(AppBannerKind.serverNotice));
    final colors = tester.element(find.byType(AppBanner)).colors;

    expect(fill(tester), colors.surfaceActive);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('is full width', (tester) async {
    await tester.pumpApp(
      banner(AppBannerKind.offline),
      size: TestSizes.expanded,
    );

    expect(
      tester.getSize(find.byType(AppBanner)).width,
      TestSizes.expanded.width,
    );
  });

  testWidgets('action and dismiss call their callbacks', (tester) async {
    var actions = 0;
    var dismissals = 0;
    await tester.pumpApp(
      banner(
        AppBannerKind.linkExpiring,
        actionLabel: 'Re-link',
        onAction: () => actions++,
        onDismiss: () => dismissals++,
      ),
    );

    await tester.tap(find.text('Re-link'));
    expect(actions, 1);
    await tester.tap(find.byTooltip('Dismiss'));
    expect(dismissals, 1);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('no dismiss button without a callback', (tester) async {
    await tester.pumpApp(banner(AppBannerKind.serverNotice));

    expect(find.byTooltip('Dismiss'), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('dismiss button has a label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(banner(AppBannerKind.offline, onDismiss: () {}));

    expect(
      tester.getSemantics(find.byType(IconButton)),
      isSemantics(
        tooltip: 'Dismiss',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('announced as a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(banner(AppBannerKind.offline));

    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('A message'))),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}
