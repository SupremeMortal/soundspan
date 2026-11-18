// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';

/// The [DesktopShell] of the running app: [WindowManagerDesktopShell] on
/// Windows, Linux and macOS, a [NoopDesktopShell] on Android and iOS.
DesktopShell createDesktopShell() =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS
    ? WindowManagerDesktopShell()
    : const NoopDesktopShell();

/// A [DesktopShell] over `window_manager`'s current window, `screen_retriever`
/// displays, a `tray_manager` icon and the runner's [singleInstanceChannel].
class WindowManagerDesktopShell implements DesktopShell {
  /// Creates the shell; [init] attaches it to the window.
  new();

  final StreamController<void> _geometry = StreamController.broadcast();
  final StreamController<void> _close = StreamController.broadcast();
  final StreamController<List<String>> _launches = StreamController.broadcast();
  final StreamController<TrayCommand> _tray = StreamController.broadcast();

  Window? _window;

  /// Whether a close request is cancelled before [closeRequests] emits.
  bool _preventClose = false;

  /// Whether [quit] closes the window, so its close request is let through.
  bool _quitting = false;

  /// The tray icon, once [initTray] created it.
  tray.TrayIcon? _trayIcon;

  /// The menu shown and its items, kept alive while the menu is shown.
  List<Object> _menu = const [];

  /// The tray icon of Windows, a light glyph for the dark taskbar.
  static const String _windowsTrayIcon = 'assets/brand/tray/tray_dark_32.png';

  /// The tray icon of Linux, a light glyph for the usual dark panels.
  static const String _linuxTrayIcon = 'assets/brand/tray/tray_dark_22.png';

  /// The service names of a StatusNotifier watcher (KDE's and the one
  /// GNOME's AppIndicator extension also registers).
  static const List<String> _watchers = [
    'org.kde.StatusNotifierWatcher',
    'com.canonical.StatusNotifierWatcher',
  ];

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
        case WindowCloseRequestedEvent(:final request):
          if (_quitting) return;
          if (_preventClose) request.cancel();
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

  @override
  Future<void> setPreventClose(bool prevent) async => _preventClose = prevent;

  @override
  Future<void> hide() async => _current.hide();

  @override
  Future<void> minimize() async => _current.minimize();

  /// Closes the window with its close request let through, which ends the
  /// runner; where the window cannot be closed, exits the process.
  @override
  Future<void> quit() async {
    _quitting = true;
    _trayIcon?.setVisible(false);
    if (Window.isCloseSupported() && _current.close()) return;
    exit(0);
  }

  @override
  Future<void> setTitle(String title) async => _current.title = title;

  /// Creates the tray icon on Windows, and on Linux when a StatusNotifier
  /// host answers; false on macOS (doc 10: the Dock keeps the app).
  @override
  Future<bool> initTray() async {
    if (_trayIcon != null) return true;
    final String asset;
    if (Platform.isWindows) {
      asset = _windowsTrayIcon;
    } else if (Platform.isLinux) {
      if (!await _hasStatusNotifierHost()) return false;
      asset = _linuxTrayIcon;
    } else {
      return false;
    }
    if (!tray.TrayManager.instance.isSupported()) return false;
    final icon = tray.TrayIcon.create();
    if (icon == null) return false;
    final image = tray.ImageAsset.fromAsset(asset);
    if (image != null) icon.icon = image;
    icon
      ..setContextMenuTrigger(tray.ContextMenuTrigger.rightClicked)
      ..addListener((event) {
        if (event is tray.TrayIconClickedEvent) {
          _tray.add(TrayCommand.showWindow);
        }
      })
      ..setVisible(true);
    _trayIcon = icon;
    return true;
  }

  /// How long [statusNotifierHostRegistered] waits for the session bus.
  /// `bootstrap` awaits the tray in step 5, before the first frame, so a
  /// bus that does not answer must not hold the app up (doc 10).
  static const Duration statusNotifierTimeout = Duration(seconds: 2);

  static Future<bool> _hasStatusNotifierHost() =>
      statusNotifierHostRegistered(DBusClient.session());

  /// Whether a StatusNotifier watcher on [client]'s bus has a host
  /// registered, so a tray icon is shown. A bus that fails, or does not
  /// answer within [timeout], has none. [client] is closed afterwards.
  @visibleForTesting
  static Future<bool> statusNotifierHostRegistered(
    DBusClient client, {
    Duration timeout = statusNotifierTimeout,
  }) async {
    Future<bool> lookup() async {
      for (final name in _watchers) {
        if (!await client.nameHasOwner(name)) continue;
        final registered = await DBusRemoteObject(
          client,
          name: name,
          path: DBusObjectPath('/StatusNotifierWatcher'),
        ).getProperty(name, 'IsStatusNotifierHostRegistered');
        if (registered is DBusBoolean && registered.value) return true;
      }
      return false;
    }

    try {
      return await lookup().timeout(timeout, onTimeout: () => false);
    } on Object {
      return false;
    } finally {
      // A bus that did not answer may not answer the close either.
      unawaited(client.close().catchError((Object _) {}));
    }
  }

  @override
  Future<void> setTray(TrayModel model) async {
    final icon = _trayIcon;
    if (icon == null) return;
    final menu = tray.Menu.create();
    if (menu == null) return;
    final items = <tray.MenuItem>[];
    for (final entry in model.entries) {
      final item = tray.MenuItem.createWithLabelAndType(
        entry.label,
        tray.MenuItemType.normal,
      );
      if (item == null) continue;
      item.isEnabled = entry.enabled;
      final command = entry.command;
      if (command != null) {
        item.addListener((event) {
          if (event is tray.MenuItemClickedEvent) _tray.add(command);
        });
      }
      menu.addItem(item);
      items.add(item);
    }
    icon
      ..setTooltip(model.labels.tooltip)
      ..setContextMenu(menu);
    final previous = _menu;
    _menu = [menu, ...items];
    // A click runs inside the clicked item's own native callback, so the
    // menu it belongs to outlives that call.
    Timer.run(() {
      for (final resource in previous) {
        switch (resource) {
          case tray.Menu():
            resource.dispose();
          case tray.MenuItem():
            resource.dispose();
        }
      }
    });
  }

  @override
  Stream<TrayCommand> get trayCommands => _tray.stream;
}
