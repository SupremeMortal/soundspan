// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/library/ui/playlists_tab.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_row.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import 'library_harness.dart';

void main() {
  FakePlaylistRepository seeded(int count) =>
      FakePlaylistRepository()..playlistList = playlists(count);

  Finder row(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(MediaRow));

  testWidgets('Liked Songs is first and opens /playlist/liked', (tester) async {
    final harness = await tester.pumpLibrary(
      tab: LibraryTab.playlists,
      playlists: seeded(5),
    );
    final rows = tester.widgetList<MediaRow>(find.byType(MediaRow));
    expect(rows.first.title, 'Liked Songs');
    expect(rows.elementAt(1).title, 'New playlist');
    expect(rows.elementAt(2).title, 'Playlist 0');
    expect(
      tester.getTopLeft(row('Liked Songs')).dy,
      lessThan(tester.getTopLeft(row('Playlist 0')).dy),
    );

    await tester.tap(find.text('Liked Songs'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/playlists/playlist/liked');
  });

  testWidgets('a playlist row shows a mosaic, the name and a pluralized '
      'track count', (tester) async {
    await tester.pumpLibrary(tab: LibraryTab.playlists, playlists: seeded(3));
    expect(
      find.descendant(of: row('Playlist 0'), matching: find.text('1 song')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row('Playlist 2'), matching: find.text('3 songs')),
      findsOneWidget,
    );
    final mosaic = tester.widget<MosaicArtwork>(
      find.descendant(
        of: row('Playlist 1'),
        matching: find.byType(MosaicArtwork),
      ),
    );
    expect(mosaic.refs, ['c1-1', 'c1-2', 'c1-3', 'c1-4']);
    expect(tester.getSize(row('Playlist 1')).height, PlaylistsTab.rowHeight);
  });

  testWidgets('tapping opens the playlist route in the Library branch', (
    tester,
  ) async {
    final harness = await tester.pumpLibrary(
      tab: LibraryTab.playlists,
      playlists: seeded(5),
    );
    await tester.tap(find.text('Playlist 3'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/playlists/playlist/pl3');
  });

  testWidgets('with no playlists Liked Songs and the hint are shown', (
    tester,
  ) async {
    await tester.pumpLibrary(tab: LibraryTab.playlists);
    expect(find.text('Liked Songs'), findsOneWidget);
    expect(find.byKey(PlaylistsTab.hintKey), findsOneWidget);
    expect(find.text('Playlists you create appear here'), findsOneWidget);
    expect(find.byType(MediaRow), findsNWidgets(2));
  });

  testWidgets('a failed load keeps Liked Songs above the error view', (
    tester,
  ) async {
    final repository = seeded(5)
      ..failingPages = {0}
      ..failure = const ServerError();
    await tester.pumpLibrary(tab: LibraryTab.playlists, playlists: repository);
    expect(find.text('Liked Songs'), findsOneWidget);
    expect(find.byType(ErrorView), findsOneWidget);

    repository.sources.single.failingPages.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Playlist 0'), findsOneWidget);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
        'meets the guidelines at ${size.width.toInt()} in ${theme.name}',
        (tester) async {
          await tester.pumpLibrary(
            tab: LibraryTab.playlists,
            playlists: seeded(20),
            size: size,
            theme: theme,
          );
          await expectMeetsGuidelines(tester);
        },
      );
    }
  }

  testWidgets('has no overflow at text scale 2.0', (tester) async {
    await tester.pumpLibrary(
      tab: LibraryTab.playlists,
      playlists: seeded(20),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Playlist 0'), findsOneWidget);
  });
}
