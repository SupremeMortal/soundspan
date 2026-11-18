// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The download state glyph of rows, the action bar and the Downloads tab
/// (doc 09, Components: `DownloadGlyph`).
library;

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';

/// What a [DownloadGlyph] shows. Values compare by content, so a provider
/// `select` over them rebuilds only when the glyph changes.
@immutable
sealed class DownloadGlyphState {
  const new();

  /// Downloading; [progress] is the fraction received, null when the size
  /// is unknown.
  const factory running(double? progress) = DownloadGlyphRunning;

  /// Not downloaded: nothing is shown.
  static const DownloadGlyphState none = DownloadGlyphNone();

  /// Waiting to download (queued, paused or waiting for a condition).
  static const DownloadGlyphState queued = DownloadGlyphQueued();

  /// Downloaded.
  static const DownloadGlyphState completed = DownloadGlyphCompleted();

  /// The download failed.
  static const DownloadGlyphState failed = DownloadGlyphFailed();

  /// The server will not let this device download it.
  static const DownloadGlyphState unavailable = DownloadGlyphUnavailable();
}

/// [DownloadGlyphState.none].
final class DownloadGlyphNone extends DownloadGlyphState {
  /// Creates the state.
  const new();

  @override
  String toString() => 'DownloadGlyphState.none';
}

/// [DownloadGlyphState.queued].
final class DownloadGlyphQueued extends DownloadGlyphState {
  /// Creates the state.
  const new();

  @override
  String toString() => 'DownloadGlyphState.queued';
}

/// [DownloadGlyphState.running].
final class DownloadGlyphRunning extends DownloadGlyphState {
  /// Creates the state of a download at [progress] (0 to 1), or of unknown
  /// progress when null.
  const new(this.progress);

  /// The fraction received, or null when the size is unknown.
  final double? progress;

  @override
  bool operator ==(Object other) =>
      other is DownloadGlyphRunning && other.progress == progress;

  @override
  int get hashCode => progress.hashCode;

  @override
  String toString() => 'DownloadGlyphState.running($progress)';
}

/// [DownloadGlyphState.completed].
final class DownloadGlyphCompleted extends DownloadGlyphState {
  /// Creates the state.
  const new();

  @override
  String toString() => 'DownloadGlyphState.completed';
}

/// [DownloadGlyphState.failed].
final class DownloadGlyphFailed extends DownloadGlyphState {
  /// Creates the state.
  const new();

  @override
  String toString() => 'DownloadGlyphState.failed';
}

/// [DownloadGlyphState.unavailable].
final class DownloadGlyphUnavailable extends DownloadGlyphState {
  /// Creates the state.
  const new();

  @override
  String toString() => 'DownloadGlyphState.unavailable';
}

/// The screen-reader label of [state], or null for
/// [DownloadGlyphState.none].
String? downloadGlyphLabel(AppLocalizations l10n, DownloadGlyphState state) =>
    switch (state) {
      DownloadGlyphNone() => null,
      DownloadGlyphQueued() => l10n.downloadGlyphQueued,
      DownloadGlyphRunning(:final progress) =>
        progress == null
            ? l10n.downloadGlyphRunningUnknown
            : l10n.downloadGlyphRunning((progress * 100).round()),
      DownloadGlyphCompleted() => l10n.downloadGlyphCompleted,
      DownloadGlyphFailed() => l10n.downloadGlyphFailed,
      DownloadGlyphUnavailable() => l10n.downloadGlyphUnavailable,
    };

/// A pure widget over a [DownloadGlyphState]: an outlined arrow while
/// waiting, a ring in `brand` while running (indeterminate when the size is
/// unknown), a filled check in `positive`, an error mark in `danger` and a
/// struck-through arrow in `contentDisabled`. [DownloadGlyphState.none]
/// takes no space.
///
/// With [onTap] it is a button of the minimum touch or pointer target with
/// its label as tooltip; otherwise its label is a plain semantics node.
class DownloadGlyph extends StatelessWidget {
  /// Creates the glyph of [state].
  const new({required this.state, this.onTap, this.size = 20, super.key});

  /// What to show.
  final DownloadGlyphState state;

  /// Called when the glyph is tapped, such as to retry a failed download.
  final VoidCallback? onTap;

  /// The glyph's size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = downloadGlyphLabel(AppLocalizations.of(context), state);
    if (label == null) return const SizedBox.shrink();
    final colors = context.colors;
    Widget icon(IconData data, Color colour) =>
        Icon(data, size: size, color: colour);
    final glyph = switch (state) {
      DownloadGlyphNone() => const SizedBox.shrink(),
      DownloadGlyphQueued() => icon(
        Icons.download_for_offline_outlined,
        colors.contentSecondary,
      ),
      DownloadGlyphRunning(:final progress) => SizedBox.square(
        dimension: size,
        child: Padding(
          padding: EdgeInsets.all(size / 10),
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: size / 10,
            color: colors.brand,
            backgroundColor: colors.line,
          ),
        ),
      ),
      DownloadGlyphCompleted() => icon(
        Icons.check_circle_rounded,
        colors.positive,
      ),
      DownloadGlyphFailed() => icon(Icons.error_rounded, colors.danger),
      DownloadGlyphUnavailable() => icon(
        Icons.file_download_off_rounded,
        colors.contentDisabled,
      ),
    };
    final onTap = this.onTap;
    if (onTap == null) {
      return Semantics(label: label, excludeSemantics: true, child: glyph);
    }
    final target = usesPointerInput() ? Sizes.pointerTarget : Sizes.touchTarget;
    return MergeSemantics(
      child: Semantics(
        label: label,
        child: IconButton(
          tooltip: label,
          constraints: BoxConstraints.tightFor(width: target, height: target),
          padding: EdgeInsets.zero,
          onPressed: onTap,
          icon: glyph,
        ),
      ),
    );
  }
}
