// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Raw colour values of the soundspan palette.
///
/// This directory is the only place colour literals are allowed. Widgets
/// read colours through `context.colors` (a `SoundspanColors`), never from
/// here. Values follow the colour token table of
/// `docs/designs/flutter-client/09-ui-and-design-system.md`.
library;

import 'package:material_ui/material_ui.dart';

/// Token values of the dark theme.
abstract final class DarkTokens {
  /// Window background behind panels.
  static const ground = Color(0xFF000000);

  /// Content area and sheets.
  static const surface = Color(0xFF0A0A0A);

  /// Sidebar, navigation bar and player bar.
  static const surfaceRaised = Color(0xFF0F0F0F);

  /// Menus and dialogs.
  static const surfaceOverlay = Color(0xFF141414);

  /// Hovered rows and cards; search field fill.
  static const surfaceHover = Color(0xFF1A1A1A);

  /// Pressed or selected row.
  static const surfaceActive = Color(0xFF1C1C1C);

  /// Artwork placeholder and skeletons.
  static const surfaceHighlight = Color(0xFF282828);

  /// Dividers and card outlines.
  static const line = Color(0xFF262626);

  /// Input outlines and focus-adjacent borders.
  static const lineStrong = Color(0xFF333333);

  /// Titles.
  static const content = Color(0xFFFFFFFF);

  /// Body text.
  static const contentBody = Color(0xFFE5E5E5);

  /// Subtitles and metadata.
  static const contentSecondary = Color(0xFFA3A3A3);

  /// Captions and timestamps.
  static const contentMuted = Color(0xFF8A8A8A);

  /// Disabled text and icons.
  static const contentDisabled = Color(0xFF676767);

  /// Focus ring, links, selected indicators and progress.
  static const brand = Color(0xFF3B82F6);

  /// Primary action fill (Play, Sign in).
  static const accent = Color(0xFF60A5FA);

  /// Text and icons on [accent].
  static const onAccent = Color(0xFF000000);

  /// Play/pause circle in the player.
  static const transport = Color(0xFFFFFFFF);

  /// Icon on the play/pause circle.
  static const onTransport = Color(0xFF000000);

  /// Downloaded, connected, shuffle/repeat on.
  static const positive = Color(0xFF22C55E);

  /// Expiring link, degraded sync.
  static const warning = Color(0xFFF59E0B);

  /// Errors and destructive actions.
  static const danger = Color(0xFFEF4444);

  /// Behind sheets and dialogs.
  static const scrim = Color(0x99000000);
}

/// Token values of the light theme.
abstract final class LightTokens {
  /// Window background behind panels.
  static const ground = Color(0xFFF5F5F5);

  /// Content area and sheets.
  static const surface = Color(0xFFFFFFFF);

  /// Sidebar, navigation bar and player bar.
  static const surfaceRaised = Color(0xFFFAFAFA);

  /// Menus and dialogs.
  static const surfaceOverlay = Color(0xFFFFFFFF);

  /// Hovered rows and cards; search field fill.
  static const surfaceHover = Color(0xFFF0F0F0);

  /// Pressed or selected row.
  static const surfaceActive = Color(0xFFE8E8E8);

  /// Artwork placeholder and skeletons.
  static const surfaceHighlight = Color(0xFFE5E5E5);

  /// Dividers and card outlines.
  static const line = Color(0xFFE5E5E5);

  /// Input outlines and focus-adjacent borders.
  static const lineStrong = Color(0xFFD4D4D4);

  /// Titles.
  static const content = Color(0xFF0A0A0A);

  /// Body text.
  static const contentBody = Color(0xFF262626);

  /// Subtitles and metadata.
  static const contentSecondary = Color(0xFF525252);

  /// Captions and timestamps.
  static const contentMuted = Color(0xFF666666);

  /// Disabled text and icons.
  static const contentDisabled = Color(0xFF858585);

  /// Focus ring, links, selected indicators and progress.
  static const brand = Color(0xFF2563EB);

  /// Primary action fill (Play, Sign in).
  static const accent = Color(0xFF2563EB);

  /// Text and icons on [accent].
  static const onAccent = Color(0xFFFFFFFF);

  /// Play/pause circle in the player.
  static const transport = Color(0xFF0A0A0A);

  /// Icon on the play/pause circle.
  static const onTransport = Color(0xFFFFFFFF);

  /// Downloaded, connected, shuffle/repeat on.
  static const positive = Color(0xFF15803D);

  /// Expiring link, degraded sync.
  static const warning = Color(0xFFB45309);

  /// Errors and destructive actions.
  static const danger = Color(0xFFB91C1C);

  /// Behind sheets and dialogs.
  static const scrim = Color(0x66000000);
}

/// Tokens that differ in the dark high-contrast theme; every other token
/// keeps its [DarkTokens] value.
abstract final class DarkHighContrastTokens {
  /// High-contrast `line`.
  static const line = Color(0xFF333333);

  /// High-contrast `lineStrong`.
  static const lineStrong = Color(0xFF404040);

  /// High-contrast `contentSecondary`.
  static const contentSecondary = Color(0xFFE5E5E5);
}

/// Tokens that differ in the light high-contrast theme; every other token
/// keeps its [LightTokens] value.
abstract final class LightHighContrastTokens {
  /// High-contrast `line`.
  static const line = Color(0xFFD4D4D4);

  /// High-contrast `lineStrong`.
  static const lineStrong = Color(0xFFA3A3A3);

  /// High-contrast `contentSecondary`.
  static const contentSecondary = Color(0xFF262626);
}
