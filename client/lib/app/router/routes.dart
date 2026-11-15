// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/guards.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/shell_route.dart';
import 'package:soundspan/app/shell/shell_history.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/settings/settings.dart';

/// The fixed paths of the router (doc 02, Routing).
abstract final class RoutePaths {
  /// Add a server: address entry.
  static const connect = '/connect';

  /// Probe progress and result.
  static const probe = '/connect/probe';

  /// Sign-in; `?profile=<id>` names a signed-out profile.
  static const signIn = '/connect/sign-in';

  /// The home branch.
  static const home = '/home';

  /// The search branch; `?q=` carries the query.
  static const search = '/search';

  /// The library branch; a [LibraryTab] follows.
  static const library = '/library';

  /// The podcasts branch.
  static const podcasts = '/podcasts';

  /// Settings, on the root navigator.
  static const settings = '/settings';

  /// The Servers settings.
  static const settingsServers = '/settings/servers';

  /// The Appearance settings.
  static const settingsAppearance = '/settings/appearance';

  /// The About settings.
  static const settingsAbout = '/settings/about';

  /// The open-source licences, opened from the About settings.
  static const settingsAboutLicenses = '/settings/about/licenses';
}

/// The tabs of `/library/:tab`.
enum LibraryTab {
  /// Playlists; the default tab.
  playlists,

  /// Artists.
  artists,

  /// Albums.
  albums,

  /// Songs.
  songs;

  /// The tab named [segment], or null when there is none.
  static LibraryTab? tryParse(String segment) {
    for (final tab in values) {
      if (tab.name == segment) return tab;
    }
    return null;
  }
}

/// The detail screens that open inside the selected branch.
enum DetailKind {
  /// `album/:albumId`.
  album,

  /// `artist/:artistId`.
  artist,

  /// `playlist/:playlistId`.
  playlist;

  /// The path parameter carrying the id.
  String get parameter => '${name}Id';

  /// The localized screen name.
  String title(AppLocalizations l10n) => switch (this) {
    album => l10n.screenAlbum,
    artist => l10n.screenArtist,
    playlist => l10n.screenPlaylist,
  };
}

/// Remembers the location of the branch the shell shows, so a top-level
/// detail path (`/album/42`) can be sent into it.
class ShellLocation {
  Uri _base = Uri(path: RoutePaths.home);

  /// The root location of the selected branch: `/home`, `/search` with its
  /// query, `/library/<tab>` or `/podcasts`. `/home` before any branch
  /// was shown.
  Uri get base => _base;

  /// Records [location] when it is inside a branch.
  void update(Uri location) {
    final base = branchBaseOf(location);
    if (base != null) _base = base;
  }

  /// The location of the [kind] detail [id] inside the selected branch.
  String detail(DetailKind kind, String id) => _base
      .replace(
        pathSegments: [..._base.pathSegments, kind.name, id],
        queryParameters: _base.queryParameters.isEmpty
            ? null
            : _base.queryParameters,
      )
      .toString();
}

/// The root location of the branch [location] is in, or null when it is in
/// none.
Uri? branchBaseOf(Uri location) {
  final segments = location.pathSegments;
  if (segments.isEmpty) return null;
  return switch (segments.first) {
    'home' => Uri(path: RoutePaths.home),
    'search' => Uri(
      path: RoutePaths.search,
      queryParameters: location.queryParameters['q'] == null
          ? null
          : {'q': location.queryParameters['q']},
    ),
    'library' => Uri(
      path:
          '${RoutePaths.library}/'
          '${(segments.length > 1 ? LibraryTab.tryParse(segments[1]) : null)?.name ?? LibraryTab.playlists.name}',
    ),
    'podcasts' => Uri(path: RoutePaths.podcasts),
    _ => null,
  };
}

/// Opens detail screens inside the selected branch, so screens never build
/// detail paths themselves.
///
/// From a branch root the detail replaces the branch's location
/// (`/<branch root>/<kind>/<id>`); from a detail it is pushed onto the
/// branch's stack, so Back returns to the detail it was opened from.
abstract final class DetailNavigation {
  /// Opens album [id].
  static void openAlbum(BuildContext context, String id) =>
      _open(context, DetailKind.album, id);

  /// Opens artist [id].
  static void openArtist(BuildContext context, String id) =>
      _open(context, DetailKind.artist, id);

  /// Opens playlist [id].
  static void openPlaylist(BuildContext context, String id) =>
      _open(context, DetailKind.playlist, id);

  /// Opens the top-level detail [location] (`/album/42`, the form deep links
  /// use) in [router]'s selected branch, pushing it when that branch already
  /// shows a detail.
  static void openLocation(GoRouter router, String location) {
    final current = router.routerDelegate.currentConfiguration.uri;
    final base = branchBaseOf(current);
    if (base != null && base.path != current.path) {
      unawaited(router.push<void>(location));
    } else {
      router.go(location);
    }
  }

  static void _open(BuildContext context, DetailKind kind, String id) =>
      openLocation(
        GoRouter.of(context),
        '/${kind.name}/${Uri.encodeComponent(id)}',
      );
}

/// Builds the app's router over [gate]. [initialLocation] is where it
/// starts before the guards run.
GoRouter createRouter(
  AuthGateState gate, {
  String initialLocation = RoutePaths.home,
}) {
  // A detail pushed onto a branch's stack is what the window shows, so the
  // browser URL follows it (doc 02, Routing).
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final location = ShellLocation();
  final history = ShellHistory();
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: gate,
    redirect: (context, state) {
      final guarded = guardRedirect(
        state.uri,
        gate.state,
        signedOut: gate.signedOut,
      );
      if (guarded != null) return guarded;
      location.update(state.uri);
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => RoutePaths.home),
      GoRoute(
        path: RoutePaths.connect,
        builder: (context, _) =>
            PlaceholderScreen(AppLocalizations.of(context).screenConnect),
        routes: [
          GoRoute(
            path: 'probe',
            builder: (context, _) => PlaceholderScreen(
              AppLocalizations.of(context).screenConnectProbe,
            ),
          ),
          GoRoute(
            path: 'sign-in',
            builder: (context, _) =>
                PlaceholderScreen(AppLocalizations.of(context).screenSignIn),
          ),
        ],
      ),
      for (final kind in DetailKind.values)
        GoRoute(
          path: '/${kind.name}/:${kind.parameter}',
          redirect: (_, state) =>
              location.detail(kind, state.pathParameters[kind.parameter]!),
        ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, _) => const SettingsScreen(),
        routes: [
          for (final section in SettingsSection.values)
            GoRoute(
              path: section.name,
              builder: (context, _) => SettingsScreen(section: section),
              routes: [
                if (section == SettingsSection.about)
                  GoRoute(
                    path: 'licenses',
                    builder: (context, _) => const LicensesScreen(),
                  ),
              ],
            ),
          for (final (path, title)
              in <(String, String Function(AppLocalizations))>[
                ('playback', (l10n) => l10n.screenSettingsPlayback),
                ('storage', (l10n) => l10n.screenSettingsStorage),
              ])
            GoRoute(
              path: path,
              builder: (context, _) =>
                  PlaceholderScreen(title(AppLocalizations.of(context))),
            ),
        ],
      ),
      buildShellRoute(location, history),
    ],
  );
}

/// The app's router, following the [ProfileRuntime].
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final gate = AuthGateState(ref.watch(profileRuntimeProvider));
  final router = createRouter(gate);
  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});
