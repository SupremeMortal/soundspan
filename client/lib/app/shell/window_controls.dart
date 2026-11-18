// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/caption_colors.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

/// How the window buttons look.
enum WindowControlsStyle {
  /// Always-visible circles with stroke icons, as Breeze draws them.
  linux,

  /// Flat 46 × 32 rectangles flush with the top edge, as Windows draws
  /// them.
  windows;

  /// The style of [platform]: Windows' on Windows, the circles elsewhere.
  static WindowControlsStyle of(TargetPlatform platform) =>
      platform == TargetPlatform.windows
      ? WindowControlsStyle.windows
      : WindowControlsStyle.linux;
}

/// Which end of a title bar a group of window buttons sits at.
enum WindowControlsSide {
  /// Before the wordmark.
  leading,

  /// After the avatar.
  trailing,
}

/// One group of window buttons drawn by the app in its top bar (doc 09,
/// Top Bar): minimise, maximise or restore, and close, in the order of
/// [buttons]. Each button calls the matching [DesktopShell] member; close
/// goes through [DesktopShell.close], the path of the system's close
/// button.
///
/// The group dims while the window is not focused and shows restore while
/// it is maximised. It owns its distance from the window edge.
class WindowControls extends ConsumerWidget {
  /// Creates the group.
  const new({
    required this.buttons,
    required this.state,
    required this.side,
    required this.height,
    this.style,
    super.key,
  });

  /// The buttons, in order.
  final List<WindowButton> buttons;

  /// The window state shown.
  final WindowChromeState state;

  /// Which end of the bar the group sits at.
  final WindowControlsSide side;

  /// The height of the bar the group sits in.
  final double height;

  /// The look; the platform's when null.
  final WindowControlsStyle? style;

  /// The diameter of a Linux circle.
  static const double circleSize = 22;

  /// The distance between the centres of two Linux circles.
  static const double circlePitch = 33;

  /// The padding between a Linux group and the window edge, so the circles
  /// land about 7 px from it.
  static const double circleEdgePadding = 2;

  /// The size of a Windows button.
  static const Size rectSize = Size(46, 32);

  /// The opacity of the group while the window is not focused.
  static const double unfocusedOpacity = 0.45;

  /// The key of [button]'s control.
  static Key buttonKey(WindowButton button) =>
      ValueKey<String>('window.${button.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shell = ref.watch(desktopShellProvider);
    final style = this.style ?? WindowControlsStyle.of(defaultTargetPlatform);
    final children = [
      for (final button in buttons)
        _CaptionButton(
          key: buttonKey(button),
          button: button,
          maximized: state.maximized,
          style: style,
          label: switch (button) {
            WindowButton.minimize => l10n.windowMinimize,
            WindowButton.maximize when state.maximized => l10n.windowRestore,
            WindowButton.maximize => l10n.windowMaximize,
            WindowButton.close => l10n.windowClose,
          },
          onPressed: () => unawaited(switch (button) {
            WindowButton.minimize => shell.minimize(),
            WindowButton.maximize => shell.toggleMaximize(),
            WindowButton.close => shell.close(),
          }),
        ),
    ];
    final group = switch (style) {
      WindowControlsStyle.linux => Padding(
        padding: EdgeInsetsDirectional.only(
          start: side == WindowControlsSide.leading ? circleEdgePadding : 0,
          end: side == WindowControlsSide.trailing ? circleEdgePadding : 0,
        ),
        child: SizedBox(
          height: height,
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
      WindowControlsStyle.windows => SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.topCenter,
          widthFactor: 1,
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    };
    return AnimatedOpacity(
      opacity: state.focused ? 1 : unfocusedOpacity,
      duration: const Duration(milliseconds: 150),
      child: group,
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const new({
    required this.button,
    required this.maximized,
    required this.style,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final WindowButton button;
  final bool maximized;
  final WindowControlsStyle style;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final caption = context.captionColors;
    final close = widget.button == WindowButton.close;
    final glyph = switch (widget.button) {
      WindowButton.minimize => _Glyph.minimize,
      WindowButton.maximize when widget.maximized => _Glyph.restore,
      WindowButton.maximize => _Glyph.maximize,
      WindowButton.close => _Glyph.close,
    };
    final linux = widget.style == WindowControlsStyle.linux;
    final Color fill;
    if (close && _pressed) {
      fill = linux ? caption.closePressed : caption.rectClosePressed;
    } else if (close && _hovered) {
      fill = linux ? caption.close : caption.rectClose;
    } else if (_pressed) {
      fill = linux ? caption.pressed : caption.rectPressed;
    } else if (_hovered) {
      fill = linux ? caption.hover : caption.rectHover;
    } else {
      fill = linux ? caption.fill : Colors.transparent;
    }
    final glyphColor = close && (_hovered || _pressed)
        ? caption.onClose
        : colors.content;
    final painter = _GlyphPainter(glyph, glyphColor, widget.style);
    final Widget face;
    final Size size;
    if (linux) {
      size = const Size.square(WindowControls.circlePitch);
      face = Center(
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: SizedBox.square(
            dimension: WindowControls.circleSize,
            child: Center(
              child: CustomPaint(
                size: const Size.square(_GlyphPainter.linuxSize),
                painter: painter,
              ),
            ),
          ),
        ),
      );
    } else {
      size = WindowControls.rectSize;
      face = ColoredBox(
        color: fill,
        child: Center(
          child: CustomPaint(
            size: const Size.square(_GlyphPainter.windowsSize),
            painter: painter,
          ),
        ),
      );
    }
    return Tooltip(
      message: widget.label,
      excludeFromSemantics: true,
      child: Semantics(
        label: widget.label,
        button: true,
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: InkWell(
          onTap: widget.onPressed,
          onHover: (hovered) => setState(() => _hovered = hovered),
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          customBorder: linux ? const CircleBorder() : null,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          mouseCursor: SystemMouseCursors.basic,
          child: SizedBox.fromSize(size: size, child: face),
        ),
      ),
    );
  }
}

enum _Glyph { minimize, maximize, restore, close }

/// Draws a caption glyph: 12 px rounded strokes on Linux (chevron down,
/// chevron up, the restore diamond, ×), 10 px hairlines on Windows (line,
/// square, two squares, ×).
class _GlyphPainter extends CustomPainter {
  const new(this.glyph, this.color, this.style);

  static const double linuxSize = 12;
  static const double windowsSize = 10;

  final _Glyph glyph;
  final Color color;
  final WindowControlsStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final linux = style == WindowControlsStyle.linux;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = linux ? 1.5 : 1
      ..strokeCap = linux ? StrokeCap.round : StrokeCap.square
      ..strokeJoin = linux ? StrokeJoin.round : StrokeJoin.miter
      ..isAntiAlias = true;
    final s = size.width;
    final path = Path();
    // Linux glyphs are drawn on a unit square scaled to the glyph size.
    void move(double x, double y) => path.moveTo(x * s, y * s);
    void line(double x, double y) => path.lineTo(x * s, y * s);
    if (linux) {
      switch (glyph) {
        case _Glyph.minimize:
          move(0.17, 0.38);
          line(0.5, 0.71);
          line(0.83, 0.38);
        case _Glyph.maximize:
          move(0.17, 0.62);
          line(0.5, 0.29);
          line(0.83, 0.62);
        case _Glyph.restore:
          move(0.5, 0.17);
          line(0.83, 0.5);
          line(0.5, 0.83);
          line(0.17, 0.5);
          path.close();
        case _Glyph.close:
          move(0.25, 0.25);
          line(0.75, 0.75);
          move(0.75, 0.25);
          line(0.25, 0.75);
      }
    } else {
      switch (glyph) {
        case _Glyph.minimize:
          // On a pixel row, not between two.
          path
            ..moveTo(0, s / 2 - 0.5)
            ..lineTo(s, s / 2 - 0.5);
        case _Glyph.maximize:
          path.addRect(Rect.fromLTWH(0.5, 0.5, s - 1, s - 1));
        case _Glyph.restore:
          path
            ..addRect(Rect.fromLTWH(0.5, 2.5, s - 3, s - 3))
            ..moveTo(2.5, 2.5)
            ..lineTo(2.5, 0.5)
            ..lineTo(s - 0.5, 0.5)
            ..lineTo(s - 0.5, s - 2.5)
            ..lineTo(s - 2.5, s - 2.5);
        case _Glyph.close:
          path
            ..moveTo(0, 0)
            ..lineTo(s, s)
            ..moveTo(s, 0)
            ..lineTo(0, s);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.style != style;
}
