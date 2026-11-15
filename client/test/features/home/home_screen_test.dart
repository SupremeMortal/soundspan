// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:soundspan/features/home/home.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan_api/soundspan_api.dart'
    show FeatureDisabled, Offline, ServerError;

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

/// Capabilities fixed for a test.
class _FixedCapabilities extends ServerCapabilitiesNotifier {
  new(this._value);

  final ServerCapabilities _value;

  @override
  ServerCapabilities build() => _value;
}

/// A version notice that records dismissals.
class _FakeVersionNotice extends VersionNoticeController {
  new(this._notice);

  final VersionNotice? _notice;

  static int dismissals = 0;

  @override
  Future<VersionNotice?> build() async => _notice;

  @override
  Future<void> dismiss() async {
    dismissals++;
    state = const AsyncData(null);
  }
}

ServerCapabilities _capabilities({bool autoPlaylists = true}) =>
    ServerCapabilities(
      serverVersion: Version.tryParse('2.7.0'),
      hasP6SelfRevoke: true,
      hasP7PlayMarker: true,
      hasP8PlayedAt: true,
      autoPlaylists: autoPlaylists,
    );

const _continueListening = 'Continue Listening';
const _recentlyAdded = 'Recently Added';
const _madeForYou = 'Made For You';
const _yourPlaylists = 'Your Playlists';
const _popularPodcasts = 'Popular Podcasts';

const List<String> _titles = [
  _continueListening,
  _recentlyAdded,
  _madeForYou,
  _yourPlaylists,
  _popularPodcasts,
];

/// A tall window that shows every shelf at once.
const Size _tall = Size(1440, 2200);

FakeRepositories _seeded() {
  final repositories = FakeRepositories();
  repositories.home
    ..recent = const [
      RecentItem.artist(
        artist: Artist(id: 'r1', name: 'Radiohead'),
      ),
      RecentItem.podcast(
        podcast: Podcast(id: 'p1', title: 'Song Exploder'),
      ),
    ]
    ..added = const [Artist(id: 'a1', name: 'Björk')]
    ..mixList = const [
      MixSummary(id: 'm1', name: 'Daily Mix 1', description: 'Upbeat'),
    ]
    ..podcasts = const [
      PodcastSummary(id: 't1', title: 'Hardcore History', author: 'Carlin'),
    ];
  repositories.playlists.playlistList = const [
    PlaylistSummary(
      id: 'pl1',
      name: 'Road trip',
      trackCount: 12,
      isOwner: true,
      isPublic: false,
      coverRefs: ['c1', 'c2', 'c3', 'c4'],
    ),
  ];
  return repositories;
}

void _empty(FakeRepositories repositories) {
  repositories.home
    ..recent = []
    ..added = []
    ..mixList = []
    ..podcasts = [];
  repositories.playlists.playlistList = [];
}

void _failAll(FakeRepositories repositories) {
  repositories.home.errors.addAll({
    'recentlyListened': const Offline(),
    'recentlyAdded': const Offline(),
    'mixes': const Offline(),
    'topPodcasts': const Offline(),
  });
  repositories.playlists
    ..failingPages = {0}
    ..failure = const Offline();
}

/// Settles, then lets provider errors that landed after the last frame
/// rebuild the screen.
Future<void> settleAll(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  late FakeRepositories repositories;
  late int capabilityRefreshes;

  setUp(() {
    repositories = _seeded();
    capabilityRefreshes = 0;
    _FakeVersionNotice.dismissals = 0;
  });

  FakeHomeRepository home() => repositories.home;

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<GoRouter> pump(
    WidgetTester tester, {
    Size size = _tall,
    ThemeMode theme = ThemeMode.dark,
    double textScale = 1.0,
    bool autoPlaylists = true,
    VersionNotice? notice,
    FakeClock? clock,
    bool settle = true,
  }) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
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
      serverCapabilitiesProvider.overrideWith(
        () => _FixedCapabilities(_capabilities(autoPlaylists: autoPlaylists)),
      ),
      versionNoticeProvider.overrideWith(() => _FakeVersionNotice(notice)),
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
      theme: theme,
      textScale: textScale,
      overrides: overrides,
      clock: clock,
    );
    if (settle) await settleAll(tester);
    return router;
  }

  Finder card(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(MediaCard));

  testWidgets('shelves appear in the documented order with their titles', (
    tester,
  ) async {
    await pump(tester);

    final tops = [
      for (final title in _titles) tester.getTopLeft(find.text(title)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    for (final title in _titles) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('an empty shelf is hidden; a failed shelf with no cache is '
      'hidden; a failed shelf with cache shows the cached cards', (
    tester,
  ) async {
    home()
      ..podcasts = []
      ..errors['recentlyAdded'] = const ServerError(status: 500)
      ..refreshErrors['recentlyListened'] = const Offline();
    await pump(tester);

    expect(find.text(_popularPodcasts), findsNothing);
    expect(find.text(_recentlyAdded), findsNothing);
    expect(find.text(_continueListening), findsOneWidget);
    expect(card('Radiohead'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets(
    'Made For You starts with Liked Songs and opens /playlist/liked',
    (tester) async {
      final router = await pump(tester);

      final liked = tester.getTopLeft(card('Liked Songs'));
      final mix = tester.getTopLeft(card('Daily Mix 1'));
      expect(liked.dx, lessThan(mix.dx));
      expect(liked.dy, mix.dy);

      await tester.tap(card('Liked Songs'));
      await tester.pumpAndSettle();
      expect(location(router), '/playlist/liked');
    },
  );

  testWidgets('mix cards appear only with autoPlaylists and the mixes '
      'request is not made without it', (tester) async {
    await pump(tester, autoPlaylists: false);

    expect(find.text(_madeForYou), findsOneWidget);
    expect(card('Liked Songs'), findsOneWidget);
    expect(card('Daily Mix 1'), findsNothing);
    expect(home().readCount('mixes'), 0);
  });

  testWidgets('mix cards with autoPlaylists are inert until mix detail '
      'exists', (tester) async {
    await pump(tester);

    expect(card('Daily Mix 1'), findsOneWidget);
    expect(tester.widget<MediaCard>(card('Daily Mix 1')).onTap, isNull);
    expect(home().readCount('mixes'), 1);
  });

  testWidgets('FeatureDisabled on mixes hides them and requests a capability '
      'refresh', (tester) async {
    home().errors['mixes'] = const FeatureDisabled(status: 404);
    await pump(tester);

    expect(card('Liked Songs'), findsOneWidget);
    expect(card('Daily Mix 1'), findsNothing);
    expect(find.byType(ErrorView), findsNothing);
    expect(capabilityRefreshes, 1);
  });

  testWidgets('FeatureDisabled refreshing cached mixes hides them and '
      'requests a capability refresh', (tester) async {
    home().refreshErrors['mixes'] = const FeatureDisabled(status: 404);
    await pump(tester);

    expect(card('Daily Mix 1'), findsNothing);
    expect(capabilityRefreshes, 1);
  });

  testWidgets('Continue Listening cards open the album, artist or playlist '
      'they stand for', (tester) async {
    final router = await pump(tester);

    expect(tester.widget<MediaCard>(card('Song Exploder')).onTap, isNull);
    await tester.tap(card('Radiohead'));
    await tester.pumpAndSettle();
    expect(location(router), '/artist/r1');
  });

  testWidgets('Recently Added cards are round and open the artist', (
    tester,
  ) async {
    final router = await pump(tester);

    final artwork = tester.widget<Artwork>(
      find.descendant(of: card('Björk'), matching: find.byType(Artwork)),
    );
    expect(artwork.shape, ArtworkShape.circle);
    await tester.tap(card('Björk'));
    await tester.pumpAndSettle();
    expect(location(router), '/artist/a1');
  });

  testWidgets('Your Playlists cards open the playlist', (tester) async {
    final router = await pump(tester);

    expect(
      find.descendant(of: card('Road trip'), matching: find.text('12 songs')),
      findsOneWidget,
    );
    await tester.tap(card('Road trip'));
    await tester.pumpAndSettle();
    expect(location(router), '/playlist/pl1');
  });

  testWidgets('Your Playlists Show all goes to /library/playlists', (
    tester,
  ) async {
    final router = await pump(tester);

    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();
    expect(location(router), '/library/playlists');
  });

  testWidgets('Popular Podcasts cards are not buttons', (tester) async {
    await pump(tester);

    expect(tester.widget<MediaCard>(card('Hardcore History')).onTap, isNull);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(card('Hardcore History')),
      isNot(matchesSemantics(isButton: true)),
    );
    handle.dispose();
  });

  for (final (hour, minute, greeting) in [
    (9, 0, 'Good morning'),
    (11, 59, 'Good morning'),
    (12, 0, 'Good afternoon'),
    (15, 0, 'Good afternoon'),
    (18, 0, 'Good evening'),
    (21, 0, 'Good evening'),
  ]) {
    testWidgets('greeting at $hour:$minute is "$greeting"', (tester) async {
      await pump(
        tester,
        clock: FakeClock(start: DateTime(2025, 3, 4, hour, minute)),
      );

      expect(find.text(greeting), findsOneWidget);
    });
  }

  testWidgets('all shelves failed without cache shows one ErrorView and '
      'Retry refetches every shelf', (tester) async {
    _failAll(repositories);
    await pump(tester, clock: FakeClock(start: DateTime(2025, 3, 4, 9)));
    expect(find.byType(ErrorView), findsOneWidget);
    for (final title in _titles) {
      expect(find.text(title), findsNothing);
    }
    expect(find.text('Good morning'), findsOneWidget);

    home().errors.clear();
    repositories.playlists.failingPages = {};
    final reads = {
      for (final method in [
        'recentlyListened',
        'recentlyAdded',
        'mixes',
        'topPodcasts',
      ])
        method: home().readCount(method),
    };
    final playlistReads = repositories.playlists.sources.length;

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    for (final MapEntry(:key, :value) in reads.entries) {
      expect(home().readCount(key), value + 1, reason: key);
    }
    expect(repositories.playlists.sources.length, playlistReads + 1);
    expect(find.byType(ErrorView), findsNothing);
    for (final title in _titles) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('all shelves empty shows the empty-library state', (
    tester,
  ) async {
    _empty(repositories);
    await pump(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.text(_madeForYou), findsNothing);
  });

  testWidgets('one shelf with content keeps the shelves', (tester) async {
    _empty(repositories);
    home().added = const [Artist(id: 'a1', name: 'Björk')];
    await pump(tester);

    expect(find.byType(EmptyState), findsNothing);
    expect(find.text(_recentlyAdded), findsOneWidget);
    expect(find.text(_madeForYou), findsOneWidget);
  });

  testWidgets('pull to refresh refreshes every shelf', (tester) async {
    await pump(tester);

    // Further than the indicator's arming distance on a tall window.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text(_continueListening)),
    );
    for (var step = 0; step < 40; step++) {
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    for (final method in [
      'refreshRecentlyListened',
      'refreshRecentlyAdded',
      'refreshMixes',
      'refreshTopPodcasts',
    ]) {
      expect(home().refreshCount(method), 1, reason: method);
    }
    expect(repositories.playlists.sources.single.refreshCount, 1);
  });

  testWidgets('F5 refreshes every shelf', (tester) async {
    await pump(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();

    for (final method in [
      'refreshRecentlyListened',
      'refreshRecentlyAdded',
      'refreshMixes',
      'refreshTopPodcasts',
    ]) {
      expect(home().refreshCount(method), 1, reason: method);
    }
    expect(repositories.playlists.sources.single.refreshCount, 1);
  });

  testWidgets('refresh requests a shelf that failed with nothing cached '
      'anew', (tester) async {
    home().errors['recentlyAdded'] = const Offline();
    await pump(tester);
    expect(find.text(_recentlyAdded), findsNothing);

    home().errors.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();

    expect(home().readCount('recentlyAdded'), 2);
    expect(find.text(_recentlyAdded), findsOneWidget);
  });

  testWidgets('a shelf below the fold is not requested until it scrolls '
      'into view', (tester) async {
    await pump(tester, size: TestSizes.compact);

    expect(home().readCount('recentlyListened'), 1);
    expect(home().readCount('topPodcasts'), 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(home().readCount('topPodcasts'), 1);
    expect(find.text(_popularPodcasts), findsOneWidget);
  });

  testWidgets('a shelf without a value yet shows card skeletons', (
    tester,
  ) async {
    await pump(tester, settle: false);
    expect(find.byType(MediaCardSkeleton), findsWidgets);
    expect(find.text(_continueListening), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(MediaCardSkeleton), findsNothing);
    expect(card('Radiohead'), findsOneWidget);
  });

  testWidgets('newer-than-tested notice is shown, dismissing it calls '
      'dismiss and removes it', (tester) async {
    await pump(
      tester,
      notice: VersionNotice.newerThanTested(Version.tryParse('9.0.0')!),
    );

    const message = 'This server is newer than this app was tested with';
    expect(find.text(message), findsOneWidget);
    expect(
      tester.widget<AppBanner>(find.byType(AppBanner)).kind,
      AppBannerKind.serverNotice,
    );
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(_FakeVersionNotice.dismissals, 1);
    expect(find.text(message), findsNothing);
  });

  testWidgets('version-unknown notice likewise', (tester) async {
    await pump(tester, notice: VersionNotice.versionUnknown);

    const message = 'This server’s version could not be read';
    expect(find.text(message), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(_FakeVersionNotice.dismissals, 1);
    expect(find.text(message), findsNothing);
  });

  testWidgets('no notice in range', (tester) async {
    await pump(tester);

    expect(find.byType(AppBanner), findsNothing);
  });

  for (final size in [
    TestSizes.compact,
    TestSizes.medium,
    TestSizes.expanded,
  ]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('meets the guidelines at ${size.width.toInt()} in '
          '${theme.name}', (tester) async {
        // Without a notice: the banner's contrast is checked by its own
        // test; the guideline's pixel sampling misreads its long text.
        await pump(tester, size: size, theme: theme);

        await expectMeetsGuidelines(tester);
      });
    }
  }

  for (final size in [
    TestSizes.compact,
    TestSizes.medium,
    TestSizes.expanded,
  ]) {
    testWidgets('text scale 2.0 at ${size.width.toInt()} does not '
        'overflow', (tester) async {
      await pump(
        tester,
        size: size,
        textScale: 2,
        notice: VersionNotice.newerThanTested(Version.tryParse('9.0.0')!),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_continueListening), findsOneWidget);
    });
  }
}
