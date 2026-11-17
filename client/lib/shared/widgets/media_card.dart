// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_intents.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/dnd/drag_payload.dart';
import 'package:soundspan/shared/dnd/pointer_draggable.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';

/// A card of one album, artist, playlist or podcast: artwork, a one-line
/// title and a one-line subtitle (doc 09, Components). Used in shelves and
/// grids; its width comes from its parent.
///
/// Hover or keyboard focus raises it to `surfaceHover` and, when [onPlay] is
/// set, shows a 40 px `accent` play button at the bottom right of the
/// artwork. Keyboard focus draws a 2 px `brand` ring 2 px outside the card.
/// Screen readers get one node, "title, subtitle", which is a button only
/// when [onTap] is set.
///
/// With [onMenu], a long press or a secondary click opens the item's menu
/// (at the pointer for the click), the Menu key and Shift+F10
/// ([OpenMenuIntent]) open it below the focused card, and screen readers
/// get a "More options" custom action.
///
/// With a [dragPayload], dragging the card with a mouse or trackpad
/// carries it to a playlist or the queue (doc 09, Desktop Interaction: Drag
/// and drop).
class MediaCard extends StatefulWidget {
  /// Creates a card titled [title] over [subtitle] with the cover
  /// [artworkRef].
  const new({
    required this.title,
    required this.subtitle,
    required this.artworkRef,
    this.shape = ArtworkShape.square,
    this.mosaicRefs,
    this.onTap,
    this.onPlay,
    this.onMenu,
    this.selected = false,
    this.dragPayload,
    super.key,
  });

  /// What dragging the card carries, an [AlbumPayload] for an album; null
  /// starts no drag.
  final DragPayload? dragPayload;

  /// Whether the card is the selected item of a two-pane list: it then sits
  /// on `surfaceActive`.
  final bool selected;

  /// Opens the item's menu, at the global pointer position for a secondary
  /// click; null leaves the gestures out.
  final void Function(Offset? position)? onMenu;

  /// The first line, in `body`.
  final String title;

  /// The second line, in `bodySmall` and `contentSecondary`.
  final String subtitle;

  /// The cover; null shows the artwork placeholder.
  final String? artworkRef;

  /// Square, or circle for artists.
  final ArtworkShape shape;

  /// Covers shown as a square [MosaicArtwork] in place of [artworkRef], as
  /// for a playlist or mix; null shows [artworkRef].
  final List<String>? mosaicRefs;

  /// Opens the item; null makes the card inert.
  final VoidCallback? onTap;

  /// Plays the item; null hides the play button.
  final VoidCallback? onPlay;

  /// The space between the card's edge and its content.
  static const double padding = Spacing.x8;

  /// The key of the focus ring while it is shown.
  static const Key focusRingKey = ValueKey('MediaCard.focusRing');

  /// The height of a card [width] wide at the ambient text scale.
  static double extentFor(BuildContext context, {required double width}) {
    final lines = _textLines(context);
    return padding * 2 +
        (width - padding * 2) +
        Spacing.x8 +
        lines.title +
        _lineGap +
        lines.subtitle;
  }

  static const double _lineGap = 2;

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final lines = _textLines(context);
    final onTap = widget.onTap;
    final onPlay = widget.onPlay;
    final onMenu = widget.onMenu;
    final highlighted = _hovered || _focused;

    return LayoutBuilder(
      builder: (context, constraints) {
        final artSize = constraints.maxWidth - MediaCard.padding * 2;
        final content = Padding(
          padding: const EdgeInsets.all(MediaCard.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  if (widget.mosaicRefs case final refs?)
                    MosaicArtwork(refs: refs, size: artSize)
                  else
                    Artwork(
                      ref: widget.artworkRef,
                      size: artSize,
                      shape: widget.shape,
                    ),
                  if (highlighted && onPlay != null)
                    Positioned(
                      right: Spacing.x4,
                      bottom: Spacing.x4,
                      child: _PlayButton(onPressed: onPlay),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.x8),
              ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: lines.title,
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.body.copyWith(color: colors.content),
                      ),
                    ),
                    const SizedBox(height: MediaCard._lineGap),
                    SizedBox(
                      height: lines.subtitle,
                      child: Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.bodySmall.copyWith(
                          color: colors.contentSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return Semantics(
          container: true,
          button: onTap != null,
          selected: widget.selected ? true : null,
          label: '${widget.title}, ${widget.subtitle}',
          customSemanticsActions: onMenu == null
              ? null
              : {
                  CustomSemanticsAction(
                    label: AppLocalizations.of(context).menuMoreOptions,
                  ): () =>
                      onMenu(null),
                },
          child: PointerDraggable(
            payload: widget.dragPayload,
            child: FocusableActionDetector(
              enabled: onTap != null || onPlay != null,
              mouseCursor: onTap != null
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              onShowFocusHighlight: (value) => setState(() => _focused = value),
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) => onTap?.call(),
                ),
                if (onMenu != null)
                  OpenMenuIntent: CallbackAction<OpenMenuIntent>(
                    onInvoke: (_) {
                      final box = context.findRenderObject()! as RenderBox;
                      onMenu(
                        box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                      );
                      return null;
                    },
                  ),
              },
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: GestureDetector(
                  onTap: onTap,
                  onLongPress: onMenu == null ? null : () => onMenu(null),
                  onSecondaryTapUp: onMenu == null
                      ? null
                      : (details) => onMenu(details.globalPosition),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.selected
                              ? colors.surfaceActive
                              : highlighted
                              ? colors.surfaceHover
                              : null,
                          borderRadius: BorderRadius.circular(Radii.small),
                        ),
                        child: content,
                      ),
                      if (_focused)
                        Positioned(
                          left: -_ringOutset,
                          top: -_ringOutset,
                          right: -_ringOutset,
                          bottom: -_ringOutset,
                          child: IgnorePointer(
                            key: MediaCard.focusRingKey,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colors.brand,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  Radii.small + _ringOutset,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The 2 px ring drawn 2 px outside the card.
  static const double _ringOutset = 4;
}

/// The 40 px `accent` play button over the artwork of a hovered card.
class _PlayButton extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: AppLocalizations.of(context).mediaCardPlay,
      icon: const Icon(Icons.play_arrow_rounded),
      style: IconButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// The skeleton of a [MediaCard]: the same outer size, in
/// `surfaceHighlight`, while the item loads.
class MediaCardSkeleton extends StatelessWidget {
  /// Creates a skeleton as wide as its parent allows.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lines = _textLines(context);
    Widget bar(double lineHeight, double widthFactor) => SizedBox(
      height: lineHeight,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final artSize = constraints.maxWidth - MediaCard.padding * 2;
          return Padding(
            padding: const EdgeInsets.all(MediaCard.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: artSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(Radii.small),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.x8),
                bar(lines.title, 0.8),
                const SizedBox(height: MediaCard._lineGap),
                bar(lines.subtitle, 0.5),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The line heights of a card's title and subtitle at the ambient text
/// scale.
({double title, double subtitle}) _textLines(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  final typography = context.typography;
  double line(TextStyle style) =>
      scaler.scale(style.fontSize!) * (style.height ?? 1);
  return (title: line(typography.body), subtitle: line(typography.bodySmall));
}
