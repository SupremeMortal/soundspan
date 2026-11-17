// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The state behind a mix's page, gated by the server's `autoPlaylists`
/// capability (doc 04, Capability Discovery and Version Gate).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/features/mixes/domain/mix_detail.dart';
import 'package:soundspan/features/mixes/mixes_providers.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan_api/soundspan_api.dart' show FeatureDisabled;

/// Whether the active server has generated mixes (`autoPlaylists`) on.
final Provider<bool> mixesEnabledProvider = Provider<bool>(
  (ref) => ref.watch(
    serverCapabilitiesProvider.select((value) => value.autoPlaylists),
  ),
  dependencies: [serverCapabilitiesProvider],
);

/// The mix with its tracks, from cache first. A `FeatureDisabled` answer,
/// with nothing cached or on a refresh, errors with it and requests a
/// capability refresh. Only read while [mixesEnabledProvider] is true.
final StreamProviderFamily<Cached<MixDetail>, String> mixDetailProvider =
    StreamProvider.autoDispose.family<Cached<MixDetail>, String>(
      (ref, mixId) async* {
        final repository = await ref.watch(mixRepositoryProvider.future);
        try {
          await for (final cached in repository.mix(mixId)) {
            if (cached.refreshError case final FeatureDisabled error) {
              ref.read(capabilityRefreshProvider)();
              // Emitted before leaving the loop, which waits for the
              // repository stream to cancel.
              yield* Stream<Cached<MixDetail>>.error(error);
              return;
            }
            yield cached;
          }
        } on FeatureDisabled {
          ref.read(capabilityRefreshProvider)();
          rethrow;
        }
      },
      retry: _noRetry,
      dependencies: [mixRepositoryProvider, capabilityRefreshProvider],
    );

/// The tracks of [mix] that can be played: those with a `playbackId`.
List<Track> playableMixTracks(MixDetail mix) => [
  for (final track in mix.tracks)
    if (track.playbackId != null) track,
];

/// The queue context of [mix].
QueueContext mixQueueContext(MixDetail mix) =>
    QueueContext(kind: QueueContextKind.mix, id: mix.id, title: mix.name);

/// Saves [mix] as a new playlist of the user: asks for a name prefilled
/// with the mix name, creates the playlist and appends the playable tracks
/// in mix order, all through the outbox, so it works offline. Confirms
/// with a snackbar whose Open action opens the new playlist under its
/// temporary id. Answers that id, or null when the dialog was cancelled.
Future<String?> saveMixAsPlaylist(
  BuildContext context,
  WidgetRef ref,
  MixDetail mix,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final router = GoRouter.maybeOf(context);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => PlaylistNameDialog(
      title: l10n.mixSaveTitle,
      confirmLabel: l10n.mixSaveConfirm,
      initialName: mix.name,
    ),
  );
  if (name == null) return null;
  final repository = await ref.read(playlistRepositoryProvider.future);
  final id = await repository.create(name);
  await repository.addTracks(id, playableMixTracks(mix));
  messenger?.showSnackBar(
    SnackBar(
      content: Text(l10n.mixSaved),
      action: router == null
          ? null
          : SnackBarAction(
              label: l10n.mixSavedOpen,
              onPressed: () => DetailNavigation.openPlaylistIn(router, id),
            ),
    ),
  );
  return id;
}

Duration? _noRetry(int _, Object _) => null;
