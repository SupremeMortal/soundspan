// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/test_root.dart';

void main() {
  String location(TestRoot root) => root.container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  Future<void> go(WidgetTester tester, TestRoot root, String path) async {
    root.container.read(routerProvider).go(path);
    await tester.pumpAndSettle();
  }

  Finder destination(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  BuildContext screen(WidgetTester tester) =>
      tester.element(find.byType(PlaceholderScreen).last);

  int selectedIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('no active profile lands on /connect', (tester) async {
    final root = await tester.pumpSoundspanApp();
    expect(location(root), '/connect');
    expect(find.text('Add server'), findsOneWidget);
  });

  testWidgets('signed-out profile lands on /connect/sign-in with its id', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedOut);
    expect(location(root), '/connect/sign-in?profile=${root.profileId}');
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('active profile lands on /home', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    expect(location(root), '/home');
    expect(find.byType(AdaptiveShell), findsOneWidget);
    expect(selectedIndex(tester), ShellDestination.home.index);
  });

  testWidgets('a session sign-out redirects to /connect/sign-in', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    final profile = root.container.read(profileRuntimeProvider).container!;
    await tester.runAsync(() async {
      profile
          .read(sessionControllerProvider)
          .onUnauthenticated(UnauthenticatedReason.sessionExpired);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(location(root), '/connect/sign-in?profile=${root.profileId}');
  });

  testWidgets('/library redirects to /library/playlists', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library');
    expect(location(root), '/library/playlists');
    expect(selectedIndex(tester), ShellDestination.library.index);
  });

  testWidgets('an unknown library tab redirects to /library/playlists', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library/bogus');
    expect(location(root), '/library/playlists');
  });

  testWidgets('/ redirects to /home', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library/albums');
    await go(tester, root, '/');
    expect(location(root), '/home');
  });

  testWidgets('each branch keeps its own stack', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library/albums');
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    expect(location(root), '/library/albums/album/a1');
    expect(find.text('Album'), findsOneWidget);

    await tester.tap(destination('Home'));
    await tester.pumpAndSettle();
    expect(location(root), '/home');
    expect(find.text('Album'), findsNothing);

    await tester.tap(destination('Library'));
    await tester.pumpAndSettle();
    expect(location(root), '/library/albums/album/a1');
    expect(find.text('Album'), findsOneWidget);
  });

  testWidgets('resizing the window keeps the branch stack', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: const Size(1440, 900),
    );
    await go(tester, root, '/library/albums');
    DetailNavigation.openAlbum(screen(tester), 'a5');
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Album'), findsOneWidget);
    expect(location(root), '/library/albums/album/a5');
  });

  testWidgets('an album opened from Search keeps Search selected', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/search?q=blue');
    DetailNavigation.openAlbum(screen(tester), 'a2');
    await tester.pumpAndSettle();
    expect(location(root), '/search/album/a2?q=blue');
    expect(selectedIndex(tester), ShellDestination.search.index);
    expect(find.text('Album'), findsOneWidget);
  });

  testWidgets('artists and playlists open inside the branch too', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    expect(location(root), '/home/artist/r1');
    expect(find.text('Artist'), findsOneWidget);
    DetailNavigation.openPlaylist(screen(tester), 'liked');
    await tester.pumpAndSettle();
    expect(location(root), '/home/playlist/liked');
    expect(find.text('Playlist'), findsOneWidget);
  });

  testWidgets('/album/42 redirects into the selected branch', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/podcasts');
    await go(tester, root, '/album/42');
    expect(location(root), '/podcasts/album/42');
    expect(selectedIndex(tester), ShellDestination.podcasts.index);
  });

  testWidgets('/album/42 goes to Home before any branch is shown', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/album/42');
    expect(location(root), '/home/album/42');
  });

  testWidgets('tapping the selected destination pops to its root', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    DetailNavigation.openAlbum(screen(tester), 'a3');
    await tester.pumpAndSettle();
    expect(location(root), '/home/album/a3');

    await tester.tap(destination('Home'));
    await tester.pumpAndSettle();
    expect(location(root), '/home');
    expect(find.text('Album'), findsNothing);
  });

  testWidgets('/connect is reachable with an active profile', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/connect');
    expect(location(root), '/connect');
    expect(find.text('Add server'), findsOneWidget);
  });

  testWidgets('settings opens on the root navigator', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/settings/appearance');
    expect(location(root), '/settings/appearance');
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.byType(AdaptiveShell), findsNothing);
  });

  testWidgets('the route sets the title', (tester) async {
    final titles = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
          titles.add(
            (call.arguments as Map<Object?, Object?>)['label']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    expect(titles.last, 'Home · soundspan');

    await go(tester, root, '/library/songs');
    expect(titles.last, 'Library · soundspan');

    DetailNavigation.openAlbum(screen(tester), 'a4');
    await tester.pumpAndSettle();
    expect(titles.last, 'Album · soundspan');
  });

  testWidgets('the guards follow a profile switch to none', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await tester.runAsync(
      () => root.container.read(profileRuntimeProvider).switchTo(null),
    );
    await tester.pumpAndSettle();
    expect(location(root), '/connect');
    expect(GoRouter.of(screen(tester)), isNotNull);
  });
}
