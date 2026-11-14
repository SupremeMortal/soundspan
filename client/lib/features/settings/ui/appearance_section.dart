// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/app.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';

/// Settings → Appearance: the theme mode and the language, stored in the
/// `themeMode` and `locale` app settings and applied at once.
class AppearanceSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final mode =
        ref.watch(themeModeSettingProvider).value ?? ThemeModeSetting.system;
    final locale = ref.watch(localeSettingProvider).value;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
      children: [
        _Heading(l10n.settingsThemeTitle),
        for (final option in ThemeModeSetting.values)
          _Choice(
            label: switch (option) {
              ThemeModeSetting.system => l10n.settingsThemeSystem,
              ThemeModeSetting.dark => l10n.settingsThemeDark,
              ThemeModeSetting.light => l10n.settingsThemeLight,
            },
            selected: option == mode,
            onTap: () =>
                unawaited(settings.write(AppSettingKeys.themeMode, option)),
          ),
        _Heading(l10n.settingsLanguageTitle),
        _Choice(
          label: l10n.settingsLanguageSystem,
          selected: locale == null,
          onTap: () => unawaited(settings.write(AppSettingKeys.locale, null)),
        ),
        for (final supported in AppLocalizations.supportedLocales)
          _Choice(
            label: lookupAppLocalizations(supported).settingsLanguageName,
            selected: locale?.toLanguageTag() == supported.toLanguageTag(),
            onTap: () => unawaited(
              settings.write(AppSettingKeys.locale, supported.toLanguageTag()),
            ),
          ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.x16,
      Spacing.x16,
      Spacing.x16,
      Spacing.x8,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: context.typography.subtitle.copyWith(
          color: context.colors.content,
        ),
      ),
    ),
  );
}

class _Choice extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    inMutuallyExclusiveGroup: true,
    checked: selected,
    child: ListTile(
      title: Text(label),
      selected: selected,
      minTileHeight: Sizes.touchTarget,
      trailing: selected
          ? Icon(Icons.check_rounded, color: context.colors.brand)
          : null,
      onTap: onTap,
    ),
  );
}
