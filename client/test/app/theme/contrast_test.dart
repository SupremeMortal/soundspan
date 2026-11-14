// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/contrast.dart';
import 'package:soundspan/app/theme/extensions.dart';

void main() {
  group('contrastRatio', () {
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    const blue = Color(0xFF3B82F6);

    test('white on black is 21:1', () {
      expect(contrastRatio(white, black), closeTo(21, 1e-9));
    });

    test('a colour on itself is 1:1', () {
      expect(contrastRatio(blue, blue), closeTo(1, 1e-9));
    });

    test('is symmetric', () {
      expect(contrastRatio(blue, black), contrastRatio(black, blue));
    });
  });

  const variants = {
    'dark': SoundspanColors.dark,
    'light': SoundspanColors.light,
    'darkHighContrast': SoundspanColors.darkHighContrast,
    'lightHighContrast': SoundspanColors.lightHighContrast,
  };

  for (final MapEntry(key: name, value: colors) in variants.entries) {
    test('$name meets every required contrast pair', () {
      final failures = <String>[];
      for (final pair in requiredContrastPairs) {
        for (final background in pair.backgrounds) {
          final ratio = contrastRatio(
            colors[pair.foreground],
            colors[background],
          );
          if (ratio < pair.minimum) {
            failures.add(
              '$name: ${pair.foreground.name} on ${background.name} is '
              '${ratio.toStringAsFixed(2)}:1, needs ${pair.minimum}:1',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }
}
