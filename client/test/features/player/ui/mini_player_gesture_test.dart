// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/player_slots.dart';
import 'package:soundspan/core/playback/playback_providers.dart';

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
          builder: (_, _) => const Text('now playing page'),
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

  testWidgets('a drag up of 30 px opens now playing', (tester) async {
    final rig = await pumpSlot(tester);

    await tester.timedDrag(
      find.text('Song a'),
      const Offset(0, -30),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(nowPlaying(), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('a slow drag up of 10 px does not open now playing', (
    tester,
  ) async {
    final rig = await pumpSlot(tester);

    await tester.timedDrag(
      find.text('Song a'),
      const Offset(0, -10),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(nowPlaying(), findsNothing);
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

    expect(nowPlaying(), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('a drag that starts on a button opens now playing', (
    tester,
  ) async {
    final rig = await pumpSlot(tester);

    await tester.timedDrag(
      find.byTooltip('Next'),
      const Offset(0, -40),
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
