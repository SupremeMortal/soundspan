// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/top_bar.dart';
import 'package:soundspan/core/auth/profile.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

void main() {
  final avatar = find.byKey(AvatarButton.buttonKey);

  testWidgets('sheet at 390, from the branch root app bar', (tester) async {
    await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    expect(
      find.descendant(of: find.byType(AppBar), matching: avatar),
      findsOneWidget,
    );
    expect(
      find.descendant(of: avatar, matching: find.text('A')),
      findsOneWidget,
    );
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    for (final label in ['music.example.com', 'Add server', 'Settings']) {
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && widget.semanticLabel == 'Current server',
      ),
      findsOneWidget,
    );
    await expectMeetsGuidelines(tester);
  });

  testWidgets('rail placement at 800', (tester) async {
    await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.medium,
    );
    expect(
      find.descendant(of: find.byType(NavigationRail), matching: avatar),
      findsOneWidget,
    );
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.widgetWithText(MenuItemButton, 'Settings'), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('popup at 1440, from the top bar', (tester) async {
    await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    expect(
      find.descendant(of: find.byType(TopBar), matching: avatar),
      findsOneWidget,
    );
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    for (final label in ['music.example.com', 'Add server', 'Settings']) {
      expect(find.widgetWithText(MenuItemButton, label), findsOneWidget);
    }
    await expectMeetsGuidelines(tester);
  });

  testWidgets('choosing another profile calls switchTo with its id', (
    tester,
  ) async {
    late RecordingProfileRuntime runtime;
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
      overrides: [recordingRuntimeOverride((r) => runtime = r)],
      others: ['other'],
    );

    await tester.tap(avatar);
    await tester.pumpAndSettle();
    runtime.delegate = false;
    await tester.tap(find.widgetWithText(MenuItemButton, 'other.example.com'));
    await tester.pumpAndSettle();
    expect(runtime.switched.last, root.otherIds['other']);
  });

  testWidgets('"Settings" opens /settings', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(locationOf(root), '/settings');
  });

  testWidgets('"Add server" opens /connect', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Add server'));
    await tester.pumpAndSettle();
    expect(locationOf(root), '/connect');
  });

  group('avatarInitial', () {
    Profile profile({required String username, String? displayName}) => Profile(
      id: 'p',
      baseUrl: Uri.parse('https://music.example.com'),
      displayName: 'music.example.com',
      userId: 'u',
      username: username,
      role: 'user',
      authKind: AuthKind.password,
      deviceId: 'd',
      credentialCreatedAt: DateTime.utc(2025),
      state: ProfileState.active,
      lastUsedAt: DateTime.utc(2025),
      userDisplayName: displayName,
    );

    test('prefers the display name and upper-cases it', () {
      expect(avatarInitial(profile(username: 'ada', displayName: 'lin')), 'L');
      expect(avatarInitial(profile(username: 'ada', displayName: ' ')), 'A');
      expect(avatarInitial(profile(username: 'ada')), 'A');
      expect(avatarInitial(null), '');
    });
  });
}
