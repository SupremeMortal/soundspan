// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/top_bar.dart';
import 'package:soundspan/features/search/search.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_root.dart';
import 'shortcuts_test.dart' show press;

/// Whether the text field [field] has focus.
bool fieldFocused(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

/// Leaves Search at a query and goes back Home, so Search reopens on that
/// query: its recent searches, shown without one, load from the database
/// in real time, which a widget test's fake time never finishes.
Future<void> visitSearch(WidgetTester tester, TestRoot root) async {
  root.container.read(routerProvider).go('/search?q=blue');
  await tester.pumpAndSettle();
  root.container.read(routerProvider).go(RoutePaths.home);
  await tester.pumpAndSettle();
}

void main() {
  final linux = TargetPlatformVariant.only(TargetPlatform.linux);

  testWidgets('Ctrl+2 opens Search and Ctrl+1 Home in the app', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    await visitSearch(tester, root);

    await press(tester, LogicalKeyboardKey.digit2, control: true);
    await tester.pumpAndSettle();
    expect(locationOf(root), '/search?q=blue');

    await press(tester, LogicalKeyboardKey.digit1, control: true);
    await tester.pumpAndSettle();
    expect(locationOf(root), '/home');
  }, variant: linux);

  testWidgets('Ctrl+, opens Settings in the app', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );

    await press(tester, LogicalKeyboardKey.comma, control: true);
    await tester.pumpAndSettle();

    expect(locationOf(root), '/settings');
  }, variant: linux);

  testWidgets('Ctrl+K focuses the top bar search field on expanded windows', (
    tester,
  ) async {
    await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );

    await press(tester, LogicalKeyboardKey.keyK, control: true);
    await tester.pumpAndSettle();

    expect(fieldFocused(tester, find.byKey(TopBar.searchFieldKey)), isTrue);
  }, variant: linux);

  testWidgets('Ctrl+K opens Search and focuses its field on medium windows', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.medium,
    );
    await visitSearch(tester, root);

    await press(tester, LogicalKeyboardKey.keyK, control: true);
    await tester.pumpAndSettle();

    expect(locationOf(root), '/search?q=blue');
    expect(fieldFocused(tester, find.byKey(SearchScreen.fieldKey)), isTrue);
  }, variant: linux);
}
