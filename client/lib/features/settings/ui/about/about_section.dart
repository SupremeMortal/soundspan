// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';

/// Settings → About: the row that opens the open-source licences.
class AboutSection extends StatelessWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
    children: [
      ListTile(
        leading: const Icon(Icons.description_rounded),
        title: Text(AppLocalizations.of(context).settingsAboutLicenses),
        minTileHeight: Sizes.touchTarget,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => unawaited(
          GoRouter.of(context).push<void>(RoutePaths.settingsAboutLicenses),
        ),
      ),
    ],
  );
}
