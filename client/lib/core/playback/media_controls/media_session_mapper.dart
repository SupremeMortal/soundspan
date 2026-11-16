// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// The skip interval of episodes until `playback.skipSeconds` is read.
const Duration defaultSkipInterval = Duration(seconds: 15);

/// What the OS media surface shows for [s] (doc 06, OS Media Controls).
///
/// Nothing current gives [MediaSessionState.empty]. A track offers play or
/// pause, seek, stop, next and previous. An episode shows the podcast as
/// its artist and offers skip forward and back; next and previous only when
/// the queue holds more than one item. [artworkUri] is shown as given.
MediaSessionState mapSnapshot(
  PlaybackSnapshot s, {
  Uri? artworkUri,
  Duration skipInterval = defaultSkipInterval,
}) {
  final item = s.current;
  if (item == null) return MediaSessionState.empty;
  final common = <MediaAction>{
    if (s.playing) MediaAction.pause else MediaAction.play,
    MediaAction.seek,
    MediaAction.stop,
  };
  final (title, artist, album, metaSeconds, actions) = switch (item) {
    TrackQueueItem(:final track) => (
      track.meta.title,
      track.meta.artist,
      track.meta.album,
      track.meta.durationSec,
      {...common, MediaAction.next, MediaAction.previous},
    ),
    EpisodeQueueItem(:final episode, :final podcast) => (
      episode.title,
      podcast.title,
      '',
      episode.durationSec,
      {
        ...common,
        MediaAction.skipForward,
        MediaAction.skipBackward,
        if (s.queue.items.length > 1) ...[
          MediaAction.next,
          MediaAction.previous,
        ],
      },
    ),
  };
  return MediaSessionState(
    queueItemId: item.queueItemId,
    title: title,
    artist: artist,
    album: album,
    duration:
        s.duration ??
        (metaSeconds == null ? null : Duration(seconds: metaSeconds)),
    artworkUri: artworkUri,
    position: s.position,
    playing: s.playing,
    buffering:
        s.status == EngineStatus.buffering || s.status == EngineStatus.loading,
    speed: 1,
    skipInterval: skipInterval,
    actions: actions,
  );
}

/// The cover value of [item]: the track's, or the episode's with the
/// podcast's as fallback.
String? artworkRefOf(QueueItem item) => switch (item) {
  TrackQueueItem(:final track) => track.meta.artworkRef,
  EpisodeQueueItem(:final episode, :final podcast) =>
    episode.artworkRef ?? podcast.artworkRef,
};
