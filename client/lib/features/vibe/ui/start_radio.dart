// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/vibe/vibe_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/util/uuid.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan_api/soundspan_api.dart' show FeatureDisabled;

final AppLogger _log = AppLogger.scope('Vibe');

/// Whether the track menu offers Start radio now: the server has similar
/// tracks ([vibeAvailableProvider]) and is reachable. The menu also needs
/// the track's library id.
///
/// A menu opened outside a profile scope has no server, so Start radio is
/// not offered there.
bool startRadioOffered(WidgetRef ref) {
  try {
    return ref.read(vibeAvailableProvider) && _online(ref);
  } on ProviderException catch (error) {
    if (_outsideProfileScope(error)) return false;
    rethrow;
  }
}

/// Whether [error] comes from reading a profile-scoped provider where no
/// profile scope exists: `profileContextProvider` throws a [StateError].
bool _outsideProfileScope(ProviderException error) {
  Object cause = error;
  while (cause is ProviderException) {
    cause = cause.exception;
  }
  return cause is StateError;
}

bool _online(WidgetRef ref) =>
    (ref.read(reachabilityStateProvider).value ??
        ref.read(reachabilityProvider).current) ==
    Reachability.online;

/// Hides Vibe after a `FeatureDisabled` answer and asks for a capability
/// refresh.
void reportVibeDisabled(WidgetRef ref) {
  ref.read(vibeTurnedOffProvider.notifier).turnOff();
  ref.read(capabilityRefreshProvider)();
}

/// The [QueueContext] of a radio of tracks that sound like [seed].
QueueContext vibeRadioContext(Track seed) => QueueContext(
  kind: QueueContextKind.radio,
  id: seed.libraryTrackId,
  title: seed.meta.title,
);

/// Start radio (doc 09, Track Actions): asks for up to 50 tracks similar to
/// [track] and replaces the queue with [track] followed by the playable
/// ones, under a [QueueContextKind.radio] context labelled with the
/// track's title, and plays. An empty answer shows "No similar tracks
/// found" and leaves the queue alone; a failure shows its message. Does
/// nothing for a track without a library id.
Future<void> startRadio(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final libraryId = track.libraryTrackId;
  if (libraryId == null) return;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  void say(String message) =>
      messenger?.showSnackBar(SnackBar(content: Text(message)));
  try {
    final similar = await ref.read(vibeRepositoryProvider).similar(libraryId);
    final playable = [
      for (final candidate in similar)
        if (candidate.playbackId != null &&
            candidate.libraryTrackId != libraryId)
          candidate,
    ];
    if (playable.isEmpty) {
      say(l10n.vibeNoSimilar);
      return;
    }
    final queueContext = vibeRadioContext(track);
    await ref.read(playbackControllerProvider).playItems([
      for (final item in [if (track.playbackId != null) track, ...playable])
        QueueItem.track(
          queueItemId: Uuid.v4(),
          track: item,
          context: queueContext,
        ),
    ], context: queueContext);
  } on FeatureDisabled catch (error) {
    reportVibeDisabled(ref);
    say(errorMessageOf(l10n, error));
  } on Object catch (error, stackTrace) {
    _log.warning('Starting a radio failed', const {}, error, stackTrace);
    final message = errorMessageOf(l10n, error);
    if (message.isNotEmpty) say(message);
  }
}
