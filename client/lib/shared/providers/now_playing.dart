// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// The track the queue's current item plays and whether it is playing.
typedef NowPlaying = ({PlaybackId? playbackId, bool playing});

/// What the playing-row indicators show (doc 09, Performance Rules): the
/// current track's playback id (null for an episode or an empty queue)
/// and whether it plays, from [playbackStateProvider], so position updates
/// change nothing. Nothing plays while the controller is unavailable.
///
/// Widgets watch it through a `select`, so only the rows whose state
/// changes rebuild.
final Provider<NowPlaying> nowPlayingProvider = Provider<NowPlaying>((ref) {
  final snapshot = ref.watch(playbackStateProvider).value;
  final current = snapshot?.current;
  return (
    playbackId: current is TrackQueueItem ? current.track.playbackId : null,
    playing: snapshot?.playing ?? false,
  );
}, dependencies: [playbackStateProvider]);
