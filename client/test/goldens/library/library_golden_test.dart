// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/library/ui/songs_tab.dart';
import 'package:soundspan/shared/widgets/fast_scroll_thumb.dart';

import '../../features/detail_fixtures.dart';
import '../../features/library/library_harness.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

/// A medium window in landscape: the two-pane layout.
const Size _landscape = Size(800, 600);

/// Library goldens of the tablet two-pane layout and the fast-scroll
/// bubble (doc 09, Shell by Window Class; Library).
void main() {
  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    for (final (name, size, select) in [
      ('library_albums_two_pane', _landscape, false),
      ('library_albums_two_pane_selected', _landscape, true),
      ('library_albums_selected', TestSizes.medium, true),
    ]) {
      final fileName = goldenFileName(name, size: size, theme: theme);
      testWidgets(fileName, tags: ['golden'], (tester) async {
        final repositories = albumRepositories(
          [fixtureTrack(1), fixtureTrack(2), fixtureTrack(3)],
          others: [for (var i = 2; i <= 9; i++) fixtureAlbum('al-$i')],
        );
        final harness = await tester.pumpLibrary(
          library: repositories.library,
          size: size,
          theme: theme,
        );
        if (select) {
          harness.router.go('/album/al-1');
          await tester.pumpAndSettle();
        }

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(goldenPath(fileName)),
        );
      });
    }

    final songs = goldenFileName(
      'library_songs_fast_scroll',
      size: TestSizes.compact,
      theme: theme,
    );
    testWidgets(songs, tags: ['golden'], (tester) async {
      await tester.pumpLibrary(
        tab: LibraryTab.songs,
        library: FakeLibraryRepository()..trackList = tracks(1000),
        theme: theme,
      );
      tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(SongsTab),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .jumpTo(10);
      await tester.pump();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(FastScrollThumb.thumbKey)),
      );
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      await tester.pump();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath(songs)),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });
  }
}
