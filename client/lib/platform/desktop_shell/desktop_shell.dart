// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The window seam of the desktop app (doc 02, Platform Seams; doc 10).
///
/// `createDesktopShell()` returns the `window_manager` implementation on
/// Windows, Linux and macOS, and a no-op on Android, iOS and web.
library;

import 'dart:ui' show Rect, Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart'
    show WindowBounds;
import 'package:soundspan/platform/desktop_shell/desktop_shell_web.dart'
    if (dart.library.io) 'package:soundspan/platform/desktop_shell/desktop_shell_io.dart';

export 'package:soundspan/core/storage/app/app_settings_store.dart'
    show WindowBounds;

export 'desktop_shell_web.dart'
    if (dart.library.io) 'desktop_shell_io.dart'
    show createDesktopShell;

/// The method channel on which the native runner forwards a second launch
/// (Windows `WM_COPYDATA`, Linux `GApplication` activate and open).
const String singleInstanceChannel = 'io.soundspan.app/single_instance';

/// The method of [singleInstanceChannel]; its argument is the second
/// launch's argument list.
const String secondInstanceMethod = 'secondInstance';

/// The app's top-level window: geometry, visibility and second launches.
abstract interface class DesktopShell {
  /// Prepares the window plugin; called once before any other member.
  Future<void> init();

  /// Stops the window from becoming smaller than [size].
  Future<void> setMinimumSize(Size size);

  /// The window's normal (not maximized) bounds, or null when unknown.
  Future<WindowBounds?> getBounds();

  /// Moves and resizes the window to [bounds].
  Future<void> setBounds(WindowBounds bounds);

  /// Whether the window is maximized.
  Future<bool> isMaximized();

  /// Maximizes the window.
  Future<void> maximize();

  /// Shows the window, restores it if minimized, and gives it focus.
  Future<void> showAndFocus();

  /// The visible areas of every connected display; the primary first.
  Future<List<Rect>> displayAreas();

  /// Emits when the window was moved, resized, maximized or restored.
  Stream<void> get geometryChanges;

  /// Emits when the user asked to close the window.
  Stream<void> get closeRequests;

  /// Emits the argument list of each later launch of the app.
  Stream<List<String>> get secondInstanceLaunches;
}

/// A [DesktopShell] that does nothing: Android, iOS and web.
class NoopDesktopShell implements DesktopShell {
  /// Creates the no-op shell.
  const new();

  @override
  Future<void> init() async {}

  @override
  Future<void> setMinimumSize(Size size) async {}

  @override
  Future<WindowBounds?> getBounds() async => null;

  @override
  Future<void> setBounds(WindowBounds bounds) async {}

  @override
  Future<bool> isMaximized() async => false;

  @override
  Future<void> maximize() async {}

  @override
  Future<void> showAndFocus() async {}

  @override
  Future<List<Rect>> displayAreas() async => const [];

  @override
  Stream<void> get geometryChanges => const Stream.empty();

  @override
  Stream<void> get closeRequests => const Stream.empty();

  @override
  Stream<List<String>> get secondInstanceLaunches => const Stream.empty();
}

/// The app's [DesktopShell]; tests override it.
final Provider<DesktopShell> desktopShellProvider = Provider<DesktopShell>(
  (ref) => createDesktopShell(),
);
