// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:ui' show SemanticsFlag, Tristate;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
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
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/widgets/artwork.dart';

import '../../../helpers/fake_clock.dart';
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

/// Forty lines of a second track, "Other 0" to "Other 39".
final SyncedLyrics _otherLong = SyncedLyrics([
  for (var i = 0; i < 40; i++)
    LyricLine(
      time: Duration(milliseconds: 250 * i),
      text: 'Other $i',
    ),
]);

const SyncedLyrics _short = SyncedLyrics([
  LyricLine(time: Duration(seconds: 1), text: 'First line'),
  LyricLine(time: Duration(seconds: 2), text: 'Second line'),
  LyricLine(time: Duration(seconds: 3), text: 'Third line'),
  LyricLine(time: Duration(seconds: 4), text: ''),
]);

/// Records the commands routed to it while attached.
class _Driver implements RemoteDriver {
  final List<PlaybackCommand> commands = [];

  @override
  Future<void> onCommand(PlaybackCommand command) async =>
      commands.add(command);

  @override
  void onCurrentItemFailed(String queueItemId) {}
}

const String _resume = 'Resume auto-scroll';

void main() {
  late FakeLyricsRepository lyrics;
  late FakeClock clock;

  setUp(() {
    lyrics = FakeLyricsRepository();
    clock = FakeClock();
  });

  List<Override> overrides(PlayerRig rig) => [
    ...rig.overrides,
    lyricsRepositoryProvider.overrideWithValue(AsyncData(lyrics)),
  ];

  /// Pumps the view alone in a [size] window with the controller holding
  /// a, b, c, paused unless [play].
  Future<PlayerRig> pumpView(
    WidgetTester tester, {
    bool play = false,
    Size size = const Size(400, 600),
    double textScale = 1.0,
  }) async {
    final rig = PlayerRig();
    final container = await tester.pumpApp(
      const Scaffold(body: LyricsView()),
      size: size,
      textScale: textScale,
      clock: clock,
      overrides: overrides(rig),
    );
    container.read(playbackControllerProvider);
    await rig.start(tester, play: play);
    await tester.pump();
    return rig;
  }

  ScrollPosition scrollPosition(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(LyricsView),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  /// How far down the view, as a fraction of its height, [text] is.
  double fractionOf(WidgetTester tester, String text) {
    final line = tester.getRect(find.text(text));
    final view = tester.getRect(find.byType(LyricsView));
    return (line.center.dy - view.top) / view.height;
  }

  group('tap to seek', () {
    testWidgets('tapping a line seeks to it and highlights it, paused', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpView(tester);
      final colors = tester.element(find.byType(LyricsView)).colors;

      await tester.tap(find.text('Third line'));
      await tester.pump();

      // At once, before the position is reported.
      expect(styleOf(tester, 'Third line').color, colors.content);
      expect(styleOf(tester, 'First line').color, colors.contentSecondary);

      await rig.settle(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(rig.controller.snapshot.position, const Duration(seconds: 3));
      expect(rig.controller.snapshot.playing, isFalse);
      expect(styleOf(tester, 'Third line').color, colors.content);
      await rig.close(tester);
    });

    testWidgets('an instrumental gap is a tappable ♪ marker', (tester) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpView(tester);

      await tester.tap(find.byKey(LyricsView.instrumentalKey));
      await rig.settle(tester);

      expect(rig.controller.snapshot.position, const Duration(seconds: 4));
      await rig.close(tester);
    });

    testWidgets('in a group the seek is routed as a command', (tester) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpView(tester);
      final driver = _Driver();
      rig.controller
        ..attachRemoteDriver(driver)
        ..setRemoteCanControl(true);
      await rig.settle(tester);

      await tester.tap(find.text('Second line'));
      await rig.settle(tester);

      expect(
        driver.commands.whereType<SeekCommand>().single.position,
        const Duration(seconds: 2),
      );
      await rig.close(tester);
    });

    testWidgets('a follower cannot seek: lines are disabled', (tester) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpView(tester);
      final driver = _Driver();
      rig.controller
        ..attachRemoteDriver(driver)
        ..setRemoteCanControl(false);
      await rig.settle(tester);

      final data = tester
          .getSemantics(find.text('Second line'))
          .getSemanticsData();
      expect(data.hint, contains('The host controls playback'));
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);

      await tester.tap(find.text('Second line'), warnIfMissed: false);
      await rig.settle(tester);
      expect(driver.commands.whereType<SeekCommand>(), isEmpty);
      await rig.close(tester);
    });

    testWidgets('plain lyrics have no tap action and no buttons', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = const PlainLyrics('Some words\nMore words');
      final rig = await pumpView(tester);

      await tester.tap(find.text('Some words\nMore words'));
      await rig.settle(tester);

      expect(rig.controller.snapshot.position, Duration.zero);
      expect(find.semantics.byFlag(SemanticsFlag.isButton), findsNothing);
      await rig.close(tester);
    });

    testWidgets('Down moves focus to the next line and Enter seeks', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpView(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await rig.settle(tester);

      expect(rig.controller.snapshot.position, const Duration(seconds: 2));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await rig.settle(tester);

      expect(rig.controller.snapshot.position, const Duration(seconds: 2));
      await rig.close(tester);
    });

    testWidgets('each synced line is a button with a Seek to hint', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpView(tester, play: true);
      await rig.advance(tester, const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      for (final (finder, label, hint) in [
        (find.text('First line'), 'First line', 'Seek to 0:01'),
        (find.text('Second line'), 'Second line', 'Seek to 0:02'),
        (
          find.byKey(LyricsView.instrumentalKey),
          'Instrumental',
          'Seek to 0:04',
        ),
      ]) {
        expect(
          tester.getSemantics(finder),
          isSemantics(
            label: label,
            hint: hint,
            isButton: true,
            isEnabled: true,
            hasTapAction: true,
            isFocusable: true,
          ),
        );
      }
      await expectMeetsGuidelines(tester);
      await rig.close(tester);
    });

    testWidgets('text scale 2.0 on a compact window does not overflow', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = SyncedLyrics([
        for (var i = 0; i < 6; i++)
          LyricLine(
            time: Duration(seconds: i + 1),
            text:
                'A rather long line of words number $i that has to wrap '
                'over several rows on a phone',
          ),
      ]);
      final rig = await pumpView(
        tester,
        play: true,
        size: TestSizes.compact,
        textScale: 2,
      );
      await rig.advance(tester, const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await rig.close(tester);
    });
  });

  group('auto-scroll', () {
    testWidgets('the current line is scrolled to 35 % of the view', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _long;
      final rig = await pumpView(tester, play: true);

      await rig.advance(tester, const Duration(seconds: 7));
      await tester.pumpAndSettle();

      expect(scrollPosition(tester).pixels, greaterThan(0));
      expect(fractionOf(tester, 'Line 28'), closeTo(0.35, 0.05));
      await rig.close(tester);
    });

    testWidgets('a drag pauses following and shows the resume pill', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _long;
      final rig = await pumpView(tester, play: true);
      await rig.advance(tester, const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text(_resume), findsNothing);

      await tester.drag(find.text('Line 16'), const Offset(0, -150));
      await tester.pumpAndSettle();
      final dragged = scrollPosition(tester).pixels;
      expect(find.text(_resume), findsOneWidget);

      await rig.advance(tester, const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(scrollPosition(tester).pixels, dragged);
      expect(find.text(_resume), findsOneWidget);
      await rig.close(tester);
    });

    testWidgets('the pill resumes following', (tester) async {
      lyrics.byTitle['Song a'] = _long;
      final rig = await pumpView(tester, play: true);
      await rig.advance(tester, const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.drag(find.text('Line 16'), const Offset(0, 200));
      await tester.pumpAndSettle();
      await rig.advance(tester, const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final paused = scrollPosition(tester).pixels;

      await tester.tap(find.text(_resume));
      await tester.pumpAndSettle();

      expect(find.text(_resume), findsNothing);
      expect(scrollPosition(tester).pixels, isNot(paused));
      expect(fractionOf(tester, 'Line 24'), closeTo(0.35, 0.05));
      await rig.close(tester);
    });

    testWidgets('tapping a line resumes following', (tester) async {
      lyrics.byTitle['Song a'] = _long;
      final rig = await pumpView(tester);
      await tester.drag(find.text('Line 3'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text(_resume), findsOneWidget);

      await tester.tap(find.text('Line 10'));
      await rig.settle(tester);
      await tester.pumpAndSettle();

      expect(find.text(_resume), findsNothing);
      expect(fractionOf(tester, 'Line 10'), closeTo(0.35, 0.05));
      await rig.close(tester);
    });

    testWidgets('following resumes 5 s after the last user scroll', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _long;
      final rig = await pumpView(tester);
      await tester.drag(find.text('Line 3'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Timers alone do not resume it: the time is read from the clock.
      await tester.pump(const Duration(seconds: 6));
      expect(find.text(_resume), findsOneWidget);

      clock.advance(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 4));
      expect(find.text(_resume), findsOneWidget);

      clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(_resume), findsNothing);
      expect(scrollPosition(tester).pixels, 0);
      await rig.close(tester);
    });

    testWidgets('a programmatic scroll does not pause following', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _long;
      final rig = await pumpView(tester, play: true);

      scrollPosition(tester).jumpTo(200);
      await tester.pump();
      await rig.advance(tester, const Duration(seconds: 7));
      await tester.pumpAndSettle();

      expect(find.text(_resume), findsNothing);
      expect(fractionOf(tester, 'Line 28'), closeTo(0.35, 0.05));
      await rig.close(tester);
    });

    testWidgets('a track change resets to the top and to following', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _long;
      lyrics.byTitle['Song b'] = _otherLong;
      final rig = await pumpView(tester, play: true);
      await rig.advance(tester, const Duration(seconds: 7));
      await tester.pumpAndSettle();
      await tester.drag(find.text('Line 28'), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(find.text(_resume), findsOneWidget);

      await rig.controller.pause();
      await rig.controller.next();
      await rig.settle(tester);
      await tester.pumpAndSettle();

      expect(find.text('Other 0'), findsOneWidget);
      expect(find.text(_resume), findsNothing);
      expect(scrollPosition(tester).pixels, 0);
      await rig.close(tester);
    });

    testWidgets('reduced motion jumps without animation frames', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _long;
      final rig = await pumpView(tester, play: true);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pump();

      await rig.advance(tester, const Duration(seconds: 7));
      await tester.pump();
      await tester.pump();
      final jumped = scrollPosition(tester).pixels;
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpAndSettle();

      expect(jumped, greaterThan(0));
      expect(scrollPosition(tester).pixels, jumped);
      await rig.close(tester);
    });

    testWidgets('position ticks within a line do not rebuild the lines', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpView(tester, play: true);
      await rig.advance(tester, const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();
      final builds = LyricsView.debugLineListBuilds;
      final element = tester.element(find.text('First line'));

      for (var i = 0; i < 4; i++) {
        await rig.advance(tester, const Duration(milliseconds: 200));
      }

      expect(LyricsView.debugLineListBuilds, builds);
      expect(tester.element(find.text('First line')), same(element));

      await rig.advance(tester, const Duration(milliseconds: 400));
      await tester.pump();
      expect(LyricsView.debugLineListBuilds, greaterThan(builds));
      await rig.close(tester);
    });
  });

  group('layout', () {
    testWidgets('the overlay at 1440 shows artwork left, lyrics right', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = PlayerRig();
      final container = await tester.pumpApp(
        AppShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          onSearch: (_) {},
          child: const Center(child: Text('content')),
        ),
        size: TestSizes.expanded,
        clock: clock,
        overrides: [
          ...overrides(rig),
          initialActiveProfileIdProvider.overrideWithValue(null),
        ],
      );
      container.read(playbackControllerProvider);
      await rig.start(tester, play: false);
      await rig.controller.seek(const Duration(milliseconds: 2100));
      await rig.settle(tester);
      await tester.pump(const Duration(milliseconds: 300));
      container.read(nowPlayingOverlayProvider.notifier).toggle();
      await tester.pumpAndSettle();

      final overlay = find.byKey(AdaptiveShell.contentOverlayKey);
      final view = find.descendant(
        of: overlay,
        matching: find.byType(LyricsView),
      );
      final artwork = find.descendant(
        of: overlay,
        matching: find.byType(Artwork),
      );
      expect(view, findsOneWidget);
      final overlayRect = tester.getRect(overlay);
      expect(tester.getRect(artwork).right, lessThan(overlayRect.center.dx));
      expect(
        tester.getRect(view).left,
        greaterThanOrEqualTo(overlayRect.center.dx - 1),
      );
      final line = find.descendant(of: view, matching: find.text('First line'));
      expect(tester.getSize(line).width, lessThanOrEqualTo(640));

      final typography = tester.element(view).typography;
      final current = tester.widget<Text>(
        find.descendant(of: view, matching: find.text('Second line')),
      );
      final other = tester.widget<Text>(line);
      expect(current.style!.fontSize, typography.headline.fontSize);
      expect(other.style!.fontSize, typography.subtitle.fontSize);
      await rig.close(tester);
    });

    Future<PlayerRig> pumpNowPlaying(WidgetTester tester, Size size) async {
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
        clock: clock,
        overrides: overrides(rig),
      );
      container.read(playbackControllerProvider);
      await rig.start(tester, play: false);
      unawaitedPush(router, RoutePaths.nowPlaying);
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets('at 800 landscape artwork and lyrics sit side by side', (
      tester,
    ) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpNowPlaying(tester, const Size(800, 600));

      await tester.tap(find.widgetWithText(Tab, 'Lyrics'));
      await tester.pumpAndSettle();

      final view = find.byType(LyricsView);
      final artwork = find.byType(Artwork).first;
      expect(view, findsOneWidget);
      expect(find.byType(LyricsSheet), findsNothing);
      expect(
        tester.getRect(artwork).right,
        lessThanOrEqualTo(tester.getRect(view).left),
      );
      await rig.close(tester);
    });

    testWidgets('at 390 the lyrics open in the sheet', (tester) async {
      lyrics.byTitle['Song a'] = _short;
      final rig = await pumpNowPlaying(tester, TestSizes.compact);

      await tester.tap(find.byTooltip('Lyrics'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(LyricsSheet),
          matching: find.byType(LyricsView),
        ),
        findsOneWidget,
      );
      await rig.close(tester);
    });
  });
}
