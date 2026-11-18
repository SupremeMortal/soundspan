// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';

/// The soundspan type styles (doc 09, Typography) as a theme extension.
///
/// Styles carry no colour; colour comes from the theme or the widget. Every
/// style but [mono] uses the bundled Montserrat variable font and sets both
/// `fontWeight` and the matching `wght` font variation.
@immutable
class SoundspanTypography extends ThemeExtension<SoundspanTypography> {
  /// Creates a style set; every style is required.
  const new({
    required this.display,
    required this.headline,
    required this.headlineCompact,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.bodySmall,
    required this.caption,
    required this.overline,
    required this.mono,
  });

  /// The styles of doc 09's table.
  factory standard() => _standard;

  static final SoundspanTypography _standard = SoundspanTypography(
    display: _montserrat(36, 40, 700),
    headline: _montserrat(28, 34, 700),
    headlineCompact: _montserrat(24, 30, 700),
    title: _montserrat(20, 26, 700),
    subtitle: _montserrat(16, 22, 600),
    body: _montserrat(14, 20, 500),
    bodySmall: _montserrat(13, 18, 400),
    caption: _montserrat(12, 16, 500),
    overline: _montserrat(11, 14, 700).copyWith(letterSpacing: 0.08 * 11),
    mono: _weighted(
      const TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: [
          'Menlo',
          'Consolas',
          'Roboto Mono',
          'DejaVu Sans Mono',
        ],
        fontSize: 22,
        height: 28 / 22,
      ),
      700,
    ),
  );

  /// The family of every style but [mono].
  static const String fontFamily = 'Montserrat';

  static TextStyle _montserrat(double size, double lineHeight, int weight) {
    return _weighted(
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: lineHeight / size,
      ),
      weight,
    );
  }

  static TextStyle _weighted(TextStyle style, int weight) {
    return style.copyWith(
      fontWeight: FontWeight(weight),
      fontVariations: [FontVariation('wght', weight.toDouble())],
    );
  }

  /// Detail-page titles on expanded windows (36 / 40, 700).
  final TextStyle display;

  /// Page titles (28 / 34, 700).
  final TextStyle headline;

  /// Detail titles on compact windows (24 / 30, 700).
  final TextStyle headlineCompact;

  /// Section headers and the now-playing track title (20 / 26, 700).
  final TextStyle title;

  /// Dialog titles and list group headers (16 / 22, 600).
  final TextStyle subtitle;

  /// Row titles and body text (14 / 20, 500).
  final TextStyle body;

  /// Row subtitles and descriptions (13 / 18, 400).
  final TextStyle bodySmall;

  /// Metadata, timestamps and badges (12 / 16, 500).
  final TextStyle caption;

  /// Column headers and labels such as "NOW PLAYING" (11 / 14, 700,
  /// +0.08 em). The widget that uses it upper-cases the text.
  final TextStyle overline;

  /// Device-link code cells in the platform monospace font (22 / 28, 700).
  final TextStyle mono;

  /// The Material [TextTheme] built from these styles.
  ///
  /// The mapping is recorded in doc 09 (Typography).
  TextTheme get textTheme => TextTheme(
    displaySmall: display,
    headlineMedium: headline,
    titleLarge: title,
    titleMedium: subtitle,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: _weighted(body, 600),
    labelMedium: caption,
    labelSmall: overline,
  );

  @override
  SoundspanTypography copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? headlineCompact,
    TextStyle? title,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? caption,
    TextStyle? overline,
    TextStyle? mono,
  }) {
    return SoundspanTypography(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      headlineCompact: headlineCompact ?? this.headlineCompact,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      bodySmall: bodySmall ?? this.bodySmall,
      caption: caption ?? this.caption,
      overline: overline ?? this.overline,
      mono: mono ?? this.mono,
    );
  }

  @override
  SoundspanTypography lerp(SoundspanTypography? other, double t) {
    if (other == null) return this;
    return SoundspanTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      headlineCompact: TextStyle.lerp(
        headlineCompact,
        other.headlineCompact,
        t,
      )!,
      title: TextStyle.lerp(title, other.title, t)!,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
    );
  }
}

/// Access to the [SoundspanTypography] of the ambient theme.
extension SoundspanTypographyContext on BuildContext {
  /// The type styles registered on the ambient [Theme].
  SoundspanTypography get typography =>
      Theme.of(this).extension<SoundspanTypography>()!;
}

/// Tabular figures for times and counts.
extension TabularFigures on TextStyle {
  /// This style with the tabular-figures font feature added.
  TextStyle get tabular => copyWith(
    fontFeatures: [...?fontFeatures, const FontFeature.tabularFigures()],
  );
}
