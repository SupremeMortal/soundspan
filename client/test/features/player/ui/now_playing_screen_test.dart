// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/quality_badge.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_root.dart';
import 'player_rig.dart';

void main() {
  /// Pumps a router at `/home` with the controller playing [items] (or
  /// a, b, c), then pushes `/now-playing`.
  Future<(PlayerRig, GoRouter)> pumpNowPlaying(
    WidgetTester tester, {
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
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
        GoRoute(
          path: '/artist/:artistId',
          builder: (_, state) => Scaffold(
            body: Text('artist page ${state.pathParameters['artistId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = await tester.pumpApp(
      Router.withConfig(config: router),
      size: size,
      theme: theme,
      overrides: rig.overrides,
    );
    container.read(playbackControllerProvider);
    await rig.start(tester, items: items, play: false);
    unawaitedPush(router, RoutePaths.nowPlaying);
    await tester.pumpAndSettle();
    return (rig, router);
  }

  testWidgets('shows the current item: artwork, title, artist, times', (
    tester,
  ) async {
    final (rig, _) = await pumpNowPlaying(tester);

    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.text('Song a'), findsOneWidget);
    expect(find.text('The Band a'), findsOneWidget);
    final artwork = tester.widget<Artwork>(find.byType(Artwork));
    expect(artwork.ref, 'cover-a');
    // The width less the 16 px gutters, under the 360 px maximum.
    expect(artwork.size, 390 - 2 * 16);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('-0:10'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(QualityBadge),
        matching: find.text('FLAC · 16/44.1 kHz'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(PlayPauseButton)),
      const Size.square(NowPlayingScreen.playButtonSize),
    );
    await rig.close(tester);
  });

  testWidgets('transport buttons call the controller', (tester) async {
    final (rig, _) = await pumpNowPlaying(tester);

    await tester.tap(find.byTooltip('Play'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isTrue);

    await tester.tap(find.byTooltip('Pause'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isFalse);

    await tester.tap(find.byTooltip('Next'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.current?.queueItemId, 'b');
    expect(find.text('Song b'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.current?.queueItemId, 'a');

    await tester.tap(find.byTooltip('Shuffle'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.queue.isShuffled, isTrue);

    await tester.tap(find.byTooltip('Repeat'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.queue.repeat, RepeatMode.all);
    await rig.close(tester);
  });

  testWidgets('an episode shows skip and speed and hides shuffle, repeat, '
      'previous and next', (tester) async {
    final (rig, _) = await pumpNowPlaying(tester, items: [playerEpisode('a')]);

    expect(find.text('Episode a'), findsOneWidget);
    expect(find.text('The Show'), findsOneWidget);
    expect(find.byTooltip('Skip back 15 seconds'), findsOneWidget);
    expect(find.byTooltip('Skip forward 15 seconds'), findsOneWidget);
    expect(find.byKey(PlayerTransport.speedKey), findsOneWidget);
    for (final tooltip in ['Shuffle', 'Previous', 'Next', 'Repeat']) {
      expect(find.byTooltip(tooltip), findsNothing, reason: tooltip);
    }
    await expectMeetsGuidelines(tester);
    await rig.close(tester);
  });

  testWidgets('the artist opens the artist page and closes the screen', (
    tester,
  ) async {
    final (rig, _) = await pumpNowPlaying(
      tester,
      items: [
        playerItem('a', artistId: 'ar-1'),
        playerItem('b'),
      ],
    );

    await tester.tap(find.byKey(NowPlayingScreen.artistKey));
    await tester.pumpAndSettle();

    expect(find.text('artist page ar-1'), findsOneWidget);
    expect(find.byType(NowPlayingScreen), findsNothing);
    await rig.close(tester);
  });

  testWidgets('an artist without an id is not a link', (tester) async {
    final (rig, _) = await pumpNowPlaying(tester);

    expect(
      find.descendant(
        of: find.byType(NowPlayingScreen),
        matching: find.byType(TextButton),
      ),
      findsNothing,
    );
    await tester.tap(find.text('The Band a'));
    await tester.pumpAndSettle();
    expect(find.byType(NowPlayingScreen), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('close pops the route', (tester) async {
    final (rig, _) = await pumpNowPlaying(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(NowPlayingScreen), findsNothing);
    expect(find.text('home page'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('the queue button opens the queue as a sheet', (tester) async {
    final (rig, _) = await pumpNowPlaying(tester);
    expect(find.byKey(NowPlayingScreen.sideQueueKey), findsNothing);

    await tester.tap(find.byTooltip('Queue'));
    await tester.pumpAndSettle();

    expect(find.byType(QueueSheet), findsOneWidget);
    expect(find.text('Next up'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(QueueSheet),
        matching: find.text('Song b'),
      ),
      findsOneWidget,
    );
    await rig.close(tester);
  });

  testWidgets('landscape medium shows the queue beside the artwork', (
    tester,
  ) async {
    final (rig, _) = await pumpNowPlaying(tester, size: const Size(1000, 700));

    final queue = find.byKey(NowPlayingScreen.sideQueueKey);
    expect(queue, findsOneWidget);
    expect(
      tester.getTopLeft(queue).dx,
      greaterThan(tester.getTopRight(find.byType(Artwork).first).dx),
    );
    expect(find.text('Next up'), findsOneWidget);
    expect(find.byTooltip('Queue'), findsNothing);
    await rig.close(tester);
  });

  testWidgets('portrait medium has the compact layout', (tester) async {
    final (rig, _) = await pumpNowPlaying(tester, size: TestSizes.medium);

    expect(find.byKey(NowPlayingScreen.sideQueueKey), findsNothing);
    expect(find.byTooltip('Queue'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('/now-playing on expanded redirects to the shell', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    final router = root.container.read(routerProvider)
      ..go(RoutePaths.nowPlaying);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, RoutePaths.home);
    expect(find.byType(NowPlayingScreen), findsNothing);
  });

  testWidgets('/now-playing on compact opens the screen', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    final router = root.container.read(routerProvider);

    unawaitedPush(router, RoutePaths.nowPlaying);
    await tester.pumpAndSettle();

    expect(find.byType(NowPlayingScreen), findsOneWidget);
    expect(find.text('Nothing is queued'), findsOneWidget);
  });

  for (final (size, theme) in [
    (TestSizes.compact, ThemeMode.dark),
    (TestSizes.compact, ThemeMode.light),
    (const Size(1000, 700), ThemeMode.dark),
  ]) {
    testWidgets('meets the guidelines at ${size.width.toInt()} '
        '(${theme.name})', (tester) async {
      final (rig, _) = await pumpNowPlaying(tester, size: size, theme: theme);

      await expectMeetsGuidelines(tester);
      await rig.close(tester);
    });
  }
}

/// Pushes [location] without waiting for the route to pop.
void unawaitedPush(GoRouter router, String location) {
  router.push<void>(location).ignore();
}
