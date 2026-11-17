// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// How the playlist data layer tells downloads that a playlist's tracks
/// changed (doc 07, Keeping Collections Current), without `core` importing
/// the layers above it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/shared/domain/track.dart';

/// Told when a playlist's track list is known to have changed: after a
/// successful detail refresh and after every local add, remove or reorder.
abstract interface class PinnedPlaylistListener {
  /// Playlist [playlistId] now holds [tracks], in order, under [title]
  /// with the cover [artworkRef].
  Future<void> onPlaylistTracksChanged(
    String playlistId,
    List<Track> tracks, {
    required String title,
    String? artworkRef,
  });
}

/// The profile's [PinnedPlaylistListener] as the playlist repository holds
/// it: it forwards to the [listener] the downloads set when they start
/// (`CollectionUpkeep`), and does nothing before that or where nothing can
/// be downloaded. A listener's error is logged, never thrown at the
/// caller.
final class PinnedPlaylistRelay implements PinnedPlaylistListener {
  static final AppLogger _log = AppLogger.scope('Downloads');

  /// The listener calls go to, or null.
  PinnedPlaylistListener? listener;

  /// Whether a call would reach a listener.
  bool get isListening => listener != null;

  @override
  Future<void> onPlaylistTracksChanged(
    String playlistId,
    List<Track> tracks, {
    required String title,
    String? artworkRef,
  }) async {
    final target = listener;
    if (target == null) return;
    try {
      await target.onPlaylistTracksChanged(
        playlistId,
        tracks,
        title: title,
        artworkRef: artworkRef,
      );
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Could not follow a playlist change',
        const {},
        error,
        stackTrace,
      );
    }
  }
}

/// The [PinnedPlaylistRelay] of the profile scope.
final Provider<PinnedPlaylistRelay> pinnedPlaylistRelayProvider =
    Provider<PinnedPlaylistRelay>(
      (ref) => PinnedPlaylistRelay(),
      dependencies: [profileContextProvider],
    );
