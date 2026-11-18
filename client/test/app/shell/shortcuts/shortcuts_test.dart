// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kBackMouseButton, kForwardMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

import '../../../features/player/ui/player_rig.dart';
import '../../../helpers/pump_app.dart';
import 'shortcuts_harness.dart';

/// Presses [key] with the given modifiers held.
Future<bool> press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool control = false,
  bool meta = false,
  bool shift = false,
  bool alt = false,
}) async {
  final modifiers = [
    if (control) LogicalKeyboardKey.controlLeft,
    if (meta) LogicalKeyboardKey.metaLeft,
    if (shift) LogicalKeyboardKey.shiftLeft,
    if (alt) LogicalKeyboardKey.altLeft,
  ];
  for (final modifier in modifiers) {
    await tester.sendKeyDownEvent(modifier);
  }
  final handled = await tester.sendKeyEvent(key);
  for (final modifier in modifiers.reversed) {
    await tester.sendKeyUpEvent(modifier);
  }
  await tester.pump();
  return handled;
}

void main() {
  final linux = TargetPlatformVariant.only(TargetPlatform.linux);
  final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);

  late PlayerRig rig;
  late ShortcutRecorder recorder;

  // The rig is made inside each test, so its controller runs in fake time.
  setUp(() => recorder = ShortcutRecorder());

  /// Pumps the harness with a, b, c queued and a playing unless [start] is
  /// false.
  Future<void> pump(
    WidgetTester tester, {
    bool start = true,
    bool play = true,
    Size size = TestSizes.expanded,
    bool back = true,
    bool forward = true,
    List<QueueItem>? items,
  }) async {
    rig = PlayerRig();
    await pumpShortcuts(
      tester,
      rig: rig,
      recorder: recorder,
      size: size,
      back: back,
      forward: forward,
    );
    if (start) await rig.start(tester, play: play, items: items);
    await tester.pump();
  }

  testWidgets('Space plays and pauses', (tester) async {
    await pump(tester);
    expect(rig.controller.snapshot.playing, isTrue);

    await press(tester, LogicalKeyboardKey.space);
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isFalse);

    await press(tester, LogicalKeyboardKey.space);
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isTrue);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+Right skips to the next item', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.arrowRight, control: true);
    await rig.settle(tester);

    expect(rig.controller.snapshot.current?.queueItemId, 'b');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+Left goes to the previous item', (tester) async {
    await pump(tester);
    await press(tester, LogicalKeyboardKey.arrowRight, control: true);
    await rig.settle(tester);

    await press(tester, LogicalKeyboardKey.arrowLeft, control: true);
    await rig.settle(tester);

    expect(rig.controller.snapshot.current?.queueItemId, 'a');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Shift+Right seeks forward 10 s, clamped to the item', (
    tester,
  ) async {
    await pump(tester, play: false);
    unawaited(rig.controller.seek(const Duration(seconds: 2)));
    await rig.settle(tester);

    await press(tester, LogicalKeyboardKey.arrowRight, shift: true);
    await rig.settle(tester);

    // The items are 10 s long: 2 s + 10 s stops at the end.
    expect(rig.controller.snapshot.position, const Duration(seconds: 10));
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Shift+Left seeks back 10 s, clamped to the start', (
    tester,
  ) async {
    await pump(tester, play: false);
    unawaited(rig.controller.seek(const Duration(seconds: 3)));
    await rig.settle(tester);

    await press(tester, LogicalKeyboardKey.arrowLeft, shift: true);
    await rig.settle(tester);

    expect(rig.controller.snapshot.position, Duration.zero);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+Up raises the volume by 5 %, clamped to 100 %', (
    tester,
  ) async {
    await pump(tester);
    unawaited(rig.controller.setVolume(0.5));
    await rig.settle(tester);

    await press(tester, LogicalKeyboardKey.arrowUp, control: true);
    await rig.settle(tester);
    expect(rig.controller.volume, closeTo(0.55, 1e-9));

    unawaited(rig.controller.setVolume(0.98));
    await rig.settle(tester);
    await press(tester, LogicalKeyboardKey.arrowUp, control: true);
    await rig.settle(tester);
    expect(rig.controller.volume, 1.0);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+Down lowers the volume by 5 %, clamped to 0 %', (
    tester,
  ) async {
    await pump(tester);
    unawaited(rig.controller.setVolume(0.5));
    await rig.settle(tester);

    await press(tester, LogicalKeyboardKey.arrowDown, control: true);
    await rig.settle(tester);
    expect(rig.controller.volume, closeTo(0.45, 1e-9));

    unawaited(rig.controller.setVolume(0.02));
    await rig.settle(tester);
    await press(tester, LogicalKeyboardKey.arrowDown, control: true);
    await rig.settle(tester);
    expect(rig.controller.volume, 0.0);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+S toggles shuffle', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.keyS, control: true);
    await rig.settle(tester);
    expect(rig.controller.snapshot.queue.isShuffled, isTrue);

    await press(tester, LogicalKeyboardKey.keyS, control: true);
    await rig.settle(tester);
    expect(rig.controller.snapshot.queue.isShuffled, isFalse);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+R cycles repeat: all, one, off', (tester) async {
    await pump(tester);
    final modes = <RepeatMode>[];
    for (var i = 0; i < 3; i++) {
      await press(tester, LogicalKeyboardKey.keyR, control: true);
      await rig.settle(tester);
      modes.add(rig.controller.snapshot.queue.repeat);
    }

    expect(modes, [RepeatMode.all, RepeatMode.one, RepeatMode.off]);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+L likes the current track', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.keyL, control: true);
    await rig.settle(tester);

    expect([for (final track in recorder.liked) track.meta.title], ['Song a']);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+L on an episode does nothing', (tester) async {
    await pump(tester, items: [playerEpisode('e')]);

    final handled = await press(tester, LogicalKeyboardKey.keyL, control: true);
    await rig.settle(tester);

    expect(handled, isFalse);
    expect(recorder.liked, isEmpty);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+K focuses search', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.keyK, control: true);

    expect(recorder.searches, 1);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('/ focuses search', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.slash);

    expect(recorder.searches, 1);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('/ types into a focused text field', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(textFieldKey));
    await tester.pump();

    await press(tester, LogicalKeyboardKey.slash);

    expect(recorder.searches, 0);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Space inside a text field does not toggle playback', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(textFieldKey));
    await tester.pump();

    await press(tester, LogicalKeyboardKey.space);
    await rig.settle(tester);

    expect(rig.controller.snapshot.playing, isTrue);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+1 to Ctrl+4 open Home, Search, Library and Podcasts', (
    tester,
  ) async {
    await pump(tester);

    for (final key in [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ]) {
      await press(tester, key, control: true);
    }

    expect(recorder.destinations, [0, 1, 2, 3]);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+Q toggles the queue panel on expanded windows', (
    tester,
  ) async {
    rig = PlayerRig();
    final container = await pumpShortcuts(tester, rig: rig, recorder: recorder);
    await rig.start(tester);

    await press(tester, LogicalKeyboardKey.keyQ, control: true);
    expect(container.read(rightPanelProvider), RightPanel.queue);

    await press(tester, LogicalKeyboardKey.keyQ, control: true);
    expect(container.read(rightPanelProvider), RightPanel.none);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+Q opens and closes the queue on compact windows', (
    tester,
  ) async {
    await pump(tester, size: TestSizes.compact);

    await press(tester, LogicalKeyboardKey.keyQ, control: true);
    await rig.settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(QueueSheet), findsOneWidget);

    await press(tester, LogicalKeyboardKey.keyQ, control: true);
    await rig.settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(QueueSheet), findsNothing);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Alt+Left goes back and Alt+Right goes forward', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.arrowLeft, alt: true);
    await press(tester, LogicalKeyboardKey.arrowRight, alt: true);

    expect(recorder.backs, 1);
    expect(recorder.forwards, 1);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('the mouse back and forward buttons navigate', (tester) async {
    await pump(tester);
    final at = tester.getCenter(find.byKey(contentButtonKey));

    for (final button in [kBackMouseButton, kForwardMouseButton]) {
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: button,
      );
      await gesture.down(at);
      await gesture.up();
      await gesture.removePointer();
      await tester.pump();
    }

    expect(recorder.backs, 1);
    expect(recorder.forwards, 1);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+, opens Settings', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.comma, control: true);

    expect(recorder.settings, 1);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('F5 refreshes the screen', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.f5);

    expect(recorder.refreshes, 1);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+Shift+R refreshes the screen and does not cycle repeat', (
    tester,
  ) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.keyR, control: true, shift: true);
    await rig.settle(tester);

    expect(recorder.refreshes, 1);
    expect(rig.controller.snapshot.queue.repeat, RepeatMode.off);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Cmd replaces Ctrl on macOS', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.arrowRight, meta: true);
    await rig.settle(tester);
    expect(rig.controller.snapshot.current?.queueItemId, 'b');

    final handled = await press(
      tester,
      LogicalKeyboardKey.arrowRight,
      control: true,
    );
    await rig.settle(tester);
    expect(handled, isFalse);
    expect(rig.controller.snapshot.current?.queueItemId, 'b');
    await rig.close(tester);
  }, variant: macOS);

  testWidgets('Ctrl+Q, not Cmd+Q, toggles the queue on macOS', (tester) async {
    rig = PlayerRig();
    final container = await pumpShortcuts(tester, rig: rig, recorder: recorder);
    await rig.start(tester);

    final cmdQ = await press(tester, LogicalKeyboardKey.keyQ, meta: true);
    expect(cmdQ, isFalse);
    expect(container.read(rightPanelProvider), RightPanel.none);

    await press(tester, LogicalKeyboardKey.keyQ, control: true);
    expect(container.read(rightPanelProvider), RightPanel.queue);
    await rig.close(tester);
  }, variant: macOS);

  testWidgets('a shortcut with no target leaves the key unhandled', (
    tester,
  ) async {
    await pump(tester, start: false, back: false);

    expect(await press(tester, LogicalKeyboardKey.space), isFalse);
    expect(
      await press(tester, LogicalKeyboardKey.arrowRight, control: true),
      isFalse,
    );
    expect(
      await press(tester, LogicalKeyboardKey.arrowLeft, alt: true),
      isFalse,
    );
    await rig.close(tester);
  }, variant: linux);

  testWidgets('the shortcuts are off on Android', (tester) async {
    await pump(tester);

    await press(tester, LogicalKeyboardKey.space);
    await rig.settle(tester);

    expect(rig.controller.snapshot.playing, isTrue);
    await rig.close(tester);
  });
}
