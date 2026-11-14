// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/app.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';

import '../helpers/test_root.dart';

void main() {
  testWidgets('generates the localized app title', (tester) async {
    await tester.pumpSoundspanApp();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final context = tester.element(find.text('Add server'));
    expect(app.onGenerateTitle!(context), 'soundspan');
    expect(AppLocalizations.of(context).appTitle, 'soundspan');
  });

  testWidgets('follows the stored theme mode', (tester) async {
    final root = await tester.pumpSoundspanApp();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.runAsync(
      () => root.container
          .read(appSettingsProvider)
          .write(AppSettingKeys.themeMode, ThemeModeSetting.light),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('follows the stored locale', (tester) async {
    final root = await tester.pumpSoundspanApp();
    await tester.runAsync(
      () => root.container
          .read(appSettingsProvider)
          .write(AppSettingKeys.locale, 'en-GB'),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en', 'GB'),
    );
  });

  test('localeFromTag reads language, script and region', () {
    expect(localeFromTag('pt-BR'), const Locale('pt', 'BR'));
    expect(
      localeFromTag('zh-Hant-TW'),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      ),
    );
    expect(localeFromTag('fr'), const Locale('fr'));
  });
}
