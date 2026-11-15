// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/domain.dart';

/// The context the test items are queued from.
const testContext = QueueContext(
  kind: QueueContextKind.album,
  id: 'al-1',
  title: 'Record',
);

/// A track queue entry with id [queueItemId] for the track [playbackId].
QueueItem trackItem(String queueItemId, {String? playbackId}) =>
    QueueItem.track(
      queueItemId: queueItemId,
      track: Track(
        meta: TrackMeta(
          title: 'Song $queueItemId',
          artist: 'Band',
          album: 'Record',
          durationSec: 180,
        ),
        playbackId: PlaybackId(playbackId ?? 'pb-$queueItemId'),
      ),
      context: testContext,
    );

/// Track entries with the ids [ids], in order.
List<QueueItem> trackItems(List<String> ids) => [
  for (final id in ids) trackItem(id),
];

/// The queue item ids of [items], in order.
List<String> idsOf(Iterable<QueueItem> items) => [
  for (final item in items) item.queueItemId,
];
