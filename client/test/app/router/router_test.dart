// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/features/artist/artist.dart';
import 'package:soundspan/features/connect/connect.dart';
import 'package:soundspan/features/connect/ui/probe_controller.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/providers/tint.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../features/connect/connect_harness.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_tint_extractor.dart';
import '../../helpers/test_root.dart';

/// The sign-in screen probes a signed-out profile's server: it is found.
final Override _probeFindsServer = probeControllerProvider.overrideWith(
  () => InstantProbeController(
    ProbeReady(
      ProbeResult(
        baseUrl: Uri.parse('https://music.example.com'),
        requestedBaseUrl: Uri.parse('https://music.example.com'),
        localLoginEnabled: true,
        oidcEnabled: false,
        isCleartext: false,
        isPrivateHost: false,
      ),
    ),
  ),
);

/// Pumps the app with fake repositories and tints, so the album and
/// playlist screens the routes open read no server.
extension on WidgetTester {
  Future<TestRoot> pumpRouterApp({
    StoredProfile stored = StoredProfile.none,
    Size size = const Size(390, 844),
    List<Override> overrides = const [],
  }) => pumpSoundspanApp(
    stored: stored,
    size: size,
    overrides: [
      ...overrides,
      ...FakeRepositories().overrides,
      tintExtractorProvider.overrideWithValue(AsyncData(FakeTintExtractor())),
    ],
  );
}

void main() {
  String location(TestRoot root) => root.container
      .read(routerProvider)
      .routeInformationProvider
      .value
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
      tester.element(find.byType(RouteTitle).last);

  int selectedIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  Future<void> back(WidgetTester tester, TestRoot root) async {
    root.container.read(routerProvider).pop();
    await tester.pumpAndSettle();
  }

  String visibleScreen(WidgetTester tester) =>
      tester.widgetList<RouteTitle>(find.byType(RouteTitle)).last.screen;

  List<String> recordTitles(WidgetTester tester) {
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
    return titles;
  }

  testWidgets('no active profile lands on /connect', (tester) async {
    final root = await tester.pumpRouterApp();
    expect(location(root), '/connect');
    expect(find.byType(AddressScreen), findsOneWidget);
  });

  testWidgets('signed-out profile lands on /connect/sign-in with its id', (
    tester,
  ) async {
    final root = await tester.pumpRouterApp(
      stored: StoredProfile.signedOut,
      overrides: [_probeFindsServer],
    );
    expect(location(root), '/connect/sign-in?profile=${root.profileId}');
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('active profile lands on /home', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    expect(location(root), '/home');
    expect(find.byType(AdaptiveShell), findsOneWidget);
    expect(selectedIndex(tester), ShellDestination.home.index);
  });

  testWidgets('a session sign-out redirects to /connect/sign-in', (
    tester,
  ) async {
    final root = await tester.pumpRouterApp(
      stored: StoredProfile.signedIn,
      overrides: [_probeFindsServer],
    );
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
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library');
    expect(location(root), '/library/playlists');
    expect(selectedIndex(tester), ShellDestination.library.index);
  });

  testWidgets('an unknown library tab redirects to /library/playlists', (
    tester,
  ) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library/bogus');
    expect(location(root), '/library/playlists');
  });

  testWidgets('/ redirects to /home', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library/playlists');
    await go(tester, root, '/');
    expect(location(root), '/home');
  });

  testWidgets('each branch keeps its own stack', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library/playlists');
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    expect(location(root), '/library/playlists/album/a1');
    expect(find.byType(AlbumScreen), findsOneWidget);

    await tester.tap(destination('Home'));
    await tester.pumpAndSettle();
    expect(location(root), '/home');
    expect(find.byType(AlbumScreen), findsNothing);

    await tester.tap(destination('Library'));
    await tester.pumpAndSettle();
    expect(location(root), '/library/playlists/album/a1');
    expect(find.byType(AlbumScreen), findsOneWidget);
  });

  testWidgets('resizing the window keeps the branch stack', (tester) async {
    final root = await tester.pumpRouterApp(
      stored: StoredProfile.signedIn,
      size: const Size(1440, 900),
    );
    await go(tester, root, '/library/playlists');
    DetailNavigation.openAlbum(screen(tester), 'a5');
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(AlbumScreen), findsOneWidget);
    expect(location(root), '/library/playlists/album/a5');
  });

  testWidgets('an album opened from Search keeps Search selected', (
    tester,
  ) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/search?q=blue');
    DetailNavigation.openAlbum(screen(tester), 'a2');
    await tester.pumpAndSettle();
    expect(location(root), '/search/album/a2?q=blue');
    expect(selectedIndex(tester), ShellDestination.search.index);
    expect(find.byType(AlbumScreen), findsOneWidget);
  });

  testWidgets('artists and playlists open inside the branch too', (
    tester,
  ) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    expect(location(root), '/home/artist/r1');
    expect(find.byType(ArtistScreen), findsOneWidget);
    DetailNavigation.openPlaylist(screen(tester), 'liked');
    await tester.pumpAndSettle();
    expect(location(root), '/home/playlist/liked');
    expect(find.byType(PlaylistScreen), findsOneWidget);
  });

  testWidgets('/album/42 redirects into the selected branch', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/podcasts');
    await go(tester, root, '/album/42');
    expect(location(root), '/podcasts/album/42');
    expect(selectedIndex(tester), ShellDestination.podcasts.index);
  });

  testWidgets('/album/42 goes to Home before any branch is shown', (
    tester,
  ) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/album/42');
    expect(location(root), '/home/album/42');
  });

  testWidgets('tapping the selected destination pops to its root', (
    tester,
  ) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    DetailNavigation.openAlbum(screen(tester), 'a3');
    await tester.pumpAndSettle();
    expect(location(root), '/home/album/a3');

    await tester.tap(destination('Home'));
    await tester.pumpAndSettle();
    expect(location(root), '/home');
    expect(find.byType(AlbumScreen), findsNothing);
  });

  testWidgets('a detail opened from a detail stacks', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library/playlists');
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    expect(location(root), '/library/playlists/artist/r1');
    DetailNavigation.openAlbum(screen(tester), 'a2');
    await tester.pumpAndSettle();
    expect(location(root), '/library/playlists/album/a2');
    expect(visibleScreen(tester), 'Album');
    expect(selectedIndex(tester), ShellDestination.library.index);

    await back(tester, root);
    expect(location(root), '/library/playlists/artist/r1');
    expect(visibleScreen(tester), 'Artist');
    await back(tester, root);
    expect(location(root), '/library/playlists/album/a1');
    expect(visibleScreen(tester), 'Album');
    await back(tester, root);
    expect(location(root), '/library/playlists');
    expect(visibleScreen(tester), 'Library');
    expect(selectedIndex(tester), ShellDestination.library.index);
  });

  testWidgets('a stacked branch survives a branch switch', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/search?q=blue');
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();

    await tester.tap(destination('Home'));
    await tester.pumpAndSettle();
    expect(location(root), '/home');

    await tester.tap(destination('Search'));
    await tester.pumpAndSettle();
    expect(location(root), '/search/artist/r1?q=blue');
    expect(visibleScreen(tester), 'Artist');

    await back(tester, root);
    expect(location(root), '/search/album/a1?q=blue');
    expect(visibleScreen(tester), 'Album');
    expect(selectedIndex(tester), ShellDestination.search.index);
  });

  testWidgets('tapping the selected destination pops a stacked branch to its '
      'root', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    DetailNavigation.openPlaylist(screen(tester), 'p1');
    await tester.pumpAndSettle();

    await tester.tap(destination('Home'));
    await tester.pumpAndSettle();
    expect(location(root), '/home');
    expect(visibleScreen(tester), 'Home');
    expect(find.byType(AlbumScreen), findsNothing);
    expect(find.byType(ArtistScreen), findsNothing);
    expect(find.byType(PlaylistScreen), findsNothing);
  });

  testWidgets('the title follows the top detail after Back', (tester) async {
    final titles = recordTitles(tester);
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/library/songs');
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    expect(titles.last, 'Artist · soundspan');

    await back(tester, root);
    expect(titles.last, 'Album · soundspan');
    await back(tester, root);
    expect(titles.last, 'Library · soundspan');
  });

  testWidgets('/album/42 pushes onto a branch that shows a detail', (
    tester,
  ) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    DetailNavigation.openLocation(
      root.container.read(routerProvider),
      '/album/42',
    );
    await tester.pumpAndSettle();
    expect(location(root), '/home/album/42');

    await back(tester, root);
    expect(location(root), '/home/artist/r1');
  });

  testWidgets('/connect is reachable with an active profile', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await go(tester, root, '/connect');
    expect(location(root), '/connect');
    expect(find.byType(AddressScreen), findsOneWidget);
  });

  testWidgets('settings opens on the root navigator', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
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
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    expect(titles.last, 'Home · soundspan');

    await go(tester, root, '/library/songs');
    expect(titles.last, 'Library · soundspan');

    DetailNavigation.openAlbum(screen(tester), 'a4');
    await tester.pumpAndSettle();
    expect(titles.last, 'Album · soundspan');
  });

  testWidgets('the guards follow a profile switch to none', (tester) async {
    final root = await tester.pumpRouterApp(stored: StoredProfile.signedIn);
    await tester.runAsync(
      () => root.container.read(profileRuntimeProvider).switchTo(null),
    );
    await tester.pumpAndSettle();
    expect(location(root), '/connect');
    expect(GoRouter.of(tester.element(find.byType(AddressScreen))), isNotNull);
  });
}
