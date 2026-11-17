// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';

import '../../../features/player/ui/player_rig.dart';
import 'shortcuts_harness.dart';
import 'shortcuts_test.dart' show press;

/// Whether the primary focus is inside [area].
bool focusWithin(WidgetTester tester, Finder area) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null || area.evaluate().isEmpty) return false;
  final target = tester.element(area);
  if (focused == target) return true;
  var found = false;
  focused.visitAncestorElements((element) {
    found = element == target;
    return !found;
  });
  return found;
}

void main() {
  final linux = TargetPlatformVariant.only(TargetPlatform.linux);
  final sidebar = find.byKey(AdaptiveShell.sidebarKey);
  final content = find.byKey(contentButtonKey).hitTestable();
  final panel = find.byKey(AdaptiveShell.rightPanelKey);
  final player = find.byKey(const Key('harness.player'));

  /// Where focus is: the sidebar, the content, the right panel or the
  /// player, by name.
  String area(WidgetTester tester) {
    if (focusWithin(tester, sidebar)) return 'sidebar';
    if (focusWithin(tester, panel)) return 'panel';
    if (focusWithin(tester, player)) return 'player';
    final field = find.byKey(textFieldKey);
    if (focusWithin(tester, field) || focusWithin(tester, content)) {
      return 'content';
    }
    return 'none';
  }

  Future<PlayerRig> pump(WidgetTester tester, {bool rightPanel = true}) async {
    final rig = PlayerRig();
    await pumpShortcuts(
      tester,
      rig: rig,
      recorder: ShortcutRecorder(),
      rightPanel: rightPanel,
    );
    await tester.pump();
    return rig;
  }

  testWidgets('F6 visits sidebar, content, right panel, player bar, sidebar', (
    tester,
  ) async {
    final rig = await pump(tester);
    final visited = <String>[];
    for (var i = 0; i < 5; i++) {
      await press(tester, LogicalKeyboardKey.f6);
      visited.add(area(tester));
    }

    expect(visited, ['sidebar', 'content', 'panel', 'player', 'sidebar']);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('F6 skips a closed right panel', (tester) async {
    final rig = await pump(tester, rightPanel: false);
    final visited = <String>[];
    for (var i = 0; i < 4; i++) {
      await press(tester, LogicalKeyboardKey.f6);
      visited.add(area(tester));
    }

    expect(visited, ['sidebar', 'content', 'player', 'sidebar']);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Shift+F6 goes the other way', (tester) async {
    final rig = await pump(tester);
    await press(tester, LogicalKeyboardKey.f6);
    final visited = <String>[];
    for (var i = 0; i < 4; i++) {
      await press(tester, LogicalKeyboardKey.f6, shift: true);
      visited.add(area(tester));
    }

    expect(visited, ['player', 'panel', 'content', 'sidebar']);
    await rig.close(tester);
  }, variant: linux);
}
