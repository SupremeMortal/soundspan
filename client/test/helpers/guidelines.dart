// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/semantics.dart';
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
///
/// The text contrast check skips the semantics nodes of the widgets that
/// [contrastSamplingExempt] finds, and only those. It is for text whose
/// rendered colour is a token pair the contrast table allows but whose glyphs
/// are too thin for the guideline's sampler, which compares the most frequent
/// light and dark pixel: at 13 px and weight 400 on a device pixel ratio of
/// 1.0 no anti-aliased shade of a short line outnumbers the others, so the
/// sampled "text colour" is an edge shade (doc 11, Golden Tests). Each use
/// names the node and the theme it is exempt in.
Future<List<Evaluation>> failedGuidelines(
  WidgetTester tester, {
  List<Finder> contrastSamplingExempt = const [],
}) async {
  final handle = tester.ensureSemantics();
  try {
    await tester.pump();
    final guidelines = contrastSamplingExempt.isEmpty
        ? screenGuidelines
        : [
            for (final guideline in screenGuidelines)
              if (identical(guideline, textContrastGuideline))
                _ExemptingTextContrastGuideline({
                  for (final finder in contrastSamplingExempt)
                    for (final element in finder.evaluate())
                      tester
                          .getSemantics(
                            find.byElementPredicate(
                              (candidate) => identical(candidate, element),
                            ),
                          )
                          .getSemanticsData(),
                })
              else
                guideline,
          ];
    final failed = <Evaluation>[];
    for (final guideline in guidelines) {
      final evaluation = await guideline.evaluate(tester);
      if (!evaluation.passed) failed.add(evaluation);
    }
    return failed;
  } finally {
    handle.dispose();
  }
}

/// Expects the pumped tree to meet [screenGuidelines], with the text contrast
/// check skipping the nodes of [contrastSamplingExempt] (see
/// [failedGuidelines]).
Future<void> expectMeetsGuidelines(
  WidgetTester tester, {
  List<Finder> contrastSamplingExempt = const [],
}) async {
  final failed = await failedGuidelines(
    tester,
    contrastSamplingExempt: contrastSamplingExempt,
  );
  expect(
    failed,
    isEmpty,
    reason: failed.map((evaluation) => evaluation.reason).join('\n'),
  );
}

/// [textContrastGuideline], skipping the semantics nodes whose data is in
/// [exempt]. Semantics data compares by value (label, rectangle, transform,
/// flags), so a node is matched by its own position, not by its text alone.
class _ExemptingTextContrastGuideline extends MinimumTextContrastGuideline {
  new(this.exempt);

  final Set<SemanticsData> exempt;

  @override
  bool shouldSkipNode(SemanticsData data) =>
      super.shouldSkipNode(data) || exempt.contains(data);
}
