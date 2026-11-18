// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/sync/data/confirmed_track_preferences.dart';
import 'package:soundspan/core/sync/data/preference_repository.dart';
import 'package:soundspan/core/sync/outbox/optimistic_overlay.dart';
import 'package:soundspan/core/sync/sync_providers.dart';
import 'package:soundspan/shared/data/preference_overlay.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// The like command every track list shares (doc 02, Error Model:
/// optimistic writes).
///
/// It has no rollback of its own: the lists show the like through the
/// repositories' overlays, and a dropped write removes it.
abstract interface class TrackLikes {
  /// Likes [track] when it is not liked and removes its like otherwise.
  Future<void> toggleLike(Track track);
}

/// [TrackLikes] through a [PreferenceRepository].
final class RepositoryTrackLikes implements TrackLikes {
  /// Creates the command over [_preferences].
  const new(this._preferences);

  final PreferenceRepository _preferences;

  @override
  Future<void> toggleLike(Track track) =>
      _preferences.setTrackLiked(track, liked: !track.isLiked);
}

/// The profile's [TrackLikes].
final Provider<TrackLikes> trackLikesProvider = Provider<TrackLikes>(
  (ref) => RepositoryTrackLikes(ref.watch(preferenceRepositoryProvider)),
  dependencies: [preferenceRepositoryProvider],
);

/// The album like command of the album page and album menus.
abstract interface class AlbumLikes {
  /// Likes the album [albumId] when [liked] is true and removes its like
  /// otherwise.
  Future<void> setAlbumLiked(String albumId, {required bool liked});
}

/// [AlbumLikes] through a [PreferenceRepository].
final class RepositoryAlbumLikes implements AlbumLikes {
  /// Creates the command over [_preferences].
  const new(this._preferences);

  final PreferenceRepository _preferences;

  @override
  Future<void> setAlbumLiked(String albumId, {required bool liked}) =>
      _preferences.setAlbumLiked(albumId, liked: liked);
}

/// The profile's [AlbumLikes].
final Provider<AlbumLikes> albumLikesProvider = Provider<AlbumLikes>(
  (ref) => RepositoryAlbumLikes(ref.watch(preferenceRepositoryProvider)),
  dependencies: [preferenceRepositoryProvider],
);

/// A track with its current preference: the server's confirmed answer of
/// this session over the preference it was loaded with, and a pending like
/// over both (doc 07, Worker: optimistic state). The players show a queue
/// entry's heart through it, since the queue keeps the track as queued.
final StreamProviderFamily<Track, Track> currentTrackProvider = StreamProvider
    .autoDispose
    .family<Track, Track>((ref, track) {
      final id = track.playbackId;
      if (id == null) return Stream.value(track);
      final confirmed = ref
          .watch(confirmedTrackPreferencesProvider)
          .watch(id.value)
          .map(
            (preference) => preference == null
                ? track
                : track.copyWith(preference: preference),
          );
      return overlayEach(
        confirmed,
        ref.watch(pendingOpsProvider)(trackPreferenceOps),
        (value, ops) => overlayTrack(value, pendingTrackPreferences(ops)),
        hold: preferenceHold,
      );
    }, dependencies: [confirmedTrackPreferencesProvider, pendingOpsProvider]);

final AppLogger _log = AppLogger.scope('Likes');

/// The `onToggleLike` of a row showing [track], through [trackLikesProvider];
/// null for a track without a `playbackId`, which offers no heart.
VoidCallback? toggleLikeOf(WidgetRef ref, Track track) {
  if (track.playbackId == null) return null;
  return () => unawaited(
    ref
        .read(trackLikesProvider)
        .toggleLike(track)
        .catchError(
          (Object error, StackTrace stackTrace) =>
              _log.severe('Like not stored', const {}, error, stackTrace),
        ),
  );
}
