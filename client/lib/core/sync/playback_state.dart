// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'playback_state.freezed.dart';

/// What a stored playback state plays (doc 06, Playback-State Sync).
enum PlaybackStateType {
  /// Music tracks.
  track,

  /// A podcast's episodes.
  podcast,
}

/// One queue entry of a playback state.
@freezed
sealed class PlaybackStateEntry with _$PlaybackStateEntry {
  /// A music track, sent as `{ playbackId, metadata }`. A stored entry the
  /// server could not give a `playbackId` has none.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PlaybackStateEntry.track({
    /// The track's playback id, if the server gave one.
    required PlaybackId? playbackId,

    /// What the client shows and sends as `metadata`.
    required TrackMeta meta,
  }) = TrackStateEntry;

  /// A podcast episode, in the server's episode item shape.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PlaybackStateEntry.episode({
    /// The podcast.
    required String podcastId,

    /// The episode.
    required String episodeId,

    /// The episode title.
    required String title,

    /// The podcast title.
    required String podcastTitle,

    /// The duration in whole seconds.
    required int durationSec,

    /// The episode's cover URL, if any.
    String? coverUrl,
  }) = EpisodeStateEntry;
}

/// The playback state this device posts (`POST /playback-state`).
@freezed
abstract class PlaybackStateDraft with _$PlaybackStateDraft {
  /// Creates a draft.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PlaybackStateDraft({
    /// What is playing.
    required PlaybackStateType playbackType,

    /// The index of the current entry in [queue].
    required int currentIndex,

    /// The position in the current entry, in seconds.
    required double currentTime,

    /// Whether shuffle is on.
    required bool isShuffle,

    /// Whether playback is running.
    required bool isPlaying,

    /// The window of the play order the server stores.
    required List<PlaybackStateEntry> queue,

    /// The current track, for a track state.
    PlaybackId? playbackId,

    /// The current podcast, for a podcast state.
    String? podcastId,
  }) = _PlaybackStateDraft;
}

/// The playback state the server stored for this device
/// (`GET /playback-state`).
@freezed
abstract class RemotePlaybackState with _$RemotePlaybackState {
  /// Creates a stored state.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory RemotePlaybackState({
    /// What was playing.
    required PlaybackStateType playbackType,

    /// The index of the current entry in [queue].
    required int currentIndex,

    /// The position in the current entry, in seconds.
    required double currentTime,

    /// Whether shuffle was on.
    required bool isShuffle,

    /// Whether playback was running.
    required bool isPlaying,

    /// The stored queue, at most 100 entries.
    required List<PlaybackStateEntry> queue,

    /// When the server stored the state, in UTC.
    required DateTime updatedAt,

    /// The current podcast, for a podcast state.
    String? podcastId,
  }) = _RemotePlaybackState;
}
