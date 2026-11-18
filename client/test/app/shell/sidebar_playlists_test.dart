// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/sidebar_playlists.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

List<PlaylistSummary> _playlists(int count) => [
  for (var i = 0; i < count; i++)
    PlaylistSummary(
      id: 'pl$i',
      name: 'Playlist $i',
      trackCount: 1,
      isOwner: true,
      isPublic: false,
    ),
];

extension on WidgetTester {
  Future<void> pumpShell({
    Size size = TestSizes.expanded,
    int playlists = 5,
    String? openPlaylistId,
    ThemeMode theme = ThemeMode.dark,
  }) async {
    final repositories = FakeRepositories(
      playlists: FakePlaylistRepository()..playlistList = _playlists(playlists),
    );
    await pumpApp(
      AppShell(
        selectedIndex: 2,
        onDestinationSelected: (_) {},
        onSearch: (_) {},
        openPlaylistId: openPlaylistId,
        child: const PlaceholderScreen('Library', branchRoot: true),
      ),
      size: size,
      theme: theme,
      overrides: <Override>[
        ...repositories.overrides,
        profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
        initialActiveProfileIdProvider.overrideWithValue(null),
      ],
    );
    await pumpAndSettle();
  }
}

void main() {
  Finder inSidebar(String text, {bool skipOffstage = true}) => find.descendant(
    of: find.byType(SidebarPlaylists),
    matching: find.text(text, skipOffstage: skipOffstage),
    skipOffstage: skipOffstage,
  );

  testWidgets('present at 1440, absent at 800 and 390', (tester) async {
    await tester.pumpShell();
    expect(find.byType(SidebarPlaylists), findsOneWidget);
    expect(inSidebar('Playlist 0'), findsOneWidget);

    await tester.pumpShell(size: TestSizes.medium);
    expect(find.byType(SidebarPlaylists), findsNothing);

    await tester.pumpShell(size: TestSizes.compact);
    expect(find.byType(SidebarPlaylists), findsNothing);
  });

  testWidgets('Liked Songs pinned', (tester) async {
    await tester.pumpShell();
    expect(inSidebar('Liked Songs'), findsOneWidget);
    expect(
      tester.getTopLeft(inSidebar('Liked Songs')).dy,
      lessThan(tester.getTopLeft(inSidebar('Playlist 0')).dy),
    );

    await tester.pumpShell(playlists: 0);
    expect(inSidebar('Liked Songs'), findsOneWidget);
  });

  testWidgets('the open playlist is marked selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpShell(openPlaylistId: 'pl2');
    expect(
      tester.getSemantics(inSidebar('Playlist 2')),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(inSidebar('Playlist 1')),
      isNot(isSemantics(isSelected: true)),
    );
    expect(
      tester.getSemantics(inSidebar('Liked Songs')),
      isNot(isSemantics(isSelected: true)),
    );

    await tester.pumpShell(openPlaylistId: 'liked');
    expect(
      tester.getSemantics(inSidebar('Liked Songs')),
      isSemantics(isSelected: true),
    );
    semantics.dispose();
  });

  testWidgets('the list scrolls while the destinations stay in place', (
    tester,
  ) async {
    await tester.pumpShell(playlists: 60);
    final home = tester.getTopLeft(find.text('Home'));
    final liked = tester.getTopLeft(inSidebar('Liked Songs'));

    await tester.drag(
      find.byKey(SidebarPlaylists.listKey),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Home')), home);
    expect(
      tester.getTopLeft(inSidebar('Liked Songs', skipOffstage: false)).dy,
      lessThan(liked.dy),
    );
  });

  test('openPlaylistIdOf reads the playlist detail at the end of a '
      'location', () {
    expect(
      openPlaylistIdOf(Uri.parse('/library/playlists/playlist/pl3')),
      'pl3',
    );
    expect(openPlaylistIdOf(Uri.parse('/home/playlist/liked')), 'liked');
    expect(openPlaylistIdOf(Uri.parse('/library/playlists')), isNull);
    expect(openPlaylistIdOf(Uri.parse('/home/playlist/p1/album/a1')), isNull);
    expect(openPlaylistIdOf(Uri.parse('/home')), isNull);
  });

  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('meets the guidelines at 1440 in ${theme.name}', (
      tester,
    ) async {
      await tester.pumpShell(openPlaylistId: 'pl1', theme: theme);
      await expectMeetsGuidelines(tester);
    });
  }
}
