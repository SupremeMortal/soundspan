// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/desktop/desktop_controller.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';

import 'desktop_rig.dart';

void main() {
  late DesktopRig r;

  Future<void> startOn(
    TargetPlatform platform, {
    bool hasTrayHost = true,
    bool? closeToTray,
  }) async {
    r = DesktopRig(platform: platform, hasTrayHost: hasTrayHost);
    if (closeToTray != null) {
      await r.settings.write(AppSettingKeys.closeToTray, closeToTray);
    }
    await r.start();
  }

  Future<void> close() async {
    r.shell.emitCloseRequest();
    await r.h.settle();
  }

  tearDown(() => r.close());

  test('Windows hides the window by default; playback continues', () async {
    await startOn(TargetPlatform.windows);
    await r.play();

    await close();

    expect(r.shell.preventClose, isTrue);
    expect(r.shell.hidden, isTrue);
    expect(r.shell.quitted, isFalse);
    expect(r.h.controller.snapshot.playing, isTrue);
  });

  test('Windows with Close to tray off quits', () async {
    await startOn(TargetPlatform.windows, closeToTray: false);
    await r.play();

    await close();

    expect(r.shell.hidden, isFalse);
    expect(r.shell.quitted, isTrue);
    expect(r.h.controller.snapshot.playing, isFalse);
    expect(r.flushes, 1);
  });

  test('Linux with a tray hides the window', () async {
    await startOn(TargetPlatform.linux);
    await r.play();

    await close();

    expect(r.desktop.hasTray, isTrue);
    expect(r.shell.hidden, isTrue);
    expect(r.shell.quitted, isFalse);
  });

  test(
    'Linux without a tray asks while playing; Keep playing minimises',
    () async {
      await startOn(TargetPlatform.linux, hasTrayHost: false);
      await r.play();
      r.answer = KeepPlayingAnswer.keepPlaying;

      await close();

      expect(r.trayHost, isFalse);
      expect(r.asked, 1);
      expect(r.shell.minimized, isTrue);
      expect(r.shell.quitted, isFalse);
      expect(r.h.controller.snapshot.playing, isTrue);
    },
  );

  test('Linux without a tray asks while playing; Quit quits', () async {
    await startOn(TargetPlatform.linux, hasTrayHost: false);
    await r.play();
    r.answer = KeepPlayingAnswer.quit;

    await close();

    expect(r.asked, 1);
    expect(r.shell.quitted, isTrue);
    expect(r.h.controller.snapshot.playing, isFalse);
  });

  test('Linux without a tray leaves the window open when the question is '
      'dismissed', () async {
    await startOn(TargetPlatform.linux, hasTrayHost: false);
    await r.play();

    await close();

    expect(r.asked, 1);
    expect(r.shell.minimized, isFalse);
    expect(r.shell.quitted, isFalse);
  });

  test('Linux without a tray quits at once while idle', () async {
    await startOn(TargetPlatform.linux, hasTrayHost: false);

    await close();

    expect(r.asked, 0);
    expect(r.shell.quitted, isTrue);
  });

  test('macOS hides the window, has no tray, and Close to tray does not '
      'apply', () async {
    await startOn(TargetPlatform.macOS, closeToTray: false);
    await r.play();

    await close();

    expect(r.shell.calls, isNot(contains('initTray')));
    expect(r.trayHost, isNull);
    expect(r.shell.hidden, isTrue);
    expect(r.shell.quitted, isFalse);
    expect(r.h.controller.snapshot.playing, isTrue);
  });

  test('closeToTray defaults to on for Windows and Linux, off elsewhere', () {
    expect(closeToTrayDefault(TargetPlatform.windows), isTrue);
    expect(closeToTrayDefault(TargetPlatform.linux), isTrue);
    expect(closeToTrayDefault(TargetPlatform.macOS), isFalse);
    expect(closeToTrayDefault(TargetPlatform.android), isFalse);
  });

  test('a stored Close to tray survives a restart', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final before = DesktopRig(database: database);
    await AppSettingsStore(database).write(AppSettingKeys.closeToTray, false);
    before.desktop.dispose();
    await before.h.controller.dispose();

    r = DesktopRig(database: database);
    await r.start();
    await close();

    expect(r.shell.quitted, isTrue);
    expect(r.shell.hidden, isFalse);
  });
}
