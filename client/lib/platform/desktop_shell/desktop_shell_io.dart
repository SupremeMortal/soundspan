// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';
import 'package:window_manager/window_manager.dart';

/// The [DesktopShell] of the running app: [WindowManagerDesktopShell] on
/// Windows, Linux and macOS, a [NoopDesktopShell] on Android and iOS.
DesktopShell createDesktopShell() =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS
    ? WindowManagerDesktopShell()
    : const NoopDesktopShell();

/// A [DesktopShell] over `window_manager`'s current window, `screen_retriever`
/// displays and the runner's [singleInstanceChannel].
class WindowManagerDesktopShell implements DesktopShell {
  /// Creates the shell; [init] attaches it to the window.
  new();

  final StreamController<void> _geometry = StreamController.broadcast();
  final StreamController<void> _close = StreamController.broadcast();
  final StreamController<List<String>> _launches = StreamController.broadcast();

  Window? _window;

  Window get _current => _window ?? (throw StateError('init() not called'));

  /// Attaches to the window; a later call does nothing.
  @override
  Future<void> init() async {
    if (_window != null) return;
    final window = WindowManager.instance.getCurrent();
    if (window == null) throw StateError('the app has no window');
    _window = window;
    window.addListener((event) {
      switch (event) {
        case WindowMovedEvent() ||
            WindowResizedEvent() ||
            WindowMaximizedEvent() ||
            WindowRestoredEvent():
          _geometry.add(null);
        case WindowCloseRequestedEvent():
          _close.add(null);
        default:
          break;
      }
    });
    const MethodChannel(singleInstanceChannel)
        .setMethodCallHandler((call) async {
          if (call.method != secondInstanceMethod) return;
          final args = call.arguments;
          _launches.add([
            if (args is List)
              for (final arg in args)
                if (arg is String) arg,
          ]);
        });
  }

  @override
  Future<void> setMinimumSize(Size size) async =>
      _current.minimumSize = size.toNative();

  @override
  Future<WindowBounds?> getBounds() async {
    final rect = _current.bounds.toRect();
    return WindowBounds(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
    );
  }

  @override
  Future<void> setBounds(WindowBounds bounds) async =>
      _current.bounds = Rect.fromLTWH(
        bounds.left,
        bounds.top,
        bounds.width,
        bounds.height,
      ).toNative();

  @override
  Future<bool> isMaximized() async => _current.isMaximized;

  @override
  Future<void> maximize() async => _current.maximize();

  @override
  Future<void> showAndFocus() async {
    final window = _current;
    if (window.isMinimized) window.restore();
    window
      ..show()
      ..focus();
  }

  @override
  Future<List<Rect>> displayAreas() async {
    final displays = DisplayManager.instance.getAll();
    return [
      for (final display in displays)
        if (display.isPrimary) display.workArea.toRect(),
      for (final display in displays)
        if (!display.isPrimary) display.workArea.toRect(),
    ];
  }

  @override
  Stream<void> get geometryChanges => _geometry.stream;

  @override
  Stream<void> get closeRequests => _close.stream;

  @override
  Stream<List<String>> get secondInstanceLaunches => _launches.stream;
}
