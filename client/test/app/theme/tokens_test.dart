// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';

// Doc 09 colour token table: token, dark, light (ARGB).
const _table = <(SoundspanColorToken, int, int)>[
  (SoundspanColorToken.ground, 0xFF000000, 0xFFF5F5F5),
  (SoundspanColorToken.surface, 0xFF0A0A0A, 0xFFFFFFFF),
  (SoundspanColorToken.surfaceRaised, 0xFF0F0F0F, 0xFFFAFAFA),
  (SoundspanColorToken.surfaceOverlay, 0xFF141414, 0xFFFFFFFF),
  (SoundspanColorToken.surfaceHover, 0xFF1A1A1A, 0xFFF0F0F0),
  (SoundspanColorToken.surfaceActive, 0xFF1C1C1C, 0xFFE8E8E8),
  (SoundspanColorToken.surfaceHighlight, 0xFF282828, 0xFFE5E5E5),
  (SoundspanColorToken.line, 0xFF262626, 0xFFE5E5E5),
  (SoundspanColorToken.lineStrong, 0xFF333333, 0xFFD4D4D4),
  (SoundspanColorToken.content, 0xFFFFFFFF, 0xFF0A0A0A),
  (SoundspanColorToken.contentBody, 0xFFE5E5E5, 0xFF262626),
  (SoundspanColorToken.contentSecondary, 0xFFA3A3A3, 0xFF525252),
  (SoundspanColorToken.contentMuted, 0xFF8A8A8A, 0xFF666666),
  (SoundspanColorToken.contentDisabled, 0xFF676767, 0xFF858585),
  (SoundspanColorToken.brand, 0xFF3B82F6, 0xFF2563EB),
  (SoundspanColorToken.accent, 0xFF60A5FA, 0xFF2563EB),
  (SoundspanColorToken.onAccent, 0xFF000000, 0xFFFFFFFF),
  (SoundspanColorToken.transport, 0xFFFFFFFF, 0xFF0A0A0A),
  (SoundspanColorToken.onTransport, 0xFF000000, 0xFFFFFFFF),
  (SoundspanColorToken.positive, 0xFF22C55E, 0xFF15803D),
  (SoundspanColorToken.warning, 0xFFF59E0B, 0xFFB45309),
  (SoundspanColorToken.danger, 0xFFEF4444, 0xFFB91C1C),
];

const Map<Brightness, Map<SoundspanColorToken, int>> _highContrast = {
  Brightness.dark: {
    SoundspanColorToken.line: 0xFF333333,
    SoundspanColorToken.lineStrong: 0xFF404040,
    SoundspanColorToken.contentSecondary: 0xFFE5E5E5,
  },
  Brightness.light: {
    SoundspanColorToken.line: 0xFFD4D4D4,
    SoundspanColorToken.lineStrong: 0xFFA3A3A3,
    SoundspanColorToken.contentSecondary: 0xFF262626,
  },
};

void main() {
  test('the table covers every token except scrim', () {
    expect({
      for (final row in _table) row.$1,
      SoundspanColorToken.scrim,
    }, SoundspanColorToken.values.toSet());
  });

  group('values equal doc 09', () {
    for (final (token, dark, light) in _table) {
      test('${token.name} dark', () {
        expect(SoundspanColors.dark[token], Color(dark));
      });
      test('${token.name} light', () {
        expect(SoundspanColors.light[token], Color(light));
      });
    }
  });

  test('contentDisabled uses the corrected greys', () {
    expect(SoundspanColors.dark.contentDisabled, const Color(0xFF676767));
    expect(SoundspanColors.light.contentDisabled, const Color(0xFF858585));
  });

  test('scrim is black at 60 % in dark and 40 % in light', () {
    final dark = SoundspanColors.dark.scrim;
    final light = SoundspanColors.light.scrim;
    expect(dark.withValues(alpha: 1), const Color(0xFF000000));
    expect(light.withValues(alpha: 1), const Color(0xFF000000));
    expect(dark.a, closeTo(0.6, 0.002));
    expect(light.a, closeTo(0.4, 0.002));
  });

  group('high contrast', () {
    final variants = {
      Brightness.dark: (SoundspanColors.dark, SoundspanColors.darkHighContrast),
      Brightness.light: (
        SoundspanColors.light,
        SoundspanColors.lightHighContrast,
      ),
    };
    for (final MapEntry(key: brightness, value: (normal, high))
        in variants.entries) {
      test(
        '${brightness.name}: line, lineStrong, contentSecondary step up',
        () {
          final overrides = _highContrast[brightness]!;
          for (final MapEntry(key: token, :value) in overrides.entries) {
            expect(high[token], Color(value), reason: token.name);
          }
        },
      );
      test('${brightness.name}: every other token is unchanged', () {
        final overrides = _highContrast[brightness]!;
        for (final token in SoundspanColorToken.values) {
          if (overrides.containsKey(token)) continue;
          expect(high[token], normal[token], reason: token.name);
        }
      });
    }
  });
}
