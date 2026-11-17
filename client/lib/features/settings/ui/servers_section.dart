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
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/settings/ui/servers/server_exit_dialog.dart';
import 'package:soundspan/platform/url_opener/url_opener.dart';

/// The role of a server administrator.
const String adminRole = 'admin';

/// The server administration page of [profile]: `<baseUrl>/admin`.
Uri serverAdminUrl(Profile profile) => Uri.parse('${profile.baseUrl}/admin');

/// Settings → Servers (doc 04, Multiple Profiles): every profile, most
/// recently used first, with its host, user, state and last seen server
/// version; switch, rename, sign out, remove, add a server, and "Open server
/// admin" for administrators.
class ServersSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    final activeId = ref.watch(activeProfileIdProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
      children: [
        for (final profile in profiles)
          ServerProfileTile(
            key: ValueKey<String>(profile.id),
            profile: profile,
            current: profile.id == activeId,
          ),
        ListTile(
          leading: const Icon(Icons.add_rounded),
          title: Text(l10n.settingsServersAdd),
          minTileHeight: Sizes.touchTarget,
          onTap: () =>
              unawaited(GoRouter.of(context).push<void>(RoutePaths.connect)),
        ),
      ],
    );
  }
}

/// One profile in Settings → Servers, with its actions.
class ServerProfileTile extends ConsumerWidget {
  /// Creates the tile of [profile]; [current] marks the active profile.
  const new({required this.profile, required this.current, super.key});

  /// The profile.
  final Profile profile;

  /// Whether [profile] is the one the app shows.
  final bool current;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(profileRepositoryProvider);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: profile.displayName),
    );
    if (name != null) await repository.rename(profile.id, name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final secondary = context.typography.bodySmall.copyWith(
      color: colors.contentSecondary,
    );
    final version = profile.serverVersion;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.x16,
        vertical: Spacing.x8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.displayName,
                  style: context.typography.body.copyWith(
                    color: colors.content,
                  ),
                ),
              ),
              if (current)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.brand,
                  semanticLabel: l10n.shellMenuCurrentServer,
                ),
            ],
          ),
          const SizedBox(height: Spacing.x4),
          Text(
            l10n.settingsServersAccount(profile.username, profile.baseUrl.host),
            style: secondary,
          ),
          Text(
            [
              switch (profile.state) {
                ProfileState.active => l10n.settingsServersStateActive,
                ProfileState.signedOut => l10n.settingsServersStateSignedOut,
              },
              if (version == null)
                l10n.settingsServersVersionUnknown
              else
                l10n.settingsServersVersion(version),
              if (profile.authKind != AuthKind.password)
                switch (profile.credentialExpiresAt) {
                  null => l10n.settingsServersLinkExpiryUnknown,
                  final expires => l10n.settingsServersLinkExpires(
                    expires.toLocal(),
                  ),
                },
            ].join(' · '),
            style: secondary,
          ),
          Wrap(
            spacing: Spacing.x8,
            children: [
              if (!current)
                TextButton(
                  onPressed: () => unawaited(
                    ref.read(profileRuntimeProvider).switchTo(profile.id),
                  ),
                  child: Text(l10n.settingsServersSwitch),
                ),
              TextButton(
                onPressed: () => unawaited(_rename(context, ref)),
                child: Text(l10n.settingsServersRename),
              ),
              if (profile.state == ProfileState.active)
                TextButton(
                  onPressed: () => unawaited(
                    showServerExitDialog(context, profile, ServerExit.signOut),
                  ),
                  child: Text(l10n.settingsServersSignOut),
                ),
              TextButton(
                onPressed: () => unawaited(
                  showServerExitDialog(context, profile, ServerExit.remove),
                ),
                child: Text(l10n.settingsServersRemove),
              ),
              if (profile.role == adminRole)
                TextButton(
                  onPressed: () => unawaited(
                    ref.read(urlOpenerProvider).open(serverAdminUrl(profile)),
                  ),
                  child: Text(l10n.settingsServersOpenAdmin),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return AlertDialog(
      title: Text(l10n.settingsServersRenameTitle),
      content: TextField(
        controller: _name,
        style: context.typography.body.copyWith(color: colors.contentBody),
        decoration: InputDecoration(
          labelText: l10n.settingsServersRenameLabel,
          labelStyle: TextStyle(color: colors.contentSecondary),
          floatingLabelStyle: TextStyle(color: colors.contentSecondary),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_name.text),
          child: Text(l10n.settingsServersRenameSave),
        ),
      ],
    );
  }
}
