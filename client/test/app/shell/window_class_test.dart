// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/shell/window_class.dart';

void main() {
  test('widths map to the window classes of doc 02', () {
    expect(windowClassOf(const Size(599, 800)), WindowClass.compact);
    expect(windowClassOf(const Size(600, 800)), WindowClass.medium);
    expect(windowClassOf(const Size(1023, 800)), WindowClass.medium);
    expect(windowClassOf(const Size(1024, 800)), WindowClass.expanded);
  });

  testWidgets('WindowClass.of throws outside a scope', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    expect(() => WindowClass.of(context), throwsFlutterError);
  });
}
