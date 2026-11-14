// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/color_schemes.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The soundspan [ThemeData] variants.
///
/// Meant for `MaterialApp.theme`, `darkTheme`, `highContrastTheme` and
/// `highContrastDarkTheme`, so the platform's brightness and high-contrast
/// settings select the variant without extra code.
abstract final class SoundspanTheme {
  /// The dark theme.
  static final ThemeData dark = _build(SoundspanColors.dark, Brightness.dark);

  /// The light theme.
  static final ThemeData light = _build(
    SoundspanColors.light,
    Brightness.light,
  );

  /// The dark theme under a platform high-contrast request.
  static final ThemeData darkHighContrast = _build(
    SoundspanColors.darkHighContrast,
    Brightness.dark,
  );

  /// The light theme under a platform high-contrast request.
  static final ThemeData lightHighContrast = _build(
    SoundspanColors.lightHighContrast,
    Brightness.light,
  );

  static ThemeData _build(SoundspanColors colors, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: soundspanColorScheme(colors, brightness),
      scaffoldBackgroundColor: colors.ground,
      extensions: [colors],
    );
  }
}
