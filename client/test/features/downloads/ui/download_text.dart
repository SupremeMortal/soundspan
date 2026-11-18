// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Every string rendered by a [Text] widget on screen.
List<String> renderedTexts(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];

/// Fails when any rendered text names a source: "TIDAL", "YouTube",
/// "provider" or "source", in any letter case.
void expectNoSourceWords(WidgetTester tester) {
  final forbidden = RegExp(
    'tidal|youtube|provider|source',
    caseSensitive: false,
  );
  final texts = renderedTexts(tester);
  expect(texts, isNotEmpty);
  for (final text in texts) {
    expect(forbidden.hasMatch(text), isFalse, reason: text);
  }
}
