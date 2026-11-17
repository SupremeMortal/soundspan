// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/app.dart' show themeModeSettingProvider;
import 'package:soundspan/app/licenses/license_catalog.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/features/connect/connect.dart';
import 'package:soundspan/features/connect/ui/probe_controller.dart';
import 'package:soundspan/features/settings/ui/settings_screen.dart'
    show SettingsSection;
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner.dart';
import 'package:soundspan/shared/providers/images.dart';
import 'package:soundspan/shared/providers/tint.dart';

import '../features/connect/connect_harness.dart';
import '../features/settings/ui/about/licenses_screen_test.dart'
    show seededSource;
import '../helpers/fake_qr_scanner.dart';
import '../helpers/fake_tint_extractor.dart';
import '../helpers/placeholder_image_provider.dart';
import '../helpers/test_root.dart';
import 'registry_content.dart';
import 'surface_cases.dart';

/// How a [ScreenCase] is pumped: the window [size] and the [theme].
class PumpOptions {
  /// Creates the options.
  const new({required this.size, required this.theme});

  /// The window size.
  final Size size;

  /// Dark or light.
  final ThemeMode theme;

  @override
  String toString() => '${size.width.toInt()} ${theme.name}';
}

/// One screen, or one surface that is not a route, of the accessibility
/// registry.
class ScreenCase {
  /// Creates a case.
  const new({
    required this.name,
    required this.pump,
    this.routePath,
    this.exemption,
    this.exemptGuideline,
    this.contrastSamplingExempt,
  }) : assert(
         (exemption == null) == (exemptGuideline == null),
         'an exemption names its guideline and its reason',
       );

  /// The case's name in test descriptions.
  final String name;

  /// The router's path pattern this case covers, such as
  /// `/library/:tab/album/:albumId`; null for a surface that is not a
  /// route (a sheet, a dialog, a menu, a state).
  final String? routePath;

  /// Pumps the screen in a loaded state with realistic content.
  final Future<void> Function(WidgetTester tester, PumpOptions options) pump;

  /// Why [exemptGuideline] cannot be met on this case; one line.
  final String? exemption;

  /// The one guideline [exemption] skips.
  final AccessibilityGuideline? exemptGuideline;

  /// The text nodes, for the given options, the contrast check does not
  /// sample: token pairs the contrast table allows whose glyphs are too thin
  /// for the guideline's sampler (`contrastSamplingExempt` of
  /// `failedGuidelines`). Each names the node and the theme.
  final List<Finder> Function(PumpOptions options)? contrastSamplingExempt;

  @override
  String toString() => name;
}

/// The path patterns of [routes] that show a screen (have a builder or a
/// page builder), with each child's path joined to its parent's. Routes
/// that only redirect are left out.
List<String> screenRoutePatterns(List<RouteBase> routes) {
  final patterns = <String>[];
  void walk(List<RouteBase> routes, String parent) {
    for (final route in routes) {
      switch (route) {
        case GoRoute():
          final path = route.path.startsWith('/')
              ? route.path
              : parent.endsWith('/')
              ? '$parent${route.path}'
              : '$parent/${route.path}';
          if (route.builder != null || route.pageBuilder != null) {
            patterns.add(path);
          }
          walk(route.routes, path);
        case ShellRouteBase():
          walk(route.routes, parent);
      }
    }
  }

  walk(routes, '/');
  return patterns;
}

/// The patterns of [routes] (see [screenRoutePatterns]) that no case of
/// [cases] covers.
List<String> uncoveredRoutePatterns(
  List<RouteBase> routes,
  List<ScreenCase> cases,
) {
  final covered = {for (final c in cases) ?c.routePath};
  return [
    for (final pattern in screenRoutePatterns(routes))
      if (!covered.contains(pattern)) pattern,
  ];
}

/// The app's route configuration, read from a signed-in app.
Future<List<RouteBase>> appRoutes(WidgetTester tester) async {
  final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
  return root.container.read(routerProvider).configuration.routes;
}

/// Pumps the whole signed-in app with [RegistryContent] and goes to
/// [location] (with [extra]).
Future<TestRoot> pumpRoute(
  WidgetTester tester,
  PumpOptions options,
  String location, {
  Object? extra,
  List<Override> overrides = const [],
  RegistryContent? content,
}) async {
  final root = await tester.pumpSoundspanApp(
    stored: StoredProfile.signedIn,
    size: options.size,
    overrides: [
      ...(content ?? RegistryContent()).overrides,
      tintExtractorProvider.overrideWithValue(AsyncData(FakeTintExtractor())),
      artworkImageProvider.overrideWithValue(
        (request) => PlaceholderImageProvider(request.ref),
      ),
      themeModeSettingProvider.overrideWithValue(
        AsyncData(switch (options.theme) {
          ThemeMode.light => ThemeModeSetting.light,
          _ => ThemeModeSetting.dark,
        }),
      ),
      ...overrides,
    ],
  );
  root.container.read(routerProvider).go(location, extra: extra);
  await tester.pumpAndSettle();
  return root;
}

ScreenCase _route(
  String name,
  String pattern, {
  String? location,
  Object? extra,
  List<Override> overrides = const [],
  List<Finder> Function(PumpOptions options)? contrastSamplingExempt,
}) => ScreenCase(
  name: name,
  routePath: pattern,
  contrastSamplingExempt: contrastSamplingExempt,
  pump: (tester, options) => pumpRoute(
    tester,
    options,
    location ?? pattern,
    extra: extra,
    overrides: overrides,
  ),
);

/// The child routes every shell branch root has, as (name, pattern suffix,
/// location suffix).
const List<(String, String, String)> _detailChildren = [
  ('Explore', 'explore', 'explore'),
  ('Listen Together', 'listen-together', 'listen-together'),
  ('Vibe', 'vibe', 'vibe'),
  ('Album', 'album/:albumId', 'album/$registryId'),
  ('Artist', 'artist/:artistId', 'artist/$registryId'),
  ('Playlist', 'playlist/:playlistId', 'playlist/$registryId'),
  ('Mix', 'mix/:mixId', 'mix/$registryId'),
];

/// The branch roots the detail routes hang under, as (name, pattern,
/// location).
const List<(String, String, String)> _branchRoots = [
  ('Home', RoutePaths.home, RoutePaths.home),
  ('Search', RoutePaths.search, RoutePaths.search),
  ('Library', '${RoutePaths.library}/:tab', '${RoutePaths.library}/playlists'),
  ('Podcasts', RoutePaths.podcasts, RoutePaths.podcasts),
];

/// Every case of the registry: the routes, then the surfaces that are not
/// routes ([surfaceCases]).
final List<ScreenCase> registry = [...screenCases, ...surfaceCases];

/// One case per route path of the router.
final List<ScreenCase> screenCases = [
  // Connect.
  _route('Connect', RoutePaths.connect),
  ScreenCase(
    name: 'Probe',
    routePath: RoutePaths.probe,
    pump: (tester, options) => pumpRoute(
      tester,
      options,
      RoutePaths.probe,
      extra: ProbeRequest(
        input: 'music.example.com',
        address: ServerAddress.parse('music.example.com'),
      ),
      overrides: [
        // The server moved, so the screen stays to show the final address.
        probeControllerProvider.overrideWith(
          () => InstantProbeController(
            ProbeReady(
              probeResult(
                'https://www.music.example.com/soundspan',
                requested: 'https://music.example.com',
              ),
            ),
          ),
        ),
      ],
    ),
  ),
  ScreenCase(
    name: 'Server too old',
    routePath: RoutePaths.probe,
    pump: (tester, options) async {
      final root = await pumpRoute(tester, options, RoutePaths.home);
      root.container
          .read(routerProvider)
          .go('${RoutePaths.probe}?profile=${root.profileId}');
      await tester.pumpAndSettle();
    },
  ),
  ScreenCase(
    name: 'Scan',
    routePath: RoutePaths.scan,
    pump: (tester, options) => pumpRoute(
      tester,
      options,
      RoutePaths.scan,
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.android,
        ),
        qrScannerFactoryProvider.overrideWithValue(FakeQrScanner.new),
      ],
    ),
  ),
  _route(
    'Sign in',
    RoutePaths.signIn,
    extra: probeResult('https://music.example.com'),
    // The focused, empty user-name field: its floating label and cursor are
    // `accent` on `surface` (5.2:1), drawn too thin for the sampler in light.
    contrastSamplingExempt: (options) => [
      if (options.theme == ThemeMode.light)
        find.descendant(
          of: find.byKey(SignInScreen.usernameKey),
          matching: find.byType(EditableText),
        ),
    ],
  ),
  // Shell branches.
  _route('Home', RoutePaths.home),
  _route(
    'Search',
    RoutePaths.search,
    location: '${RoutePaths.search}?q=$registryQuery',
  ),
  for (final tab in LibraryTab.values)
    _route(
      'Library ${tab.name}',
      '${RoutePaths.library}/:tab',
      location: '${RoutePaths.library}/${tab.name}',
    ),
  _route('Podcasts', RoutePaths.podcasts),
  _route(
    'Podcast',
    '${RoutePaths.podcasts}/:podcastId',
    location: '${RoutePaths.podcasts}/$registryId',
  ),
  for (final (rootName, rootPattern, rootLocation) in _branchRoots)
    for (final (name, pattern, location) in _detailChildren)
      _route(
        '$name in $rootName',
        '$rootPattern/$pattern',
        location: '$rootLocation/$location',
      ),
  // Root routes.
  _route('Now playing', RoutePaths.nowPlaying),
  _route('Settings', RoutePaths.settings),
  for (final section in SettingsSection.values)
    _route(
      'Settings ${section.name}',
      '${RoutePaths.settings}/${section.name}',
    ),
  _route(
    'Licenses',
    RoutePaths.settingsAboutLicenses,
    overrides: [licenseSourceProvider.overrideWithValue(seededSource())],
  ),
];
