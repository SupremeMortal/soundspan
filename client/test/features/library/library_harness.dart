// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/router/shell_route.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_reachability.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

/// What [PumpLibrary.pumpLibrary] built.
class LibraryHarness {
  new _(this.container, this.router, this.library, this.playlists);

  /// The provider container.
  final ProviderContainer container;

  /// The router.
  final GoRouter router;

  /// The library repository fake.
  final FakeLibraryRepository library;

  /// The playlist repository fake.
  final FakePlaylistRepository playlists;

  /// The router's current location.
  String get location =>
      router.routerDelegate.currentConfiguration.uri.toString();

  /// The paged sources the screen opened, in order.
  List<FakePagedSource<Object>> get sources => library.sources;
}

/// [count] albums named `Album <index>` by `Artist <index>`.
List<Album> albums(int count) => [
  for (var i = 0; i < count; i++)
    Album(
      id: 'al$i',
      title: 'Album $i',
      artistName: 'Artist $i',
      artistId: 'ar$i',
    ),
];

/// [count] artists named `Artist <index>`.
List<Artist> artists(int count) => [
  for (var i = 0; i < count; i++) Artist(id: 'ar$i', name: 'Artist $i'),
];

/// [count] tracks titled `Song <index>` by `Artist <index>` on
/// `Album <index>`; the indexes in [unplayable] have no playback id.
List<Track> tracks(int count, {Set<int> unplayable = const {}}) => [
  for (var i = 0; i < count; i++) track(i, playable: !unplayable.contains(i)),
];

/// Track [index] of [tracks].
Track track(int index, {bool playable = true}) => Track(
  meta: TrackMeta(
    title: 'Song $index',
    artist: 'Artist $index',
    album: 'Album $index',
    durationSec: 200,
    artworkRef: 'cover-$index',
  ),
  playbackId: playable ? PlaybackId('p$index') : null,
);

/// [count] playlists named `Playlist <index>` with `index + 1` tracks and
/// four covers each.
List<PlaylistSummary> playlists(int count) => [
  for (var i = 0; i < count; i++)
    PlaylistSummary(
      id: 'pl$i',
      name: 'Playlist $i',
      trackCount: i + 1,
      isOwner: true,
      isPublic: false,
      coverRefs: ['c$i-1', 'c$i-2', 'c$i-3', 'c$i-4'],
    ),
];

/// The capabilities of a server with federation [federation].
ServerCapabilities capabilities({bool federation = false}) =>
    ServerCapabilities(
      serverVersion: null,
      hasP6SelfRevoke: true,
      hasP7PlayMarker: true,
      hasP8PlayedAt: true,
      federation: federation,
    );

/// The library routes the app has: `/library/:tab` with its detail routes,
/// and the top-level detail paths that redirect into the branch.
GoRouter libraryRouter(LibraryTab tab) {
  final location = ShellLocation();
  return GoRouter(
    initialLocation: '${RoutePaths.library}/${tab.name}',
    redirect: (_, state) {
      location.update(state.uri);
      return null;
    },
    routes: [
      for (final kind in DetailKind.values)
        GoRoute(
          path: '/${kind.name}/:${kind.parameter}',
          redirect: (_, state) =>
              location.detail(kind, state.pathParameters[kind.parameter]!),
        ),
      GoRoute(
        path: RoutePaths.library,
        redirect: (_, state) => null,
        routes: [libraryTabRoute()],
      ),
    ],
  );
}

/// Pumps the Library screen.
extension PumpLibrary on WidgetTester {
  /// Pumps the library routes at [tab] in a window of [size], over
  /// [library] and [playlists] (new empty fakes by default) and a server
  /// with [federation], with [overrides] last. [settle] false pumps one
  /// frame instead of settling. [shellShortcuts] puts the shell's shortcut
  /// table around the routes.
  Future<LibraryHarness> pumpLibrary({
    LibraryTab tab = LibraryTab.albums,
    FakeLibraryRepository? library,
    FakePlaylistRepository? playlists,
    bool settle = true,
    bool federation = false,
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
    double textScale = 1.0,
    FakeReachability? reachability,
    List<Override> overrides = const [],
    bool shellShortcuts = false,
  }) async {
    library ??= FakeLibraryRepository();
    playlists ??= FakePlaylistRepository();
    final router = libraryRouter(tab);
    addTearDown(router.dispose);
    final container = await pumpApp(
      WindowClassScope(
        windowClass: windowClassOf(size),
        child: shellShortcuts
            ? Shortcuts(
                shortcuts: shortcutMap(defaultTargetPlatform),
                child: Router.withConfig(config: router),
              )
            : Router.withConfig(config: router),
      ),
      size: size,
      theme: theme,
      textScale: textScale,
      overrides: [
        ...FakeRepositories(library: library, playlists: playlists).overrides,
        serverCapabilitiesProvider.overrideWithBuild(
          (ref, notifier) => capabilities(federation: federation),
        ),
        profilesProvider.overrideWithValue(const AsyncData(<Profile>[])),
        reachabilityProvider.overrideWithValue(
          reachability ?? FakeReachability(),
        ),
        activeProfileIdProvider.overrideWithBuild((ref, notifier) => null),
        ...overrides,
      ],
    );
    if (settle) {
      await pumpAndSettle();
    } else {
      await pump();
    }
    return LibraryHarness._(container, router, library, playlists);
  }
}
