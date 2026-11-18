// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart'
    show
        GestureMultiDragStartCallback,
        ImmediateMultiDragGestureRecognizer,
        MultiDragGestureRecognizer,
        PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/dnd/drag_payload.dart';

/// Makes [child] the source of an in-app drag of [payload] with a mouse or
/// trackpad (doc 09, Desktop Interaction: Drag and drop). Touch input never
/// starts a drag, so a long press keeps opening the menu. A null [payload]
/// returns [child].
///
/// The drag shows a [DragFeedbackChip] beside the pointer; targets read the
/// pointer position as the drag's offset.
class PointerDraggable extends StatelessWidget {
  /// Creates the drag source of [payload] around [child].
  const new({required this.payload, required this.child, super.key});

  /// What the drag carries; null makes [child] no drag source.
  final DragPayload? payload;

  /// The dragged widget.
  final Widget child;

  /// The pointer kinds that start a drag.
  static const Set<PointerDeviceKind> devices = {
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget build(BuildContext context) {
    final payload = this.payload;
    if (payload == null) return child;
    return _PointerOnlyDraggable(
      data: payload,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: DragFeedbackChip(payload: payload),
      child: child,
    );
  }
}

/// The chip that follows the pointer during a drag: the title for one track
/// or an album, "5 tracks" for several, on `surfaceOverlay`. It is left out
/// of the semantics tree.
class DragFeedbackChip extends StatelessWidget {
  /// Creates the chip of [payload].
  const new({required this.payload, super.key});

  /// What is dragged.
  final DragPayload payload;

  /// How far the chip sits from the pointer.
  static const Offset pointerGap = Offset(Spacing.x12, Spacing.x12);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = switch (payload) {
      TracksPayload(:final tracks) when tracks.length == 1 =>
        tracks.single.meta.title,
      TracksPayload(:final tracks) => AppLocalizations.of(
        context,
      ).dragTrackCount(tracks.length),
      AlbumPayload(:final title) => title,
    };
    final light = Theme.of(context).brightness == Brightness.light;
    return ExcludeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: Transform.translate(
          offset: pointerGap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceOverlay,
                borderRadius: BorderRadius.circular(Radii.small),
                border: Border.all(color: colors.line),
                boxShadow: light ? const [SoundspanShadows.raised] : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.x12,
                  vertical: Spacing.x8,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.body.copyWith(
                    color: colors.content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A [Draggable] whose recognizer only tracks [PointerDraggable.devices].
class _PointerOnlyDraggable extends Draggable<DragPayload> {
  const new({
    required super.child,
    required super.feedback,
    required DragPayload super.data,
    required super.dragAnchorStrategy,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) => ImmediateMultiDragGestureRecognizer(
    supportedDevices: PointerDraggable.devices,
  )..onStart = onStart;
}
