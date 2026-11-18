// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/focus_ring.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../helpers/pump_app.dart';

void main() {
  final ring = find.byKey(FocusRingLayer.paintKey);

  /// The ring, 2 px wide in [color], 2 px outside [target].
  PaintPattern ringAround(WidgetTester tester, Finder target, Color color) {
    final rect = tester.getRect(target);
    const outset = FocusRingLayer.offset + FocusRingLayer.width / 2;
    return paints..rrect(
      rrect: RRect.fromRectAndRadius(
        rect.inflate(outset),
        const Radius.circular(FocusRingLayer.radius),
      ),
      color: color,
      style: PaintingStyle.stroke,
      strokeWidth: FocusRingLayer.width,
    );
  }

  /// One focusable of each kind the ring is checked on.
  Widget controls() => Scaffold(
    body: ListView(
      children: [
        TextButton(
          key: const Key('button'),
          onPressed: () {},
          child: const Text('Button'),
        ),
        TrackRow(
          title: 'Come Together',
          artist: 'The Beatles',
          duration: const Duration(minutes: 4),
          leading: const TrackRowLeading.index(1),
          onTap: () {},
        ),
        Center(
          child: SizedBox(
            width: 160,
            child: MediaCard(
              title: 'Abbey Road',
              subtitle: 'The Beatles',
              artworkRef: 'cover-1',
              onTap: () {},
            ),
          ),
        ),
        const TextField(key: Key('field')),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
      ],
    ),
  );

  /// Tabs until focus is inside [target].
  Future<void> tabTo(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 20; i++) {
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused != null) {
        var inside = focused.widget == tester.widget(target);
        focused.visitAncestorElements((element) {
          inside = inside || element == tester.element(target);
          return !inside;
        });
        if (inside) return;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    fail('Tab never reached $target');
  }

  // A button's ring goes around the visible button, inside its tap target.
  final buttonFace = find.descendant(
    of: find.byKey(const Key('button')),
    matching: find.byType(Material),
  );

  final targets = {
    'a button': buttonFace,
    'a TrackRow': find.byType(TrackRow),
    'a MediaCard': find.byType(MediaCard),
    'a navigation item': find.byType(NavigationDestination).first,
    'a text field': find.byType(InputDecorator),
  };

  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    for (final MapEntry(key: name, value: target) in targets.entries) {
      testWidgets('keyboard focus on $name paints the brand ring in '
          '${theme.name}', (tester) async {
        await tester.pumpApp(controls(), theme: theme);
        expect(ring, paintsNothing);

        await tabTo(tester, target);

        final brand = tester.element(target).colors.brand;
        expect(
          brand,
          theme == ThemeMode.dark
              ? SoundspanColors.dark.brand
              : SoundspanColors.light.brand,
        );
        expect(ring, ringAround(tester, target, brand));
      });
    }
  }

  testWidgets('pointer focus paints no ring', (tester) async {
    await tester.pumpApp(controls());
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.down(tester.getCenter(find.byKey(const Key('field'))));
    await mouse.up();
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.context, isNotNull);
    expect(ring, paintsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('touch focus paints no ring, and a key brings it back', (
    tester,
  ) async {
    await tester.pumpApp(controls());

    await tester.tap(find.byKey(const Key('field')));
    await tester.pumpAndSettle();
    expect(ring, paintsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(ring, paints..rrect());
  });

  testWidgets('the ring follows a control that scrolls', (tester) async {
    await tester.pumpApp(controls());
    await tabTo(tester, buttonFace);
    final brand = tester.element(buttonFace).colors.brand;

    await tester.drag(find.byType(ListView), const Offset(0, -20));
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    expect(ring, ringAround(tester, buttonFace, brand));
  });
}
