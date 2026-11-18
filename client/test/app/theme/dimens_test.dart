// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/theme.dart';

Future<Duration> _motionOf(
  WidgetTester tester, {
  required bool disableAnimations,
  required Duration duration,
}) async {
  late Duration result;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Builder(
        builder: (context) {
          result = Motion.of(context, duration);
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  test('spacing scale and gutters match doc 09', () {
    expect(
      [
        Spacing.x4,
        Spacing.x8,
        Spacing.x12,
        Spacing.x16,
        Spacing.x24,
        Spacing.x32,
        Spacing.x48,
      ],
      [4, 8, 12, 16, 24, 32, 48],
    );
    expect([Gutters.compact, Gutters.medium, Gutters.expanded], [16, 24, 32]);
  });

  test('radii match doc 09', () {
    expect(Radii.small, 6);
    expect(Radii.large, 12);
    expect(Radii.pill, const StadiumBorder());
  });

  test('sizes match doc 09', () {
    expect(Sizes.touchTarget, 48);
    expect(Sizes.pointerTarget, 32);
    expect(Sizes.pointerTargetSpacing, 4);
    expect(Sizes.trackRow, 56);
    expect(Sizes.albumTrackRow, 48);
  });

  test('motion durations and curve match doc 09', () {
    expect(Motion.standard, const Duration(milliseconds: 150));
    expect(Motion.emphasized, const Duration(milliseconds: 250));
    expect(Motion.curve, Curves.easeOutCubic);
  });

  testWidgets('Motion.of returns zero when animations are disabled', (
    tester,
  ) async {
    expect(
      await _motionOf(
        tester,
        disableAnimations: true,
        duration: Motion.emphasized,
      ),
      Duration.zero,
    );
  });

  testWidgets('Motion.of returns the duration otherwise', (tester) async {
    expect(
      await _motionOf(
        tester,
        disableAnimations: false,
        duration: Motion.emphasized,
      ),
      Motion.emphasized,
    );
  });

  test('raised shadow is 0 2 12 at 8 % black', () {
    const shadow = SoundspanShadows.raised;
    expect(shadow.offset, const Offset(0, 2));
    expect(shadow.blurRadius, 12);
    expect(shadow.spreadRadius, 0);
    expect(shadow.color.r, 0);
    expect(shadow.color.g, 0);
    expect(shadow.color.b, 0);
    expect(shadow.color.a, closeTo(0.08, 0.005));
  });

  final themes = {
    'dark': SoundspanTheme.dark,
    'light': SoundspanTheme.light,
    'darkHighContrast': SoundspanTheme.darkHighContrast,
    'lightHighContrast': SoundspanTheme.lightHighContrast,
  };
  for (final MapEntry(key: name, value: theme) in themes.entries) {
    test('$name theme applies the shapes', () {
      const pill = StadiumBorder();
      const large = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Radii.large)),
      );
      const small = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Radii.small)),
      );
      final states = <WidgetState>{};
      expect(theme.filledButtonTheme.style?.shape?.resolve(states), pill);
      expect(theme.elevatedButtonTheme.style?.shape?.resolve(states), pill);
      expect(theme.outlinedButtonTheme.style?.shape?.resolve(states), pill);
      expect(theme.textButtonTheme.style?.shape?.resolve(states), pill);
      expect(theme.chipTheme.shape, pill);
      expect(theme.searchBarTheme.shape?.resolve(states), pill);
      expect(theme.dialogTheme.shape, large);
      expect(theme.bottomSheetTheme.shape, large);
      expect(theme.cardTheme.shape, small);
    });
  }
}
