// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/playback/playback_providers.dart';

/// Whether a playback control is locked because only the group's host
/// controls playback: attached to a group and not allowed to control it.
/// False until the profile's playback controller exists: it is not
/// created here.
bool hostControlsPlayback(WidgetRef ref) =>
    ref.watch(playbackControllerProvider.exists) &&
    ref.watch(
      playbackStateProvider.select((snapshot) {
        final value = snapshot.value;
        return value != null && value.remoteAttached && !value.remoteCanControl;
      }),
    );

/// Whether this device is attached to a Listen Together group; false until
/// the profile's playback controller exists.
bool remotePlaybackAttached(WidgetRef ref) =>
    ref.watch(playbackControllerProvider.exists) &&
    ref.watch(
      playbackStateProvider.select(
        (snapshot) => snapshot.value?.remoteAttached ?? false,
      ),
    );

/// Wraps a disabled playback control in the tooltip and semantics hint
/// "The host controls playback" while [locked]; [child] alone otherwise.
class HostControlled extends StatelessWidget {
  /// Creates the wrapper of [child].
  const new({required this.locked, required this.child, super.key});

  /// Whether the control is locked.
  final bool locked;

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    final message = AppLocalizations.of(context).listenTogetherHostControls;
    return MergeSemantics(
      child: Tooltip(
        message: message,
        child: Semantics(hint: message, child: child),
      ),
    );
  }
}

/// The 16 px spinner that replaces a control's icon while its command
/// awaits the group's acknowledgement.
class GroupCommandSpinner extends StatelessWidget {
  /// Creates the spinner, in [color] (the control's colour by default).
  const new({this.color, super.key});

  /// The spinner's colour.
  final Color? color;

  /// The key of every spinner.
  static const Key spinnerKey = ValueKey('ListenTogether.pending');

  @override
  Widget build(BuildContext context) => SizedBox.square(
    key: spinnerKey,
    dimension: 16,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: color ?? IconTheme.of(context).color,
    ),
  );
}

/// Asks whether Play may replace the group's queue while in a group this
/// device controls; true at once outside a group.
Future<bool> confirmReplaceGroupQueue(
  BuildContext context,
  WidgetRef ref,
) async {
  final attached =
      ref.read(playbackControllerProvider.exists) &&
      (ref.read(playbackStateProvider).value?.remoteAttached ?? false);
  if (!attached) return true;
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.listenTogetherReplaceTitle),
      content: Text(l10n.listenTogetherReplaceBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(l10n.listenTogetherCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(l10n.listenTogetherReplaceConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
