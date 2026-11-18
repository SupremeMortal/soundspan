// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/player_slots.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

void main() {
  Future<PlayerRig> pumpMini(
    WidgetTester tester, {
    bool start = true,
    bool play = true,
    List<QueueItem>? items,
  }) async {
    final rig = PlayerRig();
    await tester.pumpApp(
      const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
      overrides: rig.overrides,
    );
    if (start) await rig.start(tester, play: play, items: items);
    return rig;
  }

  double progress(WidgetTester tester) =>
      tester.getSize(find.byKey(MiniPlayer.progressKey)).width /
      tester.getSize(find.byType(MiniPlayer)).width;

  testWidgets('shows the current item', (tester) async {
    final rig = await pumpMini(tester);

    expect(find.text('Song a'), findsOneWidget);
    expect(find.text('The Band a'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(MiniPlayer.progressKey)).height,
      MiniPlayer.progressHeight,
    );
    await rig.close(tester);
  });

  testWidgets('progress line tracks the position', (tester) async {
    final rig = await pumpMini(tester);
    expect(progress(tester), 0);

    for (var i = 0; i < 10; i++) {
      await rig.advance(tester, const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(progress(tester), closeTo(0.25, 0.03));
    await rig.close(tester);
  });

  testWidgets('play/pause and next call the controller', (tester) async {
    final rig = await pumpMini(tester);

    await tester.tap(find.byTooltip('Pause'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isFalse);

    await tester.tap(find.byTooltip('Play'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isTrue);

    await tester.tap(find.byTooltip('Next'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.current?.queueItemId, 'b');
    expect(find.text('Song b'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('an episode shows skip forward in place of next', (tester) async {
    final rig = await pumpMini(tester, items: [playerEpisode('a')]);

    expect(find.text('Episode a'), findsOneWidget);
    expect(find.text('The Show'), findsOneWidget);
    expect(find.byTooltip('Next'), findsNothing);
    await tester.tap(find.byTooltip('Skip forward 15 seconds'));
    await rig.settle(tester);
    expect(rig.harness.calls.last, startsWith('seek('));
    await rig.close(tester);
  });

  testWidgets('a track shows next and no skip', (tester) async {
    final rig = await pumpMini(tester);

    expect(find.byTooltip('Next'), findsOneWidget);
    expect(find.byTooltip('Skip forward 15 seconds'), findsNothing);
    await rig.close(tester);
  });

  testWidgets('a tap in the shell slot opens /now-playing', (tester) async {
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

    await tester.tap(find.text('Song a'));
    await tester.pumpAndSettle();

    expect(find.text('now playing page'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('empty queue renders nothing', (tester) async {
    final rig = await pumpMini(tester, start: false);
    await rig.settle(tester);

    expect(tester.getSize(find.byType(MiniPlayer)), Size.zero);
    await rig.close(tester);
  });

  for (final size in [TestSizes.compact, TestSizes.medium]) {
    testWidgets('meets the guidelines at ${size.width.toInt()}', (
      tester,
    ) async {
      final rig = PlayerRig();
      await tester.pumpApp(
        const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
        size: size,
        overrides: rig.overrides,
      );
      await rig.start(tester, play: false);

      await expectMeetsGuidelines(tester);
      await rig.close(tester);
    });
  }
}
