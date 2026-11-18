// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/tokens.dart';

/// Names of the colour tokens, for code that addresses tokens as data
/// (the contrast pairs).
enum SoundspanColorToken {
  /// See [SoundspanColors.ground].
  ground,

  /// See [SoundspanColors.surface].
  surface,

  /// See [SoundspanColors.surfaceRaised].
  surfaceRaised,

  /// See [SoundspanColors.surfaceOverlay].
  surfaceOverlay,

  /// See [SoundspanColors.surfaceHover].
  surfaceHover,

  /// See [SoundspanColors.surfaceActive].
  surfaceActive,

  /// See [SoundspanColors.surfaceHighlight].
  surfaceHighlight,

  /// See [SoundspanColors.line].
  line,

  /// See [SoundspanColors.lineStrong].
  lineStrong,

  /// See [SoundspanColors.content].
  content,

  /// See [SoundspanColors.contentBody].
  contentBody,

  /// See [SoundspanColors.contentSecondary].
  contentSecondary,

  /// See [SoundspanColors.contentMuted].
  contentMuted,

  /// See [SoundspanColors.contentDisabled].
  contentDisabled,

  /// See [SoundspanColors.brand].
  brand,

  /// See [SoundspanColors.accent].
  accent,

  /// See [SoundspanColors.onAccent].
  onAccent,

  /// See [SoundspanColors.transport].
  transport,

  /// See [SoundspanColors.onTransport].
  onTransport,

  /// See [SoundspanColors.positive].
  positive,

  /// See [SoundspanColors.warning].
  warning,

  /// See [SoundspanColors.danger].
  danger,

  /// See [SoundspanColors.scrim].
  scrim,
}

/// The soundspan colour tokens as a theme extension.
///
/// Widgets read colours as `context.colors.surfaceRaised`, never as literals.
@immutable
class SoundspanColors extends ThemeExtension<SoundspanColors> {
  /// Creates a token set; every token is required.
  const new({
    required this.ground,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.surfaceHover,
    required this.surfaceActive,
    required this.surfaceHighlight,
    required this.line,
    required this.lineStrong,
    required this.content,
    required this.contentBody,
    required this.contentSecondary,
    required this.contentMuted,
    required this.contentDisabled,
    required this.brand,
    required this.accent,
    required this.onAccent,
    required this.transport,
    required this.onTransport,
    required this.positive,
    required this.warning,
    required this.danger,
    required this.scrim,
  });

  /// The dark theme.
  static const SoundspanColors dark = SoundspanColors(
    ground: DarkTokens.ground,
    surface: DarkTokens.surface,
    surfaceRaised: DarkTokens.surfaceRaised,
    surfaceOverlay: DarkTokens.surfaceOverlay,
    surfaceHover: DarkTokens.surfaceHover,
    surfaceActive: DarkTokens.surfaceActive,
    surfaceHighlight: DarkTokens.surfaceHighlight,
    line: DarkTokens.line,
    lineStrong: DarkTokens.lineStrong,
    content: DarkTokens.content,
    contentBody: DarkTokens.contentBody,
    contentSecondary: DarkTokens.contentSecondary,
    contentMuted: DarkTokens.contentMuted,
    contentDisabled: DarkTokens.contentDisabled,
    brand: DarkTokens.brand,
    accent: DarkTokens.accent,
    onAccent: DarkTokens.onAccent,
    transport: DarkTokens.transport,
    onTransport: DarkTokens.onTransport,
    positive: DarkTokens.positive,
    warning: DarkTokens.warning,
    danger: DarkTokens.danger,
    scrim: DarkTokens.scrim,
  );

  /// The light theme.
  static const SoundspanColors light = SoundspanColors(
    ground: LightTokens.ground,
    surface: LightTokens.surface,
    surfaceRaised: LightTokens.surfaceRaised,
    surfaceOverlay: LightTokens.surfaceOverlay,
    surfaceHover: LightTokens.surfaceHover,
    surfaceActive: LightTokens.surfaceActive,
    surfaceHighlight: LightTokens.surfaceHighlight,
    line: LightTokens.line,
    lineStrong: LightTokens.lineStrong,
    content: LightTokens.content,
    contentBody: LightTokens.contentBody,
    contentSecondary: LightTokens.contentSecondary,
    contentMuted: LightTokens.contentMuted,
    contentDisabled: LightTokens.contentDisabled,
    brand: LightTokens.brand,
    accent: LightTokens.accent,
    onAccent: LightTokens.onAccent,
    transport: LightTokens.transport,
    onTransport: LightTokens.onTransport,
    positive: LightTokens.positive,
    warning: LightTokens.warning,
    danger: LightTokens.danger,
    scrim: LightTokens.scrim,
  );

  /// The dark theme when the platform requests high contrast.
  static const SoundspanColors darkHighContrast = SoundspanColors(
    ground: DarkTokens.ground,
    surface: DarkTokens.surface,
    surfaceRaised: DarkTokens.surfaceRaised,
    surfaceOverlay: DarkTokens.surfaceOverlay,
    surfaceHover: DarkTokens.surfaceHover,
    surfaceActive: DarkTokens.surfaceActive,
    surfaceHighlight: DarkTokens.surfaceHighlight,
    line: DarkHighContrastTokens.line,
    lineStrong: DarkHighContrastTokens.lineStrong,
    content: DarkTokens.content,
    contentBody: DarkTokens.contentBody,
    contentSecondary: DarkHighContrastTokens.contentSecondary,
    contentMuted: DarkTokens.contentMuted,
    contentDisabled: DarkTokens.contentDisabled,
    brand: DarkTokens.brand,
    accent: DarkTokens.accent,
    onAccent: DarkTokens.onAccent,
    transport: DarkTokens.transport,
    onTransport: DarkTokens.onTransport,
    positive: DarkTokens.positive,
    warning: DarkTokens.warning,
    danger: DarkTokens.danger,
    scrim: DarkTokens.scrim,
  );

  /// The light theme when the platform requests high contrast.
  static const SoundspanColors lightHighContrast = SoundspanColors(
    ground: LightTokens.ground,
    surface: LightTokens.surface,
    surfaceRaised: LightTokens.surfaceRaised,
    surfaceOverlay: LightTokens.surfaceOverlay,
    surfaceHover: LightTokens.surfaceHover,
    surfaceActive: LightTokens.surfaceActive,
    surfaceHighlight: LightTokens.surfaceHighlight,
    line: LightHighContrastTokens.line,
    lineStrong: LightHighContrastTokens.lineStrong,
    content: LightTokens.content,
    contentBody: LightTokens.contentBody,
    contentSecondary: LightHighContrastTokens.contentSecondary,
    contentMuted: LightTokens.contentMuted,
    contentDisabled: LightTokens.contentDisabled,
    brand: LightTokens.brand,
    accent: LightTokens.accent,
    onAccent: LightTokens.onAccent,
    transport: LightTokens.transport,
    onTransport: LightTokens.onTransport,
    positive: LightTokens.positive,
    warning: LightTokens.warning,
    danger: LightTokens.danger,
    scrim: LightTokens.scrim,
  );

  /// Window background behind panels.
  final Color ground;

  /// Content area and sheets.
  final Color surface;

  /// Sidebar, navigation bar and player bar.
  final Color surfaceRaised;

  /// Menus and dialogs.
  final Color surfaceOverlay;

  /// Hovered rows and cards; search field fill.
  final Color surfaceHover;

  /// Pressed or selected row.
  final Color surfaceActive;

  /// Artwork placeholder and skeletons.
  final Color surfaceHighlight;

  /// Dividers and card outlines.
  final Color line;

  /// Input outlines and focus-adjacent borders.
  final Color lineStrong;

  /// Titles.
  final Color content;

  /// Body text.
  final Color contentBody;

  /// Subtitles and metadata.
  final Color contentSecondary;

  /// Captions and timestamps.
  final Color contentMuted;

  /// Disabled text and icons.
  final Color contentDisabled;

  /// Focus ring, links, selected indicators and progress.
  final Color brand;

  /// Primary action fill (Play, Sign in).
  final Color accent;

  /// Text and icons on [accent].
  final Color onAccent;

  /// Play/pause circle in the player.
  final Color transport;

  /// Icon on the play/pause circle.
  final Color onTransport;

  /// Downloaded, connected, shuffle/repeat on.
  final Color positive;

  /// Expiring link, degraded sync.
  final Color warning;

  /// Errors and destructive actions.
  final Color danger;

  /// Behind sheets and dialogs.
  final Color scrim;

  /// The value of [token].
  Color operator [](SoundspanColorToken token) => switch (token) {
    SoundspanColorToken.ground => ground,
    SoundspanColorToken.surface => surface,
    SoundspanColorToken.surfaceRaised => surfaceRaised,
    SoundspanColorToken.surfaceOverlay => surfaceOverlay,
    SoundspanColorToken.surfaceHover => surfaceHover,
    SoundspanColorToken.surfaceActive => surfaceActive,
    SoundspanColorToken.surfaceHighlight => surfaceHighlight,
    SoundspanColorToken.line => line,
    SoundspanColorToken.lineStrong => lineStrong,
    SoundspanColorToken.content => content,
    SoundspanColorToken.contentBody => contentBody,
    SoundspanColorToken.contentSecondary => contentSecondary,
    SoundspanColorToken.contentMuted => contentMuted,
    SoundspanColorToken.contentDisabled => contentDisabled,
    SoundspanColorToken.brand => brand,
    SoundspanColorToken.accent => accent,
    SoundspanColorToken.onAccent => onAccent,
    SoundspanColorToken.transport => transport,
    SoundspanColorToken.onTransport => onTransport,
    SoundspanColorToken.positive => positive,
    SoundspanColorToken.warning => warning,
    SoundspanColorToken.danger => danger,
    SoundspanColorToken.scrim => scrim,
  };

  @override
  SoundspanColors copyWith({
    Color? ground,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? surfaceHover,
    Color? surfaceActive,
    Color? surfaceHighlight,
    Color? line,
    Color? lineStrong,
    Color? content,
    Color? contentBody,
    Color? contentSecondary,
    Color? contentMuted,
    Color? contentDisabled,
    Color? brand,
    Color? accent,
    Color? onAccent,
    Color? transport,
    Color? onTransport,
    Color? positive,
    Color? warning,
    Color? danger,
    Color? scrim,
  }) {
    return SoundspanColors(
      ground: ground ?? this.ground,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfaceActive: surfaceActive ?? this.surfaceActive,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      content: content ?? this.content,
      contentBody: contentBody ?? this.contentBody,
      contentSecondary: contentSecondary ?? this.contentSecondary,
      contentMuted: contentMuted ?? this.contentMuted,
      contentDisabled: contentDisabled ?? this.contentDisabled,
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      transport: transport ?? this.transport,
      onTransport: onTransport ?? this.onTransport,
      positive: positive ?? this.positive,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  SoundspanColors lerp(SoundspanColors? other, double t) {
    if (other == null) return this;
    return SoundspanColors(
      ground: Color.lerp(ground, other.ground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfaceActive: Color.lerp(surfaceActive, other.surfaceActive, t)!,
      surfaceHighlight: Color.lerp(
        surfaceHighlight,
        other.surfaceHighlight,
        t,
      )!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      content: Color.lerp(content, other.content, t)!,
      contentBody: Color.lerp(contentBody, other.contentBody, t)!,
      contentSecondary: Color.lerp(
        contentSecondary,
        other.contentSecondary,
        t,
      )!,
      contentMuted: Color.lerp(contentMuted, other.contentMuted, t)!,
      contentDisabled: Color.lerp(contentDisabled, other.contentDisabled, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      transport: Color.lerp(transport, other.transport, t)!,
      onTransport: Color.lerp(onTransport, other.onTransport, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// Access to the [SoundspanColors] of the ambient theme.
extension SoundspanColorsContext on BuildContext {
  /// The colour tokens registered on the ambient [Theme].
  SoundspanColors get colors => Theme.of(this).extension<SoundspanColors>()!;
}
