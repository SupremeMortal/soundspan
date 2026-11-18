// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'golden.dart';
import 'pump_app.dart';

void main() {
  group('goldenFileName', () {
    test('names width and theme', () {
      expect(
        goldenFileName('row', size: TestSizes.compact, theme: ThemeMode.dark),
        'row.390.dark',
      );
      expect(
        goldenFileName(
          'row',
          size: TestSizes.expanded,
          theme: ThemeMode.light,
          highContrast: true,
        ),
        'row.1440.light-hc',
      );
    });

    test('adds a scale other than 1 and a locale other than en', () {
      expect(
        goldenFileName(
          'row',
          size: TestSizes.medium,
          theme: ThemeMode.dark,
          textScale: 2,
          locale: const Locale('de'),
        ),
        'row.800.dark.x2.de',
      );
      expect(
        goldenFileName(
          'row',
          size: TestSizes.medium,
          theme: ThemeMode.dark,
          textScale: 1.5,
        ),
        'row.800.dark.x1.5',
      );
    });
  });

  group('the golden configuration', () {
    // Alchemist reads its configuration where tests are declared.
    final config = AlchemistConfig.current();

    test('stores one image set beside the test, without the CI variant', () {
      expect(config.ciGoldensConfig.enabled, isFalse);
      expect(config.platformGoldensConfig.obscureText, isFalse);
      expect(config.platformGoldensConfig.platforms, {HostPlatform.linux});
      expect(
        config.platformGoldensConfig.filePathResolver('tokens.800.dark', 'x'),
        'goldens/tokens.800.dark.png',
      );
    });

    test('compares goldens only on Linux', () {
      expect(
        goldenFileComparator is SkippingGoldenComparator,
        !Platform.isLinux,
      );
    });

    test('the skipping comparator passes and writes nothing', () async {
      final comparator = SkippingGoldenComparator();
      final golden = Uri.parse('goldens/never.png');
      expect(await comparator.compare(Uint8List(0), golden), isTrue);
      await comparator.update(golden, Uint8List(0));
      expect(File('goldens/never.png').existsSync(), isFalse);
    });
  });
}
