// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/sync/data/plays_repository.dart';
import 'package:soundspan/core/sync/data/preference_repository.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/sync_providers.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';

/// The domain [Preference] of [signal].
Preference preferenceOfSignal(PreferenceSignal signal) => switch (signal) {
  PreferenceSignal.thumbsUp => Preference.liked,
  PreferenceSignal.thumbsDown => Preference.disliked,
  PreferenceSignal.clear => Preference.neutral,
};

/// Send-only handlers for `preference`, `albumPreference` and `play` over
/// [preferences] and [plays].
List<OutboxHandlerEntry> syncOutboxHandlers(
  PreferenceRepository preferences,
  PlaysRepository plays,
) => [
  outboxHandlerEntry(
    PreferenceOp.type,
    SendOnlyOutboxHandler<PreferenceOp>(
      (op) => preferences.setTrackPreference(
        PlaybackId(op.playbackId),
        preferenceOfSignal(op.signal),
        meta: TrackMeta.fromJson(op.metadata),
      ),
    ),
  ),
  outboxHandlerEntry(
    AlbumPreferenceOp.type,
    SendOnlyOutboxHandler<AlbumPreferenceOp>(
      (op) => preferences.setAlbumPreference(
        op.albumId,
        preferenceOfSignal(op.signal),
      ),
    ),
  ),
  outboxHandlerEntry(
    PlayOp.type,
    SendOnlyOutboxHandler<PlayOp>(
      (op) => plays.report(
        playbackId: PlaybackId(op.playbackId),
        meta: TrackMeta.fromJson(op.metadata),
        playedAt: op.playedAt,
        listenedMs: op.listenedMs,
      ),
    ),
  ),
];

/// The outbox handlers of `core/sync`'s repositories.
final Provider<List<OutboxHandlerEntry>> syncOutboxHandlersProvider =
    Provider<List<OutboxHandlerEntry>>(
      (ref) => syncOutboxHandlers(
        ref.watch(preferenceRepositoryProvider),
        ref.watch(playsRepositoryProvider),
      ),
      dependencies: [preferenceRepositoryProvider, playsRepositoryProvider],
    );
