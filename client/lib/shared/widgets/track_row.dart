// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kDoubleTapTimeout;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_intents.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/shared/dnd/drag_payload.dart';
import 'package:soundspan/shared/dnd/pointer_draggable.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/providers/now_playing.dart';
import 'package:soundspan/shared/util/duration_format.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';
import 'package:soundspan/shared/widgets/equaliser_bars.dart';
import 'package:soundspan/shared/widgets/like_button.dart';
import 'package:soundspan/shared/widgets/track_selection.dart';

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
/// "title, artist, spoken duration", then the state words that apply
/// ("downloaded", "liked", "now playing" or "paused") and last the disabled
/// reason. It is a button with the hint "Play" only when [onTap] is set and
/// the row is enabled; a disabled row is marked disabled and has no tap
/// action. The like and overflow buttons inside it are out of the
/// semantics tree and stay reachable by pointer and keyboard.
///
/// While the app is offline, on a platform that downloads, a row with a
/// [playbackId] whose track has no completed file on this device is
/// disabled too, with the reason "Not available offline"; online nothing is
/// disabled by that rule.
///
/// With a [playbackId], the row marks itself while that track is the
/// queue's current item ([nowPlayingProvider]): [EqualiserBars] in `brand`
/// in place of the index or over the thumbnail, moving only while it plays
/// and motion is allowed, a `brand` title, and "now playing" or "paused"
/// read. Only those small parts watch playback; the row itself takes plain
/// values and does not rebuild when playback changes.
///
/// With [onToggleLike], a [LikeButton] showing [liked] sits before the
/// duration and the node gains a "Like" or "Remove like" custom action;
/// without it the slot is left out, as for a track with no `playbackId`.
/// The title and artist column keeps at least [minTitleFraction] of the
/// row's width at any text scale: the duration column is as wide as its
/// text, and where that is not enough the heart leaves the row while the
/// custom action stays.
/// [semanticActions] adds further custom actions to the node.
///
/// With [onMenu], an overflow button ("More options") ends the row, and a
/// long press or a secondary click opens the menu too (at the pointer for
/// the click); the node gains a "More options" custom action. With
/// [onAddToQueue] the node gains an "Add to queue" custom action. A
/// disabled row keeps its menu. While the row has focus, the Menu key and
/// Shift+F10 ([OpenMenuIntent]) open the menu positioned at the row.
///
/// With [onSelect], a mouse click selects the row instead of playing it
/// (doc 09, Desktop Interaction: Selection): the click's [SelectGesture]
/// follows the modifiers held, the row takes focus, and a double click
/// calls [onTap]. Touch input keeps tap-to-play. A [selected] row is read
/// as selected. Enter ([PlayRowIntent]) calls [onTap] unless [rowActions]
/// handles it; [rowActions] also handles [PlayRowNextIntent] and
/// [RemoveRowIntent] while the row has focus.
///
/// With a [dragPayload] and a [playbackId], dragging the row with a mouse
/// or trackpad carries the payload to a playlist or the queue (doc 09,
/// Desktop Interaction: Drag and drop); touch input starts no drag.
class TrackRow extends ConsumerStatefulWidget {
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
    this.playbackId,
    this.semanticActions = const {},
    this.onMenu,
    this.onAddToQueue,
    this.onSelect,
    this.focusNode,
    this.rowActions = const {},
    this.dragPayload,
    super.key,
  });

  /// What dragging the row carries: the selection when the row is part of
  /// it, else the row's track; null, or no [playbackId], starts no drag.
  final DragPayload? dragPayload;

  /// Selects the row on a mouse click with the gesture of the modifiers
  /// held; null keeps click-to-play.
  final ValueChanged<SelectGesture>? onSelect;

  /// The focus node of the row, which a [SelectionController] moves.
  final FocusNode? focusNode;

  /// Actions of the row's intents ([PlayRowIntent], [PlayRowNextIntent],
  /// [RemoveRowIntent]) while it has focus.
  final Map<Type, Action<Intent>> rowActions;

  /// Opens the row's menu, at the global pointer position for a secondary
  /// click and at the overflow button otherwise; null leaves out the
  /// button and the gestures.
  final void Function(Offset? position)? onMenu;

  /// Adds the track to the queue, the row's "Add to queue" custom action;
  /// null leaves the action out.
  final VoidCallback? onAddToQueue;

  /// The track's playback id, which marks the row while that track is
  /// current; null never marks it.
  final PlaybackId? playbackId;

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

  /// Further custom actions of the row's semantics node, after the like
  /// action.
  final Map<CustomSemanticsAction, VoidCallback> semanticActions;

  /// The key of the equaliser bars of the playing row.
  static const Key playingIndicatorKey = ValueKey('TrackRow.playing');

  /// The key of the overflow button.
  static const Key overflowKey = ValueKey('TrackRow.overflow');

  /// The key of the row's download glyph.
  static const Key downloadGlyphKey = ValueKey('TrackRow.downloadGlyph');

  /// The key of the box that draws the hover and selection fill.
  static const Key backgroundKey = ValueKey('TrackRow.background');

  /// The opacity of a disabled row.
  static const double disabledOpacity = 0.4;

  /// The edge of the thumbnail artwork.
  static const double thumbnailSize = 44;

  /// The share of the row's width the title and artist column keeps
  /// before the fixed columns (doc 09, Components: `TrackRow`); the heart
  /// is left out of the row where it would take that space.
  static const double minTitleFraction = 0.35;

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
  ConsumerState<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends ConsumerState<TrackRow> {
  bool _hovered = false;
  bool _focused = false;
  PointerDeviceKind? _tapKind;
  Timer? _doubleClick;
  FocusNode? _ownNode;

  FocusNode get _node =>
      widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'TrackRow'));

  @override
  void dispose() {
    _doubleClick?.cancel();
    _ownNode?.dispose();
    super.dispose();
  }

  /// A tap: with [TrackRow.onSelect] and a mouse, the first click selects
  /// and a second one within the double-tap timeout plays.
  void _onTap(VoidCallback onTap) {
    final onSelect = widget.onSelect;
    final mouse = _tapKind == PointerDeviceKind.mouse;
    if (onSelect == null || !mouse) {
      onTap();
      return;
    }
    if (_doubleClick?.isActive ?? false) {
      _doubleClick!.cancel();
      onTap();
      return;
    }
    _doubleClick = Timer(kDoubleTapTimeout, () {});
    onSelect(currentSelectGesture());
    _node.requestFocus();
  }

  /// Opens the menu below the start of the row.
  void _openMenuAtRow(void Function(Offset? position) onMenu) {
    final box = context.findRenderObject()! as RenderBox;
    onMenu(box.localToGlobal(box.size.bottomLeft(Offset.zero)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final l10n = AppLocalizations.of(context);
    // While offline a track without a file on this device is disabled too
    // (doc 07, Reachability and Offline Mode).
    final unavailableOffline =
        widget.enabled && watchUnavailableOffline(ref, widget.playbackId);
    final enabled = widget.enabled && !unavailableOffline;
    final onTap = enabled ? widget.onTap : null;
    final onToggleLike = widget.onToggleLike;
    final onMenu = widget.onMenu;
    final onAddToQueue = widget.onAddToQueue;
    final reason = enabled
        ? null
        : unavailableOffline
        ? l10n.trackNotAvailableOffline
        : widget.disabledReason;
    final withThumbnail = widget.leading is TrackRowThumbnail;

    // Title, artist and spoken duration, then the state words that apply
    // (downloaded, liked, now playing) and last the disabled reason.
    String label({bool downloaded = false, String? playing}) => [
      widget.title,
      if (widget.artist.isNotEmpty) widget.artist,
      spokenTrackDuration(l10n, widget.duration),
      if (downloaded) l10n.trackRowDownloaded,
      if (widget.liked) l10n.trackRowLiked,
      ?playing,
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
    final playbackId = widget.playbackId;
    final durationText = formatTrackDuration(widget.duration);
    final durationStyle = typography.caption.tabular.copyWith(
      color: colors.contentSecondary,
    );
    var leading = switch (widget.leading) {
      TrackRowIndex(:final number) => Text(
        '$number',
        maxLines: 1,
        textAlign: TextAlign.end,
        style: typography.caption.tabular.copyWith(color: colors.contentMuted),
      ),
      TrackRowThumbnail(:final artworkRef) => Artwork(
        ref: artworkRef,
        size: TrackRow.thumbnailSize,
      ),
    };
    Widget title = Text(
      widget.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: typography.body.copyWith(color: colors.content),
    );
    if (playbackId != null) {
      leading = _PlayingLeading(
        playbackId: playbackId,
        overThumbnail: withThumbnail,
        child: leading,
      );
      title = _PlayingTitle(
        playbackId: playbackId,
        title: widget.title,
        child: title,
      );
    }
    Widget content = _RowLayout(
      withThumbnail: withThumbnail,
      leading: leading,
      titleAndArtist: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
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
      download: playbackId == null
          ? null
          : _DownloadSlot(playbackId: playbackId),
      like: onToggleLike == null
          ? null
          : LikeButton(liked: widget.liked, onToggle: onToggleLike),
      duration: Text(durationText, maxLines: 1, style: durationStyle),
      durationWidth: _textWidth(context, durationText, durationStyle),
      overflow: onMenu == null ? null : _OverflowButton(onMenu: onMenu),
    );

    content = DecoratedBox(
      key: TrackRow.backgroundKey,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.small),
      ),
      child: content,
    );

    if (!enabled) {
      content = Opacity(opacity: TrackRow.disabledOpacity, child: content);
      if (reason != null) {
        content = Tooltip(message: reason, child: content);
      }
    }

    Widget semantics(String label, Widget child) => Semantics(
      container: true,
      enabled: enabled,
      button: onTap != null,
      selected: widget.onSelect == null ? null : widget.selected,
      label: label,
      hint: onTap != null ? l10n.trackRowPlayHint : null,
      excludeSemantics: true,
      onTap: onTap,
      customSemanticsActions:
          onToggleLike == null &&
              onAddToQueue == null &&
              onMenu == null &&
              widget.semanticActions.isEmpty
          ? null
          : {
              CustomSemanticsAction(
                label: widget.liked
                    ? l10n.likeButtonRemove
                    : l10n.likeButtonLike,
              ): ?onToggleLike,
              CustomSemanticsAction(label: l10n.menuAddToQueue): ?onAddToQueue,
              if (onMenu != null)
                CustomSemanticsAction(label: l10n.menuMoreOptions): () =>
                    onMenu(null),
              ...widget.semanticActions,
            },
      child: child,
    );

    final interactive = PointerDraggable(
      payload: playbackId == null ? null : widget.dragPayload,
      child: FocusableActionDetector(
        enabled: onTap != null,
        focusNode: _node,
        mouseCursor: onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => onTap?.call(),
          ),
          PlayRowIntent: CallbackAction<PlayRowIntent>(
            onInvoke: (_) => onTap?.call(),
          ),
          if (onMenu != null)
            OpenMenuIntent: CallbackAction<OpenMenuIntent>(
              onInvoke: (_) => _openMenuAtRow(onMenu),
            ),
          ...widget.rowActions,
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: onTap == null
                ? null
                : (details) => _tapKind = details.kind,
            onTap: onTap == null ? null : () => _onTap(onTap),
            onLongPress: onMenu == null ? null : () => onMenu(null),
            onSecondaryTapUp: onMenu == null
                ? null
                : (details) => onMenu(details.globalPosition),
            behavior: HitTestBehavior.opaque,
            child: content,
          ),
        ),
      ),
    );
    if (playbackId == null) return semantics(label(), interactive);
    return _PlayingSemantics(
      playbackId: playbackId,
      builder: (state, downloaded) => semantics(
        label(
          downloaded: downloaded,
          playing: switch (state) {
            _PlayingState.none => null,
            _PlayingState.playing => l10n.trackRowPlaying,
            _PlayingState.paused => l10n.trackRowPaused,
          },
        ),
        interactive,
      ),
      child: interactive,
    );
  }
}

/// Whether a row's track is current, and if so whether it plays.
enum _PlayingState {
  /// Another item, or none, is current.
  none,

  /// The track is current and playing.
  playing,

  /// The track is current and paused.
  paused,
}

/// The [_PlayingState] of [playbackId], watched through one `select`.
_PlayingState _watchState(WidgetRef ref, PlaybackId playbackId) => ref.watch(
  nowPlayingProvider.select((now) {
    if (now.playbackId != playbackId) return _PlayingState.none;
    return now.playing ? _PlayingState.playing : _PlayingState.paused;
  }),
);

/// The row's leading [child], or the equaliser bars in its place (over it
/// for a thumbnail) while [playbackId] is current.
class _PlayingLeading extends ConsumerWidget {
  const new({
    required this.playbackId,
    required this.overThumbnail,
    required this.child,
  });

  final PlaybackId playbackId;
  final bool overThumbnail;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _watchState(ref, playbackId);
    if (state == _PlayingState.none) return child;
    final colors = context.colors;
    final bars = EqualiserBars(
      key: TrackRow.playingIndicatorKey,
      color: colors.brand,
      animate:
          state == _PlayingState.playing &&
          !MediaQuery.disableAnimationsOf(context),
    );
    if (!overThumbnail) {
      return Align(alignment: AlignmentDirectional.centerEnd, child: bars);
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.scrim,
              borderRadius: BorderRadius.circular(Radii.small),
            ),
          ),
        ),
        bars,
      ],
    );
  }
}

/// The row's title [child], redrawn in `brand` while [playbackId] is
/// current.
class _PlayingTitle extends ConsumerWidget {
  const new({
    required this.playbackId,
    required this.title,
    required this.child,
  });

  final PlaybackId playbackId;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_watchState(ref, playbackId) == _PlayingState.none) return child;
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.typography.body.copyWith(color: context.colors.brand),
    );
  }
}

/// The row's semantics node, rebuilt by [builder] only when the
/// [_PlayingState] of [playbackId] changes; [child] is kept.
class _PlayingSemantics extends ConsumerWidget {
  const new({
    required this.playbackId,
    required this.builder,
    required this.child,
  });

  final PlaybackId playbackId;
  final Widget Function(_PlayingState state, bool downloaded) builder;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = TrackItemKey(playbackId.value);
    final downloaded = ref.watch(
      itemDownloadStatesProvider.select(
        (states) => states.value?[key]?.status == DownloadStatus.completed,
      ),
    );
    return builder(_watchState(ref, playbackId), downloaded);
  }
}

/// The row's download glyph, rebuilt only when this track's glyph changes;
/// a failed one retries when tapped.
class _DownloadSlot extends ConsumerWidget {
  const new({required this.playbackId});

  final PlaybackId playbackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glyph = watchTrackGlyph(ref, playbackId);
    if (glyph == DownloadGlyphState.none) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: Spacing.x8),
      child: DownloadGlyph(
        key: TrackRow.downloadGlyphKey,
        state: glyph,
        onTap: glyph == DownloadGlyphState.failed
            ? () => ref
                  .read(downloadControllerProvider)
                  .retry(TrackItemKey(playbackId.value))
            : null,
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

/// The width of [text] in [style] as a [Text] in [context] draws it.
double _textWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// The columns of a track row, shared by [TrackRow] and
/// [TrackRowSkeleton] so both have the same height.
///
/// The duration column is [durationWidth] wide. The [like] slot is left
/// out where it would leave the title and artist column less than
/// [TrackRow.minTitleFraction] of the row.
class _RowLayout extends StatelessWidget {
  const new({
    required this.withThumbnail,
    required this.leading,
    required this.titleAndArtist,
    required this.duration,
    required this.durationWidth,
    this.album,
    this.download,
    this.like,
    this.overflow,
  });

  final bool withThumbnail;
  final Widget leading;
  final Widget titleAndArtist;
  final Widget? album;
  final Widget? download;
  final Widget? like;
  final Widget duration;
  final double durationWidth;
  final Widget? overflow;

  /// The width of the index column.
  static const double _indexWidth = 32;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final album = this.album;
    final download = this.download;
    final overflow = this.overflow;
    final target = usesPointerInput() ? Sizes.pointerTarget : Sizes.touchTarget;
    final leadingWidth = withThumbnail
        ? TrackRow.thumbnailSize
        : scaler.scale(_indexWidth);
    // Everything but the title, artist, album and like columns.
    final fixed =
        2 * Spacing.x8 +
        leadingWidth +
        Spacing.x12 +
        Spacing.x16 +
        durationWidth +
        (overflow == null ? 0 : Spacing.x4 + target);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var like = this.like;
        if (like != null && width.isFinite) {
          final flexible = width - fixed - Spacing.x8 - target;
          final title = album == null
              ? flexible
              : (flexible - Spacing.x16) * 3 / 5;
          if (title < width * TrackRow.minTitleFraction) like = null;
        }
        return _row(scaler, leading, album, download, like, overflow, target);
      },
    );
  }

  Widget _row(
    TextScaler scaler,
    Widget leading,
    Widget? album,
    Widget? download,
    Widget? like,
    Widget? overflow,
    double target,
  ) {
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
            ?download,
            if (like != null) ...[
              const SizedBox(width: Spacing.x8),
              SizedBox.square(dimension: target, child: like),
            ],
            const SizedBox(width: Spacing.x16),
            SizedBox(
              width: durationWidth,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                heightFactor: 1,
                child: duration,
              ),
            ),
            if (overflow != null) ...[
              const SizedBox(width: Spacing.x4),
              overflow,
            ],
          ],
        ),
      ),
    );
  }
}

/// The overflow button of a row: "More options", opening the menu at the
/// button. 48 px on touch input and 32 px with a pointer (doc 09, Shape).
class _OverflowButton extends StatelessWidget {
  const new({required this.onMenu});

  final void Function(Offset? position) onMenu;

  @override
  Widget build(BuildContext context) {
    final size = usesPointerInput() ? Sizes.pointerTarget : Sizes.touchTarget;
    return IconButton(
      key: TrackRow.overflowKey,
      tooltip: AppLocalizations.of(context).menuMoreOptions,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      padding: EdgeInsets.zero,
      iconSize: 20,
      color: context.colors.contentSecondary,
      icon: const Icon(Icons.more_horiz_rounded),
      onPressed: () {
        final box = context.findRenderObject()! as RenderBox;
        onMenu(box.localToGlobal(box.size.bottomCenter(Offset.zero)));
      },
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
        durationWidth: _textWidth(
          context,
          formatTrackDuration(Duration.zero),
          typography.caption.tabular,
        ),
      ),
    );
  }
}
