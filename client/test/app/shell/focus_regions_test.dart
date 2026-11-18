// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';

import '../../features/player/ui/player_rig.dart';
import '../../helpers/pump_app.dart';
import 'shortcuts/shortcuts_harness.dart';
import 'shortcuts/shortcuts_test.dart' show press;

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
  final topBar = find.byKey(topBarButtonKey);
  final navigation = find.byType(NavigationBar);
  final rail = find.byType(NavigationRail);
  final sidebar = find.byKey(AdaptiveShell.sidebarKey);
  final content = find.byKey(contentButtonKey).hitTestable();
  final panel = find.byKey(AdaptiveShell.rightPanelKey);
  final player = find.byKey(const Key('harness.player'));

  /// Where focus is, by region name.
  String area(WidgetTester tester) {
    if (focusWithin(tester, topBar)) return 'top bar';
    if (focusWithin(tester, sidebar)) return 'sidebar';
    if (focusWithin(tester, rail)) return 'rail';
    if (focusWithin(tester, navigation)) return 'navigation bar';
    if (focusWithin(tester, panel)) return 'panel';
    if (focusWithin(tester, player)) return 'player';
    final field = find.byKey(textFieldKey);
    if (focusWithin(tester, field) || focusWithin(tester, content)) {
      return 'content';
    }
    return 'none';
  }

  Future<PlayerRig> pump(
    WidgetTester tester, {
    Size size = TestSizes.expanded,
    bool rightPanel = true,
    bool sidebarPlaylists = false,
  }) async {
    final rig = PlayerRig();
    await pumpShortcuts(
      tester,
      rig: rig,
      recorder: ShortcutRecorder(),
      size: size,
      rightPanel: rightPanel,
      topBar: true,
      sidebarPlaylists: sidebarPlaylists,
    );
    await tester.pump();
    return rig;
  }

  Future<List<String>> visit(
    WidgetTester tester,
    int count, {
    bool shift = false,
  }) async {
    final visited = <String>[];
    for (var i = 0; i < count; i++) {
      await press(tester, LogicalKeyboardKey.f6, shift: shift);
      visited.add(area(tester));
    }
    return visited;
  }

  testWidgets('expanded: F6 visits top bar, sidebar, content, right panel, '
      'player bar and wraps', (tester) async {
    final rig = await pump(tester);

    expect(await visit(tester, 6), [
      'top bar',
      'sidebar',
      'content',
      'panel',
      'player',
      'top bar',
    ]);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('expanded: F6 skips a closed right panel', (tester) async {
    final rig = await pump(tester, rightPanel: false);

    expect(await visit(tester, 5), [
      'top bar',
      'sidebar',
      'content',
      'player',
      'top bar',
    ]);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('expanded: Shift+F6 goes the other way', (tester) async {
    final rig = await pump(tester);
    await press(tester, LogicalKeyboardKey.f6);

    expect(await visit(tester, 5, shift: true), [
      'player',
      'panel',
      'content',
      'sidebar',
      'top bar',
    ]);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('medium: F6 visits rail, content, mini player', (tester) async {
    final rig = await pump(tester, size: TestSizes.medium);

    expect(await visit(tester, 4), ['rail', 'content', 'player', 'rail']);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('compact: F6 visits content, mini player, navigation bar', (
    tester,
  ) async {
    final rig = await pump(tester, size: TestSizes.compact);

    expect(await visit(tester, 4), [
      'content',
      'player',
      'navigation bar',
      'content',
    ]);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Tab inside the sidebar goes from top to bottom', (tester) async {
    final rig = await pump(tester, sidebarPlaylists: true);
    await visit(tester, 2);
    expect(area(tester), 'sidebar');

    final tops = <double>[];
    var reachedLastPlaylist = false;
    while (focusWithin(tester, sidebar)) {
      tops.add(FocusManager.instance.primaryFocus!.rect.top);
      reachedLastPlaylist = focusWithin(
        tester,
        find.byKey(sidebarPlaylistKeys.last),
      );
      await press(tester, LogicalKeyboardKey.tab);
    }

    expect(tops.length, greaterThan(4), reason: 'destinations and playlists');
    expect(tops, orderedEquals([...tops]..sort()));
    expect(reachedLastPlaylist, isTrue);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('closing a dialog returns focus to the control that opened it', (
    tester,
  ) async {
    final rig = await pump(tester);
    await visit(tester, 3);
    expect(area(tester), 'content');
    final opener = FocusManager.instance.primaryFocus;

    final dialog = showDialog<void>(
      context: tester.element(find.byKey(contentButtonKey)),
      builder: (context) => AlertDialog(
        content: const Text('Dialog'),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      focusWithin(tester, find.byType(AlertDialog)),
      isTrue,
      reason: 'focus moves into the dialog',
    );

    await press(tester, LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await dialog;

    expect(FocusManager.instance.primaryFocus, same(opener));
    await rig.close(tester);
  }, variant: linux);

  testWidgets('F6 does nothing on a touch-only platform', (tester) async {
    final rig = await pump(tester, size: TestSizes.compact);
    final before = FocusManager.instance.primaryFocus;

    await press(tester, LogicalKeyboardKey.f6);

    expect(FocusManager.instance.primaryFocus, same(before));
    expect(area(tester), isNot('content'));
    await rig.close(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
