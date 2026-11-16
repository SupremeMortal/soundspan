// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/player_slots.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';

import '../../features/player/ui/player_rig.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

void main() {
  testWidgets('no player bar while the queue is empty at 1440', (tester) async {
    await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    expect(find.byType(PlayerBar), findsNothing);
    expect(find.byKey(PlayerBarSlot.panelKey), findsNothing);
    expect(find.byKey(MiniPlayerSlot.slotKey), findsNothing);
    await expectMeetsGuidelines(tester);
  });

  for (final size in [TestSizes.compact, TestSizes.medium]) {
    testWidgets('zero-height mini player at ${size.width.toInt()} while the '
        'queue is empty', (tester) async {
      await tester.pumpSoundspanApp(stored: StoredProfile.signedIn, size: size);
      expect(tester.getSize(find.byKey(MiniPlayerSlot.slotKey)).height, 0);
      expect(find.byKey(PlayerBarSlot.panelKey), findsNothing);
      await expectMeetsGuidelines(tester);
    });
  }

  Widget slot(Widget child) =>
      Column(mainAxisAlignment: MainAxisAlignment.end, children: [child]);

  testWidgets('a queue shows the 96 px player bar', (tester) async {
    final rig = PlayerRig();
    final container = await tester.pumpApp(
      slot(const PlayerBarSlot()),
      size: TestSizes.expanded,
      overrides: rig.overrides,
    );
    expect(find.byKey(PlayerBarSlot.panelKey), findsNothing);

    // A play action reads the controller, as the Explore screen does.
    container.read(playbackControllerProvider);
    await rig.start(tester, play: false);

    expect(
      tester.getSize(find.byKey(PlayerBarSlot.panelKey)).height,
      PlayerBarSlot.height,
    );
    await rig.close(tester);
  });

  testWidgets('a queue shows the mini player', (tester) async {
    final rig = PlayerRig();
    final container = await tester.pumpApp(
      slot(const MiniPlayerSlot()),
      overrides: rig.overrides,
    );
    expect(tester.getSize(find.byKey(MiniPlayerSlot.slotKey)).height, 0);

    container.read(playbackControllerProvider);
    await rig.start(tester, play: false);

    expect(find.text('Song a'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(MiniPlayerSlot.slotKey)).height,
      greaterThan(0),
    );
    await rig.close(tester);
  });

  testWidgets('the slots do not create the controller', (tester) async {
    final rig = PlayerRig();
    await rig.start(tester, play: false);
    final container = await tester.pumpApp(
      slot(const Column(children: [MiniPlayerSlot(), PlayerBarSlot()])),
      size: TestSizes.expanded,
      overrides: rig.overrides,
    );
    await rig.settle(tester);

    expect(container.read(playbackControllerProvider.exists), isFalse);
    expect(find.byType(MiniPlayer), findsNothing);
    expect(find.byType(PlayerBar), findsNothing);
    await rig.close(tester);
  });
}
