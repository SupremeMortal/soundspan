// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/util/duration_format.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/like_button.dart';

/// What a [TrackRow] starts with: the track's number or its cover.
sealed class TrackRowLeading {
  const new();

  /// The track's position, for album and playlist track lists.
  const factory index(int number) = TrackRowIndex;

  /// The track's cover, for lists that mix albums.
  const factory thumbnail(String? artworkRef) = TrackRowThumbnail;
}

/// A [TrackRowLeading] showing [number].
final class TrackRowIndex extends TrackRowLeading {
  /// Shows [number].
  const new(this.number);

  /// The number shown.
  final int number;
}

/// A [TrackRowLeading] showing the cover [artworkRef].
final class TrackRowThumbnail extends TrackRowLeading {
  /// Shows the cover [artworkRef]; null shows the artwork placeholder.
  const new(this.artworkRef);

  /// The server's cover value.
  final String? artworkRef;
}

/// One track in a list, in its read-only form (doc 09, Components): the
/// leading index or thumbnail, title over artist, an optional album column
/// and the duration.
///
/// Its height is at least [Sizes.trackRow] with a thumbnail and
/// [Sizes.albumTrackRow] with an index, and grows with the text scale.
/// Hover draws `surfaceHover`, [selected] `surfaceActive`, keyboard focus a
/// 2 px `brand` ring. A disabled row is drawn at 40 % opacity, ignores taps
/// and gives [disabledReason] as its tooltip. Screen readers get one node,
/// "title, artist, spoken duration[, reason]", which is a button only when
/// [onTap] is set and the row is enabled.
///
/// With [onToggleLike], a [LikeButton] showing [liked] sits before the
/// duration and the node gains a "Like" or "Remove like" custom action;
/// without it the slot is left out, as for a track with no `playbackId`.
class TrackRow extends StatefulWidget {
  /// Creates a row for the track [title] by [artist].
  const new({
    required this.title,
    required this.artist,
    required this.duration,
    required this.leading,
    this.album,
    this.showAlbumColumn = false,
    this.enabled = true,
    this.disabledReason,
    this.onTap,
    this.selected = false,
    this.liked = false,
    this.onToggleLike,
    super.key,
  });

  /// The track title, in `body`.
  final String title;

  /// The artist line, in `bodySmall` and `contentSecondary`; empty leaves
  /// the line out, as album tracks by the album artist do.
  final String artist;

  /// The album title shown in the album column.
  final String? album;

  /// The track length, shown as `m:ss` or `h:mm:ss`.
  final Duration duration;

  /// The index or thumbnail at the start of the row.
  final TrackRowLeading leading;

  /// Whether the album column is shown; callers pass true on expanded
  /// windows.
  final bool showAlbumColumn;

  /// False draws the row at 40 % opacity and ignores taps.
  final bool enabled;

  /// Why the row is disabled; shown as its tooltip and read last.
  final String? disabledReason;

  /// Called when the enabled row is tapped or activated; null makes it
  /// inert.
  final VoidCallback? onTap;

  /// Draws the row in `surfaceActive`.
  final bool selected;

  /// Whether the heart is filled.
  final bool liked;

  /// Called when the heart or the row's like action is used; null leaves
  /// the heart out.
  final VoidCallback? onToggleLike;

  /// The key of the focus ring while it is shown.
  static const Key focusRingKey = ValueKey('TrackRow.focusRing');

  /// The key of the box that draws the hover and selection fill.
  static const Key backgroundKey = ValueKey('TrackRow.background');

  /// The opacity of a disabled row.
  static const double disabledOpacity = 0.4;

  /// The edge of the thumbnail artwork.
  static const double thumbnailSize = 44;

  /// The height of a row with a title and an artist line at the ambient
  /// text scale, for fixed-extent lists: at least [Sizes.trackRow] with a
  /// thumbnail and [Sizes.albumTrackRow] with an index.
  static double extentFor(BuildContext context, {required bool withThumbnail}) {
    final typography = context.typography;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle style) =>
        scaler.scale(style.fontSize!) * (style.height ?? 1);
    final content =
        line(typography.body) + line(typography.bodySmall) + Spacing.x8;
    return [
      if (withThumbnail) Sizes.trackRow else Sizes.albumTrackRow,
      content,
      if (withThumbnail) thumbnailSize + Spacing.x8,
    ].reduce((a, b) => a > b ? a : b);
  }

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final l10n = AppLocalizations.of(context);
    final onTap = widget.enabled ? widget.onTap : null;
    final onToggleLike = widget.onToggleLike;
    final reason = widget.enabled ? null : widget.disabledReason;
    final withThumbnail = widget.leading is TrackRowThumbnail;

    final label = [
      widget.title,
      if (widget.artist.isNotEmpty) widget.artist,
      spokenTrackDuration(l10n, widget.duration),
      ?reason,
    ].join(', ');

    final Color? fill;
    if (widget.selected) {
      fill = colors.surfaceActive;
    } else if (onTap != null && (_hovered || _focused)) {
      fill = colors.surfaceHover;
    } else {
      fill = null;
    }

    final album = widget.album;
    Widget content = _RowLayout(
      withThumbnail: withThumbnail,
      leading: switch (widget.leading) {
        TrackRowIndex(:final number) => Text(
          '$number',
          maxLines: 1,
          textAlign: TextAlign.end,
          style: typography.caption.tabular.copyWith(
            color: colors.contentMuted,
          ),
        ),
        TrackRowThumbnail(:final artworkRef) => Artwork(
          ref: artworkRef,
          size: TrackRow.thumbnailSize,
        ),
      },
      titleAndArtist: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.body.copyWith(color: colors.content),
          ),
          if (widget.artist.isNotEmpty)
            Text(
              widget.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall.copyWith(
                color: colors.contentSecondary,
              ),
            ),
        ],
      ),
      album: widget.showAlbumColumn
          ? Text(
              album ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall.copyWith(
                color: colors.contentSecondary,
              ),
            )
          : null,
      like: onToggleLike == null
          ? null
          : LikeButton(liked: widget.liked, onToggle: onToggleLike),
      duration: Text(
        formatTrackDuration(widget.duration),
        maxLines: 1,
        style: typography.caption.tabular.copyWith(
          color: colors.contentSecondary,
        ),
      ),
    );

    content = Stack(
      children: [
        DecoratedBox(
          key: TrackRow.backgroundKey,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Radii.small),
          ),
          child: content,
        ),
        if (_focused)
          Positioned.fill(
            child: IgnorePointer(
              key: TrackRow.focusRingKey,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.brand, width: 2),
                  borderRadius: BorderRadius.circular(Radii.small),
                ),
              ),
            ),
          ),
      ],
    );

    if (!widget.enabled) {
      content = Opacity(opacity: TrackRow.disabledOpacity, child: content);
      if (reason != null) {
        content = Tooltip(message: reason, child: content);
      }
    }

    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      customSemanticsActions: onToggleLike == null
          ? null
          : {
              CustomSemanticsAction(
                label: widget.liked
                    ? l10n.likeButtonRemove
                    : l10n.likeButtonLike,
              ): onToggleLike,
            },
      child: FocusableActionDetector(
        enabled: onTap != null,
        mouseCursor: onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => onTap?.call(),
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// [duration] as a screen reader says it: "3 minutes 41 seconds",
/// "1 hour 2 minutes 3 seconds", "0 seconds".
String spokenTrackDuration(AppLocalizations l10n, Duration duration) {
  final total = duration.isNegative ? 0 : duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = total % 3600 ~/ 60;
  final seconds = total % 60;
  return [
    if (hours > 0) l10n.trackRowDurationHours(hours),
    if (minutes > 0) l10n.trackRowDurationMinutes(minutes),
    if (seconds > 0 || total == 0) l10n.trackRowDurationSeconds(seconds),
  ].join(' ');
}

/// The columns of a track row, shared by [TrackRow] and
/// [TrackRowSkeleton] so both have the same height.
class _RowLayout extends StatelessWidget {
  const new({
    required this.withThumbnail,
    required this.leading,
    required this.titleAndArtist,
    required this.duration,
    this.album,
    this.like,
  });

  final bool withThumbnail;
  final Widget leading;
  final Widget titleAndArtist;
  final Widget? album;
  final Widget? like;
  final Widget duration;

  /// The width of the index column.
  static const double _indexWidth = 32;

  /// The width of the duration column at text scale 1.0.
  static const double _durationWidth = 56;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final album = this.album;
    final like = this.like;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: withThumbnail ? Sizes.trackRow : Sizes.albumTrackRow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x8,
          vertical: Spacing.x4,
        ),
        child: Row(
          children: [
            if (withThumbnail)
              leading
            else
              SizedBox(width: scaler.scale(_indexWidth), child: leading),
            const SizedBox(width: Spacing.x12),
            Expanded(flex: 3, child: titleAndArtist),
            if (album != null) ...[
              const SizedBox(width: Spacing.x16),
              Expanded(flex: 2, child: album),
            ],
            if (like != null) ...[const SizedBox(width: Spacing.x8), like],
            const SizedBox(width: Spacing.x16),
            SizedBox(
              width: scaler.scale(_durationWidth),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                heightFactor: 1,
                child: duration,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The placeholder of a [TrackRow] a paged source has not loaded yet:
/// `surfaceHighlight` bars at the row's height.
class TrackRowSkeleton extends StatelessWidget {
  /// Creates a skeleton of a row with a thumbnail or with an index.
  const new({required this.withThumbnail, super.key});

  /// Whether the row it stands for has a thumbnail.
  final bool withThumbnail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle style) =>
        scaler.scale(style.fontSize!) * (style.height ?? 1);
    Widget bar(double height, double widthFactor) => SizedBox(
      height: height,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          heightFactor: 0.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceHighlight,
              borderRadius: BorderRadius.circular(Spacing.x4),
            ),
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: _RowLayout(
        withThumbnail: withThumbnail,
        leading: withThumbnail
            ? SizedBox.square(
                dimension: TrackRow.thumbnailSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(Radii.small),
                  ),
                ),
              )
            : bar(line(typography.caption), 0.6),
        titleAndArtist: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(line(typography.body), 0.6),
            bar(line(typography.bodySmall), 0.4),
          ],
        ),
        duration: bar(line(typography.caption), 0.7),
      ),
    );
  }
}
