// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

/// A titled, horizontal row of [MediaCard]s (doc 09, Components).
///
/// The header has the [title] and, with [onShowAll], a "Show all" button.
/// Cards are [cardWidth] wide and built lazily; their artwork lines up with
/// the header at the page gutter of the window class. On desktop, or once a
/// mouse has been seen, previous and next arrows page by the visible width
/// and are disabled at the ends; they stay when the pointer leaves the window
/// (Linux reports that as the mouse disconnecting), so the header never
/// changes height. On touch the row snaps to cards. A shelf with no items
/// renders nothing.
class Shelf extends StatefulWidget {
  /// Creates a shelf titled [title] of [itemCount] cards built by
  /// [itemBuilder].
  const new({
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.onShowAll,
    super.key,
  });

  /// The section header.
  final String title;

  /// How many cards the shelf has.
  final int itemCount;

  /// Builds the card at an index; it is given [cardWidth].
  final IndexedWidgetBuilder itemBuilder;

  /// Opens the whole section; null hides "Show all".
  final VoidCallback? onShowAll;

  /// The width of each card.
  static const double cardWidth = 160;

  @override
  State<Shelf> createState() => _ShelfState();
}

class _ShelfState extends State<Shelf> {
  final ScrollController _controller = ScrollController();
  final MouseTracker _mouseTracker = RendererBinding.instance.mouseTracker;
  late bool _mouse = _isDesktop || _mouseTracker.mouseIsConnected;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncEnds);
    _mouseTracker.addListener(_syncMouse);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEnds());
  }

  @override
  void dispose() {
    _mouseTracker.removeListener(_syncMouse);
    _controller.dispose();
    super.dispose();
  }

  static bool get _isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    _ => false,
  };

  /// Latches on: a mouse leaving the window must not hide the arrows.
  void _syncMouse() {
    if (!mounted || _mouse || !_mouseTracker.mouseIsConnected) return;
    setState(() => _mouse = true);
  }

  void _syncEnds() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    final back = position.pixels > position.minScrollExtent + _epsilon;
    final forward = position.pixels < position.maxScrollExtent - _epsilon;
    if (back == _canGoBack && forward == _canGoForward) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  Future<void> _page(int direction) async {
    final position = _controller.position;
    final target = (position.pixels + direction * position.viewportDimension)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    final duration = Motion.of(context, Motion.emphasized);
    if (duration == Duration.zero) {
      _controller.jumpTo(target);
    } else {
      await _controller.animateTo(
        target,
        duration: duration,
        curve: Motion.curve,
      );
    }
  }

  static const double _epsilon = 0.5;

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final gutter = switch (WindowClass.of(context)) {
      WindowClass.compact => Gutters.compact,
      WindowClass.medium => Gutters.medium,
      WindowClass.expanded => Gutters.expanded,
    };
    final onShowAll = widget.onShowAll;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.title.copyWith(
                      color: colors.content,
                    ),
                  ),
                ),
              ),
              if (onShowAll != null)
                TextButton(
                  onPressed: onShowAll,
                  child: Text(l10n.shelfShowAll),
                ),
              if (_mouse) ...[
                IconButton(
                  onPressed: _canGoBack ? () => _page(-1) : null,
                  tooltip: l10n.shelfScrollBack,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  onPressed: _canGoForward ? () => _page(1) : null,
                  tooltip: l10n.shelfScrollForward,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.x8),
        SizedBox(
          height: MediaCard.extentFor(context, width: Shelf.cardWidth),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              _syncEnds();
              return false;
            },
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: gutter - MediaCard.padding,
              ),
              itemExtent: Shelf.cardWidth,
              physics: _mouse
                  ? null
                  : const _SnapScrollPhysics(extent: Shelf.cardWidth),
              itemCount: widget.itemCount,
              itemBuilder: widget.itemBuilder,
            ),
          ),
        ),
      ],
    );
  }
}

/// Settles a scroll on a multiple of [extent], so a flung row stops with a
/// card at the leading edge.
class _SnapScrollPhysics extends ScrollPhysics {
  const new({required this.extent, super.parent});

  final double extent;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapScrollPhysics(extent: extent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    var page = position.pixels / extent;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    final target = (page.roundToDouble() * extent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
