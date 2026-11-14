// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'guidelines.dart';
import 'pump_app.dart';

Widget _button({required double size, String? label}) {
  return Center(
    child: Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {},
        child: SizedBox.square(dimension: size),
      ),
    ),
  );
}

void main() {
  testWidgets('a labelled 48 x 48 button meets the guidelines', (tester) async {
    await tester.pumpApp(_button(size: 48, label: 'Play'));
    expect(await failedGuidelines(tester), isEmpty);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('an unlabelled 20 x 20 button fails the guidelines', (
    tester,
  ) async {
    await tester.pumpApp(_button(size: 20));
    final failed = await failedGuidelines(tester);
    final reasons = failed.map((evaluation) => evaluation.reason).join();
    expect(failed, hasLength(2));
    expect(reasons, contains('expected tap target size of at least'));
    expect(reasons, contains('label'));
  });
}
