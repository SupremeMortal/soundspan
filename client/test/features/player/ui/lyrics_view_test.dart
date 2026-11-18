// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_lyrics_repository.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'now_playing_screen_test.dart' show unawaitedPush;
import 'player_rig.dart';

/// Forty lines a quarter second apart, "Line 0" to "Line 39".
final SyncedLyrics _long = SyncedLyrics([
  for (var i = 0; i < 40; i++)
    LyricLine(
      time: Duration(milliseconds: 250 * i),
      text: 'Line $i',
    ),
]);

const SyncedLyrics _short = SyncedLyrics([
  LyricLine(time: Duration(seconds: 1), text: 'First line'),
  LyricLine(time: Duration(seconds: 2), text: 'Second line'),
  LyricLine(time: Duration(seconds: 3), text: 'Third line'),
]);

QueueItem _episode() => const QueueItem.episode(
  queueItemId: 'ep',
  episode: Episode(id: 'e1', podcastId: 'p1', title: 'Episode one'),
  podcast: Podcast(id: 'p1', title: 'The Show'),
);

void main() {
  late FakeLyricsRepository lyrics;

  setUp(() => lyrics = FakeLyricsRepository());

  List<Override> overrides(PlayerRig rig) => [
    ...rig.overrides,
    lyricsRepositoryProvider.overrideWithValue(AsyncData(lyrics)),
  ];

  /// Pumps the view alone, [size] high, with the controller holding a, b,
  /// c (or [items]), paused unless [play].
  Future<PlayerRig> pumpView(
    WidgetTester tester, {
    bool play = false,
    List<QueueItem>? items,
    Size size = const Size(400, 600),
    ThemeMode theme = ThemeMode.dark,
  }) async {
    final rig = PlayerRig();
    final container = await tester.pumpApp(
      const Scaffold(body: LyricsView()),
      size: size,
      theme: theme,
      overrides: overrides(rig),
    );
    container.read(playbackControllerProvider);
    await rig.start(tester, items: items, play: play);
    await tester.pump();
    return rig;
  }

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  ScrollPosition scrollPosition(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(LyricsView),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  testWidgets('the current line follows the position', (tester) async {
    lyrics.byTitle['Song a'] = _short;
    final rig = await pumpView(tester, play: true);
    final context = tester.element(find.byType(LyricsView));
    final typography = context.typography;
    final colors = context.colors;

    expect(styleOf(tester, 'First line').fontSize, typography.body.fontSize);
    expect(styleOf(tester, 'First line').color, colors.contentSecondary);

    await rig.advance(tester, const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    final current = styleOf(tester, 'Second line');
    expect(current.fontSize, typography.title.fontSize);
    expect(current.color, colors.content);
    expect(styleOf(tester, 'First line').color, colors.contentSecondary);
    expect(styleOf(tester, 'Third line').color, colors.contentSecondary);
    expect(
      tester.getSemantics(find.text('Second line')),
      isSemantics(label: 'Second line', isSelected: true, isButton: true),
    );
    await rig.close(tester);
  });

  testWidgets('the list scrolls the current line to 35 % of the view', (
    tester,
  ) async {
    lyrics.byTitle['Song a'] = _long;
    final rig = await pumpView(tester, play: true);
    expect(scrollPosition(tester).pixels, 0);

    await rig.advance(tester, const Duration(seconds: 7));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = scrollPosition(tester).pixels;
    await tester.pumpAndSettle();
    final settled = scrollPosition(tester).pixels;

    expect(midway, greaterThan(0));
    expect(settled, greaterThan(midway));
    final line = tester.getRect(find.text('Line 28'));
    final view = tester.getRect(find.byType(LyricsView));
    expect((line.center.dy - view.top) / view.height, closeTo(0.35, 0.05));
    await rig.close(tester);
  });

  testWidgets('reduced motion jumps to the current line', (tester) async {
    lyrics.byTitle['Song a'] = _long;
    final rig = await pumpView(tester, play: true);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();

    await rig.advance(tester, const Duration(seconds: 7));
    await tester.pump();
    await tester.pump();
    final jumped = scrollPosition(tester).pixels;
    await tester.pumpAndSettle();

    expect(jumped, greaterThan(0));
    expect(scrollPosition(tester).pixels, jumped);
    await rig.close(tester);
  });

  testWidgets('plain lyrics are selectable text', (tester) async {
    lyrics.byTitle['Song a'] = const PlainLyrics('Some words\nMore words');
    final rig = await pumpView(tester);

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Some words\nMore words'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('no lyrics says so', (tester) async {
    final rig = await pumpView(tester);

    expect(find.widgetWithText(EmptyState, 'No lyrics found'), findsOneWidget);
    expect(lyrics.requested.single.meta.title, 'Song a');
    await rig.close(tester);
  });

  testWidgets('loading shows skeleton lines', (tester) async {
    lyrics.pending = true;
    final rig = await pumpView(tester);

    expect(find.byKey(LyricsView.skeletonKey), findsOneWidget);
    await lyrics.close();
    await rig.close(tester);
  });

  testWidgets('a failure shows Retry, which loads again', (tester) async {
    lyrics.error = const api.ServerError(status: 503);
    final rig = await pumpView(tester);
    expect(find.byType(ErrorView), findsOneWidget);

    lyrics
      ..error = null
      ..byTitle['Song a'] = const PlainLyrics('Back again');
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Back again'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('synced lyrics meet the guidelines', (tester) async {
    lyrics.byTitle['Song a'] = _short;
    final rig = await pumpView(tester, play: true);
    await rig.advance(tester, const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await expectMeetsGuidelines(tester);
    await rig.close(tester);
  });

  group('surfaces', () {
    Future<PlayerRig> pumpShell(
      WidgetTester tester, {
      List<QueueItem>? items,
    }) async {
      final rig = PlayerRig();
      final container = await tester.pumpApp(
        AppShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          onSearch: (_) {},
          child: const Center(child: Text('content')),
        ),
        size: TestSizes.expanded,
        overrides: [
          ...overrides(rig),
          initialActiveProfileIdProvider.overrideWithValue(null),
        ],
      );
      container.read(playbackControllerProvider);
      await rig.start(tester, items: items, play: false);
      await tester.pumpAndSettle();
      return rig;
    }

    Future<PlayerRig> pumpNowPlaying(
      WidgetTester tester, {
      Size size = TestSizes.compact,
      List<QueueItem>? items,
    }) async {
      final rig = PlayerRig();
      final router = GoRouter(
        initialLocation: RoutePaths.home,
        routes: [
          GoRoute(
            path: RoutePaths.home,
            builder: (_, _) => const Scaffold(body: Text('home page')),
          ),
          GoRoute(
            path: RoutePaths.nowPlaying,
            builder: (_, _) => const NowPlayingScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = await tester.pumpApp(
        Router.withConfig(config: router),
        size: size,
        overrides: overrides(rig),
      );
      container.read(playbackControllerProvider);
      await rig.start(tester, items: items, play: false);
      unawaitedPush(router, RoutePaths.nowPlaying);
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets('the lyrics button toggles the lyrics panel on expanded', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = const PlainLyrics('Panel words');
      final rig = await pumpShell(tester);
      expect(find.byKey(AdaptiveShell.rightPanelKey), findsNothing);

      await tester.tap(find.byTooltip('Lyrics'));
      await tester.pumpAndSettle();

      final panel = find.byKey(AdaptiveShell.rightPanelKey);
      expect(
        find.descendant(of: panel, matching: find.byType(LyricsPanel)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('Panel words')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Lyrics'));
      await tester.pumpAndSettle();
      expect(find.byKey(AdaptiveShell.rightPanelKey), findsNothing);
      await rig.close(tester);
    });

    testWidgets('the lyrics button opens the sheet on compact', (tester) async {
      lyrics.byTitle['Song a'] = const PlainLyrics('Sheet words');
      final rig = await pumpNowPlaying(tester);

      await tester.tap(find.byTooltip('Lyrics'));
      await tester.pumpAndSettle();

      expect(find.byType(LyricsSheet), findsOneWidget);
      expect(find.text('Sheet words'), findsOneWidget);
      await expectMeetsGuidelines(tester);
      await rig.close(tester);
    });

    testWidgets('medium landscape offers Queue and Lyrics tabs', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = const PlainLyrics('Tab words');
      final rig = await pumpNowPlaying(tester, size: const Size(1000, 700));
      expect(find.byKey(NowPlayingScreen.sideQueueKey), findsOneWidget);
      expect(find.byTooltip('Lyrics'), findsNothing);

      await tester.tap(find.widgetWithText(Tab, 'Lyrics'));
      await tester.pumpAndSettle();

      expect(find.text('Tab words'), findsOneWidget);
      await rig.close(tester);
    });

    testWidgets('hidden for an episode', (tester) async {
      final rig = await pumpShell(tester, items: [_episode()]);
      expect(find.byTooltip('Queue'), findsOneWidget);
      expect(find.byTooltip('Lyrics'), findsNothing);
      await rig.close(tester);

      final nowPlaying = await pumpNowPlaying(tester, items: [_episode()]);
      expect(find.byTooltip('Queue'), findsOneWidget);
      expect(find.byTooltip('Lyrics'), findsNothing);
      await nowPlaying.close(tester);

      final landscape = await pumpNowPlaying(
        tester,
        size: const Size(1000, 700),
        items: [_episode()],
      );
      expect(find.byType(TabBar), findsNothing);
      expect(find.byKey(NowPlayingScreen.sideQueueKey), findsOneWidget);
      await landscape.close(tester);
    });
  });
}
