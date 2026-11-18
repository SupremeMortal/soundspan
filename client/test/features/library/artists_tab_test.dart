// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import 'library_harness.dart';

void main() {
  FakeLibraryRepository library(int count) =>
      FakeLibraryRepository()..artistList = artists(count);

  testWidgets('cards are round and labelled with the artist name', (
    tester,
  ) async {
    await tester.pumpLibrary(tab: LibraryTab.artists, library: library(10));
    final card = tester.widget<MediaCard>(
      find.widgetWithText(MediaCard, 'Artist 1'),
    );
    expect(card.shape, ArtworkShape.circle);
    expect(card.onPlay, isNull);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('^Artist 1, ')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tapping opens the artist route', (tester) async {
    final harness = await tester.pumpLibrary(
      tab: LibraryTab.artists,
      library: library(10),
    );
    await tester.tap(find.text('Artist 2'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/artists/artist/ar2');
  });

  testWidgets('origin chips are hidden without federation and map to the '
      'origin parameter with it', (tester) async {
    var harness = await tester.pumpLibrary(
      tab: LibraryTab.artists,
      library: library(10),
    );
    expect(find.byType(ChoiceChip), findsNothing);

    harness = await tester.pumpLibrary(
      tab: LibraryTab.artists,
      library: library(10),
      federation: true,
    );
    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .map((chip) => (chip.label as Text).data)
        .toList();
    expect(chips, ['All', 'Local', 'Peers', 'Remote']);

    for (final (label, origin) in [
      ('Local', LibraryOrigin.local),
      ('Peers', LibraryOrigin.peers),
      ('Remote', LibraryOrigin.remote),
      ('All', LibraryOrigin.all),
    ]) {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      expect(harness.library.queries.last, ArtistQuery(origin: origin));
    }
    expect(harness.library.queries.first, const ArtistQuery());
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
        'meets the guidelines at ${size.width.toInt()} in ${theme.name}',
        (tester) async {
          await tester.pumpLibrary(
            tab: LibraryTab.artists,
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
      tab: LibraryTab.artists,
      library: library(100),
      textScale: 2,
      federation: true,
    );
    expect(tester.takeException(), isNull);
  });
}
