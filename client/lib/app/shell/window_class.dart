// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/widgets.dart';

/// The layout class of the window (doc 02, Adaptive Layout). Screens read it
/// with [WindowClass.of], never from the `MediaQuery` width.
enum WindowClass {
  /// Narrower than 600 logical pixels.
  compact,

  /// 600 to 1023 logical pixels wide.
  medium,

  /// 1024 logical pixels wide or more.
  expanded;

  /// The class set by the nearest [WindowClassScope].
  ///
  /// Throws a [FlutterError] when there is none.
  static WindowClass of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WindowClassScope>();
    if (scope == null) {
      throw FlutterError('WindowClass.of() called outside a WindowClassScope');
    }
    return scope.windowClass;
  }
}

/// The [WindowClass] of a window of [size].
WindowClass windowClassOf(Size size) => switch (size.width) {
  < 600 => WindowClass.compact,
  < 1024 => WindowClass.medium,
  _ => WindowClass.expanded,
};

/// Provides the [WindowClass] to its descendants. The shell sets it once,
/// from its layout constraints.
class WindowClassScope extends InheritedWidget {
  /// Provides [windowClass] to [child].
  const new({required this.windowClass, required super.child, super.key});

  /// The class of the window.
  final WindowClass windowClass;

  @override
  bool updateShouldNotify(WindowClassScope oldWidget) =>
      oldWidget.windowClass != windowClass;
}
