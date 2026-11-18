// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/desktop/desktop_controller.dart';
import 'package:soundspan/app/desktop/keep_playing_prompt.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/features/settings/settings.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

import '../../helpers/fake_desktop_shell.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

// The guideline checks run first, on the default platform: the theme's
// density follows the first platform a test isolate builds it for.
void main() {
  Future<TestRoot> openDesktop(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
      overrides: overrides,
    );
    root.container.read(routerProvider).go(SettingsSection.desktop.path);
    await tester.pumpAndSettle();
    return root;
  }

  SwitchListTile closeToTray(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byKey(DesktopSection.closeToTrayKey));

  // On the default (touch) platform, with desktop capabilities: the
  // tap-target guideline is the touch one.
  for (final capabilities in [
    PlatformCapabilities.windowsAndLinux,
    PlatformCapabilities.windowsAndLinux.withoutTray(),
  ]) {
    testWidgets('Settings → Desktop with the switch meets the guidelines, '
        'hasTray ${capabilities.hasTray}', (tester) async {
      await openDesktop(
        tester,
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(capabilities),
        ],
      );

      expect(find.text('Close to tray'), findsOneWidget);
      await expectMeetsGuidelines(tester);
    });
  }

  testWidgets('the switch reads and writes Close to tray', (tester) async {
    final root = await openDesktop(tester);
    final settings = root.container.read(appSettingsProvider);

    expect(closeToTray(tester).value, isTrue);
    expect(
      tester.getTopLeft(find.byKey(DesktopSection.closeToTrayKey)).dy,
      lessThan(tester.getTopLeft(find.text('Keyboard shortcuts')).dy),
    );

    await tester.tap(find.byKey(DesktopSection.closeToTrayKey));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(() => settings.read(AppSettingKeys.closeToTray)),
      isFalse,
    );
    expect(closeToTray(tester).value, isFalse);

    await tester.runAsync(
      () => settings.write(AppSettingKeys.closeToTray, true),
    );
    await tester.pumpAndSettle();
    expect(closeToTray(tester).value, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('without a tray the switch is disabled and says why', (
    tester,
  ) async {
    await openDesktop(
      tester,
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.windowsAndLinux.withoutTray(),
        ),
      ],
    );

    expect(closeToTray(tester).onChanged, isNull);
    expect(closeToTray(tester).value, isFalse);
    expect(find.text('No system tray was found'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('macOS has no switch', (tester) async {
    await openDesktop(tester);

    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    expect(find.byKey(DesktopSection.closeToTrayKey), findsNothing);
    expect(find.byKey(DesktopSection.useSystemTitleBarKey), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Use system title bar is off by default, says it needs a '
      'restart, and stores the choice for the runner', (tester) async {
    final shell = FakeDesktopShell();
    final root = await openDesktop(
      tester,
      overrides: [desktopShellProvider.overrideWithValue(shell)],
    );
    final settings = root.container.read(appSettingsProvider);
    SwitchListTile useSystemTitleBar() => tester.widget<SwitchListTile>(
      find.byKey(DesktopSection.useSystemTitleBarKey),
    );

    expect(useSystemTitleBar().value, isFalse);
    expect(
      find.text('Takes effect after restarting soundspan.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DesktopSection.useSystemTitleBarKey));
    await tester.pumpAndSettle();
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(
        () => settings.read(AppSettingKeys.useSystemTitleBar),
      ),
      isTrue,
    );
    expect(shell.storedUseSystemTitleBar, [true]);
    expect(useSystemTitleBar().value, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('the keep-playing question answers what was tapped', (
    tester,
  ) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => Column(
          children: [
            for (final answer in KeepPlayingAnswer.values)
              TextButton(
                onPressed: () async {
                  final got = await showKeepPlayingDialog(context);
                  expect(got, answer);
                },
                child: Text('ask ${answer.name}'),
              ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('ask keepPlaying'));
    await tester.pumpAndSettle();
    expect(find.text('Keep playing in the background?'), findsOneWidget);
    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ask quit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quit'));
    await tester.pumpAndSettle();
    expect(find.text('Keep playing in the background?'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('the section is absent on Android', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    root.container.read(routerProvider).go(RoutePaths.settings);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Desktop'), findsNothing);
  });
}
