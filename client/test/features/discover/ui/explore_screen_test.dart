// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart'
    show FeatureDisabled, ServerError;

import '../../../helpers/fake_discovery_repository.dart';
import '../../../helpers/fake_reachability.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';

class _FixedCapabilities extends ServerCapabilitiesNotifier {
  new(this._value);

  final ServerCapabilities _value;

  @override
  ServerCapabilities build() => _value;
}

/// Records the commands the screen sends to playback.
class _RecordingController extends Fake implements PlaybackController {
  final List<bool> shuffles = [];
  final List<(List<QueueItem>, int, QueueContext?)> plays = [];

  @override
  Future<void> setShuffle(bool enabled) async => shuffles.add(enabled);

  @override
  Future<void> playItems(
    List<QueueItem> items, {
    int startIndex = 0,
    QueueContext? context,
  }) async => plays.add((items, startIndex, context));
}

Track _track(String title, {bool playable = true}) => Track(
  meta: TrackMeta(
    title: title,
    artist: 'Artist',
    album: 'Album',
    durationSec: 200,
  ),
  playbackId: playable ? PlaybackId('pb-$title') : null,
);

const _thisWeek = 'This week’s discoveries';
const _recommended = 'Recommended For You';
const _popular = 'Popular Artists';

void main() {
  late FakeDiscoveryRepository discovery;
  late FakeReachability reachability;
  late _RecordingController controller;
  late int capabilityRefreshes;

  setUp(() {
    capabilityRefreshes = 0;
    reachability = FakeReachability();
    controller = _RecordingController();
    discovery = FakeDiscoveryRepository()
      ..playlist = DiscoveryPlaylist(
        tracks: [
          _track('One'),
          _track('Two', playable: false),
          _track('Three'),
        ],
      )
      ..recommended = const [
        DiscoveryArtist(name: 'Similar Soul', libraryArtistId: 'ar-9'),
      ]
      ..popular = const [DiscoveryArtist(name: 'Chart Topper')];
  });

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<GoRouter> pump(
    WidgetTester tester, {
    bool discoveryOn = true,
    Size size = const Size(1440, 2000),
    ThemeMode theme = ThemeMode.dark,
  }) async {
    final router = GoRouter(
      initialLocation: '/explore',
      routes: [
        GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
        GoRoute(path: '/search', builder: (_, _) => const Text('search')),
        GoRoute(
          path: '/:kind/:id',
          builder: (_, state) => Text('${state.pathParameters['kind']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    final overrides = <Override>[
      discovery.providerOverride,
      serverCapabilitiesProvider.overrideWith(
        () => _FixedCapabilities(
          ServerCapabilities(
            serverVersion: Version.tryParse('2.7.0'),
            hasP6SelfRevoke: true,
            hasP7PlayMarker: true,
            hasP8PlayedAt: true,
            discovery: discoveryOn,
          ),
        ),
      ),
      capabilityRefreshProvider.overrideWithValue(() => capabilityRefreshes++),
      playbackControllerProvider.overrideWithValue(controller),
      profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
      reachabilityProvider.overrideWithValue(reachability),
    ];
    await tester.pumpApp(
      WindowClassScope(
        windowClass: windowClassOf(size),
        child: Router.withConfig(config: router),
      ),
      size: size,
      theme: theme,
      overrides: overrides,
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();
    return router;
  }

  Finder card(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(MediaCard));

  group('enabled', () {
    testWidgets('shows the three sections in order', (tester) async {
      await pump(tester);

      final tops = [
        for (final title in [_thisWeek, _recommended, _popular])
          tester.getTopLeft(find.text(title)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(find.byType(TrackRow), findsNWidgets(3));
      expect(card('Similar Soul'), findsOneWidget);
      expect(card('Chart Topper'), findsOneWidget);
    });

    testWidgets('a track without a playbackId is disabled', (tester) async {
      await pump(tester);

      final rows = tester.widgetList<TrackRow>(find.byType(TrackRow)).toList();
      expect([for (final row in rows) row.enabled], [true, false, true]);
    });

    testWidgets('Play queues the playable tracks in order with a playlist '
        'context', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(ExploreScreen.playKey));
      await tester.pumpAndSettle();

      expect(controller.shuffles, [false]);
      final (items, start, context) = controller.plays.single;
      expect(
        [for (final item in items) (item as TrackQueueItem).track.meta.title],
        ['One', 'Three'],
      );
      expect(start, 0);
      expect(context?.kind, QueueContextKind.playlist);
      expect(items.map((item) => item.queueItemId).toSet(), hasLength(2));
    });

    testWidgets('Shuffle queues the playable tracks with shuffle on', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byKey(ExploreScreen.shuffleKey));
      await tester.pumpAndSettle();

      expect(controller.shuffles, [true]);
      final (items, start, _) = controller.plays.single;
      expect(items, hasLength(2));
      expect(start, inInclusiveRange(0, 1));
    });

    testWidgets('Play and Shuffle are disabled when no track is playable', (
      tester,
    ) async {
      discovery.playlist = DiscoveryPlaylist(
        tracks: [_track('Only', playable: false)],
      );
      await pump(tester);

      expect(
        tester
            .widget<ButtonStyleButton>(find.byKey(ExploreScreen.playKey))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ButtonStyleButton>(find.byKey(ExploreScreen.shuffleKey))
            .onPressed,
        isNull,
      );
    });

    testWidgets('shows 10 tracks, and Show all shows the rest', (tester) async {
      discovery.playlist = DiscoveryPlaylist(
        tracks: [for (var i = 0; i < 14; i++) _track('Track $i')],
      );
      await pump(tester, size: const Size(1440, 4000));

      expect(find.byType(TrackRow), findsNWidgets(10));
      await tester.tap(find.text('Show all'));
      await tester.pumpAndSettle();
      expect(find.byType(TrackRow), findsNWidgets(14));
      expect(find.text('Show all'), findsNothing);
    });

    testWidgets('an artist with a library id opens /artist/<id>, one '
        'without opens /search?q=<name>', (tester) async {
      var router = await pump(tester);
      await tester.tap(card('Similar Soul'));
      await tester.pumpAndSettle();
      expect(location(router), '/artist/ar-9');

      router = await pump(tester);
      await tester.tap(card('Chart Topper'));
      await tester.pumpAndSettle();
      expect(location(router), '/search?q=Chart+Topper');
    });

    testWidgets('an empty or failed section is hidden', (tester) async {
      discovery
        ..playlist = null
        ..errors['popularArtists'] = const ServerError(status: 500);
      await pump(tester);

      expect(find.text(_thisWeek), findsNothing);
      expect(find.text(_popular), findsNothing);
      expect(find.text(_recommended), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('FeatureDisabled from one call hides that section and '
        'requests a capability refresh', (tester) async {
      discovery.errors['currentDiscovery'] = const FeatureDisabled(status: 404);
      await pump(tester);

      expect(find.text(_thisWeek), findsNothing);
      expect(find.text(_recommended), findsOneWidget);
      expect(capabilityRefreshes, 1);
    });

    testWidgets('every section empty shows one empty state', (tester) async {
      discovery
        ..playlist = null
        ..recommended = []
        ..popular = [];
      await pump(tester);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Nothing to explore yet'), findsOneWidget);
    });

    testWidgets('offline shows the cached sections under the banner', (
      tester,
    ) async {
      reachability.set(Reachability.serverUnreachable);
      await pump(tester);

      expect(
        find.text(
          'Can’t reach the server. Showing what’s saved on this '
          'device.',
        ),
        findsOneWidget,
      );
      expect(find.text(_thisWeek), findsOneWidget);
      expect(find.text(_recommended), findsOneWidget);
    });

    testWidgets('F5 refreshes every section', (tester) async {
      await pump(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.f5);
      await tester.pumpAndSettle();

      expect(discovery.count('refreshCurrentDiscovery'), 1);
      expect(discovery.count('refreshRecommendedForYou'), 1);
      expect(discovery.count('refreshPopularArtists'), 1);
    });

    testWidgets('artist cards are labelled with the artist name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(find.bySemanticsLabel(RegExp('^Chart Topper')), findsOneWidget);
      handle.dispose();
    });

    for (final size in [
      TestSizes.compact,
      TestSizes.medium,
      TestSizes.expanded,
    ]) {
      testWidgets('meets the guidelines at ${size.width.toInt()}', (
        tester,
      ) async {
        await pump(tester, size: size);

        await expectMeetsGuidelines(tester);
      });
    }
  });

  group('disabled', () {
    testWidgets('says it is not available and requests nothing', (
      tester,
    ) async {
      await pump(tester, discoveryOn: false);

      expect(find.text('Not available on this server'), findsOneWidget);
      expect(find.text(_thisWeek), findsNothing);
      expect(discovery.reads, 0);
    });
  });

  group('sidebar', () {
    Future<void> pumpShell(WidgetTester tester, {VoidCallback? onExplore}) =>
        tester.pumpApp(
          AdaptiveShell(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            onExplore: onExplore,
            child: const SizedBox.expand(),
          ),
          size: TestSizes.expanded,
        );

    testWidgets('has Explore below Podcasts at 1440 when given onExplore', (
      tester,
    ) async {
      var opened = 0;
      await pumpShell(tester, onExplore: () => opened++);

      final sidebar = find.byKey(AdaptiveShell.sidebarKey);
      final explore = find.descendant(
        of: sidebar,
        matching: find.text('Explore'),
      );
      expect(explore, findsOneWidget);
      expect(
        tester.getTopLeft(explore).dy,
        greaterThan(
          tester
              .getTopLeft(
                find.descendant(of: sidebar, matching: find.text('Podcasts')),
              )
              .dy,
        ),
      );
      await tester.tap(explore);
      expect(opened, 1);
    });

    testWidgets('has no Explore without onExplore', (tester) async {
      await pumpShell(tester);

      expect(find.text('Explore'), findsNothing);
    });
  });
}
