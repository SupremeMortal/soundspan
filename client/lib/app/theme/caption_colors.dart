// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/tokens.dart';

/// The colours of the window caption buttons the app draws in its top bar
/// (doc 09, Top Bar), as a theme extension.
///
/// Widgets read them as `context.captionColors.fill`.
@immutable
class CaptionColors extends ThemeExtension<CaptionColors> {
  /// Creates a set; every colour is required.
  const new({
    required this.fill,
    required this.hover,
    required this.pressed,
    required this.close,
    required this.closePressed,
    required this.onClose,
    required this.rectHover,
    required this.rectPressed,
    required this.rectClose,
    required this.rectClosePressed,
  });

  /// The dark theme's set.
  static const CaptionColors dark = CaptionColors(
    fill: DarkCaptionTokens.fill,
    hover: DarkCaptionTokens.hover,
    pressed: DarkCaptionTokens.pressed,
    close: DarkCaptionTokens.close,
    closePressed: DarkCaptionTokens.closePressed,
    onClose: DarkCaptionTokens.onClose,
    rectHover: DarkCaptionTokens.rectHover,
    rectPressed: DarkCaptionTokens.rectPressed,
    rectClose: DarkCaptionTokens.rectClose,
    rectClosePressed: DarkCaptionTokens.rectClosePressed,
  );

  /// The light theme's set.
  static const CaptionColors light = CaptionColors(
    fill: LightCaptionTokens.fill,
    hover: LightCaptionTokens.hover,
    pressed: LightCaptionTokens.pressed,
    close: LightCaptionTokens.close,
    closePressed: LightCaptionTokens.closePressed,
    onClose: LightCaptionTokens.onClose,
    rectHover: LightCaptionTokens.rectHover,
    rectPressed: LightCaptionTokens.rectPressed,
    rectClose: LightCaptionTokens.rectClose,
    rectClosePressed: LightCaptionTokens.rectClosePressed,
  );

  /// Linux circle at rest.
  final Color fill;

  /// Linux circle under the pointer.
  final Color hover;

  /// Linux circle while pressed.
  final Color pressed;

  /// Linux close circle under the pointer.
  final Color close;

  /// Linux close circle while pressed.
  final Color closePressed;

  /// The glyph on a red close button.
  final Color onClose;

  /// Windows button under the pointer.
  final Color rectHover;

  /// Windows button while pressed.
  final Color rectPressed;

  /// Windows close button under the pointer.
  final Color rectClose;

  /// Windows close button while pressed.
  final Color rectClosePressed;

  @override
  CaptionColors copyWith({
    Color? fill,
    Color? hover,
    Color? pressed,
    Color? close,
    Color? closePressed,
    Color? onClose,
    Color? rectHover,
    Color? rectPressed,
    Color? rectClose,
    Color? rectClosePressed,
  }) => CaptionColors(
    fill: fill ?? this.fill,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    close: close ?? this.close,
    closePressed: closePressed ?? this.closePressed,
    onClose: onClose ?? this.onClose,
    rectHover: rectHover ?? this.rectHover,
    rectPressed: rectPressed ?? this.rectPressed,
    rectClose: rectClose ?? this.rectClose,
    rectClosePressed: rectClosePressed ?? this.rectClosePressed,
  );

  @override
  CaptionColors lerp(CaptionColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return CaptionColors(
      fill: mix(fill, other.fill),
      hover: mix(hover, other.hover),
      pressed: mix(pressed, other.pressed),
      close: mix(close, other.close),
      closePressed: mix(closePressed, other.closePressed),
      onClose: mix(onClose, other.onClose),
      rectHover: mix(rectHover, other.rectHover),
      rectPressed: mix(rectPressed, other.rectPressed),
      rectClose: mix(rectClose, other.rectClose),
      rectClosePressed: mix(rectClosePressed, other.rectClosePressed),
    );
  }
}

/// Reads [CaptionColors] from the theme.
extension CaptionColorsContext on BuildContext {
  /// The caption button colours of the current theme.
  CaptionColors get captionColors =>
      Theme.of(this).extension<CaptionColors>() ?? CaptionColors.dark;
}
