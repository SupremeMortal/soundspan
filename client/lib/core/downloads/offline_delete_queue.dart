// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/shared/domain/playback_id.dart';

/// Where removed downloads are reported to the server: one call per batch
/// of at most [maxOfflineDeleteBatch] ids (doc 07, Removing Downloads).
///
/// The outbox implements it (`lib/shared/data/downloads/`), so a removal
/// made offline is sent later and one made online is sent at once.
abstract interface class OfflineDeleteQueue {
  /// Queues `DELETE /offline/items` of [playbackIds] for [deviceId].
  Future<void> enqueue({
    required String deviceId,
    required List<PlaybackId> playbackIds,
  });
}
