// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The WCAG 2.x contrast ratio between [foreground] and [background], from
/// 1.0 (identical luminance) to 21.0 (black on white).
///
/// Alpha is ignored; both colours are treated as opaque. The result is
/// symmetric in its arguments.
double contrastRatio(Color foreground, Color background) {
  final a = _relativeLuminance(foreground);
  final b = _relativeLuminance(background);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// A text token and the surfaces it is allowed on, with the minimum contrast
/// it must reach on each of them.
@immutable
class ContrastPair {
  /// Creates a pair of [foreground] on each of [backgrounds].
  const new(this.foreground, this.backgrounds, this.minimum);

  /// The text or icon token.
  final SoundspanColorToken foreground;

  /// The surface tokens [foreground] may be drawn on.
  final List<SoundspanColorToken> backgrounds;

  /// The lowest acceptable [contrastRatio].
  final double minimum;
}

const List<SoundspanColorToken> _surfaces = [
  SoundspanColorToken.ground,
  SoundspanColorToken.surface,
  SoundspanColorToken.surfaceRaised,
  SoundspanColorToken.surfaceOverlay,
  SoundspanColorToken.surfaceHover,
  SoundspanColorToken.surfaceActive,
  SoundspanColorToken.surfaceHighlight,
];

const List<SoundspanColorToken> _surfacesWithoutHighlight = [
  SoundspanColorToken.ground,
  SoundspanColorToken.surface,
  SoundspanColorToken.surfaceRaised,
  SoundspanColorToken.surfaceOverlay,
  SoundspanColorToken.surfaceHover,
  SoundspanColorToken.surfaceActive,
];

const List<SoundspanColorToken> _baseSurfaces = [
  SoundspanColorToken.ground,
  SoundspanColorToken.surface,
  SoundspanColorToken.surfaceRaised,
  SoundspanColorToken.surfaceOverlay,
];

/// The allowed text-on-surface pairs of doc 09 with their minimum ratios.
///
/// Every theme variant must meet each of them; a test enforces it.
const List<ContrastPair> requiredContrastPairs = [
  ContrastPair(SoundspanColorToken.content, _surfaces, 4.5),
  ContrastPair(SoundspanColorToken.contentBody, _surfaces, 4.5),
  ContrastPair(SoundspanColorToken.contentSecondary, _surfaces, 4.5),
  ContrastPair(
    SoundspanColorToken.contentMuted,
    _surfacesWithoutHighlight,
    4.5,
  ),
  ContrastPair(
    SoundspanColorToken.contentDisabled,
    _surfacesWithoutHighlight,
    3,
  ),
  ContrastPair(SoundspanColorToken.brand, _baseSurfaces, 4.5),
  ContrastPair(SoundspanColorToken.positive, _baseSurfaces, 4.5),
  ContrastPair(SoundspanColorToken.warning, _baseSurfaces, 4.5),
  ContrastPair(SoundspanColorToken.danger, _baseSurfaces, 4.5),
  ContrastPair(SoundspanColorToken.onAccent, [SoundspanColorToken.accent], 4.5),
  ContrastPair(SoundspanColorToken.onTransport, [
    SoundspanColorToken.transport,
  ], 4.5),
];
