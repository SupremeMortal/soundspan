// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/features/library/library.dart';
import 'package:soundspan/features/library/ui/playlists_tab.dart';
import 'package:soundspan/features/library/ui/songs_tab.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';
import 'package:soundspan/shared/widgets/offline_banner.dart';

import '../../helpers/fake_reachability.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import 'library_harness.dart';

void main() {
  Finder tab(String label) =>
      find.descendant(of: find.byType(TabBar), matching: find.text(label));

  FakeLibraryRepository seeded() => FakeLibraryRepository()
    ..albumList = albums(200)
    ..artistList = artists(200);

  testWidgets('tabs appear in order and follow the route', (tester) async {
    final harness = await tester.pumpLibrary(tab: LibraryTab.artists);
    final labels = tester
        .widgetList<Tab>(find.byType(Tab))
        .map((t) => t.text)
        .toList();
    expect(labels, ['Playlists', 'Artists', 'Albums', 'Songs', 'Downloads']);
    final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(controller.index, LibraryTab.artists.index);

    harness.router.go('/library/songs');
    await tester.pumpAndSettle();
    expect(controller.index, LibraryTab.songs.index);
    expect(find.byType(LibraryScreen), findsOneWidget);
  });

  testWidgets('selecting a tab updates the location', (tester) async {
    final harness = await tester.pumpLibrary(tab: LibraryTab.playlists);
    await tester.tap(tab('Albums'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/albums');
    await tester.tap(tab('Artists'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/artists');
  });

  testWidgets('a tab keeps its scroll offset after switching away and back', (
    tester,
  ) async {
    final harness = await tester.pumpLibrary(library: seeded());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    double offset() => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    final scrolled = offset();
    expect(scrolled, greaterThan(0));

    await tester.tap(tab('Artists'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/artists');
    expect(offset(), 0);

    await tester.tap(tab('Albums'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/albums');
    expect(offset(), scrolled);
    // The albums source is the one opened first; switching did not reopen it.
    expect(harness.library.queries.whereType<Object>().length, 2);
  });

  testWidgets('Songs and Playlists show their tabs and open a source only '
      'when shown', (tester) async {
    final harness = await tester.pumpLibrary(tab: LibraryTab.songs);
    expect(find.byType(SongsTab), findsOneWidget);
    expect(find.byType(PlaylistsTab), findsNothing);
    expect(harness.library.queries, [const TrackQuery()]);
    expect(harness.playlists.sources, isEmpty);

    harness.router.go('/library/playlists');
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistsTab), findsOneWidget);
    expect(harness.playlists.sources, hasLength(1));
    expect(harness.library.queries, [const TrackQuery()]);
  });

  for (final (state, text) in [
    (
      Reachability.noNetwork,
      'You’re offline. Showing what’s saved on this device.',
    ),
    (
      Reachability.serverUnreachable,
      'Can’t reach the server. Showing what’s saved on this device.',
    ),
    (Reachability.forcedOffline, 'Offline mode is on.'),
  ]) {
    testWidgets('${state.name} shows its offline banner at the top over the '
        'cached list, requesting no refresh', (tester) async {
      final harness = await tester.pumpLibrary(
        library: seeded(),
        reachability: FakeReachability(initial: state),
      );

      expect(find.text(text), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(OfflineBanner)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(IndexedStack)).dy),
      );
      expect(find.text('Album 0'), findsOneWidget);
      expect(harness.sources.map((s) => s.refreshCount), everyElement(0));
    });
  }

  testWidgets('no offline banner while online', (tester) async {
    await tester.pumpLibrary(library: seeded());
    expect(find.byType(AppBanner), findsNothing);
  });

  testWidgets('Retry on the server-unreachable banner probes at once', (
    tester,
  ) async {
    final reachability = FakeReachability(
      initial: Reachability.serverUnreachable,
    );
    await tester.pumpLibrary(reachability: reachability);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(reachability.probes, 1);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
        'meets the guidelines at ${size.width.toInt()} in ${theme.name}',
        (tester) async {
          await tester.pumpLibrary(
            tab: LibraryTab.songs,
            size: size,
            theme: theme,
          );
          await expectMeetsGuidelines(tester);
        },
      );
    }
  }

  testWidgets('has no overflow at text scale 2.0', (tester) async {
    await tester.pumpLibrary(tab: LibraryTab.playlists, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
