// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final font in [
    'assets/fonts/Montserrat-VariableFont_wght.ttf',
    'assets/fonts/TurretRoad-ExtraBold.ttf',
  ]) {
    test('$font loads', () async {
      final data = await rootBundle.load(font);
      expect(data.lengthInBytes, greaterThan(0));
    });
  }

  for (final licence in [
    'assets/licenses/fonts/Montserrat.txt',
    'assets/licenses/fonts/TurretRoad.txt',
  ]) {
    test('$licence is an SIL Open Font License text', () async {
      final text = await rootBundle.loadString(licence);
      expect(text, isNotEmpty);
      expect(text, contains('SIL Open Font License'));
    });
  }

  for (final n in [16, 22, 24, 32]) {
    for (final variant in ['light', 'dark']) {
      final icon = 'assets/brand/tray/tray_${variant}_$n.png';
      test('$icon is bundled', () async {
        final data = await rootBundle.load(icon);
        expect(data.lengthInBytes, greaterThan(0));
      });
    }
  }
}
