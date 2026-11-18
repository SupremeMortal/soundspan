// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Binds the downloads' server writes to the outbox (doc 07, Outbox). It
/// lives outside `lib/core/` because `downloads` and `sync` may not import
/// each other.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_complete_queue.dart';
import 'package:soundspan/core/downloads/offline_delete_queue.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/util/uuid.dart';

/// An [OfflineDeleteQueue] that enqueues one `offlineDelete` outbox op per
/// batch.
final class OutboxOfflineDeleteQueue implements OfflineDeleteQueue {
  /// Creates the queue over [_enqueue], usually `Outbox.enqueue`.
  const new(this._enqueue);

  final Future<int?> Function(OutboxOp op) _enqueue;

  @override
  Future<void> enqueue({
    required String deviceId,
    required List<PlaybackId> playbackIds,
  }) async {
    if (playbackIds.isEmpty) return;
    await _enqueue(
      OfflineDeleteOp(
        batchUuid: Uuid.v4(),
        deviceId: deviceId,
        playbackIds: [for (final id in playbackIds) id.value],
      ),
    );
  }
}

/// An [OfflineCompleteQueue] that enqueues one `offlineComplete` outbox op
/// per track; a newer op for the same track replaces a pending one.
final class OutboxOfflineCompleteQueue implements OfflineCompleteQueue {
  /// Creates the queue over [_enqueue], usually `Outbox.enqueue`.
  const new(this._enqueue);

  final Future<int?> Function(OutboxOp op) _enqueue;

  @override
  Future<void> enqueue({
    required String deviceId,
    required PlaybackId playbackId,
    required String quality,
    required int sizeBytes,
  }) async {
    await _enqueue(
      OfflineCompleteOp(
        deviceId: deviceId,
        playbackId: playbackId.value,
        quality: quality,
        sizeBytes: sizeBytes,
      ),
    );
  }
}

/// Sends `offlineComplete` ops and marks the item `serverConfirmed` in
/// [_store] once the server recorded it. A dropped op leaves the item
/// unconfirmed for reconciliation and shows nothing.
final class OfflineCompleteHandler implements OutboxHandler<OfflineCompleteOp> {
  /// Creates the handler.
  const new(this._offline, this._store, this._clock);

  final OfflineRepository _offline;
  final DownloadStore _store;
  final Clock _clock;

  @override
  Future<Object?> send(OfflineCompleteOp op) async {
    await _offline.complete(
      deviceId: op.deviceId,
      playbackId: PlaybackId(op.playbackId),
      quality: op.quality,
      sizeBytes: op.sizeBytes,
    );
    return null;
  }

  @override
  Future<void> onSuccess(OfflineCompleteOp op, Object? response) =>
      _store.markServerConfirmed(TrackItemKey(op.playbackId), _clock.now());

  @override
  Future<void> onDropped(OfflineCompleteOp op, OutboxDropReason reason) async {}
}

/// The handlers of `offlineDelete` ops (`DELETE /offline/items`) and
/// `offlineComplete` ops (`POST /offline/items/complete`) through
/// [offline]; a delivered completion is recorded in [store].
List<OutboxHandlerEntry> downloadOutboxHandlers(
  OfflineRepository offline, {
  required DownloadStore store,
  required Clock clock,
}) => [
  outboxHandlerEntry(
    OfflineDeleteOp.type,
    SendOnlyOutboxHandler<OfflineDeleteOp>(
      (op) => offline.delete(
        deviceId: op.deviceId,
        playbackIds: [for (final id in op.playbackIds) PlaybackId(id)],
      ),
    ),
  ),
  outboxHandlerEntry(
    OfflineCompleteOp.type,
    OfflineCompleteHandler(offline, store, clock),
  ),
];

/// The outbox handlers of the downloads' server writes.
final Provider<List<OutboxHandlerEntry>> downloadOutboxHandlersProvider =
    Provider<List<OutboxHandlerEntry>>(
      (ref) => downloadOutboxHandlers(
        ref.watch(offlineRepositoryProvider),
        store: ref.watch(downloadStoreProvider),
        clock: ref.watch(clockProvider),
      ),
      dependencies: [offlineRepositoryProvider, downloadStoreProvider],
    );

/// The profile's [OfflineCompleteQueue], over its outbox.
final Provider<OfflineCompleteQueue> offlineCompleteQueueProvider =
    Provider<OfflineCompleteQueue>(
      (ref) => OutboxOfflineCompleteQueue(ref.watch(outboxProvider).enqueue),
      dependencies: [outboxProvider],
    );

/// The profile's [OfflineDeleteQueue], over its outbox.
final Provider<OfflineDeleteQueue> offlineDeleteQueueProvider =
    Provider<OfflineDeleteQueue>(
      (ref) => OutboxOfflineDeleteQueue(ref.watch(outboxProvider).enqueue),
      dependencies: [outboxProvider],
    );
