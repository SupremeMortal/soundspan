// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/features/settings/settings.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/test_root.dart';

void main() {
  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).last)).brightness;

  Future<T?> read<T extends Object>(
    WidgetTester tester,
    TestRoot root,
    AppSettingKey<T> key,
  ) => tester.runAsync<T?>(() => AppSettingsStore(root.database).read(key));

  Future<TestRoot> openAppearance(
    WidgetTester tester, {
    AppDatabase? database,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      database: database,
    );
    root.container.read(routerProvider).go(SettingsSection.appearance.path);
    await tester.pumpAndSettle();
    return root;
  }

  testWidgets('choosing Light changes the brightness and persists themeMode', (
    tester,
  ) async {
    final root = await openAppearance(tester);
    expect(brightness(tester), Brightness.dark);
    await expectMeetsGuidelines(tester);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.light);
    expect(
      await read(tester, root, AppSettingKeys.themeMode),
      ThemeModeSetting.light,
    );
    await expectMeetsGuidelines(tester);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('a container rebuilt on the same database starts in Light', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(database.close));
    final first = await openAppearance(tester, database: database);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(first.dispose);

    await tester.pumpSoundspanApp(database: database);
    expect(brightness(tester), Brightness.light);
  });

  testWidgets('choosing a locale persists it', (tester) async {
    final root = await openAppearance(tester);
    expect(await read(tester, root, AppSettingKeys.locale), isNull);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(await read(tester, root, AppSettingKeys.locale), 'en');

    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    expect(await read(tester, root, AppSettingKeys.locale), isNull);
  });
}
