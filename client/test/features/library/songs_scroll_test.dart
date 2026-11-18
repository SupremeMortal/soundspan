// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/library/ui/songs_tab.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../helpers/fake_repositories.dart';
import 'library_harness.dart';

void main() {
  testWidgets('scroll extent is stable over a 10,000-row source', (
    tester,
  ) async {
    const pageDelay = Duration(milliseconds: 500);
    final library = FakeLibraryRepository()
      ..trackList = tracks(10000)
      ..pageDelay = pageDelay;
    final harness = await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library,
      size: const Size(390, 800),
      settle: false,
    );
    await tester.pump();
    final source = harness.sources.single;
    expect(source.total, 10000);
    expect(find.byType(TrackRow), findsNothing, reason: 'no page loaded yet');

    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(SongsTab),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    final rowExtent = tester
        .getSize(find.byType(TrackRowSkeleton).first)
        .height;
    final expected =
        10000 * rowExtent + SongsTab.bottomPadding - position.viewportDimension;
    expect(position.maxScrollExtent, moreOrLessEquals(expected));

    var maxBuilt = 0;
    void check() {
      expect(position.maxScrollExtent, moreOrLessEquals(expected));
      final built =
          find.byType(TrackRow, skipOffstage: false).evaluate().length +
          find.byType(TrackRowSkeleton, skipOffstage: false).evaluate().length;
      if (built > maxBuilt) maxBuilt = built;
    }

    for (final index in [0, 2500, 5000, 9999, 0]) {
      position.jumpTo(
        (index * rowExtent).clamp(0, position.maxScrollExtent).toDouble(),
      );
      await tester.pump();
      check();
      await tester.pump();
      check();

      if (index == 5000) {
        // Row 5000 is a skeleton until its page arrives, at the same place.
        // The first skeleton on screen stands for row 5000.
        final skeletonTop = tester
            .getTopLeft(find.byType(TrackRowSkeleton).first)
            .dy;
        await tester.pump(pageDelay);
        await tester.pump();
        check();
        expect(find.text('Song 5000'), findsOneWidget);
        expect(
          tester
              .getTopLeft(
                find.ancestor(
                  of: find.text('Song 5000'),
                  matching: find.byType(TrackRow),
                ),
              )
              .dy,
          moreOrLessEquals(skeletonTop),
        );
      } else {
        await tester.pump(pageDelay);
        await tester.pump();
        check();
      }
    }

    expect(
      source.requestedPages.toSet(),
      everyElement(isIn(const {0, 1, 25, 26, 50, 51, 99})),
    );
    expect(source.requestedPages, containsAll(const [50, 51]));
    expect(maxBuilt, lessThan(60));
    expect(maxBuilt, greaterThan(0));
  });

  testWidgets('scrolling does not rebuild the rows on screen', (tester) async {
    final library = FakeLibraryRepository()..trackList = tracks(10000);
    final harness = await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library,
      size: const Size(390, 800),
    );
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(SongsTab),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    final row = find.ancestor(
      of: find.text('Song 5'),
      matching: find.byType(TrackRow),
    );
    final before = tester.widget<TrackRow>(row);
    final requested = harness.sources.single.requestedPages.length;

    for (var offset = 1; offset <= 10; offset++) {
      position.jumpTo(offset * 3.0);
      await tester.pump();
      expect(identical(tester.widget<TrackRow>(row), before), isTrue);
    }

    // The visible range is still followed: scrolling far requests its page.
    position.jumpTo(position.maxScrollExtent / 2);
    await tester.pumpAndSettle();
    expect(
      harness.sources.single.requestedPages.length,
      greaterThan(requested),
    );
    expect(find.text('Song 5000'), findsOneWidget);
  });
}
