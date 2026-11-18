// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

class _Driver implements RemoteDriver {
  @override
  Future<void> onCommand(PlaybackCommand command) async {}

  @override
  void onCurrentItemFailed(String queueItemId) {}
}

void main() {
  final avatar = find.byKey(AvatarButton.buttonKey);

  /// Attaches a remote driver to the profile's playback controller as
  /// joining a group as a follower does.
  Future<void> joinAGroup(WidgetTester tester) async {
    ProviderScope.containerOf(tester.element(find.byType(AppShell)))
        .read(playbackControllerProvider)
      ..attachRemoteDriver(_Driver())
      ..setRemoteCanControl(false);
    await tester.pumpAndSettle();
  }

  testWidgets('the avatar sheet at 390 has Listen Together, which opens '
      'it in the selected branch', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await tester.tap(avatar);
    await tester.pumpAndSettle();

    final entry = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('Listen Together'),
    );
    expect(entry, findsOneWidget);
    expect(find.byKey(shellActiveDotKey), findsNothing);

    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(locationOf(root), '/home/listen-together');
  });

  testWidgets('the avatar sheet says "In a group" with the dot in a group', (
    tester,
  ) async {
    await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await joinAGroup(tester);
    await tester.tap(avatar);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('In a group'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(shellActiveDotKey), findsOneWidget);
  });

  testWidgets('the sidebar at 1440 has Listen Together below Podcasts; the '
      'avatar popup does not', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    final item = find.byKey(AdaptiveShell.listenTogetherKey);
    expect(
      find.descendant(of: item, matching: find.text('Listen Together')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(item).dy,
      greaterThan(tester.getTopLeft(find.text('Podcasts').first).dy),
    );

    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(MenuItemButton, 'Listen Together'),
      findsNothing,
    );
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await joinAGroup(tester);
    expect(
      find.descendant(of: item, matching: find.text('In a group')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: item, matching: find.byKey(shellActiveDotKey)),
      findsOneWidget,
    );

    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(locationOf(root), '/home/listen-together');
  });
}
