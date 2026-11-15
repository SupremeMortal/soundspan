// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/util/duration_format.dart';

/// One episode of a podcast page (doc 09, Podcasts): the title (at most two
/// lines), the publication date and the duration, a thin `brand` progress
/// bar while the episode is started but not finished, and a `positive`
/// check labelled "Played" once it is finished.
///
/// The row is one merged semantics node, such as "Title, Mar 12, 2026,
/// 42 minutes, played" or "…, 18 minutes left", and is a button only with
/// an [onTap]. Every row of a list has the height [extentFor] gives.
class EpisodeRow extends StatelessWidget {
  /// Creates the row of the episode titled [title].
  const new({
    required this.title,
    this.publishedAt,
    this.duration,
    this.position,
    this.isFinished = false,
    this.onTap,
    super.key,
  });

  /// The episode title.
  final String title;

  /// When the episode was published; no date when null.
  final DateTime? publishedAt;

  /// The episode's length; no duration when null.
  final Duration? duration;

  /// How far the user got; null when they never played it.
  final Duration? position;

  /// Whether the user finished the episode.
  final bool isFinished;

  /// Called when the row is tapped; null makes the row inert.
  final VoidCallback? onTap;

  /// The key of the progress bar's filled part.
  static const Key progressKey = ValueKey('EpisodeRow.progress');

  /// The key of the played check.
  static const Key playedKey = ValueKey('EpisodeRow.played');

  static const double _verticalPadding = Spacing.x12;
  static const double _barHeight = 3;
  static const double _barGap = Spacing.x8;

  /// The height of every episode row at the ambient text scale.
  static double extentFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final typography = context.typography;
    double line(TextStyle style) =>
        scaler.scale(style.fontSize!) * (style.height ?? 1);
    return _verticalPadding * 2 +
        line(typography.body) * 2 +
        Spacing.x4 +
        line(typography.bodySmall) +
        _barGap +
        _barHeight;
  }

  /// The share of the episode played, from 0 to 1, or null when no bar
  /// shows: the episode is finished, untouched, or has no known length.
  double? get progress {
    final position = this.position;
    final duration = this.duration;
    if (isFinished || position == null || duration == null) return null;
    if (position <= Duration.zero || duration <= Duration.zero) return null;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final date = _date(context);
    final duration = this.duration;
    final progress = this.progress;
    final meta = [
      ?date,
      if (duration != null) formatTrackDuration(duration),
    ].join(' · ');

    final label = [
      title,
      ?date,
      if (duration != null) l10n.podcastsEpisodeMinutes(_minutes(duration)),
      if (isFinished)
        l10n.podcastsEpisodePlayedSpoken
      else if (progress != null)
        l10n.podcastsEpisodeMinutesLeft(_minutesLeft(duration! - position!)),
    ].join(', ');

    final content = SizedBox(
      height: extentFor(context),
      child: ClipRect(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x8,
            vertical: _verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.body.copyWith(color: colors.content),
              ),
              const SizedBox(height: Spacing.x4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodySmall.tabular.copyWith(
                        color: colors.contentSecondary,
                      ),
                    ),
                  ),
                  if (isFinished) ...[
                    const SizedBox(width: Spacing.x8),
                    Icon(
                      Icons.check_circle_rounded,
                      key: playedKey,
                      size: typography.bodySmall.fontSize,
                      color: colors.positive,
                    ),
                    const SizedBox(width: Spacing.x4),
                    Text(
                      l10n.podcastsEpisodePlayed,
                      style: typography.bodySmall.copyWith(
                        color: colors.positive,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              if (progress != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(_barHeight),
                  child: SizedBox(
                    height: _barHeight,
                    child: ColoredBox(
                      color: colors.surfaceActive,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          key: progressKey,
                          widthFactor: progress,
                          heightFactor: 1,
                          child: ColoredBox(color: colors.brand),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final onTap = this.onTap;
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(Radii.small),
              child: content,
            ),
    );
  }

  String? _date(BuildContext context) {
    final publishedAt = this.publishedAt;
    if (publishedAt == null) return null;
    final locale = Intl.verifiedLocale(
      Localizations.localeOf(context).toLanguageTag(),
      DateFormat.localeExists,
      onFailure: (_) => 'en',
    );
    return DateFormat.yMMMd(locale).format(publishedAt.toLocal());
  }

  /// The whole minutes of [duration], rounded, at least 1.
  static int _minutes(Duration duration) =>
      ((duration.inSeconds + 30) ~/ 60).clamp(1, 1 << 31);

  /// The minutes left of [left], rounded up, at least 1.
  static int _minutesLeft(Duration left) =>
      ((left.inSeconds + 59) ~/ 60).clamp(1, 1 << 31);
}
