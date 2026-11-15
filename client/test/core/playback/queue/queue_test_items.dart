// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/queue/queue_state.dart';
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

/// A queue of track entries [ids] with the cursor at [cursor], the play
/// order [shuffleOrder] and the repeat mode [repeat].
QueueState queueOf(
  List<String> ids, {
  int? cursor = 0,
  List<int>? shuffleOrder,
  RepeatMode repeat = RepeatMode.off,
  int revision = 3,
}) => QueueState(
  items: trackItems(ids),
  shuffleOrder: shuffleOrder,
  cursor: ids.isEmpty ? null : cursor,
  repeat: repeat,
  context: testContext,
  revision: revision,
);

/// The queue item ids of [state] in play order.
List<String> playIdsOf(QueueState state) => [
  for (final index in state.playOrder) state.items[index].queueItemId,
];

/// The entry ids `p0`..`p{count - 1}`.
List<String> numberedIds(int count, {String prefix = 'p'}) => [
  for (var i = 0; i < count; i++) '$prefix$i',
];
