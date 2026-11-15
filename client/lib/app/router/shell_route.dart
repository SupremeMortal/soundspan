// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/local_data_too_new_screen.dart';
import 'package:soundspan/app/shell/shell_history.dart';
import 'package:soundspan/core/profile/profile_scope.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/features/artist/artist.dart';
import 'package:soundspan/features/home/home.dart';
import 'package:soundspan/features/library/library.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/features/search/search.dart';

/// The detail routes, attached as children of every branch root so a detail
/// opens inside the branch it was opened from.
List<RouteBase> detailRoutes() => [
  for (final kind in DetailKind.values)
    GoRoute(
      path: '${kind.name}/:${kind.parameter}',
      builder: (context, state) {
        final id = state.pathParameters[kind.parameter]!;
        return switch (kind) {
          DetailKind.album => AlbumScreen(albumId: id),
          DetailKind.playlist => PlaylistScreen(playlistId: id),
          DetailKind.artist => ArtistScreen(artistId: id),
        };
      },
    ),
];

/// The `:tab` route under `/library`: the [LibraryScreen] of a
/// [LibraryTab], with the detail routes as children. An unknown tab
/// redirects to Playlists. Every tab is the same page, so switching tabs
/// keeps the screen and the state of each tab.
GoRoute libraryTabRoute() => GoRoute(
  path: ':tab',
  redirect: (_, state) =>
      LibraryTab.tryParse(state.pathParameters['tab']!) == null
      ? '${RoutePaths.library}/${LibraryTab.playlists.name}'
      : null,
  pageBuilder: (context, state) => MaterialPage<void>(
    key: const ValueKey<String>(RoutePaths.library),
    child: LibraryScreen(
      tab: LibraryTab.tryParse(state.pathParameters['tab']!)!,
    ),
  ),
  routes: detailRoutes(),
);

/// The Search location of [query]: `/search?q=<query>`, or `/search` when
/// [query] is empty.
String searchLocation(String query) => Uri(
  path: RoutePaths.search,
  queryParameters: query.isEmpty ? null : {'q': query},
).toString();

/// The shell: one branch per [ShellDestination], each with its own
/// navigation stack, inside the profile scope. [location] follows the
/// selected branch and [history] records each branch's locations for the
/// top bar's Back and Forward.
///
/// While the active profile's local data is too new for this app, the
/// shell is replaced by the [LocalDataTooNewGate]'s screen.
StatefulShellRoute buildShellRoute(
  ShellLocation location,
  ShellHistory history,
) => StatefulShellRoute.indexedStack(
  builder: (context, state, shell) {
    location.update(state.uri);
    final branch = shell.currentIndex;
    history.visit(branch, state.uri.toString());
    final router = GoRouter.of(context);
    final canBack = branchBaseOf(state.uri)?.path != state.uri.path;
    return LocalDataTooNewGate(
      child: ProfileScope(
        child: AppShell(
          selectedIndex: branch,
          onDestinationSelected: (index) =>
              shell.goBranch(index, initialLocation: index == branch),
          onSearch: (query) => router.go(searchLocation(query)),
          onSearchChanged: branch == ShellDestination.search.index
              ? (query) => router.go(searchLocation(query))
              : null,
          onBack: canBack
              ? () {
                  history.back(branch);
                  router.pop();
                }
              : null,
          onForward: history.canForward(branch)
              ? () {
                  final target = history.forward(branch);
                  // Pushed onto a detail so the branch's stack survives.
                  if (target != null) {
                    DetailNavigation.openLocation(router, target);
                  }
                }
              : null,
          child: shell,
        ),
      ),
    );
  },
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (_, _) => const HomeScreen(),
          routes: detailRoutes(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RoutePaths.search,
          builder: (_, state) =>
              SearchScreen(query: state.uri.queryParameters['q']),
          routes: detailRoutes(),
        ),
      ],
    ),
    StatefulShellBranch(
      initialLocation: '${RoutePaths.library}/${LibraryTab.playlists.name}',
      routes: [
        GoRoute(
          path: RoutePaths.library,
          redirect: (_, state) => state.uri.pathSegments.length == 1
              ? '${RoutePaths.library}/${LibraryTab.playlists.name}'
              : null,
          routes: [libraryTabRoute()],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RoutePaths.podcasts,
          builder: (context, _) => PlaceholderScreen(
            AppLocalizations.of(context).navPodcasts,
            branchRoot: true,
          ),
          routes: detailRoutes(),
        ),
      ],
    ),
  ],
);
