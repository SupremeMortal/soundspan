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
import 'package:soundspan/shared/widgets/context_menu.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';

/// A row of one album, artist, playlist or podcast (doc 09, Components):
/// [MediaRow.artworkSize] artwork, a one-line title and an optional
/// one-line subtitle, then a play button when [onPlay] is set and an
/// overflow button ("More options") when [onMenu] is set.
///
/// The artwork is [leading] when given, otherwise a [MosaicArtwork] of
/// [mosaicRefs] (a playlist), otherwise an [Artwork] of [artworkRef] in
/// [shape] (a circle for an artist). The [selected] row of a two-pane list
/// sits on `surfaceActive`.
///
/// With [onMenu], a long press or a secondary click also opens the menu
/// (at the pointer for the click), the Menu key and Shift+F10
/// ([OpenMenuIntent]) open it below the focused row, and screen readers get
/// a "More options" custom action. With a [dragPayload], dragging the row
/// with a mouse or trackpad carries it to a playlist or the queue.
class MediaRow extends StatelessWidget {
  /// Creates the row of [title].
  const new({
    required this.title,
    this.subtitle,
    this.artworkRef,
    this.shape = ArtworkShape.square,
    this.mosaicRefs,
    this.leading,
    this.onTap,
    this.onPlay,
    this.onMenu,
    this.selected = false,
    this.dragPayload,
    super.key,
  });

  /// The height of a row at text scale 1.0.
  static const double rowHeight = 56;

  /// The edge of a row's artwork.
  static const double artworkSize = 40;

  /// The key of the overflow button.
  static const Key overflowKey = Key('mediaRow.overflow');

  /// The key of the play button.
  static const Key playKey = Key('mediaRow.play');

  /// The height of a row at the ambient text scale: [rowHeight], or the
  /// two text lines when they need more.
  static double extentFor(BuildContext context) {
    final typography = context.typography;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle style) =>
        scaler.scale(style.fontSize!) * (style.height ?? 1);
    final content =
        line(typography.body) + line(typography.bodySmall) + Spacing.x8;
    return content > rowHeight ? content : rowHeight;
  }

  /// The first line, in `body`.
  final String title;

  /// The second line, in `bodySmall` and `contentSecondary`.
  final String? subtitle;

  /// The cover; null shows the artwork placeholder.
  final String? artworkRef;

  /// Square, or circle for artists.
  final ArtworkShape shape;

  /// Covers shown as a [MosaicArtwork] in place of [artworkRef], as for a
  /// playlist; null shows [artworkRef].
  final List<String>? mosaicRefs;

  /// A square of [artworkSize] shown in place of the artwork, such as the
  /// Liked Songs heart.
  final Widget? leading;

  /// Opens the item; null makes the row inert.
  final VoidCallback? onTap;

  /// Plays the item; null hides the play button.
  final VoidCallback? onPlay;

  /// Opens the item's menu, at the global pointer position for a secondary
  /// click; null hides the overflow button and leaves the gestures out.
  final void Function(Offset? position)? onMenu;

  /// Whether the row is the selected item of a two-pane list.
  final bool selected;

  /// What dragging the row carries; null starts no drag.
  final DragPayload? dragPayload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final l10n = AppLocalizations.of(context);
    final subtitle = this.subtitle;
    final onPlay = this.onPlay;
    final onMenu = this.onMenu;
    final radius = BorderRadius.circular(Radii.small);
    final artwork =
        leading ??
        switch (mosaicRefs) {
          final refs? => MosaicArtwork(refs: refs, size: artworkSize),
          null => Artwork(ref: artworkRef, size: artworkSize, shape: shape),
        };
    Widget row = Semantics(
      selected: selected ? true : null,
      customSemanticsActions: onMenu == null
          ? null
          : {
              CustomSemanticsAction(label: l10n.menuMoreOptions): () =>
                  onMenu(null),
            },
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? colors.surfaceActive : null,
          borderRadius: radius,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onMenu == null ? null : () => onMenu(null),
          onSecondaryTapUp: onMenu == null
              ? null
              : (details) => onMenu(details.globalPosition),
          hoverColor: colors.surfaceHover,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.x8,
              vertical: Spacing.x4,
            ),
            child: Row(
              children: [
                artwork,
                const SizedBox(width: Spacing.x12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.body.copyWith(color: colors.content),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodySmall.copyWith(
                            color: colors.contentSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onPlay != null)
                  _RowButton(
                    key: playKey,
                    tooltip: l10n.mediaCardPlay,
                    icon: Icons.play_arrow_rounded,
                    onPressed: (_) => onPlay(),
                  ),
                if (onMenu != null)
                  _RowButton(
                    key: overflowKey,
                    tooltip: l10n.menuMoreOptions,
                    icon: Icons.more_horiz_rounded,
                    onPressed: onMenu,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (onMenu != null) {
      row = Actions(
        actions: {
          OpenMenuIntent: CallbackAction<OpenMenuIntent>(
            onInvoke: (_) {
              final box = context.findRenderObject()! as RenderBox;
              onMenu(box.localToGlobal(box.size.bottomLeft(Offset.zero)));
              return null;
            },
          ),
        },
        child: row,
      );
    }
    return PointerDraggable(payload: dragPayload, child: row);
  }
}

/// A trailing button of a row, 48 px on touch input and 32 px with a
/// pointer (doc 09, Shape); [onPressed] gets the global bottom centre of
/// the button.
class _RowButton extends StatelessWidget {
  const new({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final void Function(Offset position) onPressed;

  @override
  Widget build(BuildContext context) {
    final size = usesPointerInput() ? Sizes.pointerTarget : Sizes.touchTarget;
    return IconButton(
      tooltip: tooltip,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      padding: EdgeInsets.zero,
      iconSize: 20,
      color: context.colors.contentSecondary,
      icon: Icon(icon),
      onPressed: () {
        final box = context.findRenderObject()! as RenderBox;
        onPressed(box.localToGlobal(box.size.bottomCenter(Offset.zero)));
      },
    );
  }
}
