// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/theme.dart';
import 'package:soundspan/app/theme/typography.dart';

typedef _Row = (
  String,
  TextStyle Function(SoundspanTypography),
  double,
  double,
  int,
);

// Doc 09, Typography: style, size, line height, weight.
final List<_Row> _table = [
  ('display', (t) => t.display, 36, 40, 700),
  ('headline', (t) => t.headline, 28, 34, 700),
  ('headlineCompact', (t) => t.headlineCompact, 24, 30, 700),
  ('title', (t) => t.title, 20, 26, 700),
  ('subtitle', (t) => t.subtitle, 16, 22, 600),
  ('body', (t) => t.body, 14, 20, 500),
  ('bodySmall', (t) => t.bodySmall, 13, 18, 400),
  ('caption', (t) => t.caption, 12, 16, 500),
  ('overline', (t) => t.overline, 11, 14, 700),
  ('mono', (t) => t.mono, 22, 28, 700),
];

final Map<String, ThemeData> _themes = {
  'dark': SoundspanTheme.dark,
  'light': SoundspanTheme.light,
  'darkHighContrast': SoundspanTheme.darkHighContrast,
  'lightHighContrast': SoundspanTheme.lightHighContrast,
};

List<TextStyle> _allStyles(SoundspanTypography t) => [
  for (final (_, read, _, _, _) in _table) read(t),
];

void main() {
  final typography = SoundspanTypography.standard();

  group('styles match doc 09', () {
    for (final (name, read, size, lineHeight, weight) in _table) {
      test(name, () {
        final style = read(typography);
        expect(style.fontSize, size);
        expect(style.height, closeTo(lineHeight / size, 1e-9));
        expect(style.fontWeight, FontWeight(weight));
        expect(style.fontVariations, [
          FontVariation('wght', weight.toDouble()),
        ]);
        expect(style.color, isNull);
      });
    }
  });

  test('all styles but mono use Montserrat', () {
    for (final (name, read, _, _, _) in _table) {
      final family = read(typography).fontFamily;
      if (name == 'mono') {
        expect(family, 'monospace');
      } else {
        expect(family, 'Montserrat', reason: name);
      }
    }
  });

  test('mono falls back to the platform monospace fonts', () {
    expect(typography.mono.fontFamilyFallback, [
      'Menlo',
      'Consolas',
      'Roboto Mono',
      'DejaVu Sans Mono',
    ]);
  });

  test('overline letter spacing is 0.08 em', () {
    final overline = typography.overline;
    expect(overline.letterSpacing, closeTo(0.08 * overline.fontSize!, 1e-9));
  });

  test('tabular adds tabular figures and keeps the other properties', () {
    final tabular = typography.caption.tabular;
    expect(tabular.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(
      tabular,
      typography.caption.copyWith(fontFeatures: tabular.fontFeatures),
    );
  });

  test('tabular keeps existing font features', () {
    const style = TextStyle(fontFeatures: [FontFeature.enable('smcp')]);
    expect(style.tabular.fontFeatures, [
      const FontFeature.enable('smcp'),
      const FontFeature.tabularFigures(),
    ]);
  });

  test('copyWith and lerp keep or replace styles', () {
    final replaced = typography.copyWith(body: typography.title);
    expect(replaced.body, typography.title);
    expect(replaced.caption, typography.caption);
    expect(typography.lerp(null, 0.5), typography);
    expect(typography.lerp(typography, 0.5).body, typography.body);
  });

  for (final MapEntry(key: name, value: theme) in _themes.entries) {
    group('$name theme', () {
      test('registers the typography extension', () {
        expect(theme.extension<SoundspanTypography>(), typography);
      });

      test('maps the TextTheme', () {
        final text = theme.textTheme;
        void same(TextStyle? actual, TextStyle expected, String role) {
          expect(actual?.fontSize, expected.fontSize, reason: role);
          expect(actual?.height, expected.height, reason: role);
          expect(actual?.fontWeight, expected.fontWeight, reason: role);
          expect(actual?.letterSpacing, expected.letterSpacing, reason: role);
          expect(actual?.fontFamily, expected.fontFamily, reason: role);
          expect(actual?.fontVariations, expected.fontVariations, reason: role);
        }

        same(text.displaySmall, typography.display, 'displaySmall');
        same(text.headlineMedium, typography.headline, 'headlineMedium');
        same(text.titleLarge, typography.title, 'titleLarge');
        same(text.titleMedium, typography.subtitle, 'titleMedium');
        same(text.bodyLarge, typography.body, 'bodyLarge');
        same(text.bodyMedium, typography.body, 'bodyMedium');
        same(text.bodySmall, typography.bodySmall, 'bodySmall');
        same(
          text.labelLarge,
          typography.body.copyWith(
            fontWeight: FontWeight.w600,
            fontVariations: const [FontVariation('wght', 600)],
          ),
          'labelLarge',
        );
        same(text.labelMedium, typography.caption, 'labelMedium');
        same(text.labelSmall, typography.overline, 'labelSmall');
      });

      test('never uses Turret Road', () {
        final text = theme.textTheme;
        final styles = [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
          ..._allStyles(theme.extension<SoundspanTypography>()!),
        ];
        for (final style in styles) {
          expect(style?.fontFamily, isNot('Turret Road'));
          expect(
            style?.fontFamilyFallback ?? const [],
            isNot(contains('Turret Road')),
          );
        }
      });
    });
  }

  testWidgets('context.typography reads the ambient extension', (tester) async {
    late SoundspanTypography read;
    await tester.pumpWidget(
      MaterialApp(
        theme: SoundspanTheme.dark,
        home: Builder(
          builder: (context) {
            read = context.typography;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, typography);
  });
}
