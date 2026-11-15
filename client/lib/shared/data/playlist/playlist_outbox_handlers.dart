// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/providers/cache.dart';

/// Send-only handlers for the six playlist ops over [remote]. The create
/// handler answers the created `PlaylistSummary`, whose id replaces the
/// temporary one.
List<OutboxHandlerEntry> playlistOutboxHandlers(PlaylistRemoteSource remote) =>
    [
      outboxHandlerEntry(
        PlaylistCreateOp.type,
        SendOnlyOutboxHandler<PlaylistCreateOp>(
          (op) => remote.create(op.name, isPublic: op.isPublic),
        ),
      ),
      outboxHandlerEntry(
        PlaylistRenameOp.type,
        SendOnlyOutboxHandler<PlaylistRenameOp>(
          (op) async => await remote.update(op.playlistId, name: op.name),
        ),
      ),
      outboxHandlerEntry(
        PlaylistDeleteOp.type,
        SendOnlyOutboxHandler<PlaylistDeleteOp>(
          (op) async => await remote.delete(op.playlistId),
        ),
      ),
      outboxHandlerEntry(
        PlaylistAddOp.type,
        SendOnlyOutboxHandler<PlaylistAddOp>(
          (op) => remote.addItem(
            op.playlistId,
            PlaybackId(op.playbackId),
            meta: TrackMeta.fromJson(op.metadata),
          ),
        ),
      ),
      outboxHandlerEntry(
        PlaylistRemoveOp.type,
        SendOnlyOutboxHandler<PlaylistRemoveOp>(
          (op) async =>
              await remote.removeItem(op.playlistId, PlaybackId(op.playbackId)),
        ),
      ),
      outboxHandlerEntry(
        PlaylistReorderOp.type,
        SendOnlyOutboxHandler<PlaylistReorderOp>(
          (op) async => await remote.reorder(op.playlistId, [
            for (final id in op.playbackIds) PlaybackId(id),
          ]),
        ),
      ),
    ];

/// The outbox handlers of the playlist repository.
final Provider<List<OutboxHandlerEntry>> playlistOutboxHandlersProvider =
    Provider<List<OutboxHandlerEntry>>(
      (ref) => playlistOutboxHandlers(ref.watch(playlistRemoteSourceProvider)),
      dependencies: [playlistRemoteSourceProvider],
    );
