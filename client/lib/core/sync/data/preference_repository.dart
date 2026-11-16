// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/shared/domain/track.dart';

/// Likes and unlikes tracks and albums through the outbox (doc 07, Outbox).
///
/// The client has two states, liked and not liked: liking sends
/// `thumbs_up` and unliking sends `clear`, whatever the server held before,
/// so a disliked track is liked by one tap. `thumbs_down` is never sent.
/// Reads show the change at once through their optimistic overlays; the
/// outbox handlers are the only callers of the preference endpoints.
final class PreferenceRepository {
  /// Creates a repository that enqueues into [_outbox].
  new(this._outbox);

  final Outbox _outbox;

  /// Likes [track] when [liked] is true and removes its like otherwise.
  ///
  /// Throws [StateError] when [track] has no `playbackId`: such a track
  /// cannot be liked, and the UI offers no heart for it.
  Future<void> setTrackLiked(Track track, {required bool liked}) async {
    final id = track.playbackId;
    if (id == null) {
      throw StateError('A track without a playbackId cannot be liked');
    }
    await _outbox.enqueue(
      PreferenceOp(
        playbackId: id.value,
        signal: likeSignal(liked: liked),
        metadata: track.meta.toJson(),
      ),
    );
  }

  /// Likes the album [albumId] when [liked] is true and removes its like
  /// otherwise.
  Future<void> setAlbumLiked(String albumId, {required bool liked}) async {
    await _outbox.enqueue(
      AlbumPreferenceOp(
        albumId: albumId,
        signal: likeSignal(liked: liked),
      ),
    );
  }
}

/// The signal that sets a like: `thumbs_up` when [liked], `clear`
/// otherwise.
PreferenceSignal likeSignal({required bool liked}) =>
    liked ? PreferenceSignal.thumbsUp : PreferenceSignal.clear;

/// The domain [Preference] of [signal].
Preference preferenceOfSignal(PreferenceSignal signal) => switch (signal) {
  PreferenceSignal.thumbsUp => Preference.liked,
  PreferenceSignal.thumbsDown => Preference.disliked,
  PreferenceSignal.clear => Preference.neutral,
};
