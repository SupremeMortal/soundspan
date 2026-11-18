// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/playback_id.dart';

/// Where a verified download is reported to the server when it cannot be
/// reported at once (doc 07, Verification).
///
/// The outbox implements it (`lib/shared/data/downloads/`) with one
/// `offlineComplete` op per track; when the op is delivered the item is
/// marked `serverConfirmed`.
abstract interface class OfflineCompleteQueue {
  /// Queues `POST /offline/items/complete` of [playbackId] for [deviceId].
  Future<void> enqueue({
    required String deviceId,
    required PlaybackId playbackId,
    required String quality,
    required int sizeBytes,
  });
}
