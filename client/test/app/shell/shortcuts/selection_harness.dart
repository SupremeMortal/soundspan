// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kDoubleTapTimeout, kSecondaryButton;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// [screen] under the shell's shortcut table, as the shell puts it.
Widget underShellShortcuts(Widget screen) =>
    Shortcuts(shortcuts: shortcutMap(defaultTargetPlatform), child: screen);

/// The row showing [title].
Finder rowOf(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(TrackRow));

/// The titles of the selected rows, in list order.
List<String> selectedTitles(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
    if (row.selected) row.title,
];

/// Clicks the row showing [title] with the mouse, holding [modifier], and
/// waits out the double-click timeout.
Future<void> click(
  WidgetTester tester,
  String title, {
  LogicalKeyboardKey? modifier,
}) async {
  if (modifier != null) await tester.sendKeyDownEvent(modifier);
  await tester.tap(rowOf(title), kind: PointerDeviceKind.mouse);
  if (modifier != null) await tester.sendKeyUpEvent(modifier);
  await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
}

/// Double-clicks the row showing [title] with the mouse.
Future<void> doubleClick(WidgetTester tester, String title) async {
  await tester.tap(rowOf(title), kind: PointerDeviceKind.mouse);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(rowOf(title), kind: PointerDeviceKind.mouse);
  await tester.pump();
}

/// Presses [key] while holding [modifier].
Future<void> pressWith(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

/// The entries of the menu of several tracks (`trackSelectionActions`).
const List<String> selectionMenuEntries = [
  'Play now',
  'Play next',
  'Add to queue',
  'Add to playlist…',
];

/// Opens the menu of the row showing [title] with a right click and checks
/// that it is the menu of several tracks: it lists [selectionMenuEntries]
/// and leaves out Like and Share link.
Future<void> expectSelectionMenu(WidgetTester tester, String title) async {
  await tester.tap(rowOf(title), buttons: kSecondaryButton);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  for (final entry in selectionMenuEntries) {
    expect(find.text(entry), findsOneWidget, reason: entry);
  }
  expect(find.text('Like'), findsNothing);
  expect(find.text('Share link'), findsNothing);
}
