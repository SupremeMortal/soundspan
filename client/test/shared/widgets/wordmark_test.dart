// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/brand.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/theme.dart';
import 'package:soundspan/shared/widgets/wordmark.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: SoundspanTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  test('the product name is lower case soundspan', () {
    expect(Brand.productName, 'soundspan');
  });

  testWidgets('renders soundspan in Turret Road ExtraBold content colour', (
    tester,
  ) async {
    await _pump(tester, const Wordmark());
    final text = tester.widget<Text>(find.text('soundspan'));
    expect(text.style?.fontFamily, 'Turret Road');
    expect(text.style?.fontWeight, FontWeight.w800);
    expect(text.style?.color, SoundspanColors.light.content);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('scales the text so its cap height matches the mark', (
    tester,
  ) async {
    await _pump(tester, const Wordmark(height: 40));
    final text = tester.widget<Text>(find.text('soundspan'));
    // Turret Road's cap height is 0.7 em.
    expect(text.style!.fontSize! * 0.7, closeTo(40, 1e-9));
    final mark = tester.getSize(find.byType(SvgPicture));
    expect(mark.height, 40);
  });

  testWidgets('showMark false renders no SVG', (tester) async {
    await _pump(tester, const Wordmark(showMark: false));
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.text('soundspan'), findsOneWidget);
  });

  testWidgets('exposes exactly one semantics node labelled soundspan', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const Wordmark());
    expect(find.bySemanticsLabel('soundspan'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('soundspan')), findsOneWidget);
    final node = tester.getSemantics(find.byType(Wordmark));
    expect(node.label, 'soundspan');
    expect(node.childrenCount, 0);
    handle.dispose();
  });
}
