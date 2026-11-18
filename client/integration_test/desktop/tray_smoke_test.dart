// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The tray of the real app on a desktop runner (doc 11, Integration
// (desktop); doc 10): `DesktopShell.initTray()` completes on each OS. It
// creates the icon on Windows; the Linux runner has no StatusNotifier host
// and macOS has no tray, so there it is false, and closing the window while
// nothing plays quits. Run by the desktop-integration jobs of
// .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/desktop/tray_smoke_test.dart -d <os>

@Tags(['desktop'])
library;

import 'dart:io' show Platform;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soundspan/app/desktop/desktop_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell_io.dart';
import 'package:window_manager/window_manager.dart' show WindowManager;

import '../support/desktop_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initTray completes: the icon on Windows, none on the Linux '
      'runner and macOS; without a tray, closing the idle window quits '
      'cleanly', (tester) async {
    final server = (await tester.runAsync(DesktopApiServer.start))!;
    addTearDown(server.close);
    final shell = _QuitRecordingShell(WindowManagerDesktopShell());
    final app = await startDesktopApp(
      tester,
      server,
      overrides: [desktopShellProvider.overrideWithValue(shell)],
    );
    final desktop = app.container.read(desktopControllerProvider)!;

    // Bootstrap step 5 started the controller, which asked for the tray on
    // Windows and Linux.
    final expected = Platform.isWindows;
    expect(desktop.hasTray, expected);
    final again = await tester.runAsync(
      () => shell.initTray().timeout(const Duration(seconds: 10)),
    );
    expect(again, expected);

    if (!Platform.isLinux) return;

    // No tray and nothing playing: a close request of the window quits,
    // after the queue and the window state are written.
    final controller = app.container
        .read(profileRuntimeProvider)
        .container!
        .read(playbackControllerProvider);
    expect(controller.snapshot.playing, isFalse);
    final settings = AppSettingsStore(app.container.read(appDatabaseProvider));
    await tester.runAsync(
      () => settings.write(AppSettingKeys.windowBounds, null),
    );
    WindowManager.instance.getCurrent()!.close();
    await pumpUntil(
      tester,
      () => shell.quits > 0,
      reason: 'closing the idle window quits',
    );
    expect(shell.quits, 1);
    final saved = await tester.runAsync(
      () => settings.read(AppSettingKeys.windowBounds),
    );
    expect(saved, isNotNull, reason: 'the window state is saved on quitting');
  });
}

/// The app's [DesktopShell], except that [quit] is counted instead of
/// ending the process, which would end the test before it reports.
final class _QuitRecordingShell implements DesktopShell {
  new(this._inner);

  final DesktopShell _inner;

  /// How many times the app quit.
  int quits = 0;

  @override
  Future<void> quit() async => quits++;

  @override
  Future<bool> initTray() => _inner.initTray();

  @override
  Future<void> init() => _inner.init();

  @override
  Future<void> setMinimumSize(Size size) => _inner.setMinimumSize(size);

  @override
  Future<WindowBounds?> getBounds() => _inner.getBounds();

  @override
  Future<void> setBounds(WindowBounds bounds) => _inner.setBounds(bounds);

  @override
  Future<bool> isMaximized() => _inner.isMaximized();

  @override
  Future<void> maximize() => _inner.maximize();

  @override
  Future<void> showAndFocus() => _inner.showAndFocus();

  @override
  Future<List<Rect>> displayAreas() => _inner.displayAreas();

  @override
  Stream<void> get geometryChanges => _inner.geometryChanges;

  @override
  Stream<void> get closeRequests => _inner.closeRequests;

  @override
  Stream<List<String>> get secondInstanceLaunches =>
      _inner.secondInstanceLaunches;

  @override
  Future<void> setPreventClose(bool prevent) => _inner.setPreventClose(prevent);

  @override
  Future<void> hide() => _inner.hide();

  @override
  Future<void> minimize() => _inner.minimize();

  @override
  Future<void> setTitle(String title) => _inner.setTitle(title);

  @override
  Future<void> setTray(TrayModel model) => _inner.setTray(model);

  @override
  Stream<TrayCommand> get trayCommands => _inner.trayCommands;

  @override
  Future<void> initTitleBar({required bool useSystemTitleBar}) =>
      _inner.initTitleBar(useSystemTitleBar: useSystemTitleBar);

  @override
  Future<void> setUseSystemTitleBar(bool useSystemTitleBar) =>
      _inner.setUseSystemTitleBar(useSystemTitleBar);

  @override
  bool get integratedTitleBar => _inner.integratedTitleBar;

  @override
  WindowButtonLayout get buttonLayout => _inner.buttonLayout;

  @override
  Stream<void> get buttonLayoutChanges => _inner.buttonLayoutChanges;

  @override
  WindowChromeState get chromeState => _inner.chromeState;

  @override
  Stream<void> get chromeStateChanges => _inner.chromeStateChanges;

  @override
  Future<void> toggleMaximize() => _inner.toggleMaximize();

  @override
  Future<void> close() => _inner.close();

  @override
  Future<void> startDragging() => _inner.startDragging();

  @override
  Future<void> showWindowMenu(Offset globalPosition) =>
      _inner.showWindowMenu(globalPosition);
}
