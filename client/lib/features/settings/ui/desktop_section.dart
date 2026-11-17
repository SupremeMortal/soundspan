// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/desktop/desktop_controller.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';

/// Settings → Desktop: the Close to tray switch on Windows and Linux, then
/// the keyboard shortcuts, one line per [ShortcutBinding] with the keys
/// named for this platform (doc 09, Settings).
///
/// Without a system tray the switch is disabled and says so; macOS, where
/// closing the window keeps the app in the Dock, and the web have no
/// switch.
class DesktopSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  /// The key of the Close to tray switch.
  static const Key closeToTrayKey = ValueKey<String>('settings.closeToTray');

  /// The key of the line of [binding].
  static Key lineKey(ShortcutBinding binding) => ValueKey<String>(
    'settings.shortcut.${shortcutBindings.indexOf(binding)}',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final platform = defaultTargetPlatform;
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final closeToTrayShown =
        capabilities.isDesktop && platform != TargetPlatform.macOS;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
      children: [
        if (closeToTrayShown)
          SwitchListTile(
            key: closeToTrayKey,
            title: Text(l10n.settingsCloseToTray),
            subtitle: capabilities.hasTray
                ? null
                : Text(l10n.settingsCloseToTrayUnavailable),
            value:
                capabilities.hasTray &&
                (ref.watch(closeToTraySettingProvider).value ??
                    closeToTrayDefault(platform)),
            onChanged: capabilities.hasTray
                ? (value) => unawaited(
                    ref
                        .read(appSettingsProvider)
                        .write(AppSettingKeys.closeToTray, value),
                  )
                : null,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.x16,
            Spacing.x16,
            Spacing.x16,
            Spacing.x8,
          ),
          child: Semantics(
            header: true,
            child: Text(
              l10n.settingsShortcutsTitle,
              style: typography.subtitle.copyWith(color: colors.content),
            ),
          ),
        ),
        for (final binding in shortcutBindings)
          MergeSemantics(
            key: lineKey(binding),
            child: ListTile(
              minTileHeight: Sizes.touchTarget,
              title: Text(binding.label(l10n)),
              trailing: Text(
                [
                  for (final keys in binding.keys)
                    keys.describe(l10n, platform),
                  ?binding.pointerLabel?.call(l10n),
                ].join(' / '),
                style: typography.bodySmall.copyWith(
                  color: colors.contentSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
