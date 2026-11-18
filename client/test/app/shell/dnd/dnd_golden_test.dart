// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/golden.dart';
import '../../../helpers/pump_app.dart';
import '../shortcuts/selection_harness.dart';
import 'dnd_harness.dart';

void main() {
  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    String name(String what) =>
        goldenFileName('dnd_$what', size: TestSizes.expanded, theme: theme);

    testWidgets(name('sidebar'), tags: ['golden'], (tester) async {
      final rig = await DndRig.pump(tester, theme: theme);
      final gesture = await startDrag(tester, rowOf('Song 1.1'));
      await hover(tester, gesture, tester.getCenter(sidebarRow(ownedPlaylist)));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath(name('sidebar'))),
      );
      await gesture.up();
      await rig.play.settle(tester);
      await rig.close(tester);
    });

    testWidgets(name('queue'), tags: ['golden'], (tester) async {
      final rig = await DndRig.pump(tester, theme: theme);
      final gesture = await startDrag(tester, rowOf('Song 1.1'));
      await hover(tester, gesture, belowQueueRow(tester, 'b'));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath(name('queue'))),
      );
      await gesture.up();
      await rig.play.settle(tester);
      await rig.close(tester);
    });
  }
}
