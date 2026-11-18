// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:ui' show Offset, Rect, Size;

import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

/// A [DesktopShell] with an in-memory window.
///
/// Every call is recorded in [calls], in order, as its member name. The
/// window's bounds, maximized state and displays are fields a test sets;
/// [emitGeometryChange], [emitCloseRequest], [emitSecondInstance] and
/// [emitTrayCommand] play the window and tray events. [hasTrayHost] is what
/// [initTray] answers; the models shown are in [trayModels] and the titles
/// set in [titles]. [integrated], [layout] and [state] are the title bar
/// the app draws; [emitChromeState] and [emitLayout] change them.
class FakeDesktopShell implements DesktopShell {
  /// Creates a window at [bounds] on [displays] (primary first; one
  /// 1920 × 1080 display by default).
  new({this.bounds, List<Rect>? displays})
    : displays = displays ?? [const Rect.fromLTWH(0, 0, 1920, 1080)];

  /// The member names called, in order.
  final List<String> calls = [];

  /// The window's normal bounds.
  WindowBounds? bounds;

  /// Whether the window is maximized.
  bool maximized = false;

  /// The minimum size last set.
  Size? minimumSize;

  /// Whether [showAndFocus] was called.
  bool get shown => calls.contains('showAndFocus');

  /// What [displayAreas] answers.
  List<Rect> displays;

  /// What [initTray] answers.
  bool hasTrayHost = true;

  /// Every tray model shown, in order.
  final List<TrayModel> trayModels = [];

  /// Every window title set, in order.
  final List<String> titles = [];

  /// Whether a close request leaves the window open.
  bool preventClose = false;

  /// Whether the window is hidden.
  bool hidden = false;

  /// Whether the window is minimized.
  bool minimized = false;

  /// Whether the app quit.
  bool quitted = false;

  /// What [integratedTitleBar] answers.
  bool integrated = false;

  /// What [buttonLayout] answers while [integrated].
  WindowButtonLayout layout = WindowButtonLayout.standard;

  /// What [chromeState] answers.
  WindowChromeState state = const WindowChromeState();

  /// The `useSystemTitleBar` of the last [initTitleBar].
  bool? initUseSystemTitleBar;

  /// Every choice stored by [setUseSystemTitleBar], in order.
  final List<bool> storedUseSystemTitleBar = [];

  /// Where [showWindowMenu] was asked to open, in order.
  final List<Offset> windowMenus = [];

  final StreamController<void> _layoutChanges = StreamController.broadcast(
    sync: true,
  );
  final StreamController<void> _chromeChanges = StreamController.broadcast(
    sync: true,
  );

  /// Plays a change of the window's state to [to].
  void emitChromeState(WindowChromeState to) {
    state = to;
    _chromeChanges.add(null);
  }

  /// Plays a change of the desktop's button layout to [to].
  void emitLayout(WindowButtonLayout to) {
    layout = to;
    _layoutChanges.add(null);
  }

  final StreamController<TrayCommand> _tray = StreamController.broadcast(
    sync: true,
  );

  final StreamController<void> _geometry = StreamController.broadcast(
    sync: true,
  );
  final StreamController<void> _close = StreamController.broadcast(sync: true);
  final StreamController<List<String>> _launches = StreamController.broadcast(
    sync: true,
  );

  /// Plays a move or resize of the window to [to], or a change of the
  /// maximized state to [maximized].
  void emitGeometryChange({WindowBounds? to, bool? maximized}) {
    if (to != null) bounds = to;
    if (maximized != null) this.maximized = maximized;
    _geometry.add(null);
  }

  /// Plays the user closing the window.
  void emitCloseRequest() => _close.add(null);

  /// Plays a second launch of the app with [args].
  void emitSecondInstance(List<String> args) => _launches.add(args);

  /// Plays a click on the tray icon or one of its menu entries.
  void emitTrayCommand(TrayCommand command) => _tray.add(command);

  @override
  Future<void> init() async => calls.add('init');

  @override
  Future<void> setMinimumSize(Size size) async {
    calls.add('setMinimumSize');
    minimumSize = size;
  }

  @override
  Future<WindowBounds?> getBounds() async {
    calls.add('getBounds');
    return bounds;
  }

  @override
  Future<void> setBounds(WindowBounds bounds) async {
    calls.add('setBounds');
    this.bounds = bounds;
  }

  @override
  Future<bool> isMaximized() async {
    calls.add('isMaximized');
    return maximized;
  }

  @override
  Future<void> maximize() async {
    calls.add('maximize');
    maximized = true;
  }

  @override
  Future<void> showAndFocus() async {
    calls.add('showAndFocus');
    hidden = false;
    minimized = false;
  }

  @override
  Future<List<Rect>> displayAreas() async {
    calls.add('displayAreas');
    return displays;
  }

  @override
  Stream<void> get geometryChanges => _geometry.stream;

  @override
  Stream<void> get closeRequests => _close.stream;

  @override
  Stream<List<String>> get secondInstanceLaunches => _launches.stream;

  @override
  Future<void> setPreventClose(bool prevent) async {
    calls.add('setPreventClose');
    preventClose = prevent;
  }

  @override
  Future<void> hide() async {
    calls.add('hide');
    hidden = true;
  }

  @override
  Future<void> minimize() async {
    calls.add('minimize');
    minimized = true;
  }

  @override
  Future<void> quit() async {
    calls.add('quit');
    quitted = true;
  }

  @override
  Future<void> setTitle(String title) async {
    calls.add('setTitle');
    titles.add(title);
  }

  @override
  Future<bool> initTray() async {
    calls.add('initTray');
    return hasTrayHost;
  }

  @override
  Future<void> setTray(TrayModel model) async {
    calls.add('setTray');
    trayModels.add(model);
  }

  @override
  Stream<TrayCommand> get trayCommands => _tray.stream;

  @override
  Future<void> initTitleBar({required bool useSystemTitleBar}) async {
    calls.add('initTitleBar');
    initUseSystemTitleBar = useSystemTitleBar;
    _layoutChanges.add(null);
  }

  @override
  Future<void> setUseSystemTitleBar(bool useSystemTitleBar) async {
    calls.add('setUseSystemTitleBar');
    storedUseSystemTitleBar.add(useSystemTitleBar);
  }

  @override
  bool get integratedTitleBar => integrated;

  @override
  WindowButtonLayout get buttonLayout =>
      integratedTitleBar ? layout : WindowButtonLayout.none;

  @override
  Stream<void> get buttonLayoutChanges => _layoutChanges.stream;

  @override
  WindowChromeState get chromeState => state;

  @override
  Stream<void> get chromeStateChanges => _chromeChanges.stream;

  @override
  Future<void> toggleMaximize() async {
    calls.add('toggleMaximize');
    maximized = !maximized;
  }

  @override
  Future<void> close() async {
    calls.add('close');
    if (preventClose) return _close.add(null);
    quitted = true;
  }

  @override
  Future<void> startDragging() async => calls.add('startDragging');

  @override
  Future<void> showWindowMenu(Offset globalPosition) async {
    calls.add('showWindowMenu');
    windowMenus.add(globalPosition);
  }
}
