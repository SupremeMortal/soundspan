// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/player/player.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

void main() {
  Future<PlayerRig> pumpMini(
    WidgetTester tester, {
    bool start = true,
    bool play = true,
  }) async {
    final rig = PlayerRig();
    await tester.pumpApp(
      const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
      overrides: rig.overrides,
    );
    if (start) await rig.start(tester, play: play);
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
