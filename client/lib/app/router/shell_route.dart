// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:go_router/go_router.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/core/profile/profile_scope.dart';

/// The detail routes, attached as children of every branch root so a detail
/// opens inside the branch it was opened from.
List<RouteBase> detailRoutes() => [
  for (final kind in DetailKind.values)
    GoRoute(
      path: '${kind.name}/:${kind.parameter}',
      builder: (context, _) =>
          PlaceholderScreen(kind.title(AppLocalizations.of(context))),
    ),
];

/// The shell: one branch per [ShellDestination], each with its own
/// navigation stack, inside the profile scope. [location] follows the
/// selected branch.
StatefulShellRoute buildShellRoute(
  ShellLocation location,
) => StatefulShellRoute.indexedStack(
  builder: (context, state, shell) {
    location.update(state.uri);
    return ProfileScope(
      child: AdaptiveShell(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        child: shell,
      ),
    );
  },
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, _) =>
              PlaceholderScreen(AppLocalizations.of(context).navHome),
          routes: detailRoutes(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RoutePaths.search,
          builder: (context, _) =>
              PlaceholderScreen(AppLocalizations.of(context).navSearch),
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
          routes: [
            GoRoute(
              path: ':tab',
              redirect: (_, state) =>
                  LibraryTab.tryParse(state.pathParameters['tab']!) == null
                  ? '${RoutePaths.library}/${LibraryTab.playlists.name}'
                  : null,
              builder: (context, _) =>
                  PlaceholderScreen(AppLocalizations.of(context).navLibrary),
              routes: detailRoutes(),
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RoutePaths.podcasts,
          builder: (context, _) =>
              PlaceholderScreen(AppLocalizations.of(context).navPodcasts),
          routes: detailRoutes(),
        ),
      ],
    ),
  ],
);
