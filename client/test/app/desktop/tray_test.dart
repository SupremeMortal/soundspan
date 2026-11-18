// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

import 'desktop_rig.dart';

/// The labels of [model]'s entries, disabled ones in brackets.
List<String> menuOf(TrayModel model) => [
  for (final entry in model.entries)
    if (entry.enabled) entry.label else '[${entry.label}]',
];

void main() {
  late DesktopRig r;

  setUp(() async {
    r = DesktopRig();
    await r.start();
  });

  tearDown(() => r.close());

  test('the menu is Play, Next, Previous, Show window and Quit, transport '
      'disabled, with an empty queue', () {
    expect(menuOf(r.shell.trayModels.last), [
      '[Play]',
      '[Next track]',
      '[Previous track]',
      'Show window',
      'Quit',
    ]);
    expect(r.shell.trayModels.last.entries.map((e) => e.command), [
      TrayCommand.playPause,
      TrayCommand.next,
      TrayCommand.previous,
      TrayCommand.showWindow,
      TrayCommand.quit,
    ]);
  });

  test('while playing the menu has Pause and the current "Title — Artist" '
      'as a disabled label', () async {
    await r.play();

    expect(menuOf(r.shell.trayModels.last), [
      'Pause',
      'Next track',
      'Previous track',
      '[Song a — Band]',
      'Show window',
      'Quit',
    ]);
  });

  test('the Play/Pause label follows the state', () async {
    await r.play();
    await r.h.controller.pause();
    await r.h.settle();

    expect(r.shell.trayModels.last.entries.first.label, 'Play');
    expect(r.shell.trayModels.last.playing, isFalse);
  });

  test('the label follows a track change', () async {
    await r.play();
    await r.h.controller.next();
    await r.h.settle();

    expect(r.shell.trayModels.last.nowPlayingLabel, 'Song b — Band');
  });

  test('position updates push no new model', () async {
    await r.play();
    final pushed = r.shell.trayModels.length;

    r.h.fake.advance(const Duration(seconds: 5));
    await r.h.settle();
    r.h.fake.advance(const Duration(seconds: 5));
    await r.h.settle();

    expect(r.h.controller.snapshot.position, isNot(Duration.zero));
    expect(r.shell.trayModels, hasLength(pushed));
  });

  test('Play/Pause, Next and Previous call the controller', () async {
    await r.play();

    r.shell.emitTrayCommand(TrayCommand.playPause);
    await r.h.settle();
    expect(r.h.controller.snapshot.playing, isFalse);

    r.shell.emitTrayCommand(TrayCommand.playPause);
    await r.h.settle();
    expect(r.h.controller.snapshot.playing, isTrue);

    r.shell.emitTrayCommand(TrayCommand.next);
    await r.h.settle();
    expect(r.h.controller.snapshot.current?.queueItemId, 'b');

    r.shell.emitTrayCommand(TrayCommand.previous);
    await r.h.settle();
    expect(r.h.controller.snapshot.current?.queueItemId, 'a');
  });

  test('Show window shows the window', () async {
    r.shell.calls.clear();

    r.shell.emitTrayCommand(TrayCommand.showWindow);
    await r.h.settle();

    expect(r.shell.calls, ['showAndFocus']);
  });

  test('Quit stops playback, writes the queue, then quits', () async {
    await r.play();
    r.shell.calls.clear();

    r.shell.emitTrayCommand(TrayCommand.quit);
    await r.h.settle();

    expect(r.h.controller.snapshot.playing, isFalse);
    expect(r.h.controller.snapshot.current?.queueItemId, 'a');
    expect(r.flushes, 1);
    expect(r.shell.quitted, isTrue);
    expect(r.shell.calls.last, 'quit');
  });

  test('the tray icon is created on Windows and its host reported', () {
    expect(r.shell.calls, contains('initTray'));
    expect(r.desktop.hasTray, isTrue);
    expect(r.trayHost, isTrue);
  });

  test('the web shell is a no-op without a tray', () async {
    const shell = NoopDesktopShell();
    expect(await shell.initTray(), isFalse);
    await shell.setTray(
      const TrayModel(
        labels: TrayLabels(
          play: 'Play',
          pause: 'Pause',
          next: 'Next',
          previous: 'Previous',
          showWindow: 'Show window',
          quit: 'Quit',
          tooltip: 'soundspan',
        ),
      ),
    );
    await shell.quit();
    expect(await shell.trayCommands.isEmpty, isTrue);
  });
}
