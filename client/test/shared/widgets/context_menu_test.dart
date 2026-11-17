// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart' show PointerDeviceKind, kSecondaryButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';

import '../../helpers/pump_app.dart';

void main() {
  late List<String> selected;

  List<MenuEntry> entries() => [
    MenuEntry(
      id: 'play',
      label: 'Play now',
      icon: Icons.play_arrow_rounded,
      onSelected: () => selected.add('play'),
    ),
    MenuEntry(
      id: 'delete',
      label: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
      onSelected: () => selected.add('delete'),
    ),
  ];

  setUp(() => selected = []);

  /// Pumps a target that opens [menu] on a long press or secondary tap at
  /// the pointer.
  Future<void> pumpTarget(
    WidgetTester tester, [
    List<MenuEntry> Function()? menu,
  ]) async {
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onLongPress: () => showContextMenu(context, (menu ?? entries)()),
              onSecondaryTapUp: (details) => showContextMenu(
                context,
                (menu ?? entries)(),
                position: details.globalPosition,
              ),
              child: const SizedBox(width: 200, height: 80, child: Text('X')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('touch input opens a bottom sheet', (tester) async {
    await pumpTarget(tester);
    await tester.longPress(find.text('X'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(find.text('Play now'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    final context = tester.element(find.text('Play now'));
    expect(sheet.backgroundColor, context.colors.surfaceOverlay);
    expect(
      (sheet.shape! as RoundedRectangleBorder).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(12)),
    );
  });

  testWidgets('a mouse opens a popup at the pointer with the same entries', (
    tester,
  ) async {
    await pumpTarget(tester);
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    addTearDown(mouse.removePointer);
    final at = tester.getTopLeft(find.text('X')) + const Offset(30, 40);
    await mouse.down(at);
    await mouse.up();
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(PopupMenuItem<String>), findsNWidgets(2));
    expect(find.text('Play now'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    final first = tester.getTopLeft(find.byType(PopupMenuItem<String>).first);
    expect(first.dx, closeTo(at.dx, 1));
    expect((first.dy - at.dy).abs(), lessThan(Spacing.x16));
  });

  testWidgets('a desktop platform opens a popup without a mouse', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await pumpTarget(tester);
    await tester.longPress(find.text('X'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsNWidgets(2));
    expect(find.byType(BottomSheet), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('destructive entries are drawn in danger', (tester) async {
    await pumpTarget(tester);
    await tester.longPress(find.text('X'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Delete'));
    expect(
      tester.widget<Text>(find.text('Delete')).style!.color,
      context.colors.danger,
    );
    expect(
      tester.widget<Text>(find.text('Play now')).style!.color,
      context.colors.content,
    );
  });

  testWidgets('an empty list shows nothing', (tester) async {
    await pumpTarget(tester, () => const []);
    await tester.longPress(find.text('X'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(ListTile), findsNothing);
  });

  for (final mouse in [false, true]) {
    testWidgets('choosing an entry closes the ${mouse ? 'popup' : 'sheet'} '
        'and calls it once', (tester) async {
      await pumpTarget(tester);
      if (mouse) {
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        addTearDown(gesture.removePointer);
        await gesture.down(tester.getCenter(find.text('X')));
        await gesture.up();
      } else {
        await tester.longPress(find.text('X'));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(selected, ['delete']);
      expect(find.text('Delete'), findsNothing);
    });
  }
}
