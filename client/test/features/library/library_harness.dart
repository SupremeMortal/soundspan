// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/router/shell_route.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

/// What [PumpLibrary.pumpLibrary] built.
class LibraryHarness {
  new _(this.container, this.router, this.library);

  /// The provider container.
  final ProviderContainer container;

  /// The router.
  final GoRouter router;

  /// The library repository fake.
  final FakeLibraryRepository library;

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
  /// [library] (a new empty fake by default) and a server with
  /// [federation].
  Future<LibraryHarness> pumpLibrary({
    LibraryTab tab = LibraryTab.albums,
    FakeLibraryRepository? library,
    bool federation = false,
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
    double textScale = 1.0,
  }) async {
    library ??= FakeLibraryRepository();
    final router = libraryRouter(tab);
    addTearDown(router.dispose);
    final container = await pumpApp(
      WindowClassScope(
        windowClass: windowClassOf(size),
        child: Router.withConfig(config: router),
      ),
      size: size,
      theme: theme,
      textScale: textScale,
      overrides: [
        ...FakeRepositories(library: library).overrides,
        serverCapabilitiesProvider.overrideWithBuild(
          (ref, notifier) => capabilities(federation: federation),
        ),
        profilesProvider.overrideWithValue(const AsyncData(<Profile>[])),
        activeProfileIdProvider.overrideWithBuild((ref, notifier) => null),
      ],
    );
    await pumpAndSettle();
    return LibraryHarness._(container, router, library);
  }
}
