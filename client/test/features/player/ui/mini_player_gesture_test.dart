// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/player_slots.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';

import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

void main() {
  /// Pumps the mini player slot at `/home` beside a `/now-playing` route,
  /// with the queue a, b, c paused on a.
  Future<PlayerRig> pumpSlot(WidgetTester tester) async {
    final rig = PlayerRig();
    final router = GoRouter(
      initialLocation: RoutePaths.home,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (_, _) => const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayerSlot(),
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.nowPlaying,
          pageBuilder: (_, state) => NowPlayingSheetPage(
            key: state.pageKey,
            openDrag: switch (state.extra) {
              final NowPlayingOpenDrag drag => drag,
              _ => null,
            },
            child: const ColoredBox(
              color: Color(0xFF000000),
              child: Text('now playing page'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = await tester.pumpApp(
      Router.withConfig(config: router),
      overrides: rig.overrides,
    );
    container.read(playbackControllerProvider);
    await rig.start(tester, play: false);
    return rig;
  }

  Finder nowPlaying() => find.text('now playing page');

  final height = TestSizes.compact.height;

  /// The top of the sheet, or the window's height while it is not shown.
  double sheetTop(WidgetTester tester) => nowPlaying().evaluate().isEmpty
      ? height
      : tester.getTopLeft(nowPlaying()).dy;

  /// Drags from the mini player's title up by [dy] in 10 px steps, 100 ms
  /// apart, and holds still, so the release is not a fling.
  Future<TestGesture> slowDragUp(WidgetTester tester, double dy) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Song a')),
    );
    var moved = 0.0;
    var time = Duration.zero;
    while (moved < dy) {
      time += const Duration(milliseconds: 100);
      await gesture.moveBy(const Offset(0, -10), timeStamp: time);
      await tester.pump();
      moved += 10;
    }
    await gesture.moveBy(
      Offset.zero,
      timeStamp: time + const Duration(seconds: 1),
    );
    await tester.pump();
    return gesture;
  }

  testWidgets('a drag up of half the height shows the sheet half open, and '
      'the release opens it', (tester) async {
    final rig = await pumpSlot(tester);

    final gesture = await slowDragUp(tester, height / 2);
    expect(sheetTop(tester), closeTo(height / 2, 10));
    // The page beneath stays painted.
    expect(find.text('Song a'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(sheetTop(tester), 0);
    await rig.close(tester);
  });

  testWidgets('a drag up of 10 % of the height and release leaves it '
      'closed and pops the route', (tester) async {
    final rig = await pumpSlot(tester);

    final gesture = await slowDragUp(tester, height / 10);
    expect(sheetTop(tester), closeTo(height * 0.9, 10));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(nowPlaying(), findsNothing);
    // The mini player takes taps again: the route is gone.
    await tester.tap(find.byTooltip('Play'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isTrue);
    await rig.close(tester);
  });

  testWidgets('a tap opens the sheet fully', (tester) async {
    final rig = await pumpSlot(tester);

    await tester.tap(find.text('Song a'));
    await tester.pumpAndSettle();

    expect(sheetTop(tester), 0);
    await rig.close(tester);
  });

  testWidgets('with reduced motion the sheet does not follow the drag and '
      'opens on release', (tester) async {
    final rig = await pumpSlot(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final gesture = await slowDragUp(tester, height / 2);
    expect(sheetTop(tester), greaterThanOrEqualTo(height));
    await gesture.up();
    await tester.pump();
    expect(sheetTop(tester), 0);
    await rig.close(tester);
  });

  testWidgets('a short upward fling opens now playing', (tester) async {
    final rig = await pumpSlot(tester);

    // 20 px up at 1000 px/s: under the distance, over the speed.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Song a')),
    );
    for (var i = 1; i <= 5; i++) {
      await gesture.moveBy(
        const Offset(0, -4),
        timeStamp: Duration(milliseconds: 4 * i),
      );
    }
    await gesture.up(timeStamp: const Duration(milliseconds: 21));
    await tester.pumpAndSettle();

    expect(sheetTop(tester), 0);
    await rig.close(tester);
  });

  testWidgets('a drag that starts on a button opens now playing', (
    tester,
  ) async {
    final rig = await pumpSlot(tester);

    await tester.timedDrag(
      find.byTooltip('Next'),
      Offset(0, -height / 2),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(nowPlaying(), findsOneWidget);
    expect(rig.controller.snapshot.current?.queueItemId, 'a');
    await rig.close(tester);
  });

  testWidgets('a horizontal swipe changes neither the route nor the track', (
    tester,
  ) async {
    final rig = await pumpSlot(tester);

    for (final dx in [-200.0, 200.0]) {
      await tester.fling(find.text('Song a'), Offset(dx, 0), 1500);
      await tester.pumpAndSettle();
    }

    expect(nowPlaying(), findsNothing);
    expect(rig.controller.snapshot.current?.queueItemId, 'a');
    await rig.close(tester);
  });

  testWidgets('tapping play/pause toggles without navigating', (tester) async {
    final rig = await pumpSlot(tester);

    await tester.tap(find.byTooltip('Play'));
    await rig.settle(tester);

    expect(rig.controller.snapshot.playing, isTrue);
    expect(nowPlaying(), findsNothing);
    await rig.close(tester);
  });
}
