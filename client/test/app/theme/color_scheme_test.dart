// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/color_schemes.dart';
import 'package:soundspan/app/theme/extensions.dart';

void main() {
  const variants = {
    Brightness.dark: SoundspanColors.dark,
    Brightness.light: SoundspanColors.light,
  };

  for (final MapEntry(key: brightness, value: c) in variants.entries) {
    group('${brightness.name} ColorScheme', () {
      final scheme = soundspanColorScheme(c, brightness);
      final rows = <String, (Color, Color)>{
        'primary = accent': (scheme.primary, c.accent),
        'onPrimary = onAccent': (scheme.onPrimary, c.onAccent),
        'secondary = brand': (scheme.secondary, c.brand),
        'surface = surface': (scheme.surface, c.surface),
        'onSurface = contentBody': (scheme.onSurface, c.contentBody),
        'surfaceContainer = surfaceRaised': (
          scheme.surfaceContainer,
          c.surfaceRaised,
        ),
        'surfaceContainerHigh = surfaceOverlay': (
          scheme.surfaceContainerHigh,
          c.surfaceOverlay,
        ),
        'outline = lineStrong': (scheme.outline, c.lineStrong),
        'outlineVariant = line': (scheme.outlineVariant, c.line),
        'error = danger': (scheme.error, c.danger),
        'onSecondary = onAccent': (scheme.onSecondary, c.onAccent),
        'scrim = scrim': (scheme.scrim, c.scrim),
        'surfaceContainerLow = surface': (
          scheme.surfaceContainerLow,
          c.surface,
        ),
        'surfaceContainerLowest = ground': (
          scheme.surfaceContainerLowest,
          c.ground,
        ),
        'surfaceContainerHighest = surfaceHover': (
          scheme.surfaceContainerHighest,
          c.surfaceHover,
        ),
      };
      for (final MapEntry(key: row, value: (actual, expected))
          in rows.entries) {
        test(row, () => expect(actual, expected));
      }

      test('brightness matches', () {
        expect(scheme.brightness, brightness);
      });
    });
  }

  test('onError is black in dark and white in light', () {
    expect(
      soundspanColorScheme(SoundspanColors.dark, Brightness.dark).onError,
      const Color(0xFF000000),
    );
    expect(
      soundspanColorScheme(SoundspanColors.light, Brightness.light).onError,
      const Color(0xFFFFFFFF),
    );
  });

  group('SoundspanColors.lerp', () {
    test('returns the end points at 0 and 1', () {
      const a = SoundspanColors.dark;
      const b = SoundspanColors.light;
      for (final token in SoundspanColorToken.values) {
        expect(a.lerp(b, 0)[token], a[token], reason: token.name);
        expect(a.lerp(b, 1)[token], b[token], reason: token.name);
      }
    });

    test('with no other returns itself', () {
      expect(SoundspanColors.dark.lerp(null, 0.5), SoundspanColors.dark);
    });
  });

  test('copyWith replaces only the named token', () {
    const red = Color(0xFFFF0000);
    final copy = SoundspanColors.dark.copyWith(accent: red);
    for (final token in SoundspanColorToken.values) {
      expect(
        copy[token],
        token == SoundspanColorToken.accent ? red : SoundspanColors.dark[token],
        reason: token.name,
      );
    }
  });
}
