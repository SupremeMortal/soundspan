// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:go_router/go_router.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/local_data_too_new_screen.dart';
import 'package:soundspan/app/shell/shell_history.dart';
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
          onSearch: (query) => router.go(
            Uri(
              path: RoutePaths.search,
              queryParameters: {'q': query},
            ).toString(),
          ),
          onBack: canBack
              ? () {
                  history.back(branch);
                  router.pop();
                }
              : null,
          onForward: history.canForward(branch)
              ? () {
                  final target = history.forward(branch);
                  if (target != null) router.go(target);
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
          builder: (context, _) => PlaceholderScreen(
            AppLocalizations.of(context).navHome,
            branchRoot: true,
          ),
          routes: detailRoutes(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RoutePaths.search,
          builder: (context, _) => PlaceholderScreen(
            AppLocalizations.of(context).navSearch,
            branchRoot: true,
          ),
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
              builder: (context, _) => PlaceholderScreen(
                AppLocalizations.of(context).navLibrary,
                branchRoot: true,
              ),
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
