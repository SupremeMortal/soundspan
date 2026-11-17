// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/two_pane.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/features/library/ui/library_screen.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../library_harness.dart';

void main() {
  const landscape = Size(800, 600);

  Future<LibraryHarness> pump(
    WidgetTester tester, {
    Size size = landscape,
    LibraryTab tab = LibraryTab.albums,
    ThemeMode theme = ThemeMode.dark,
  }) => tester.pumpLibrary(
    tab: tab,
    size: size,
    theme: theme,
    library: FakeLibraryRepository()..albumList = albums(6),
  );

  final empty = find.byKey(TwoPaneList.emptyKey);
  final listPane = find
      .descendant(
        of: find.byType(LibraryScreen),
        matching: find.byType(Scaffold),
      )
      .first;
  final detail = find.byType(AlbumScreen);

  MediaCard card(WidgetTester tester, String title) => tester.widget<MediaCard>(
    find.ancestor(of: find.text(title), matching: find.byType(MediaCard)),
  );

  Future<void> resize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    await tester.pumpAndSettle();
  }

  testWidgets('800 × 600 shows the list pane beside an empty detail pane', (
    tester,
  ) async {
    await pump(tester);

    expect(tester.getSize(listPane).width, TwoPane.listWidth);
    expect(empty, findsOneWidget);
    expect(find.text('Select an item'), findsOneWidget);
    expect(
      tester.getTopLeft(empty).dx,
      greaterThanOrEqualTo(TwoPane.listWidth),
    );
    await expectMeetsGuidelines(tester);
  });

  testWidgets('selecting an album opens it in the detail pane and highlights '
      'its card; Back clears the selection', (tester) async {
    final harness = await pump(tester);

    await tester.tap(find.text('Album 2'));
    await tester.pumpAndSettle();

    expect(harness.location, '/library/albums/album/al2');
    expect(detail, findsOneWidget);
    expect(
      tester.getTopLeft(detail).dx,
      TwoPane.listWidth + TwoPane.dividerWidth,
    );
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(card(tester, 'Album 2').selected, isTrue);
    expect(card(tester, 'Album 1').selected, isFalse);
    final colors = tester.element(detail).colors;
    expect(
      tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.ancestor(
                of: find.text('Album 2'),
                matching: find.byType(MediaCard),
              ),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as BoxDecoration?)?.color),
      contains(colors.surfaceActive),
    );

    // Another album replaces the open one; the list stays usable.
    await tester.tap(find.text('Album 3'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/albums/album/al3');
    expect(card(tester, 'Album 3').selected, isTrue);
    expect(card(tester, 'Album 2').selected, isFalse);
    await expectMeetsGuidelines(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(harness.location, '/library/albums');
    expect(detail, findsNothing);
    expect(empty, findsOneWidget);
    expect(card(tester, 'Album 3').selected, isFalse);
  });

  testWidgets('800 × 1280 with a selection shows the detail pushed over the '
      'list, and rotating back restores the panes', (tester) async {
    final harness = await pump(tester);
    await tester.tap(find.text('Album 2'));
    await tester.pumpAndSettle();

    await resize(tester, TestSizes.medium);
    expect(harness.location, '/library/albums/album/al2');
    expect(detail, findsOneWidget);
    expect(tester.getTopLeft(detail).dx, 0);
    expect(tester.getSize(detail).width, TestSizes.medium.width);
    expect(find.byType(LibraryScreen), findsNothing);
    expect(empty, findsNothing);

    await resize(tester, landscape);
    expect(harness.location, '/library/albums/album/al2');
    expect(
      tester.getTopLeft(detail).dx,
      TwoPane.listWidth + TwoPane.dividerWidth,
    );
    expect(card(tester, 'Album 2').selected, isTrue);
  });

  testWidgets('the Songs tab stays single-pane', (tester) async {
    await pump(tester, tab: LibraryTab.songs);

    expect(empty, findsNothing);
    expect(tester.getSize(listPane).width, landscape.width);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    testWidgets('${size.width.toInt()} never shows two panes', (tester) async {
      final harness = await pump(tester, size: size);
      expect(empty, findsNothing);

      await tester.tap(find.text('Album 1'));
      await tester.pumpAndSettle();

      expect(harness.location, '/library/albums/album/al1');
      expect(tester.getTopLeft(detail).dx, 0);
      expect(find.byType(LibraryScreen), findsNothing);
    });
  }

  testWidgets('meets the guidelines in light', (tester) async {
    await pump(tester, theme: ThemeMode.light);
    await tester.tap(find.text('Album 2'));
    await tester.pumpAndSettle();

    await expectMeetsGuidelines(tester);
  });
}
