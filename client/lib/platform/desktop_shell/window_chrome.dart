// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The window buttons the app draws in its top bar and the window state
/// they show (doc 10, Linux and Windows).
library;

import 'package:flutter/foundation.dart' show immutable, listEquals;

/// A button of the window's title bar.
enum WindowButton {
  /// Minimises the window.
  minimize,

  /// Maximises the window, or restores it while maximised.
  maximize,

  /// Closes the window.
  close,
}

/// The window buttons in order, split by the side of the top bar they sit
/// on.
@immutable
final class WindowButtonLayout {
  /// Creates a layout with [leading] buttons before the wordmark and
  /// [trailing] buttons after the avatar.
  const new({this.leading = const [], this.trailing = const []});

  /// Reads GTK's `gtk-decoration-layout` setting, such as
  /// `icon:minimize,maximize,close`: the buttons before the colon go to the
  /// leading side, the ones after it to the trailing side, and without a
  /// colon every button is leading. Entries other than `minimize`,
  /// `maximize` and `close` are ignored, and a button named twice keeps its
  /// first place. An empty [value] gives [standard].
  factory parse(String value) {
    if (value.trim().isEmpty) return standard;
    final colon = value.indexOf(':');
    final before = colon < 0 ? value : value.substring(0, colon);
    final after = colon < 0 ? '' : value.substring(colon + 1);
    final seen = <WindowButton>{};
    List<WindowButton> side(String part) => [
      for (final name in part.split(RegExp('[,:]')))
        if (_byName[name.trim()] case final button?)
          if (seen.add(button)) button,
    ];
    final leading = side(before);
    return WindowButtonLayout(leading: leading, trailing: side(after));
  }

  static const Map<String, WindowButton> _byName = {
    'minimize': WindowButton.minimize,
    'maximize': WindowButton.maximize,
    'close': WindowButton.close,
  };

  /// No buttons: macOS (native traffic lights), mobile and the web.
  static const WindowButtonLayout none = WindowButtonLayout();

  /// Minimise, maximise and close at the trailing end: the layout of
  /// Windows, and of Linux when the desktop's layout cannot be read.
  static const WindowButtonLayout standard = WindowButtonLayout(
    trailing: [
      WindowButton.minimize,
      WindowButton.maximize,
      WindowButton.close,
    ],
  );

  /// The buttons before the wordmark, in order.
  final List<WindowButton> leading;

  /// The buttons after the avatar, in order.
  final List<WindowButton> trailing;

  /// Whether there is no button on either side.
  bool get isEmpty => leading.isEmpty && trailing.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is WindowButtonLayout &&
      listEquals(other.leading, leading) &&
      listEquals(other.trailing, trailing);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(leading), Object.hashAll(trailing));

  @override
  String toString() =>
      'WindowButtonLayout(${leading.map((b) => b.name).join(',')}:'
      '${trailing.map((b) => b.name).join(',')})';
}

/// The window state the title bar shows.
@immutable
final class WindowChromeState {
  /// Creates the state.
  const new({
    this.maximized = false,
    this.fullscreen = false,
    this.focused = true,
  });

  /// Whether the window is maximised; maximise then shows restore.
  final bool maximized;

  /// Whether the window fills the screen; the buttons are then hidden.
  final bool fullscreen;

  /// Whether the window has focus; the buttons dim without it.
  final bool focused;

  @override
  bool operator ==(Object other) =>
      other is WindowChromeState &&
      other.maximized == maximized &&
      other.fullscreen == fullscreen &&
      other.focused == focused;

  @override
  int get hashCode => Object.hash(maximized, fullscreen, focused);

  @override
  String toString() =>
      'WindowChromeState(maximized: $maximized, fullscreen: $fullscreen, '
      'focused: $focused)';
}
