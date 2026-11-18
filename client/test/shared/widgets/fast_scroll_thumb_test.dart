// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/library/ui/paged_library_view.dart';
import 'package:soundspan/features/library/ui/songs_tab.dart';
import 'package:soundspan/shared/widgets/fast_scroll_thumb.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../features/library/library_harness.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';

void main() {
  final thumb = find.byKey(FastScrollThumb.thumbKey);
  final bubble = find.byKey(FastScrollThumb.bubbleKey);

  ScrollPosition songsPosition(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(SongsTab),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  /// Pumps the Songs tab over [count] tracks.
  Future<LibraryHarness> pumpSongs(WidgetTester tester, int count) =>
      tester.pumpLibrary(
        tab: LibraryTab.songs,
        library: FakeLibraryRepository()..trackList = tracks(count),
        size: const Size(390, 800),
      );

  /// Scrolls the list a little, which shows the thumb when it is offered.
  Future<void> nudge(WidgetTester tester) async {
    final position = songsPosition(tester);
    position.jumpTo(position.pixels + 10);
    await tester.pump();
  }

  String bubbleText(WidgetTester tester) => tester
      .widget<Text>(find.descendant(of: bubble, matching: find.byType(Text)))
      .data!;

  /// Moves the thumb down by [dy] in [steps] equal moves, one frame each,
  /// and returns the gesture still held.
  Future<TestGesture> dragThumb(
    WidgetTester tester,
    double dy, {
    int steps = 1,
  }) async {
    final gesture = await tester.startGesture(tester.getCenter(thumb));
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(0, dy / steps));
      await tester.pump(const Duration(milliseconds: 16));
    }
    return gesture;
  }

  testWidgets('hidden at 200 rows and shown at 201', (tester) async {
    await pumpSongs(tester, 200);
    await nudge(tester);
    expect(thumb, findsNothing);

    await pumpSongs(tester, 201);
    await nudge(tester);
    expect(thumb, findsOneWidget);
    expect(tester.getSize(thumb).height, FastScrollThumb.thumbHeight);

    // It stays for 1.5 s after scrolling stops.
    await tester.pump(const Duration(milliseconds: 1400));
    expect(thumb, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(thumb, findsNothing);
  });

  testWidgets('hidden with a mouse connected', (tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await pumpSongs(tester, 1000);
    await tester.pump();

    await nudge(tester);
    expect(thumb, findsNothing);
  });

  testWidgets('dragging to the middle of 10,000 rows lands near row 5,000 '
      'and keeps the scroll extent', (tester) async {
    await pumpSongs(tester, 10000);
    final position = songsPosition(tester);
    final extent = position.maxScrollExtent;
    final rowExtent = tester.getSize(find.byType(TrackRow).first).height;
    await nudge(tester);

    final track = position.viewportDimension - FastScrollThumb.thumbHeight;
    final gesture = await dragThumb(tester, track / 2, steps: 10);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      (position.pixels - 5000 * rowExtent).abs(),
      lessThan(position.viewportDimension),
    );
    expect(position.maxScrollExtent, extent);
    // The resting page loaded.
    expect(find.byType(TrackRowSkeleton), findsNothing);
    expect(find.byType(TrackRow), findsWidgets);
  });

  testWidgets('the bubble shows the position until the row loads, then its '
      'letter', (tester) async {
    await pumpSongs(tester, 10000);
    final position = songsPosition(tester);
    await nudge(tester);
    expect(bubble, findsNothing);

    final track = position.viewportDimension - FastScrollThumb.thumbHeight;
    final gesture = await dragThumb(tester, track / 2);
    await tester.pump();

    expect(bubble, findsOneWidget);
    expect(bubbleText(tester), matches(RegExp(r'^\d+ / 10000$')));

    await tester.pump(PagedLibraryView.fastScrollRest);
    await tester.pump();
    await tester.pump();
    expect(bubbleText(tester), 'S');

    await gesture.up();
    await tester.pump();
    expect(bubble, findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('a continuous drag over 50 pages requests only the resting '
      'page', (tester) async {
    final harness = await pumpSongs(tester, 10000);
    final source = harness.sources.single;
    final position = songsPosition(tester);
    final rowExtent = tester.getSize(find.byType(TrackRow).first).height;
    await nudge(tester);
    final before = source.requestedPages.length;

    // Each step moves about one page; none rests for 150 ms.
    final track = position.viewportDimension - FastScrollThumb.thumbHeight;
    final gesture = await dragThumb(tester, track / 2, steps: 50);
    expect(source.requestedPages.length, before);

    await tester.pump(PagedLibraryView.fastScrollRest);
    await tester.pump();
    // The first visible row's page, the one after it, and the last visible
    // row's page when that is later.
    final resting = position.pixels ~/ rowExtent ~/ source.pageSize;
    expect(
      source.requestedPages.skip(before).toSet(),
      everyElement(inInclusiveRange(resting, resting + 2)),
    );
    expect(source.requestedPages.skip(before), isNotEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the thumb is left out of the semantics tree', (tester) async {
    await pumpSongs(tester, 1000);
    await nudge(tester);
    expect(thumb, findsOneWidget);

    await expectMeetsGuidelines(tester);
    await tester.pumpAndSettle();
  });
}
