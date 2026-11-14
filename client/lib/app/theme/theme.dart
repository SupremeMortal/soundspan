// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/color_schemes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

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

  static const _pill = WidgetStatePropertyAll<OutlinedBorder>(Radii.pill);
  static const _pillButton = ButtonStyle(shape: _pill);
  static const _large = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(Radii.large)),
  );
  static const _small = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(Radii.small)),
  );

  static ThemeData _build(SoundspanColors colors, Brightness brightness) {
    final typography = SoundspanTypography.standard();
    return ThemeData(
      useMaterial3: true,
      colorScheme: soundspanColorScheme(colors, brightness),
      scaffoldBackgroundColor: colors.ground,
      fontFamily: SoundspanTypography.fontFamily,
      textTheme: typography.textTheme,
      filledButtonTheme: const FilledButtonThemeData(style: _pillButton),
      elevatedButtonTheme: const ElevatedButtonThemeData(style: _pillButton),
      outlinedButtonTheme: const OutlinedButtonThemeData(style: _pillButton),
      textButtonTheme: const TextButtonThemeData(style: _pillButton),
      chipTheme: const ChipThemeData(shape: Radii.pill),
      searchBarTheme: const SearchBarThemeData(shape: _pill),
      dialogTheme: const DialogThemeData(shape: _large),
      bottomSheetTheme: const BottomSheetThemeData(shape: _large),
      cardTheme: const CardThemeData(shape: _small),
      extensions: [colors, typography],
    );
  }
}
