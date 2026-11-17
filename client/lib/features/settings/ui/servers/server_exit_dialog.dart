// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/session/sign_out_sequence.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/profile.dart';

/// What a [ServerExitDialog] does once confirmed.
enum ServerExit {
  /// Sign out of the server; its data stays on this device.
  signOut,

  /// Remove the server and everything stored for it.
  remove,
}

/// Asks to confirm [exit] of [profile] and runs it (doc 04, Sign-Out).
Future<void> showServerExitDialog(
  BuildContext context,
  Profile profile,
  ServerExit exit,
) => showDialog<void>(
  context: context,
  builder: (_) => ServerExitDialog(profile: profile, exit: exit),
);

/// The confirmation of signing out of, or removing, a server.
///
/// Sign-out offers "Also remove downloads" when a participant reports
/// downloads; removal warns when the outbox holds changes that would be
/// lost. While the sequence runs the dialog shows progress and cannot be
/// dismissed; it closes when the sequence completes and shows an error when
/// it fails.
class ServerExitDialog extends ConsumerStatefulWidget {
  /// Creates the dialog for [exit] of [profile].
  const new({required this.profile, required this.exit, super.key});

  /// The server profile.
  final Profile profile;

  /// What the dialog does.
  final ServerExit exit;

  @override
  ConsumerState<ServerExitDialog> createState() => _ServerExitDialogState();
}

class _ServerExitDialogState extends ConsumerState<ServerExitDialog> {
  late final SignOutSequence _sequence = ref.read(signOutSequenceProvider);
  int _pending = 0;
  bool _offersDownloads = false;
  bool _removeDownloads = false;
  bool _running = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final id = widget.profile.id;
    switch (widget.exit) {
      case ServerExit.signOut:
        final offers = await _sequence.offersDownloadRemoval(id);
        if (mounted) setState(() => _offersDownloads = offers);
      case ServerExit.remove:
        final pending = await _sequence.pendingChanges(id);
        if (mounted) setState(() => _pending = pending);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _running = true;
      _failed = false;
    });
    final id = widget.profile.id;
    try {
      switch (widget.exit) {
        case ServerExit.signOut:
          await _sequence.signOut(id, removeDownloads: _removeDownloads);
        case ServerExit.remove:
          await _sequence.removeServer(id);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _running = false;
          _failed = true;
        });
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final body = context.typography.body.copyWith(color: colors.contentBody);
    final server = widget.profile.displayName;
    final signOut = widget.exit == ServerExit.signOut;
    return PopScope(
      canPop: !_running,
      child: AlertDialog(
        title: Text(
          signOut
              ? l10n.settingsServersSignOutTitle(server)
              : l10n.settingsServersRemoveTitle(server),
        ),
        content: _running
            ? Row(
                children: [
                  const SizedBox.square(
                    dimension: Spacing.x24,
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(width: Spacing.x16),
                  Expanded(
                    child: Text(
                      signOut
                          ? l10n.settingsServersSigningOut
                          : l10n.settingsServersRemoving,
                      style: body,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signOut
                        ? l10n.settingsServersSignOutBody
                        : l10n.settingsServersRemoveBody(server),
                    style: body,
                  ),
                  if (!signOut && _pending > 0) ...[
                    const SizedBox(height: Spacing.x8),
                    Text(
                      l10n.settingsServersRemovePending(_pending),
                      style: body,
                    ),
                  ],
                  if (signOut && _offersDownloads)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _removeDownloads,
                      onChanged: (value) =>
                          setState(() => _removeDownloads = value ?? false),
                      title: Text(
                        l10n.settingsServersSignOutRemoveDownloads,
                        style: body,
                      ),
                    ),
                  if (_failed) ...[
                    const SizedBox(height: Spacing.x8),
                    Text(
                      l10n.settingsServersExitFailed,
                      style: body.copyWith(color: colors.danger),
                    ),
                  ],
                ],
              ),
        actions: _running
            ? const []
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonCancel),
                ),
                TextButton(
                  onPressed: () => unawaited(_confirm()),
                  child: Text(
                    signOut
                        ? l10n.settingsServersSignOut
                        : _pending > 0
                        ? l10n.settingsServersRemoveAnyway
                        : l10n.settingsServersRemoveConfirm,
                  ),
                ),
              ],
      ),
    );
  }
}
