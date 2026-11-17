// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/persistence.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/sync/playback_state_sync.dart';

/// What `PlaybackStateSync` reads of [snapshot].
SyncedPlayback syncedPlaybackOf(PlaybackSnapshot snapshot) => SyncedPlayback(
  items: snapshot.queue.items,
  shuffleOrder: snapshot.queue.shuffleOrder,
  cursor: snapshot.queue.cursor,
  revision: snapshot.queue.revision,
  playing: snapshot.playing,
  position: snapshot.position,
);

/// The queue the controller restores from [remote]: its items in the order
/// stored, which is play order, so with shuffle on the shuffle order is the
/// identity (the order is kept and shuffle shows as on).
RestoredQueue restoredQueueOf(RemoteQueue remote) => (
  queue: QueueState(
    items: remote.items,
    shuffleOrder: remote.isShuffle
        ? List<int>.generate(remote.items.length, (i) => i)
        : null,
    cursor: remote.cursor,
  ),
  position: remote.position,
);
