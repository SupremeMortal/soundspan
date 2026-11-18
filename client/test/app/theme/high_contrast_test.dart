// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/app.dart' show themeModeSettingProvider;
import 'package:soundspan/app/theme/contrast.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';

import '../../helpers/test_root.dart';

void main() {
  /// The colours the app's screens use with the operating system asking for
  /// [highContrast], in theme [mode].
  Future<SoundspanColors> colorsOf(
    WidgetTester tester, {
    required ThemeModeSetting mode,
    required bool highContrast,
  }) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(highContrast: highContrast);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpSoundspanApp(
      overrides: [themeModeSettingProvider.overrideWithValue(AsyncData(mode))],
    );
    await tester.pumpAndSettle();
    return tester.element(find.byType(Text).first).colors;
  }

  const cases = {
    ThemeModeSetting.dark: (
      normal: SoundspanColors.dark,
      high: SoundspanColors.darkHighContrast,
    ),
    ThemeModeSetting.light: (
      normal: SoundspanColors.light,
      high: SoundspanColors.lightHighContrast,
    ),
  };

  for (final MapEntry(key: mode, value: (:normal, :high)) in cases.entries) {
    testWidgets('the platform flag selects the ${mode.name} high-contrast '
        'variant', (tester) async {
      expect(
        await colorsOf(tester, mode: mode, highContrast: true),
        same(high),
      );
    });

    testWidgets('without the flag ${mode.name} stays normal', (tester) async {
      expect(
        await colorsOf(tester, mode: mode, highContrast: false),
        same(normal),
      );
    });

    test('the ${mode.name} variant steps the lines and the secondary text '
        'only', () {
      expect(high.line, normal.lineStrong);
      expect(high.contentSecondary, normal.contentBody);
      expect(
        contrastRatio(high.lineStrong, high.surface),
        greaterThan(contrastRatio(normal.lineStrong, normal.surface)),
      );
      for (final token in SoundspanColorToken.values) {
        if (const {
          SoundspanColorToken.line,
          SoundspanColorToken.lineStrong,
          SoundspanColorToken.contentSecondary,
        }.contains(token)) {
          continue;
        }
        expect(high[token], normal[token], reason: token.name);
      }
    });

    test('every allowed text-on-surface pair of the ${mode.name} variant '
        'meets its ratio', () {
      for (final pair in requiredContrastPairs) {
        for (final background in pair.backgrounds) {
          expect(
            contrastRatio(high[pair.foreground], high[background]),
            greaterThanOrEqualTo(pair.minimum),
            reason: '${pair.foreground.name} on ${background.name}',
          );
        }
      }
    });
  }
}
