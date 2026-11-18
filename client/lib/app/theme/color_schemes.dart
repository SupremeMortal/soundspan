// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The Material [ColorScheme] for the token set [c], so stock Material
/// widgets pick up soundspan colours without per-widget styling.
///
/// The mapping follows doc 09; roles it does not name take the nearest
/// token.
ColorScheme soundspanColorScheme(SoundspanColors c, Brightness b) {
  return ColorScheme(
    brightness: b,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.brand,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: b == Brightness.dark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF),
    surface: c.surface,
    onSurface: c.contentBody,
    surfaceContainerLowest: c.ground,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surfaceRaised,
    surfaceContainerHigh: c.surfaceOverlay,
    surfaceContainerHighest: c.surfaceHover,
    outline: c.lineStrong,
    outlineVariant: c.line,
    scrim: c.scrim,
  );
}
