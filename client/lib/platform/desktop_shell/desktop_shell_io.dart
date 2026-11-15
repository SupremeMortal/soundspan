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

  /// Bounds requested while the window was hidden on Linux, re-applied when
  /// the shown window measures its decorations.
  WindowBounds? _hiddenRequest;

  /// Counts [setBounds] calls, so a later request wins over a pending
  /// re-application.
  int _requests = 0;

  /// How long [showAndFocus] waits for a shown window's decorations.
  static const Duration _decorationsTimeout = Duration(milliseconds: 600);

  /// How often a hidden request is re-applied at most.
  static const int _maxReapplies = 3;

  /// How long a re-application is given to land before the next one.
  static const Duration _reapplyGap = Duration(milliseconds: 120);

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

  /// Moves and resizes the window. On Linux the window manager's title bar
  /// cannot be measured while the window is hidden, so a request made then
  /// sizes the content, not the frame; [showAndFocus] re-applies it once
  /// the shown window measures them.
  @override
  Future<void> setBounds(WindowBounds bounds) async {
    _requests++;
    final window = _current;
    _hiddenRequest = Platform.isLinux && !window.isVisible ? bounds : null;
    _apply(window, bounds);
  }

  static void _apply(Window window, WindowBounds bounds) =>
      window.bounds = Rect.fromLTWH(
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
    final request = _hiddenRequest;
    _hiddenRequest = null;
    if (request != null) unawaited(_reapplyWhenDecorated(window, request));
  }

  /// Waits until the shown [window] has a frame larger than its content and
  /// re-applies [request] while the frame's size is not the requested one:
  /// at most [_maxReapplies] times, [_reapplyGap] apart, so a resize the
  /// window manager has half applied is not taken for the result.
  /// A window without decorations, or a later [setBounds], ends the wait.
  Future<void> _reapplyWhenDecorated(
    Window window,
    WindowBounds request,
  ) async {
    final generation = _requests;
    final deadline = DateTime.now().add(_decorationsTimeout);
    var reapplies = 0;
    DateTime? lastApplied;
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (generation != _requests) return;
      final frame = window.bounds;
      final content = window.contentBounds;
      if (frame.width == content.width && frame.height == content.height) {
        continue;
      }
      if ((frame.width - request.width).abs() <= 2 &&
          (frame.height - request.height).abs() <= 2) {
        return;
      }
      if (reapplies >= _maxReapplies) return;
      final now = DateTime.now();
      if (lastApplied != null && now.difference(lastApplied) < _reapplyGap) {
        continue;
      }
      _apply(window, request);
      reapplies++;
      lastApplied = now;
    }
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
