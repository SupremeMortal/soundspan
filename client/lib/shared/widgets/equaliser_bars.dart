// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The "now playing" glyph of the playing row (doc 09, Components): three
/// vertical bars in [color] that rise and fall while [animate] is true and
/// stand still at fixed heights otherwise (paused, or reduced motion).
class EqualiserBars extends StatefulWidget {
  /// Creates the glyph, [size] logical pixels square.
  const new({
    required this.color,
    required this.animate,
    this.size = 16,
    super.key,
  });

  /// The bar colour.
  final Color color;

  /// Whether the bars move.
  final bool animate;

  /// The edge of the square the bars fill.
  final double size;

  /// The time of one full cycle of the bars.
  static const Duration period = Duration(milliseconds: 1200);

  @override
  State<EqualiserBars> createState() => _EqualiserBarsState();
}

class _EqualiserBarsState extends State<EqualiserBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: EqualiserBars.period,
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(EqualiserBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.animate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _BarsPainter(_controller, widget.color),
      ),
    ),
  );
}

class _BarsPainter extends CustomPainter {
  new(this._progress, this._color) : super(repaint: _progress);

  final Animation<double> _progress;
  final Color _color;

  /// The resting height of each bar, as a share of the glyph.
  static const List<double> _rest = [0.55, 1, 0.75];

  /// Where each bar starts in the cycle, so they move out of step.
  static const List<double> _phase = [0, 0.35, 0.7];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _color;
    final gap = size.width / 7;
    final width = (size.width - gap * 2) / 3;
    for (var bar = 0; bar < 3; bar++) {
      final share = _progress.value == 0
          ? _rest[bar]
          : 0.3 +
                0.7 *
                    (0.5 +
                            0.5 *
                                math.sin(
                                  2 * math.pi * (_progress.value + _phase[bar]),
                                ))
                        .abs();
      final height = size.height * share;
      final left = bar * (width + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - height, width, height),
          Radius.circular(width / 3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      oldDelegate._color != _color || oldDelegate._progress != _progress;
}
