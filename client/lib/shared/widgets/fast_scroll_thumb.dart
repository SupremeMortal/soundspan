// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

/// A fast-scroll thumb over the trailing edge of the vertical scroll view
/// [child], driven by [controller] (doc 09, Library: Songs).
///
/// When [enabled], a [thumbHeight] thumb appears while [child] scrolls and
/// for [visibleFor] after. Dragging it scrolls proportionally through the
/// whole scroll extent, and a bubble beside it shows [bubbleLabel], rebuilt
/// whenever [labelChanges] notifies. [onDraggingChanged] reports when a
/// drag starts and ends. The thumb and the bubble are left out of the
/// semantics tree: screen-reader users scroll the list itself.
class FastScrollThumb extends StatefulWidget {
  /// Creates a thumb over [child].
  const new({
    required this.controller,
    required this.child,
    this.enabled = true,
    this.bubbleLabel,
    this.labelChanges,
    this.onDraggingChanged,
    super.key,
  });

  /// The controller of [child]'s scroll view.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// Whether the thumb is offered at all.
  final bool enabled;

  /// The text of the bubble shown while dragging; no bubble when null.
  final String Function()? bubbleLabel;

  /// Notifies when [bubbleLabel] may answer something else.
  final Listenable? labelChanges;

  /// Called with true when a drag of the thumb starts and false when it
  /// ends.
  final ValueChanged<bool>? onDraggingChanged;

  /// The height of the thumb.
  static const double thumbHeight = 48;

  /// The width of the thumb's touch area.
  static const double touchWidth = 32;

  /// The width of the drawn thumb.
  static const double thumbWidth = 6;

  /// How long the thumb stays after scrolling stops.
  static const Duration visibleFor = Duration(milliseconds: 1500);

  /// The key of the thumb.
  static const Key thumbKey = Key('fastScroll.thumb');

  /// The key of the bubble.
  static const Key bubbleKey = Key('fastScroll.bubble');

  @override
  State<FastScrollThumb> createState() => _FastScrollThumbState();
}

class _FastScrollThumbState extends State<FastScrollThumb> {
  bool _visible = false;
  bool _dragging = false;
  double _dragTop = 0;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        !widget.enabled) {
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      if (!_visible) setState(() => _visible = true);
      _scheduleHide();
    }
    return false;
  }

  void _scheduleHide() {
    _hide?.cancel();
    if (_dragging) return;
    _hide = Timer(FastScrollThumb.visibleFor, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  /// The top of the thumb in a track of [track] for the current position.
  double _thumbTop(ScrollPosition position, double track) {
    final max = position.maxScrollExtent - position.minScrollExtent;
    if (max <= 0) return 0;
    final fraction = ((position.pixels - position.minScrollExtent) / max).clamp(
      0.0,
      1.0,
    );
    return fraction * track;
  }

  void _dragStart(double track) {
    _hide?.cancel();
    _dragTop = _thumbTop(widget.controller.position, track);
    setState(() => _dragging = true);
    widget.onDraggingChanged?.call(true);
  }

  void _dragUpdate(double dy, double track) {
    final position = widget.controller.position;
    _dragTop = (_dragTop + dy).clamp(0.0, track);
    final fraction = track <= 0 ? 0.0 : _dragTop / track;
    position.jumpTo(
      position.minScrollExtent +
          fraction * (position.maxScrollExtent - position.minScrollExtent),
    );
  }

  void _dragEnd() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    widget.onDraggingChanged?.call(false);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final list = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
    final shown = widget.enabled && (_visible || _dragging);
    return LayoutBuilder(
      builder: (context, constraints) {
        final track = math.max<double>(
          0,
          constraints.maxHeight - FastScrollThumb.thumbHeight,
        );
        return Stack(
          children: [
            Positioned.fill(child: list),
            if (shown)
              ExcludeSemantics(
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.controller,
                    ?widget.labelChanges,
                  ]),
                  builder: (context, _) {
                    if (!widget.controller.hasClients) {
                      return const SizedBox.shrink();
                    }
                    final top = _dragging
                        ? _dragTop
                        : _thumbTop(widget.controller.position, track);
                    return _ThumbAndBubble(
                      top: top,
                      label: _dragging ? widget.bubbleLabel?.call() : null,
                      onDragStart: () => _dragStart(track),
                      onDragUpdate: (dy) => _dragUpdate(dy, track),
                      onDragEnd: _dragEnd,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The thumb at [top] on the trailing edge and, with a [label], the bubble
/// beside it.
class _ThumbAndBubble extends StatelessWidget {
  const new({
    required this.top,
    required this.label,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double top;
  final String? label;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = this.label;
    return Stack(
      children: [
        if (label != null)
          PositionedDirectional(
            key: FastScrollThumb.bubbleKey,
            top: top,
            end: FastScrollThumb.touchWidth + Spacing.x8,
            height: FastScrollThumb.thumbHeight,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.surfaceOverlay,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.large),
                  side: BorderSide(color: colors.line),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.x16),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: context.typography.title.tabular.copyWith(
                      color: colors.content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          top: top,
          end: 0,
          width: FastScrollThumb.touchWidth,
          height: FastScrollThumb.thumbHeight,
          child: GestureDetector(
            key: FastScrollThumb.thumbKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onVerticalDragStart: (_) => onDragStart(),
            onVerticalDragUpdate: (details) => onDragUpdate(details.delta.dy),
            onVerticalDragEnd: (_) => onDragEnd(),
            onVerticalDragCancel: onDragEnd,
            child: Center(
              child: SizedBox(
                width: FastScrollThumb.thumbWidth,
                height: FastScrollThumb.thumbHeight,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.contentSecondary,
                    shape: Radii.pill,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
