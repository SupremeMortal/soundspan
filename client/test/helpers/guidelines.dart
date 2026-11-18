// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The guidelines every screen meets: tap-target size, tap-target labels and
/// text contrast.
const List<AccessibilityGuideline> screenGuidelines = [
  androidTapTargetGuideline,
  labeledTapTargetGuideline,
  textContrastGuideline,
];

/// Evaluates [screenGuidelines] on the pumped tree, with semantics turned on
/// for the duration of the check, and returns the failed evaluations. The
/// guidelines in [skip] are not evaluated.
///
/// With [skipTextAtClipEdge], the text contrast check also skips the nodes
/// of [textAtClipEdge]: text at the edge of a viewport or panel (see there).
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
  Set<AccessibilityGuideline> skip = const {},
  bool skipTextAtClipEdge = false,
}) async {
  final handle = tester.ensureSemantics();
  try {
    await tester.pump();
    final exempt = {
      for (final finder in contrastSamplingExempt)
        for (final element in finder.evaluate())
          tester
              .getSemantics(
                find.byElementPredicate(
                  (candidate) => identical(candidate, element),
                ),
              )
              .getSemanticsData(),
      if (skipTextAtClipEdge) ...textAtClipEdge(tester),
    };
    final guidelines = exempt.isEmpty
        ? screenGuidelines
        : [
            for (final guideline in screenGuidelines)
              if (identical(guideline, textContrastGuideline))
                _ExemptingTextContrastGuideline(exempt)
              else
                guideline,
          ];
    final failed = <Evaluation>[];
    for (final (index, guideline) in guidelines.indexed) {
      if (skip.contains(screenGuidelines[index])) continue;
      final evaluation = await guideline.evaluate(tester);
      if (!evaluation.passed) failed.add(evaluation);
    }
    return failed;
  } finally {
    handle.dispose();
  }
}

/// The semantics nodes of the text whose contrast sample reaches past the
/// paint clip around it: text at the edge of a scrolling viewport or of a
/// clipped panel, such as a header flush with the bottom of the content
/// panel.
///
/// The text contrast guideline samples the text's box and 4 px around it,
/// so at a clip edge it reads the colours outside the clip (the window's
/// `ground` below a panel, or whatever covers a viewport's edge) instead of
/// the text's own background. What shows of such text is the same token
/// pair as when it is scrolled away from the edge, where it is checked.
Set<SemanticsData> textAtClipEdge(WidgetTester tester) => {
  for (final element
      in find
          .byWidgetPredicate(
            (widget) => widget is Text || widget is EditableText,
          )
          .evaluate())
    ?_nodeIfSampleCrossesClip(element)?.getSemanticsData(),
};

/// The 4 px the contrast guideline samples around a text's box.
const double _contrastSampleMargin = 4;

SemanticsNode? _nodeIfSampleCrossesClip(Element element) {
  final box = element.renderObject;
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  // The node the text belongs to: the nearest one at or above its box.
  RenderObject? owner = box;
  while (owner != null && owner.debugSemantics == null) {
    owner = owner.parent;
  }
  final node = owner?.debugSemantics;
  final clip = node?.parentPaintClipRect;
  if (node == null || clip == null) return null;
  // The clip is in the node's coordinates, as its rectangle is.
  var clipRect = clip;
  for (
    SemanticsNode? current = node;
    current != null;
    current = current.parent
  ) {
    final transform = current.transform;
    if (transform != null) {
      clipRect = MatrixUtils.transformRect(transform, clipRect);
    }
  }
  final sample = MatrixUtils.transformRect(
    box.getTransformTo(null),
    box.paintBounds,
  ).inflate(_contrastSampleMargin);
  final inside = clipRect.inflate(0.5);
  if (inside.contains(sample.topLeft) && inside.contains(sample.bottomRight)) {
    return null;
  }
  // A node merged into its parent is checked as that parent.
  var checked = node;
  while (checked.isMergedIntoParent && checked.parent != null) {
    checked = checked.parent!;
  }
  return checked;
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
/// `exempt`. A node is matched by its label, rectangle and transform, not
/// by `SemanticsData` equality: the data of a node a sliver tags never
/// equals itself, since its tag set compares by identity.
class _ExemptingTextContrastGuideline extends MinimumTextContrastGuideline {
  new(Set<SemanticsData> exempt)
    : _exempt = {for (final data in exempt) _key(data)};

  final Set<(String, Rect, String?)> _exempt;

  static (String, Rect, String?) _key(SemanticsData data) =>
      (data.label, data.rect, data.transform?.storage.join(','));

  @override
  bool shouldSkipNode(SemanticsData data) =>
      super.shouldSkipNode(data) || _exempt.contains(_key(data));
}
