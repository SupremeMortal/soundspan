// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';

import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

void main() {
  /// Pumps a router at `/home` with the controller holding [count] tracks,
  /// then pushes `/now-playing`.
  Future<PlayerRig> pumpNowPlaying(
    WidgetTester tester, {
    Size size = TestSizes.compact,
    int count = 3,
    bool reduceMotion = false,
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
      overrides: rig.overrides,
    );
    if (reduceMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
    }
    container.read(playbackControllerProvider);
    await rig.start(
      tester,
      play: false,
      items: [for (var i = 0; i < count; i++) playerItem('t$i')],
    );
    router.push<void>(RoutePaths.nowPlaying).ignore();
    await tester.pumpAndSettle();
    return rig;
  }

  Finder screen() => find.byType(NowPlayingScreen);

  double top(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(NowPlayingScreen.dragHandleKey)).dy;

  /// Drags from [from] down by [dy] in steps of 10 px over 10 ms each, so the
  /// release is slow, and returns the gesture before release.
  Future<TestGesture> slowDrag(
    WidgetTester tester,
    Offset from,
    double dy,
  ) async {
    final gesture = await tester.startGesture(from);
    var moved = 0.0;
    var time = Duration.zero;
    while (moved < dy) {
      time += const Duration(milliseconds: 100);
      await gesture.moveBy(const Offset(0, 10), timeStamp: time);
      await tester.pump();
      moved += 10;
    }
    // Hold still before releasing, so the release is not a fling.
    await gesture.moveBy(
      Offset.zero,
      timeStamp: time + const Duration(seconds: 1),
    );
    return gesture;
  }

  testWidgets('a drag down of 30 % of the height pops the route', (
    tester,
  ) async {
    final rig = await pumpNowPlaying(tester);
    final start = top(tester);

    final gesture = await slowDrag(
      tester,
      tester.getCenter(find.byKey(NowPlayingScreen.dragHandleKey)),
      0.3 * TestSizes.compact.height,
    );
    expect(top(tester), greaterThan(start + 200));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(screen(), findsNothing);
    expect(find.text('home page'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('a drag down of 10 % springs back', (tester) async {
    final rig = await pumpNowPlaying(tester);
    final start = top(tester);

    final gesture = await slowDrag(
      tester,
      tester.getCenter(find.text('NOW PLAYING')),
      0.1 * TestSizes.compact.height,
    );
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(top(tester), greaterThan(start));
    await tester.pumpAndSettle();

    expect(screen(), findsOneWidget);
    expect(top(tester), start);
    await rig.close(tester);
  });

  testWidgets('a fast fling down from the artwork pops the route', (
    tester,
  ) async {
    final rig = await pumpNowPlaying(tester);

    await tester.fling(
      find.byKey(NowPlayingScreen.artworkKey),
      const Offset(0, 80),
      1500,
    );
    await tester.pumpAndSettle();

    expect(screen(), findsNothing);
    await rig.close(tester);
  });

  testWidgets('a drag inside the scrolled queue scrolls it, and at its top '
      'dismisses', (tester) async {
    final rig = await pumpNowPlaying(
      tester,
      size: const Size(800, 600),
      count: 30,
    );
    final queue = find.byKey(NowPlayingScreen.sideQueueKey);
    final list = find.descendant(of: queue, matching: find.byType(Scrollable));
    ScrollPosition position() =>
        tester.state<ScrollableState>(list.first).position;
    final start = top(tester);

    await tester.drag(queue, const Offset(0, -400));
    await tester.pumpAndSettle();
    final scrolled = position().pixels;
    expect(scrolled, greaterThan(0));

    var gesture = await slowDrag(tester, tester.getCenter(queue), 100);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(position().pixels, lessThan(scrolled));
    expect(screen(), findsOneWidget);
    expect(top(tester), start);

    position().jumpTo(0);
    await tester.pump();
    gesture = await slowDrag(tester, tester.getCenter(queue), 250);
    expect(top(tester), greaterThan(start));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(screen(), findsNothing);
    await rig.close(tester);
  });

  testWidgets('with reduced motion the screen does not follow the finger and '
      'pops on release', (tester) async {
    final rig = await pumpNowPlaying(tester, reduceMotion: true);
    final start = top(tester);

    final gesture = await slowDrag(
      tester,
      tester.getCenter(find.byKey(NowPlayingScreen.dragHandleKey)),
      0.3 * TestSizes.compact.height,
    );
    expect(top(tester), start);
    await gesture.up();
    await tester.pump();
    expect(top(tester), start);
    await tester.pumpAndSettle();
    expect(screen(), findsNothing);
    await rig.close(tester);
  });

  testWidgets('with reduced motion a short drag stays without moving', (
    tester,
  ) async {
    final rig = await pumpNowPlaying(tester, reduceMotion: true);
    final start = top(tester);

    final gesture = await slowDrag(
      tester,
      tester.getCenter(find.byKey(NowPlayingScreen.dragHandleKey)),
      0.1 * TestSizes.compact.height,
    );
    expect(top(tester), start);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(screen(), findsOneWidget);
    expect(top(tester), start);
    await rig.close(tester);
  });

  testWidgets('Escape pops the route', (tester) async {
    final rig = await pumpNowPlaying(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(screen(), findsNothing);
    await rig.close(tester);
  });
}
