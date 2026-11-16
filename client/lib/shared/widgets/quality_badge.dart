// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';

/// The quality of the playing stream in one neutral style: `surfaceActive`
/// fill, `contentSecondary` text in `caption` (doc 09, Components). It
/// never varies by where the track comes from.
///
/// With a bit depth it reads "FLAC · 24/96 kHz", else with a bit rate
/// "AAC · 256 kbps", else the codec alone. It renders nothing for null
/// [info] or info without a codec.
class QualityBadge extends StatelessWidget {
  /// Creates the badge of [info].
  const new({required this.info, super.key});

  /// The stream's quality; null while unknown.
  final StreamQualityInfo? info;

  /// The badge text of [info], or null when there is nothing to show.
  static String? textOf(AppLocalizations l10n, StreamQualityInfo? info) {
    final codec = info?.codec?.trim().toUpperCase();
    if (info == null || codec == null || codec.isEmpty) return null;
    final bitDepth = info.bitDepth;
    final sampleRate = info.sampleRate;
    if (bitDepth != null && sampleRate != null) {
      return l10n.qualityBadgeSampleRate(
        codec,
        _number(bitDepth),
        _number(sampleRate / 1000),
      );
    }
    final bitrate = info.bitrate;
    if (bitrate != null) {
      return l10n.qualityBadgeBitrate(codec, '${bitrate.round()}');
    }
    return codec;
  }

  /// [value] without a trailing `.0`, at most one decimal.
  static String _number(num value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? '${rounded.round()}'
        : rounded.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final text = textOf(AppLocalizations.of(context), info);
    if (text == null) return const SizedBox.shrink();
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceActive,
        borderRadius: const BorderRadius.all(Radius.circular(Spacing.x4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x8,
          vertical: 2,
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.typography.caption.copyWith(
            color: colors.contentSecondary,
          ),
        ),
      ),
    );
  }
}
