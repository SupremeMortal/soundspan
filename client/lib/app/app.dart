// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/theme.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';

/// The stored theme choice, now and after every change.
final StreamProvider<ThemeModeSetting> themeModeSettingProvider =
    StreamProvider<ThemeModeSetting>(
      (ref) => ref
          .watch(appSettingsProvider)
          .watch(AppSettingKeys.themeMode)
          .map((mode) => mode ?? ThemeModeSetting.system),
    );

/// The locale the user picked, or null to follow the system.
final StreamProvider<Locale?> localeSettingProvider = StreamProvider<Locale?>(
  (ref) => ref
      .watch(appSettingsProvider)
      .watch(AppSettingKeys.locale)
      .map((tag) => tag == null ? null : localeFromTag(tag)),
);

/// The [Locale] of a BCP 47 language tag such as `pt-BR` or `zh-Hant-TW`.
Locale localeFromTag(String tag) {
  final parts = tag.split(RegExp('[-_]'));
  String? script;
  String? country;
  for (final part in parts.skip(1)) {
    if (part.length == 4) {
      script = part;
    } else {
      country ??= part;
    }
  }
  return Locale.fromSubtags(
    languageCode: parts.first,
    scriptCode: script,
    countryCode: country,
  );
}

/// The soundspan application: themes, localization and the router.
class SoundspanApp extends ConsumerWidget {
  /// Creates the application.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode =
        ref.watch(themeModeSettingProvider).value ?? ThemeModeSetting.system;
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeSettingProvider).value,
      theme: SoundspanTheme.light,
      darkTheme: SoundspanTheme.dark,
      highContrastTheme: SoundspanTheme.lightHighContrast,
      highContrastDarkTheme: SoundspanTheme.darkHighContrast,
      themeMode: switch (mode) {
        ThemeModeSetting.system => ThemeMode.system,
        ThemeModeSetting.dark => ThemeMode.dark,
        ThemeModeSetting.light => ThemeMode.light,
      },
    );
  }
}
