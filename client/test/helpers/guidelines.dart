// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';

/// The guidelines every screen meets: tap-target size, tap-target labels and
/// text contrast.
const List<AccessibilityGuideline> screenGuidelines = [
  androidTapTargetGuideline,
  labeledTapTargetGuideline,
  textContrastGuideline,
];

/// Evaluates [screenGuidelines] on the pumped tree, with semantics turned on
/// for the duration of the check, and returns the failed evaluations.
Future<List<Evaluation>> failedGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  try {
    await tester.pump();
    final failed = <Evaluation>[];
    for (final guideline in screenGuidelines) {
      final evaluation = await guideline.evaluate(tester);
      if (!evaluation.passed) failed.add(evaluation);
    }
    return failed;
  } finally {
    handle.dispose();
  }
}

/// Expects the pumped tree to meet [screenGuidelines].
Future<void> expectMeetsGuidelines(WidgetTester tester) async {
  final failed = await failedGuidelines(tester);
  expect(
    failed,
    isEmpty,
    reason: failed.map((evaluation) => evaluation.reason).join('\n'),
  );
}
