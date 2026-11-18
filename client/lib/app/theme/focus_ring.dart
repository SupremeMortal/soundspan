// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The visible focus ring (doc 09, Accessibility): 2 px of `brand`, 2 px
/// outside the focused control, in both themes, around whatever has
/// keyboard focus. It is drawn once for the whole app, over everything
/// below [child] (dialogs, sheets and menus included), so buttons, icon
/// buttons, track rows, cards, navigation items, chips, text fields,
/// sliders and menu items all get the same ring and nothing draws over it.
///
/// The ring shows only while focus came from the keyboard: the focus
/// manager is in [FocusHighlightMode.traditional] and the last input was a
/// key, not a pointer or a touch. Typing into a text field does not count
/// as keyboard navigation; only Tab does. It surrounds the primary focus,
/// or the whole field for a text field, and skips nodes that only hold
/// focus for a region (scopes and nodes that traversal skips) and text
/// fields that draw their own focused border.
class FocusRingLayer extends StatefulWidget {
  /// Draws the ring over [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  /// The key of the layer the ring is painted on.
  static const Key paintKey = Key('FocusRingLayer.paint');

  /// The ring's stroke width.
  static const double width = 2;

  /// The gap between the control and the ring.
  static const double offset = 2;

  /// The ring's corner radius, around the control's own corners.
  static const double radius = 8;

  @override
  State<FocusRingLayer> createState() => _FocusRingLayerState();
}

class _FocusRingLayerState extends State<FocusRingLayer> {
  final ValueNotifier<Rect?> _ring = ValueNotifier(null);

  /// Whether the last input was a key press.
  bool _keyboard = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance
      ..addListener(_update)
      ..addHighlightModeListener(_onHighlightMode);
    HardwareKeyboard.instance.addHandler(_onKey);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  @override
  void dispose() {
    FocusManager.instance
      ..removeListener(_update)
      ..removeHighlightModeListener(_onHighlightMode);
    HardwareKeyboard.instance.removeHandler(_onKey);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    _ring.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && !_keyboard && !_isTyping(event)) {
      _keyboard = true;
      _update();
    }
    return false;
  }

  /// Whether [event] edits the focused text field rather than moving focus.
  bool _isTyping(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.tab) return false;
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused != null &&
        focused.mounted &&
        focused.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent && _keyboard) {
      _keyboard = false;
      _update();
    }
  }

  void _onHighlightMode(FocusHighlightMode _) => _update();

  /// Places the ring now and after every frame while it shows, so it
  /// follows a control that scrolls or moves.
  void _update() {
    if (!mounted) return;
    _ring.value = _ringRect();
    if (_ring.value != null && !_scheduled) {
      _scheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        _update();
      });
    }
  }

  Rect? _ringRect() {
    if (!_keyboard ||
        FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return null;
    }
    final node = FocusManager.instance.primaryFocus;
    if (node == null ||
        node is FocusScopeNode ||
        node.skipTraversal ||
        !node.canRequestFocus) {
      return null;
    }
    final focused = node.context;
    if (focused == null || !focused.mounted) return null;
    final layer = context.findRenderObject();
    var target = focused.findRenderObject();
    // A text field's ring goes around the whole field, unless the field
    // already draws its own focused border.
    var ownBorder = false;
    focused.visitAncestorElements((element) {
      if (element.widget case InputDecorator(:final decoration)) {
        final border = decoration.focusedBorder;
        ownBorder = border != null && border.borderSide != BorderSide.none;
        target = element.findRenderObject();
        return false;
      }
      return element.widget is! FocusRingLayer;
    });
    if (ownBorder) return null;
    final box = target;
    if (layer is! RenderBox ||
        box is! RenderBox ||
        !box.attached ||
        !box.hasSize) {
      return null;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: layer);
    return (origin & box.size).inflate(
      FocusRingLayer.offset + FocusRingLayer.width / 2,
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    textDirection: TextDirection.ltr,
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                key: FocusRingLayer.paintKey,
                painter: _RingPainter(_ring, context.colors.brand),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _RingPainter extends CustomPainter {
  new(this.ring, this.color) : super(repaint: ring);

  final ValueListenable<Rect?> ring;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = ring.value;
    if (rect == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(FocusRingLayer.radius),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = FocusRingLayer.width,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ring != ring || old.color != color;
}
