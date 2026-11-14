// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';

/// The spacing scale (doc 09, Shape, Spacing, Motion).
abstract final class Spacing {
  /// 4 logical pixels.
  static const double x4 = 4;

  /// 8 logical pixels.
  static const double x8 = 8;

  /// 12 logical pixels.
  static const double x12 = 12;

  /// 16 logical pixels.
  static const double x16 = 16;

  /// 24 logical pixels.
  static const double x24 = 24;

  /// 32 logical pixels.
  static const double x32 = 32;

  /// 48 logical pixels.
  static const double x48 = 48;
}

/// Page gutters per window class.
abstract final class Gutters {
  /// Compact windows.
  static const double compact = 16;

  /// Medium windows.
  static const double medium = 24;

  /// Expanded windows.
  static const double expanded = 32;
}

/// Corner radii.
abstract final class Radii {
  /// Artwork, cards and rows.
  static const double small = 6;

  /// Panels, sheets, dialogs and now-playing artwork.
  static const double large = 12;

  /// Buttons, chips and the search field: a full pill.
  static const StadiumBorder pill = StadiumBorder();
}

/// Minimum target and row sizes.
abstract final class Sizes {
  /// Minimum touch target edge.
  static const double touchTarget = 48;

  /// Minimum pointer target edge.
  static const double pointerTarget = 32;

  /// Spacing between pointer targets.
  static const double pointerTargetSpacing = 4;

  /// Track row with thumbnail.
  static const double trackRow = 56;

  /// Album track row without thumbnail.
  static const double albumTrackRow = 48;
}

/// Animation durations and curve.
abstract final class Motion {
  /// Standard transitions.
  static const Duration standard = Duration(milliseconds: 150);

  /// Sheets and route changes.
  static const Duration emphasized = Duration(milliseconds: 250);

  /// The curve of every transition.
  static const Curve curve = Curves.easeOutCubic;

  /// [duration], or [Duration.zero] when the platform asks for reduced
  /// motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// Elevation shadows. Dark themes express elevation by surface colour.
abstract final class SoundspanShadows {
  /// The light-theme elevation shadow: offset 0 2, blur 12, 8 % black.
  static const BoxShadow raised = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 2),
    blurRadius: 12,
  );
}
