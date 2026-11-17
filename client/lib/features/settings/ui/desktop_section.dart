// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

/// Settings → Desktop: the keyboard shortcuts, one line per
/// [ShortcutBinding] with the keys named for this platform (doc 09,
/// Settings).
class DesktopSection extends StatelessWidget {
  /// Creates the section.
  const new({super.key});

  /// The key of the line of [binding].
  static Key lineKey(ShortcutBinding binding) => ValueKey<String>(
    'settings.shortcut.${shortcutBindings.indexOf(binding)}',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final platform = defaultTargetPlatform;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
      children: [
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
