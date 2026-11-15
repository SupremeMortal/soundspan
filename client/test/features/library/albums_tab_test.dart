// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/library/ui/library_controls.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/media_grid_layout.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import 'library_harness.dart';

void main() {
  int columns(WidgetTester tester) {
    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
        .crossAxisCount;
  }

  FakeLibraryRepository library(int count) =>
      FakeLibraryRepository()..albumList = albums(count);

  ScrollPosition position(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  testWidgets('2 columns at 390, 8 at 1440, and the count follows the '
      'formula at 800', (tester) async {
    await tester.pumpLibrary(library: library(100));
    expect(columns(tester), 2);

    await tester.pumpLibrary(library: library(100), size: TestSizes.expanded);
    expect(columns(tester), 8);

    await tester.pumpLibrary(library: library(100), size: TestSizes.medium);
    // The grid spans the window less the gutter, with the card padding
    // lining the artwork up with it.
    const available = 800 - 2 * (24 - MediaCard.padding);
    expect(
      columns(tester),
      ((available + gridSpacing) / (gridMinTileWidth + gridSpacing)).floor(),
    );
    expect(columns(tester), 4);
  });

  testWidgets('shows skeletons for unloaded indexes and cards for loaded '
      'ones', (tester) async {
    final fake = library(500)..pageDelay = const Duration(seconds: 1);
    await tester.pumpLibrary(library: fake);
    await tester.pump();
    // The first pages are still loading.
    expect(find.byType(MediaCardSkeleton), findsWidgets);
    expect(find.byType(MediaCard), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(MediaCard), findsWidgets);
    expect(find.byType(MediaCardSkeleton), findsNothing);
    expect(find.text('Album 0'), findsOneWidget);
  });

  testWidgets('scrolling to index 600 requests the page containing it and '
      'the next, not the pages between', (tester) async {
    final harness = await tester.pumpLibrary(library: library(1000));
    final source = harness.sources.single;
    expect(source.requestedPages, [0, 1]);

    final first = tester.getRect(find.byType(MediaCard).first);
    final second = tester.getRect(find.widgetWithText(MediaCard, 'Album 2'));
    final rowExtent = second.top - first.top;
    final scrollTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    final gridStart = first.top - scrollTop;
    // Index 600 is the first of row 300 in two columns.
    position(tester).jumpTo(gridStart + 300 * rowExtent);
    await tester.pumpAndSettle();

    expect(source.requestedPages, [0, 1, 10, 11]);
    expect(find.text('Album 600'), findsOneWidget);
  });

  testWidgets('total 0 shows the empty state', (tester) async {
    await tester.pumpLibrary(library: library(0));
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No albums yet'), findsOneWidget);
  });

  testWidgets('an error with no cache shows ErrorView and Retry refetches', (
    tester,
  ) async {
    final fake = library(100);
    final harness = await tester.pumpLibrary(
      library: _FailingLibrary(fake, {0, 1}),
    );
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(MediaCard), findsNothing);

    final source = harness.sources.single;
    source.failingPages.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(source.refreshCount, 1);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Album 0'), findsOneWidget);
  });

  testWidgets('a refresh error with cache keeps the grid and shows a '
      'snackbar', (tester) async {
    final harness = await tester.pumpLibrary(library: library(100));
    final source = harness.sources.single;
    source.failingPages.add(0);
    unawaited(source.refresh());
    await tester.pumpAndSettle();
    expect(find.text('Album 0'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Couldn’t refresh the list'), findsOneWidget);
  });

  testWidgets('pull to refresh calls refresh', (tester) async {
    final harness = await tester.pumpLibrary(library: library(100));
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(harness.sources.single.refreshCount, 1);
  });

  testWidgets('tapping an album opens its detail route inside the Library '
      'branch', (tester) async {
    final harness = await tester.pumpLibrary(library: library(10));
    await tester.tap(find.text('Album 3'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/albums/album/al3');
  });

  testWidgets('changing sort requests a new source with that sortBy and '
      'returns to the top', (tester) async {
    final harness = await tester.pumpLibrary(library: library(500));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(position(tester).pixels, greaterThan(0));

    await tester.tap(find.byKey(LibrarySortMenu.buttonKey));
    await tester.pumpAndSettle();
    expect(find.text('Name (A-Z)'), findsOneWidget);
    expect(find.text('Name (Z-A)'), findsOneWidget);
    await tester.tap(
      find.ancestor(
        of: find.text('Year (newest)'),
        matching: find.byType(CheckedPopupMenuItem<AlbumSort>),
      ),
    );
    await tester.pumpAndSettle();

    expect(harness.library.queries, [
      const AlbumQuery(),
      const AlbumQuery(sortBy: AlbumSort.recent),
    ]);
    expect(harness.sources.first.disposed, isTrue);
    expect(position(tester).pixels, 0);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
        'meets the guidelines at ${size.width.toInt()} in ${theme.name}',
        (tester) async {
          await tester.pumpLibrary(
            library: library(100),
            size: size,
            theme: theme,
            federation: true,
          );
          await expectMeetsGuidelines(tester);
        },
      );
    }
  }

  testWidgets('has no overflow at text scale 2.0', (tester) async {
    await tester.pumpLibrary(
      library: library(100),
      textScale: 2,
      federation: true,
    );
    expect(tester.takeException(), isNull);
  });
}

/// A library whose album sources fail [failingPages].
class _FailingLibrary extends FakeLibraryRepository {
  new(FakeLibraryRepository base, this.failingPages) {
    albumList = base.albumList;
  }

  final Set<int> failingPages;

  @override
  PagedSource<Album> albums(AlbumQuery query) {
    queries.add(query);
    final source = FakePagedSource<Album>(
      items: albumList,
      pageSize: gridPageSize,
      failingPages: {...failingPages},
      failure: const ServerError(),
    );
    sources.add(source);
    return source;
  }
}
