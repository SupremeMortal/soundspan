// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The platform-neutral half of the OS media controls (doc 06, OS Media
/// Controls): what a platform adapter is given to show, and what it calls
/// back when the user presses a button.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';

part 'media_controls.freezed.dart';

/// The OS media surface of one platform: notification, lock screen, Now
/// Playing, Media Session API, MPRIS or SMTC.
///
/// The adapter holds no state of its own; it renders the latest
/// [MediaSessionState] it was given.
abstract interface class MediaControls {
  /// Registers the surface with the OS; button presses are sent to
  /// [handler] from then on. Called once.
  Future<void> init(MediaCommandHandler handler);

  /// Shows [state]: metadata, playing flag, position, speed and the enabled
  /// actions.
  void update(MediaSessionState state);

  /// Removes the surface.
  Future<void> dispose();
}

/// What the OS media surface asks the player to do.
abstract interface class MediaCommandHandler {
  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback.
  Future<void> stop();

  /// Skips to the next item.
  Future<void> next();

  /// Goes to the previous item, or to the start of the current one.
  Future<void> previous();

  /// Moves to [position] in the current item.
  Future<void> seek(Duration position);

  /// Moves forward by the skip interval.
  Future<void> skipForward();

  /// Moves back by the skip interval.
  Future<void> skipBackward();

  /// Likes or unlikes the current item.
  Future<void> setLiked(bool liked);

  /// The library Android Auto browses (doc 10, Android Auto); null when
  /// there is none to browse.
  MediaBrowseSource? get browseSource;

  /// Replaces the queue with the tracks of [request] and plays from its
  /// start index.
  Future<void> playRequest(PlayRequest request);
}

/// An action the OS media surface may offer.
enum MediaAction {
  /// Start or resume.
  play,

  /// Pause.
  pause,

  /// Skip to the next item.
  next,

  /// Go to the previous item.
  previous,

  /// Move within the item.
  seek,

  /// Stop.
  stop,

  /// Move forward by the skip interval.
  skipForward,

  /// Move back by the skip interval.
  skipBackward,

  /// Like the item.
  like,
}

/// What the OS media surface shows (doc 06, OS Media Controls).
@freezed
abstract class MediaSessionState with _$MediaSessionState {
  /// Creates a state.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory MediaSessionState({
    /// The item's title.
    required String title,

    /// The artist, or for an episode the podcast's title.
    required String artist,

    /// The album; empty for an episode.
    required String album,

    /// The position in the item when the state was made.
    required Duration position,

    /// The play intent.
    required bool playing,

    /// Whether playback waits for data.
    required bool buffering,

    /// The playback speed.
    required double speed,

    /// How far [MediaAction.skipForward] and [MediaAction.skipBackward]
    /// move.
    required Duration skipInterval,

    /// The actions the surface offers.
    required Set<MediaAction> actions,

    /// The queue entry shown, null when nothing is current.
    String? queueItemId,

    /// The item's duration once known.
    Duration? duration,

    /// The artwork as a URI the OS can load without credentials: a local
    /// file, or on web a URL carrying the access token.
    Uri? artworkUri,

    /// Whether the current item is liked; what [MediaAction.like] shows.
    @Default(false) bool liked,
  }) = _MediaSessionState;

  /// Nothing is playing and no action is offered.
  static const MediaSessionState empty = MediaSessionState(
    title: '',
    artist: '',
    album: '',
    position: Duration.zero,
    playing: false,
    buffering: false,
    speed: 1,
    skipInterval: Duration(seconds: 15),
    actions: {},
  );
}

/// [MediaControls] that show nothing: the targets without an adapter.
final class NoopMediaControls implements MediaControls {
  /// Creates the no-op controls.
  const new();

  @override
  Future<void> init(MediaCommandHandler handler) async {}

  @override
  void update(MediaSessionState state) {}

  @override
  Future<void> dispose() async {}
}
