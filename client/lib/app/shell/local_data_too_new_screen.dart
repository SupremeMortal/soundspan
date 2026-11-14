// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';

/// Shows [LocalDataTooNewScreen] instead of [child] while the
/// [ProfileRuntime] reports that the active profile's `state.db` was
/// written by a newer version of the app (doc 05, Migrations).
class LocalDataTooNewGate extends ConsumerWidget {
  /// Creates the gate around [child].
  const new({required this.child, super.key});

  /// The shell.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ValueListenableBuilder<ProfileRuntimeState>(
        valueListenable: ref.watch(profileRuntimeProvider).state,
        builder: (context, state, _) => switch (state) {
          ProfileRuntimeLocalDataTooNew(:final profileId) =>
            LocalDataTooNewScreen(profileId: profileId),
          _ => child,
        },
      );
}

/// Says that the local data of profile [profileId] was written by a newer
/// version of the app, and offers to reset it or to switch server.
///
/// Nothing is deleted until the user confirms the reset.
class LocalDataTooNewScreen extends ConsumerWidget {
  /// Creates the screen for [profileId].
  const new({required this.profileId, super.key});

  /// The profile whose local data is too new.
  final String profileId;

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final runtime = ref.read(profileRuntimeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) {
        final l10n = AppLocalizations.of(dialog);
        return AlertDialog(
          title: Text(l10n.localDataTooNewConfirmTitle),
          content: Text(l10n.localDataTooNewConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: dialog.colors.danger,
              ),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.localDataTooNewConfirmReset),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) await runtime.resetLocalState(profileId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.x24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.update_rounded,
                    size: Spacing.x48,
                    color: colors.warning,
                  ),
                  const SizedBox(height: Spacing.x16),
                  Text(
                    l10n.localDataTooNewTitle,
                    textAlign: TextAlign.center,
                    style: context.typography.title.copyWith(
                      color: colors.content,
                    ),
                  ),
                  const SizedBox(height: Spacing.x12),
                  Text(
                    l10n.localDataTooNewBody,
                    textAlign: TextAlign.center,
                    style: context.typography.body.copyWith(
                      color: colors.contentSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.x24),
                  FilledButton(
                    onPressed: () => unawaited(_reset(context, ref)),
                    child: Text(l10n.localDataTooNewReset),
                  ),
                  const SizedBox(height: Spacing.x8),
                  OutlinedButton(
                    onPressed: () => unawaited(
                      GoRouter.of(context)
                          .push<void>(RoutePaths.settingsServers),
                    ),
                    child: Text(l10n.localDataTooNewSwitch),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
