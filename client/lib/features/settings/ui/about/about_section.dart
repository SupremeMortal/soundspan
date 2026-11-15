// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/core/profile/profile_scope.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';

/// Settings → About: the active profile's pending changes and the row that
/// opens the open-source licences.
class AboutSection extends StatelessWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
    children: [
      const ProfileScope(child: PendingChangesTile()),
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

/// "Pending changes: N": the active profile's outbox count, shown once it
/// is known.
class PendingChangesTile extends ConsumerWidget {
  /// Creates the row; it reads the profile scope.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ValueListenableBuilder<int?>(
        valueListenable: ref.watch(outboxProvider).pendingCount,
        builder: (context, count, _) => count == null
            ? const SizedBox.shrink()
            : ListTile(
                leading: const Icon(Icons.cloud_upload_rounded),
                title: Text(
                  AppLocalizations.of(context)
                      .settingsAboutPendingChanges(count),
                ),
                minTileHeight: Sizes.touchTarget,
              ),
      );
}
