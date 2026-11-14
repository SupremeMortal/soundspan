// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/shell/player_slots.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

void main() {
  testWidgets('96 px panel at 1440', (tester) async {
    await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    expect(tester.getSize(find.byKey(PlayerBarSlot.panelKey)).height, 96);
    expect(find.byKey(MiniPlayerSlot.slotKey), findsNothing);
    await expectMeetsGuidelines(tester);
  });

  for (final size in [TestSizes.compact, TestSizes.medium]) {
    testWidgets('zero-height slot at ${size.width.toInt()}', (tester) async {
      await tester.pumpSoundspanApp(stored: StoredProfile.signedIn, size: size);
      expect(tester.getSize(find.byKey(MiniPlayerSlot.slotKey)).height, 0);
      expect(find.byKey(PlayerBarSlot.panelKey), findsNothing);
      await expectMeetsGuidelines(tester);
    });
  }
}
