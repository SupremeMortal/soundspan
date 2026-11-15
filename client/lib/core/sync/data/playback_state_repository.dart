// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/data/playback_metadata.dart';
import 'package:soundspan/core/sync/playback_state.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// Reads, writes and clears this device's stored playback state
/// (`/playback-state`, doc 06). The `X-Playback-Device-Id` header comes
/// from `ApiConfig.playbackDeviceId` through the transport.
/// `ApiException` propagates.
final class PlaybackStateRepository {
  /// Creates a repository over the generated playback client.
  new(this._client);

  final api.PlaybackClient _client;

  /// The state stored for this device; null when there is none, or when it
  /// is of a kind this app does not play (an audiobook).
  Future<RemotePlaybackState?> fetch() async {
    final state = await _client.getPlaybackState();
    return state == null ? null : remotePlaybackStateFromWire(state);
  }

  /// Stores [draft] as this device's state.
  Future<void> save(PlaybackStateDraft draft) async {
    await _client.savePlaybackState(body: savePlaybackStateRequest(draft));
  }

  /// Removes this device's state.
  Future<void> clear() async {
    await _client.clearPlaybackState();
  }
}

/// The body of `POST /playback-state` for [draft].
api.SavePlaybackStateRequest savePlaybackStateRequest(
  PlaybackStateDraft draft,
) => api.SavePlaybackStateRequest(
  playbackType: switch (draft.playbackType) {
    PlaybackStateType.track => api.SavePlaybackStateRequestPlaybackType.track,
    PlaybackStateType.podcast =>
      api.SavePlaybackStateRequestPlaybackType.podcast,
  },
  playbackId: draft.playbackId?.value,
  podcastId: draft.podcastId,
  currentIndex: draft.currentIndex,
  currentTime: draft.currentTime,
  isShuffle: draft.isShuffle,
  isPlaying: draft.isPlaying,
  queue: [for (final entry in draft.queue) _queueItem(entry)],
);

api.SavePlaybackStateRequestQueueItem _queueItem(PlaybackStateEntry entry) =>
    switch (entry) {
      TrackStateEntry(:final playbackId, :final meta) =>
        api.SavePlaybackStateRequestQueueItem(
          itemType: api.SavePlaybackStateRequestQueueItemItemType.track,
          playbackId: playbackId?.value,
          metadata: playbackMetadataFromMeta(meta),
        ),
      EpisodeStateEntry() => api.SavePlaybackStateRequestQueueItem(
        itemType: api.SavePlaybackStateRequestQueueItemItemType.episode,
        // The web client's episode item id.
        id: '${entry.podcastId}:${entry.episodeId}',
        episodeId: entry.episodeId,
        podcastId: entry.podcastId,
        title: entry.title,
        podcastTitle: entry.podcastTitle,
        duration: entry.durationSec,
        coverUrl: entry.coverUrl,
      ),
    };

/// Maps a stored state; null for a kind this app does not play.
RemotePlaybackState? remotePlaybackStateFromWire(api.PlaybackState state) {
  final type = switch (state.playbackType) {
    api.PlaybackStatePlaybackTypeKnown(
      value: api.PlaybackStatePlaybackTypeValue.track,
    ) =>
      PlaybackStateType.track,
    api.PlaybackStatePlaybackTypeKnown(
      value: api.PlaybackStatePlaybackTypeValue.podcast,
    ) =>
      PlaybackStateType.podcast,
    _ => null,
  };
  if (type == null) return null;
  return RemotePlaybackState(
    playbackType: type,
    podcastId: state.podcastId,
    currentIndex: state.currentIndex,
    currentTime: state.currentTime.toDouble(),
    isShuffle: state.isShuffle,
    isPlaying: state.isPlaying,
    updatedAt: state.updatedAt,
    queue: [
      for (final item in state.queue ?? const <api.PlaybackQueueItem>[])
        ?_entryFromWire(item),
    ],
  );
}

PlaybackStateEntry? _entryFromWire(api.PlaybackQueueItem item) {
  if (item.itemType case api.PlaybackQueueItemItemTypeKnown(
    value: api.PlaybackQueueItemItemTypeValue.episode,
  )) {
    final podcastId = item.podcastId;
    final episodeId = item.episodeId;
    if (podcastId == null || episodeId == null) return null;
    return PlaybackStateEntry.episode(
      podcastId: podcastId,
      episodeId: episodeId,
      title: item.title,
      podcastTitle: item.podcastTitle ?? '',
      durationSec: item.duration.round(),
      coverUrl: item.coverUrl,
    );
  }
  final playbackId = item.playbackId;
  return PlaybackStateEntry.track(
    playbackId: playbackId == null ? null : PlaybackId(playbackId),
    meta: TrackMeta(
      title: item.title,
      artist: item.artist?.name ?? '',
      album: item.album?.title ?? '',
      durationSec: item.duration.round(),
      artworkRef: item.album?.coverArt ?? item.coverUrl,
    ),
  );
}
