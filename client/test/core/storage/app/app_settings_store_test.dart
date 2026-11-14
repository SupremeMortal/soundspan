// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';

void main() {
  late AppDatabase db;
  late AppSettingsStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = AppSettingsStore(db);
  });
  tearDown(() => db.close());

  Future<void> roundTrip<T extends Object>(
    AppSettingKey<T> key,
    T value,
  ) async {
    await store.write(key, value);
    expect(await store.read(key), value, reason: key.name);
    // A fresh store over the same database reads the stored value.
    expect(await AppSettingsStore(db).read(key), value, reason: key.name);
  }

  test('the six keys are exactly the documented ones', () {
    expect(AppSettingKeys.all.map((k) => k.name), [
      'activeProfileId',
      'themeMode',
      'locale',
      'window.bounds',
      'window.maximized',
      'closeToTray',
    ]);
  });

  test('each key round-trips', () async {
    await roundTrip(AppSettingKeys.activeProfileId, 'profile-1');
    await roundTrip(AppSettingKeys.themeMode, ThemeModeSetting.light);
    await roundTrip(AppSettingKeys.themeMode, ThemeModeSetting.dark);
    await roundTrip(AppSettingKeys.locale, 'pt-BR');
    await roundTrip(
      AppSettingKeys.windowBounds,
      const WindowBounds(left: 10, top: 20.5, width: 1280, height: 800),
    );
    await roundTrip(AppSettingKeys.windowMaximized, true);
    await roundTrip(AppSettingKeys.closeToTray, false);
  });

  test('values are stored JSON-encoded under the key name', () async {
    await store.write(AppSettingKeys.themeMode, ThemeModeSetting.dark);
    await store.write(AppSettingKeys.closeToTray, true);
    final rows = {
      for (final row in await db.select(db.appSettings).get())
        row.key: row.value,
    };
    expect(rows, {'themeMode': '"dark"', 'closeToTray': 'true'});
  });

  test('themeMode defaults to system; other keys default to null', () async {
    expect(await store.read(AppSettingKeys.themeMode), ThemeModeSetting.system);
    expect(await store.read(AppSettingKeys.activeProfileId), isNull);
    expect(await store.read(AppSettingKeys.windowBounds), isNull);
    expect(await store.read(AppSettingKeys.closeToTray), isNull);
  });

  test('an unknown stored themeMode reads as the default', () async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(key: 'themeMode', value: '"sepia"'),
        );
    expect(await store.read(AppSettingKeys.themeMode), ThemeModeSetting.system);
  });

  test('a stored value that is not JSON reads as the default', () async {
    await db
        .into(db.appSettings)
        .insert(AppSettingsCompanion.insert(key: 'locale', value: '{oops'));
    expect(await store.read(AppSettingKeys.locale), isNull);
  });

  test('WindowBounds is a value', () {
    const a = WindowBounds(left: 1, top: 2, width: 3, height: 4);
    final b = WindowBounds(left: 1, top: 2, width: 3, height: [4.0].single);
    expect(b, a);
    expect(b.hashCode, a.hashCode);
    expect(b, isNot(const WindowBounds(left: 1, top: 2, width: 3, height: 5)));
  });

  test('writing null removes the key', () async {
    await store.write(AppSettingKeys.activeProfileId, 'p1');
    await store.write(AppSettingKeys.activeProfileId, null);
    expect(await store.read(AppSettingKeys.activeProfileId), isNull);
    expect(await db.select(db.appSettings).get(), isEmpty);

    await store.write(AppSettingKeys.themeMode, ThemeModeSetting.light);
    await store.write(AppSettingKeys.themeMode, null);
    expect(await store.read(AppSettingKeys.themeMode), ThemeModeSetting.system);
  });

  test('watch emits the current value and every change', () async {
    final seen = <String?>[];
    final subscription = store
        .watch(AppSettingKeys.activeProfileId)
        .listen(seen.add);
    addTearDown(subscription.cancel);

    Future<void> settle() => pumpEventQueue();
    await settle();
    await store.write(AppSettingKeys.activeProfileId, 'a');
    await settle();
    await store.write(AppSettingKeys.locale, 'de'); // another key: no event
    await settle();
    await store.write(AppSettingKeys.activeProfileId, 'b');
    await settle();
    await store.write(AppSettingKeys.activeProfileId, null);
    await settle();

    expect(seen, [null, 'a', 'b', null]);
  });

  test('watch applies the default', () async {
    expect(
      await store.watch(AppSettingKeys.themeMode).first,
      ThemeModeSetting.system,
    );
  });
}
