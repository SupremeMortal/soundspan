// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:ui' show Rect, Size;

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/shell/window_state_controller.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

import '../../core/logging/recording_sink.dart';
import '../../helpers/fake_desktop_shell.dart';

const _display = Rect.fromLTWH(0, 0, 1920, 1080);

void main() {
  late AppDatabase db;
  late AppSettingsStore settings;
  late FakeDesktopShell shell;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = AppSettingsStore(db);
    shell = FakeDesktopShell(displays: [_display]);
  });

  tearDown(() => db.close());

  WindowStateController controllerFor({bool isDesktop = true}) =>
      WindowStateController(
        shell: shell,
        settings: settings,
        isDesktop: isDesktop,
      );

  /// Runs [body] in fake time, flushing microtasks and drift's work after.
  void inFakeTime(void Function(FakeAsync async) body) {
    fakeAsync((async) {
      body(async);
      async.flushMicrotasks();
    });
  }

  /// Settles [future] in fake time and returns its value.
  T settle<T>(FakeAsync async, Future<T> future) {
    late T value;
    var done = false;
    unawaited(
      future.then((v) {
        value = v;
        done = true;
      }),
    );
    async
      ..flushMicrotasks()
      ..elapse(Duration.zero);
    expect(done, isTrue, reason: 'the future did not complete');
    return value;
  }

  test('first run uses 1280 × 800 and sets the minimum size', () {
    inFakeTime((async) {
      settle(async, controllerFor().start());
      expect(shell.minimumSize, const Size(480, 600));
      expect(
        shell.bounds,
        const WindowBounds(left: 320, top: 140, width: 1280, height: 800),
      );
      expect(shell.maximized, isFalse);
      expect(shell.shown, isTrue);
    });
  });

  test('the title bar is set up before the window is shown, with the '
      'system title bar off by default', () {
    inFakeTime((async) {
      settle(async, controllerFor().start());
      expect(shell.initUseSystemTitleBar, isFalse);
      expect(
        shell.calls.indexOf('initTitleBar'),
        lessThan(shell.calls.indexOf('showAndFocus')),
      );
    });
  });

  test('the stored Use system title bar choice reaches the shell', () {
    inFakeTime((async) {
      settle(async, settings.write(AppSettingKeys.useSystemTitleBar, true));
      settle(async, controllerFor().start());
      expect(shell.initUseSystemTitleBar, isTrue);
    });
  });

  test('saved bounds are restored before the window is shown', () {
    inFakeTime((async) {
      const saved = WindowBounds(left: 100, top: 50, width: 900, height: 700);
      settle(async, settings.write(AppSettingKeys.windowBounds, saved));
      settle(async, controllerFor().start());
      expect(shell.bounds, saved);
      expect(
        shell.calls.indexOf('setBounds'),
        lessThan(shell.calls.indexOf('showAndFocus')),
      );
    });
  });

  test('bounds smaller than the minimum are clamped to 480 × 600', () {
    inFakeTime((async) {
      settle(
        async,
        settings.write(
          AppSettingKeys.windowBounds,
          const WindowBounds(left: 10, top: 20, width: 200, height: 300),
        ),
      );
      settle(async, controllerFor().start());
      expect(
        shell.bounds,
        const WindowBounds(left: 10, top: 20, width: 480, height: 600),
      );
    });
  });

  test('bounds outside every display are centred on the primary display', () {
    inFakeTime((async) {
      shell.displays = [_display, const Rect.fromLTWH(1920, 0, 1280, 1024)];
      settle(
        async,
        settings.write(
          AppSettingKeys.windowBounds,
          const WindowBounds(left: 4000, top: 100, width: 1000, height: 600),
        ),
      );
      settle(async, controllerFor().start());
      expect(
        shell.bounds,
        const WindowBounds(left: 460, top: 240, width: 1000, height: 600),
      );
    });
  });

  test('maximized is restored and the normal bounds are kept', () {
    inFakeTime((async) {
      const saved = WindowBounds(left: 100, top: 50, width: 900, height: 700);
      settle(async, settings.write(AppSettingKeys.windowBounds, saved));
      settle(async, settings.write(AppSettingKeys.windowMaximized, true));
      settle(async, controllerFor().start());
      expect(shell.bounds, saved);
      expect(shell.maximized, isTrue);
      expect(
        shell.calls.indexOf('setBounds'),
        lessThan(shell.calls.indexOf('maximize')),
      );
    });
  });

  test('moves and resizes are saved once after 500 ms of quiet', () {
    inFakeTime((async) {
      final controller = controllerFor();
      settle(async, controller.start());
      int reads() => shell.calls.where((c) => c == 'getBounds').length;

      shell.emitGeometryChange(
        to: const WindowBounds(left: 1, top: 1, width: 700, height: 700),
      );
      async.elapse(const Duration(milliseconds: 300));
      shell.emitGeometryChange(
        to: const WindowBounds(left: 2, top: 2, width: 800, height: 700),
      );
      async.elapse(const Duration(milliseconds: 499));
      expect(reads(), 0);
      expect(settle(async, settings.read(AppSettingKeys.windowBounds)), isNull);

      async.elapse(const Duration(milliseconds: 1));
      expect(
        settle(async, settings.read(AppSettingKeys.windowBounds)),
        const WindowBounds(left: 2, top: 2, width: 800, height: 700),
      );
      async.elapse(const Duration(seconds: 2));
      expect(reads(), 1);
      controller.dispose();
    });
  });

  test('closing the window saves at once', () {
    inFakeTime((async) {
      final controller = controllerFor();
      settle(async, controller.start());
      shell
        ..bounds = const WindowBounds(left: 5, top: 6, width: 700, height: 650)
        ..emitCloseRequest();
      async.flushMicrotasks();
      expect(
        settle(async, settings.read(AppSettingKeys.windowBounds)),
        const WindowBounds(left: 5, top: 6, width: 700, height: 650),
      );
      controller.dispose();
    });
  });

  test('while maximized only the maximized flag is written', () {
    inFakeTime((async) {
      const saved = WindowBounds(left: 100, top: 50, width: 900, height: 700);
      settle(async, settings.write(AppSettingKeys.windowBounds, saved));
      final controller = controllerFor();
      settle(async, controller.start());

      shell.emitGeometryChange(
        to: const WindowBounds(left: 0, top: 0, width: 1920, height: 1080),
        maximized: true,
      );
      async.elapse(const Duration(milliseconds: 600));

      expect(settle(async, settings.read(AppSettingKeys.windowBounds)), saved);
      expect(
        settle(async, settings.read(AppSettingKeys.windowMaximized)),
        isTrue,
      );
      controller.dispose();
    });
  });

  test('a second-instance launch shows and focuses the window and logs no '
      'argument values', () {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: true);
    addTearDown(AppLogging.reset);
    inFakeTime((async) {
      final controller = controllerFor();
      settle(async, controller.start());
      shell.calls.clear();

      shell.emitSecondInstance(['soundspan://link?code=SECRET1', '--x']);
      async.flushMicrotasks();

      expect(shell.calls, ['showAndFocus']);
      final entry = sink.entries.singleWhere(
        (e) => e.message == WindowStateController.secondInstanceMessage,
      );
      expect(entry.fields, {'argumentCount': 2});
      expect(entry.toJson().toString(), isNot(contains('SECRET1')));
      controller.dispose();
    });
  });

  test('the started controller outlives the tray host answer, so second '
      'launches still reach it', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = ProviderContainer(
      overrides: [
        desktopShellProvider.overrideWithValue(shell),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    final started = container.read(windowStateControllerProvider);

    // The desktop controller records that no tray host answered.
    container.read(trayHostProvider.notifier).available = false;

    expect(container.read(windowStateControllerProvider), same(started));
  });

  test('on a non-desktop platform nothing is called', () {
    inFakeTime((async) {
      final controller = controllerFor(isDesktop: false);
      settle(async, controller.start());
      shell.emitGeometryChange(
        to: const WindowBounds(left: 1, top: 1, width: 700, height: 700),
      );
      async.elapse(const Duration(seconds: 1));
      expect(shell.calls, isEmpty);
      expect(settle(async, settings.read(AppSettingKeys.windowBounds)), isNull);
    });
  });
}
