// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/local_data_too_new_screen.dart';
import 'package:soundspan/app/shell/outbox_notice_listener.dart';
import 'package:soundspan/app/shell/play_notice_listener.dart';
import 'package:soundspan/app/shell/shell_history.dart';
import 'package:soundspan/app/shell/two_pane.dart';
import 'package:soundspan/core/profile/profile_scope.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/features/artist/artist.dart';
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/features/home/home.dart';
import 'package:soundspan/features/library/library.dart';
import 'package:soundspan/features/listen_together/listen_together.dart';
import 'package:soundspan/features/listen_together/ui/listen_together_screen.dart'
    deferred as listen_together_screen;
import 'package:soundspan/features/mixes/mixes.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/features/search/search.dart';

/// The detail routes and Explore, attached as children of every branch
/// root so a detail opens inside the branch it was opened from.
///
/// When [paneEligible] answers true for a detail's state, that detail opens
/// in the detail pane of a two-pane window ([twoPaneDetailPage]).
List<RouteBase> detailRoutes({
  bool Function(GoRouterState state)? paneEligible,
}) => [
  GoRoute(
    path: RoutePaths.exploreSegment,
    builder: (_, _) => const ExploreScreen(),
  ),
  GoRoute(
    path: RoutePaths.listenTogetherSegment,
    builder: (_, _) => const DeferredListenTogetherScreen(),
  ),
  for (final kind in DetailKind.values)
    if (paneEligible == null)
      GoRoute(
        path: '${kind.name}/:${kind.parameter}',
        builder: (context, state) => _detailScreen(kind, state),
      )
    else
      GoRoute(
        path: '${kind.name}/:${kind.parameter}',
        pageBuilder: (context, state) => twoPaneDetailPage(
          context,
          state,
          child: _detailScreen(kind, state),
          paneEligible: paneEligible(state),
        ),
      ),
];

/// The Listen Together screen, loaded through a deferred import so the web
/// build keeps it out of the initial bundle (doc 09, Listen Together);
/// nothing shows until it is loaded.
class DeferredListenTogetherScreen extends StatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  State<DeferredListenTogetherScreen> createState() =>
      _DeferredListenTogetherScreenState();
}

class _DeferredListenTogetherScreenState
    extends State<DeferredListenTogetherScreen> {
  late final Future<void> _loaded = listen_together_screen.loadLibrary();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loaded,
    builder: (context, snapshot) =>
        snapshot.connectionState == ConnectionState.done
        ? listen_together_screen.ListenTogetherScreen()
        : const SizedBox.shrink(),
  );
}

Widget _detailScreen(DetailKind kind, GoRouterState state) {
  final id = state.pathParameters[kind.parameter]!;
  return switch (kind) {
    DetailKind.album => AlbumScreen(albumId: id),
    DetailKind.playlist => PlaylistScreen(playlistId: id),
    DetailKind.artist => ArtistScreen(artistId: id),
    DetailKind.mix => MixDetailScreen(mixId: id),
  };
}

/// The location segments after the first [depth] segments of [state]'s
/// location, at most two: the detail a two-pane list has open.
List<String> _paneSelection(GoRouterState state, int depth) =>
    state.uri.pathSegments.skip(depth).take(2).toList();

/// The `:tab` route under `/library`: the [LibraryScreen] of a
/// [LibraryTab], with the detail routes as children. An unknown tab
/// redirects to Playlists. Every tab is the same page, so switching tabs
/// keeps the screen and the state of each tab. Details opened from the
/// Playlists, Artists and Albums tabs open in the detail pane of a
/// two-pane window; Songs and Downloads stay single-pane.
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
      selected: _paneSelection(state, 2),
    ),
  ),
  routes: detailRoutes(
    paneEligible: (state) =>
        switch (LibraryTab.tryParse(state.pathParameters['tab'] ?? '')) {
          LibraryTab.songs || LibraryTab.downloads => false,
          _ => true,
        },
  ),
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
        child: OutboxNoticeListener(
          child: PlayNoticeListener(
            child: ListenTogetherNoticeListener(
              child: Consumer(
                builder: (context, ref, shellChild) => AppShell(
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
                  openPlaylistId: openPlaylistIdOf(state.uri),
                  onExplore: () =>
                      DetailNavigation.openLocation(router, RoutePaths.explore),
                  onListenTogether: () => DetailNavigation.openLocation(
                    router,
                    RoutePaths.listenTogether,
                  ),
                  child: shellChild!,
                ),
                child: shell,
              ),
            ),
          ),
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
          builder: (_, state) =>
              PodcastsScreen(selected: _paneSelection(state, 1)),
          routes: [
            ...detailRoutes(),
            GoRoute(
              path: ':podcastId',
              pageBuilder: (context, state) => twoPaneDetailPage(
                context,
                state,
                child: PodcastDetailScreen(
                  podcastId: state.pathParameters['podcastId']!,
                ),
                paneEligible: true,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
