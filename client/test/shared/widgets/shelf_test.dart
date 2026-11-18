// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/shelf.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  final built = <int>{};

  Widget shelf({
    int itemCount = 200,
    VoidCallback? onShowAll,
    WindowClass windowClass = WindowClass.compact,
  }) => WindowClassScope(
    windowClass: windowClass,
    child: Align(
      alignment: Alignment.topLeft,
      child: Shelf(
        title: 'Recently added',
        itemCount: itemCount,
        onShowAll: onShowAll,
        itemBuilder: (context, index) {
          built.add(index);
          return MediaCard(
            title: 'Album $index',
            subtitle: 'Artist $index',
            artworkRef: 'cover-$index',
            onTap: () {},
          );
        },
      ),
    ),
  );

  setUp(built.clear);

  Future<void> connectMouse(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await tester.pump();
  }

  final back = find.byTooltip('Scroll back');
  final forward = find.byTooltip('Scroll forward');

  bool enabled(WidgetTester tester, Finder button) =>
      tester
          .widget<IconButton>(
            find.ancestor(of: button, matching: find.byType(IconButton)),
          )
          .onPressed !=
      null;

  double offset(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  testWidgets('builds only visible cards of 200', (tester) async {
    await tester.pumpApp(shelf());

    expect(find.text('Album 0'), findsOneWidget);
    expect(find.text('Album 199'), findsNothing);
    expect(built.length, lessThan(10));
    await expectMeetsGuidelines(tester);
  });

  testWidgets('arrows page and disable at the ends on pointer devices', (
    tester,
  ) async {
    await tester.pumpApp(shelf(itemCount: 6), size: TestSizes.medium);
    await connectMouse(tester);

    expect(back, findsOneWidget);
    expect(enabled(tester, back), isFalse);
    expect(enabled(tester, forward), isTrue);

    final viewport = tester.getSize(find.byType(Scrollable)).width;
    await tester.tap(forward);
    await tester.pumpAndSettle();
    final maxExtent = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .maxScrollExtent;
    expect(offset(tester), viewport < maxExtent ? viewport : maxExtent);

    while (enabled(tester, forward)) {
      await tester.tap(forward);
      await tester.pumpAndSettle();
    }
    expect(offset(tester), maxExtent);
    expect(enabled(tester, back), isTrue);

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(offset(tester), maxExtent - viewport < 0 ? 0 : maxExtent - viewport);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('arrows stay when the mouse leaves the window', (tester) async {
    await tester.pumpApp(shelf(itemCount: 6), size: TestSizes.medium);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await tester.pump();
    final height = tester.getSize(find.byType(Shelf)).height;

    await mouse.removePointer();
    await tester.pump();

    expect(back, findsOneWidget);
    expect(forward, findsOneWidget);
    expect(tester.getSize(find.byType(Shelf)).height, height);
  });

  testWidgets('arrows show on desktop before any mouse', (tester) async {
    await tester.pumpApp(shelf());

    expect(back, findsOneWidget);
    expect(forward, findsOneWidget);
  }, variant: const TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('arrows are absent on touch', (tester) async {
    await tester.pumpApp(shelf());

    expect(back, findsNothing);
    expect(forward, findsNothing);
  });

  testWidgets('a fling on touch settles on a card edge', (tester) async {
    await tester.pumpApp(shelf());

    await tester.fling(find.byType(Scrollable), const Offset(-250, 0), 1000);
    await tester.pumpAndSettle();
    expect(offset(tester) % Shelf.cardWidth, 0);
    expect(offset(tester), greaterThan(0));
  });

  testWidgets('Show all is absent without a callback', (tester) async {
    await tester.pumpApp(shelf());
    expect(find.text('Show all'), findsNothing);

    var opened = 0;
    await tester.pumpApp(shelf(onShowAll: () => opened++));
    await tester.tap(find.text('Show all'));
    expect(opened, 1);
  });

  testWidgets('empty shelf renders nothing', (tester) async {
    await tester.pumpApp(shelf(itemCount: 0));

    expect(find.text('Recently added'), findsNothing);
    expect(tester.getSize(find.byType(Shelf)), Size.zero);
  });

  for (final (windowClass, gutter) in [
    (WindowClass.compact, 16.0),
    (WindowClass.medium, 24.0),
    (WindowClass.expanded, 32.0),
  ]) {
    testWidgets('gutter follows the window class (${windowClass.name})', (
      tester,
    ) async {
      await tester.pumpApp(shelf(windowClass: windowClass));

      expect(tester.getTopLeft(find.text('Recently added')).dx, gutter);
      expect(tester.getTopLeft(find.byType(Artwork).first).dx, gutter);
    });
  }

  testWidgets('cards are 160 wide and fit at text scale 2.0', (tester) async {
    await tester.pumpApp(shelf(), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MediaCard).first).width, 160);
  });
}
