// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_notice.dart';
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/features/home/home.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/shelf.dart';
import 'package:soundspan_api/soundspan_api.dart'
    show FeatureDisabled, ServerError;

import '../../../helpers/fake_discovery_repository.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

class _FixedCapabilities extends ServerCapabilitiesNotifier {
  new(this._value);

  final ServerCapabilities _value;

  @override
  ServerCapabilities build() => _value;
}

class _NoNotice extends VersionNoticeController {
  @override
  Future<VersionNotice?> build() async => null;
}

const _madeForYou = 'Made For You';
const _recommended = 'Recommended For You';
const _popular = 'Popular Artists';
const _yourPlaylists = 'Your Playlists';

/// A tall window that shows every shelf at once.
const Size _tall = Size(1440, 2400);

void main() {
  late FakeRepositories repositories;
  late FakeDiscoveryRepository discovery;
  late int capabilityRefreshes;

  setUp(() {
    capabilityRefreshes = 0;
    repositories = FakeRepositories();
    repositories.home
      ..added = const [Artist(id: 'a1', name: 'Björk')]
      ..mixList = const [
        MixSummary(id: 'm1', name: 'Daily Mix 1', description: 'Upbeat'),
      ];
    repositories.playlists.playlistList = const [
      PlaylistSummary(
        id: 'pl1',
        name: 'Road trip',
        trackCount: 12,
        isOwner: true,
        isPublic: false,
      ),
    ];
    discovery = FakeDiscoveryRepository()
      ..recommended = const [
        DiscoveryArtist(name: 'Similar Soul', libraryArtistId: 'ar-9'),
      ]
      ..popular = const [DiscoveryArtist(name: 'Chart Topper')];
  });

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<GoRouter> pump(
    WidgetTester tester, {
    required bool discoveryOn,
    Size size = _tall,
  }) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/explore', builder: (_, _) => const Text('explore')),
        GoRoute(path: '/search', builder: (_, _) => const Text('search')),
        GoRoute(
          path: '/library/:tab',
          builder: (_, state) => Text('library ${state.pathParameters['tab']}'),
        ),
        GoRoute(
          path: '/:kind/:id',
          builder: (_, state) => Text('${state.pathParameters['kind']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    final overrides = <Override>[
      ...repositories.overrides,
      discovery.providerOverride,
      serverCapabilitiesProvider.overrideWith(
        () => _FixedCapabilities(
          ServerCapabilities(
            serverVersion: Version.tryParse('2.7.0'),
            hasP6SelfRevoke: true,
            hasP7PlayMarker: true,
            hasP8PlayedAt: true,
            autoPlaylists: true,
            discovery: discoveryOn,
          ),
        ),
      ),
      versionNoticeProvider.overrideWith(_NoNotice.new),
      capabilityRefreshProvider.overrideWithValue(() => capabilityRefreshes++),
      profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
    ];
    await tester.pumpApp(
      WindowClassScope(
        windowClass: windowClassOf(size),
        child: Router.withConfig(config: router),
      ),
      size: size,
      overrides: overrides,
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();
    return router;
  }

  Finder card(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(MediaCard));

  Finder shelf(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(Shelf));

  group('enabled', () {
    testWidgets('both shelves sit after Made For You and before Your '
        'Playlists, with round artist cards', (tester) async {
      await pump(tester, discoveryOn: true);

      final tops = [
        for (final title in [
          _madeForYou,
          _recommended,
          _popular,
          _yourPlaylists,
        ])
          tester.getTopLeft(find.text(title)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(card('Similar Soul'), findsOneWidget);
      expect(card('Chart Topper'), findsOneWidget);
      expect(tester.widget<MediaCard>(card('Similar Soul')).onPlay, isNull);
    });

    testWidgets('Show all of either shelf opens /explore', (tester) async {
      for (final title in [_recommended, _popular]) {
        final router = await pump(tester, discoveryOn: true);
        await tester.tap(
          find.descendant(of: shelf(title), matching: find.text('Show all')),
        );
        await tester.pumpAndSettle();
        expect(location(router), '/explore');
      }
    });

    testWidgets('an artist with a library id opens its artist page; one '
        'without opens Search for its name', (tester) async {
      var router = await pump(tester, discoveryOn: true);
      await tester.tap(card('Similar Soul'));
      await tester.pumpAndSettle();
      expect(location(router), '/artist/ar-9');

      router = await pump(tester, discoveryOn: true);
      await tester.tap(card('Chart Topper'));
      await tester.pumpAndSettle();
      expect(location(router), '/search?q=Chart+Topper');
    });

    testWidgets('an empty shelf is hidden', (tester) async {
      discovery.popular = [];
      await pump(tester, discoveryOn: true);

      expect(find.text(_popular), findsNothing);
      expect(find.text(_recommended), findsOneWidget);
    });

    testWidgets('a failing shelf is hidden while the rest of Home renders', (
      tester,
    ) async {
      discovery.errors['recommendedForYou'] = const ServerError(status: 500);
      await pump(tester, discoveryOn: true);

      expect(find.text(_recommended), findsNothing);
      expect(find.text(_popular), findsOneWidget);
      expect(find.text(_madeForYou), findsOneWidget);
      expect(find.text(_yourPlaylists), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('FeatureDisabled hides the shelf and requests a capability '
        'refresh', (tester) async {
      discovery.errors['popularArtists'] = const FeatureDisabled(status: 404);
      await pump(tester, discoveryOn: true);

      expect(find.text(_popular), findsNothing);
      expect(find.text(_recommended), findsOneWidget);
      expect(capabilityRefreshes, 1);
    });

    testWidgets('the Explore card ends Home at 390 and opens /explore', (
      tester,
    ) async {
      final router = await pump(
        tester,
        discoveryOn: true,
        size: TestSizes.compact,
      );
      await tester.scrollUntilVisible(
        find.text('Explore'),
        200,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(location(router), '/explore');
    });

    testWidgets('no Explore card at 1440, where the sidebar has the entry', (
      tester,
    ) async {
      await pump(tester, discoveryOn: true);

      expect(find.text('Explore'), findsNothing);
    });
  });

  group('disabled', () {
    testWidgets('neither shelf is present and no discovery request is '
        'made, but the Explore card is, for radio', (tester) async {
      await pump(tester, discoveryOn: false, size: const Size(390, 2400));

      expect(find.text(_recommended), findsNothing);
      expect(find.text(_popular), findsNothing);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text(_madeForYou), findsOneWidget);
      expect(discovery.reads, 0);
    });
  });
}
