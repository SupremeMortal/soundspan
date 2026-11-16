// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Binds the downloads' server writes to the outbox (doc 07, Outbox). It
/// lives outside `lib/core/` because `downloads` and `sync` may not import
/// each other.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/offline_delete_queue.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
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

/// The handler of `offlineDelete` ops: `DELETE /offline/items` through
/// [offline].
List<OutboxHandlerEntry> downloadOutboxHandlers(OfflineRepository offline) => [
  outboxHandlerEntry(
    OfflineDeleteOp.type,
    SendOnlyOutboxHandler<OfflineDeleteOp>(
      (op) => offline.delete(
        deviceId: op.deviceId,
        playbackIds: [for (final id in op.playbackIds) PlaybackId(id)],
      ),
    ),
  ),
];

/// The outbox handlers of the downloads' server writes.
final Provider<List<OutboxHandlerEntry>> downloadOutboxHandlersProvider =
    Provider<List<OutboxHandlerEntry>>(
      (ref) => downloadOutboxHandlers(ref.watch(offlineRepositoryProvider)),
      dependencies: [offlineRepositoryProvider],
    );

/// The profile's [OfflineDeleteQueue], over its outbox.
final Provider<OfflineDeleteQueue> offlineDeleteQueueProvider =
    Provider<OfflineDeleteQueue>(
      (ref) => OutboxOfflineDeleteQueue(ref.watch(outboxProvider).enqueue),
      dependencies: [outboxProvider],
    );
