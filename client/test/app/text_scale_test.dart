// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_root.dart';

void main() {
  /// The scale the app's screens apply to 10 logical pixels of text, with
  /// the operating system asking for [osScale].
  Future<double> scaledTen(WidgetTester tester, double osScale) async {
    tester.platformDispatcher.textScaleFactorTestValue = osScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpSoundspanApp();
    await tester.pumpAndSettle();
    final text = tester.element(find.byType(Text).first);
    return MediaQuery.textScalerOf(text).scale(10);
  }

  testWidgets('an operating-system text scale of 3.0 is clamped to 2.0', (
    tester,
  ) async {
    expect(await scaledTen(tester, 3), 20);
  });

  testWidgets('an operating-system text scale of 1.3 passes through', (
    tester,
  ) async {
    expect(await scaledTen(tester, 1.3), closeTo(13, 0.001));
  });
}
