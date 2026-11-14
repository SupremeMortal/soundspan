// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

final AppLogger _log = AppLogger.scope('Window');

/// Restores and persists the desktop window's bounds and maximized state,
/// and brings the window forward on a second launch (doc 09, Desktop
/// Interaction; doc 10).
///
/// [start] runs in bootstrap step 5 (doc 02); on a platform that is not a
/// desktop it does nothing.
class WindowStateController {
  /// Creates a controller of [shell] that keeps the window state in
  /// [settings]; [isDesktop] is `PlatformCapabilities.isDesktop`.
  new({required this.shell, required this.settings, required this.isDesktop});

  /// The window cannot be made smaller than this.
  static const Size minimumSize = Size(480, 600);

  /// The window's size on first run, centred on the primary display.
  static const Size firstRunSize = Size(1280, 800);

  /// How long moves and resizes must pause before the bounds are saved.
  static const Duration saveDelay = Duration(milliseconds: 500);

  /// The log message of a second launch; its only field is the argument
  /// count.
  static const String secondInstanceMessage = 'Second instance launched';

  /// The window.
  final DesktopShell shell;

  /// Where `window.bounds` and `window.maximized` are kept.
  final AppSettingsStore settings;

  /// Whether the app runs on a desktop; nothing happens otherwise.
  final bool isDesktop;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _saveTimer;

  /// Sets the minimum size, restores the saved bounds and maximized state,
  /// shows the window, and starts following window events.
  Future<void> start() async {
    if (!isDesktop) return;
    await shell.init();
    await shell.setMinimumSize(minimumSize);
    await _restore();
    await shell.showAndFocus();
    _subscriptions.addAll([
      shell.geometryChanges.listen((_) => _scheduleSave()),
      shell.closeRequests.listen((_) => unawaited(_saveNow())),
      shell.secondInstanceLaunches.listen(_onSecondInstance),
    ]);
  }

  Future<void> _restore() async {
    final saved = await settings.read(AppSettingKeys.windowBounds);
    final maximized =
        await settings.read(AppSettingKeys.windowMaximized) ?? false;
    final displays = await shell.displayAreas();
    final primary = displays.isEmpty ? null : displays.first;

    final WindowBounds bounds;
    if (saved == null) {
      bounds = _centred(primary, firstRunSize);
    } else {
      final size = Size(
        math.max(saved.width, minimumSize.width),
        math.max(saved.height, minimumSize.height),
      );
      final rect = Rect.fromLTWH(
        saved.left,
        saved.top,
        size.width,
        size.height,
      );
      bounds = displays.isEmpty || displays.any(rect.overlaps)
          ? WindowBounds(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
            )
          : _centred(primary, size);
    }
    await shell.setBounds(bounds);
    if (maximized) await shell.maximize();
  }

  static WindowBounds _centred(Rect? display, Size size) {
    final area = display ?? Rect.fromLTWH(0, 0, size.width, size.height);
    return WindowBounds(
      left: area.left + (area.width - size.width) / 2,
      top: area.top + (area.height - size.height) / 2,
      width: size.width,
      height: size.height,
    );
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () => unawaited(_saveNow()));
  }

  Future<void> _saveNow() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      await save();
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Could not save the window state',
        const {},
        error,
        stackTrace,
      );
    }
  }

  /// Saves the window state now: only `window.maximized` while the window
  /// is maximized, so the normal bounds survive; otherwise both.
  Future<void> save() async {
    if (await shell.isMaximized()) {
      await settings.write(AppSettingKeys.windowMaximized, true);
      return;
    }
    final bounds = await shell.getBounds();
    if (bounds != null) {
      await settings.write(AppSettingKeys.windowBounds, bounds);
    }
    await settings.write(AppSettingKeys.windowMaximized, false);
  }

  void _onSecondInstance(List<String> args) {
    _log.info(secondInstanceMessage, {'argumentCount': args.length});
    unawaited(shell.showAndFocus());
  }

  /// Stops following window events; a pending save is dropped.
  void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }
}

/// The app's [WindowStateController], over the root `app.db`.
final Provider<WindowStateController> windowStateControllerProvider =
    Provider<WindowStateController>((ref) {
      final controller = WindowStateController(
        shell: ref.watch(desktopShellProvider),
        settings: AppSettingsStore(ref.watch(appDatabaseProvider)),
        isDesktop: ref.watch(platformCapabilitiesProvider).isDesktop,
      );
      ref.onDispose(controller.dispose);
      return controller;
    });
