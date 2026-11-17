// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan/shared/util/uuid.dart';

final AppLogger _log = AppLogger.scope('PlayActions');

/// A one-shot message of [PlayActions] for the UI, shown as a snackbar.
sealed class PlayNotice {
  const new();
}

/// The queue holds at most [queued] items and the rest were left out.
final class QueueTruncated extends PlayNotice {
  /// Creates the notice.
  const new(this.queued);

  /// How many items the queue holds, [QueueReducer.maxItems].
  final int queued;
}

/// Loading a collection to play failed with [error]; nothing was queued.
final class PlayLoadFailed extends PlayNotice {
  /// Creates the notice.
  const new(this.error);

  /// What the load failed with.
  final Object error;
}

/// The one place outside the player UI that changes the queue on the
/// user's behalf (doc 09, Components; doc 06, Queue Model): playing a list
/// from a row, playing an album, playlist or artist, playing an episode,
/// Play next and Add to queue.
///
/// Only playable tracks are queued: a track with a `playbackId` (a playlist
/// also leaves out items the server marks not playable). Each queued track
/// becomes a [TrackQueueItem] with a fresh `queueItemId`. Collections load
/// through the library and playlist repositories, from the cache first; a
/// failed load is reported to [_notify] and queues nothing, as is a queue
/// cut at [QueueReducer.maxItems].
class PlayActions {
  /// Creates the actions over [_controller] and the repositories the two
  /// functions open, reporting to [_notify]; shuffled starts are drawn from
  /// [random].
  new({
    required this._controller,
    required this._library,
    required this._playlists,
    required this._notify,
    Random? random,
  }) : _random = random ?? Random();

  final PlaybackController _controller;
  final Future<LibraryRepository> Function() _library;
  final Future<PlaylistRepository> Function() _playlists;
  final void Function(PlayNotice notice) _notify;
  final Random _random;

  /// How long loading a paged collection waits for its next page before it
  /// plays what it has.
  static const Duration pageWait = Duration(seconds: 10);

  /// The reserved playlist id of the user's liked tracks.
  static const String likedPlaylistId = 'liked';

  /// Replaces the queue with the playable [tracks] in order and plays the
  /// one at [startIndex]; nothing happens when that track is not playable.
  Future<void> playTracks(
    List<Track> tracks, {
    required int startIndex,
    required QueueContext context,
  }) async {
    if (startIndex < 0 || startIndex >= tracks.length) return;
    if (!_isPlayable(tracks[startIndex])) return;
    final playable = <Track>[];
    var start = 0;
    for (var index = 0; index < tracks.length; index++) {
      if (!_isPlayable(tracks[index])) continue;
      if (index == startIndex) start = playable.length;
      playable.add(tracks[index]);
    }
    await _replace(playable, start: start, context: context);
  }

  /// Replaces the queue with the one [episode] of [podcast] and plays it
  /// from its saved progress (doc 06, Podcasts): one episode at a time.
  Future<void> playEpisode(Podcast podcast, Episode episode) =>
      _controller.playItems([
        QueueItem.episode(
          queueItemId: Uuid.v4(),
          episode: episode,
          podcast: podcast,
        ),
      ]);

  /// Inserts the playable [tracks], in order, directly after the current
  /// item; on an empty queue they become the queue, paused.
  Future<void> playNext(List<Track> tracks) => _add(tracks, next: true);

  /// Adds the playable [tracks] at the end of the queue; on an empty queue
  /// they become the queue, paused.
  Future<void> addToQueue(List<Track> tracks) => _add(tracks, next: false);

  /// Replaces the queue with the playable [tracks] of a collection the
  /// caller already holds, such as a mix, under [context]: from the first,
  /// or with [shuffle] on from a random one.
  Future<void> playCollection(
    List<Track> tracks, {
    required QueueContext context,
    bool shuffle = false,
  }) => _playCollection(() async => (tracks, context), shuffle: shuffle);

  /// Plays the album [albumId] from its first track, or shuffled.
  Future<void> playAlbum(String albumId, {bool shuffle = false}) =>
      _playCollection(() async {
        final detail = await _first((await _library()).album(albumId));
        return (
          detail.tracks,
          QueueContext(
            kind: QueueContextKind.album,
            id: albumId,
            title: detail.album.title,
          ),
        );
      }, shuffle: shuffle);

  /// Plays the playlist [playlistId] (or the liked tracks for
  /// [likedPlaylistId]) from its first track, or shuffled.
  Future<void> playPlaylist(String playlistId, {bool shuffle = false}) =>
      _playCollection(() async {
        if (playlistId == likedPlaylistId) {
          final source = (await _library()).likedTracks();
          try {
            return (
              await _loadAll(source),
              const QueueContext(
                kind: QueueContextKind.playlist,
                id: likedPlaylistId,
              ),
            );
          } finally {
            source.dispose();
          }
        }
        final detail = await _first((await _playlists()).playlist(playlistId));
        return (
          [
            for (final item in detail.items)
              if (item.isPlayable) item.track,
          ],
          QueueContext(
            kind: QueueContextKind.playlist,
            id: playlistId,
            title: detail.summary.name,
          ),
        );
      }, shuffle: shuffle);

  /// Plays the Popular tracks of the artist [artistId], or shuffled.
  Future<void> playArtist(String artistId, {bool shuffle = false}) =>
      _playCollection(() async {
        final detail = await _first((await _library()).artist(artistId));
        return (
          detail.topTracks,
          QueueContext(
            kind: QueueContextKind.artist,
            id: artistId,
            title: detail.artist.name,
          ),
        );
      }, shuffle: shuffle);

  /// The playable tracks of the album [albumId], in order, for Play next,
  /// Add to queue and Add to playlist of its menu; empty, reported to the
  /// notices, when loading fails.
  Future<List<Track>> albumTracks(String albumId) => _playableOf(
    () async => (await _first((await _library()).album(albumId))).tracks,
  );

  /// The playable tracks of the playlist [playlistId], in order, for Play
  /// next and Add to queue of its menu; empty, reported to the notices,
  /// when loading fails.
  Future<List<Track>> playlistTracks(String playlistId) =>
      _playableOf(() async {
        final detail = await _first((await _playlists()).playlist(playlistId));
        return [
          for (final item in detail.items)
            if (item.isPlayable) item.track,
        ];
      });

  Future<List<Track>> _playableOf(Future<List<Track>> Function() load) async {
    try {
      return (await load()).where(_isPlayable).toList();
    } on Object catch (error, stackTrace) {
      _failed(error, stackTrace);
      return const [];
    }
  }

  /// "Shuffle all" of Library Songs: plays the library tracks the server
  /// shuffled, in its order, with shuffle off.
  Future<void> shuffleLibrary() async {
    final List<Track> tracks;
    try {
      tracks = await (await _library()).shuffledTracks();
    } on Object catch (error, stackTrace) {
      _failed(error, stackTrace);
      return;
    }
    final playable = tracks.where(_isPlayable).toList();
    if (playable.isEmpty) return;
    await _controller.setShuffle(false);
    await _replace(
      playable,
      start: 0,
      context: const QueueContext(kind: QueueContextKind.library),
    );
  }

  Future<void> _playCollection(
    Future<(List<Track>, QueueContext)> Function() load, {
    required bool shuffle,
  }) async {
    final List<Track> tracks;
    final QueueContext context;
    try {
      (tracks, context) = await load();
    } on Object catch (error, stackTrace) {
      _failed(error, stackTrace);
      return;
    }
    final playable = tracks.where(_isPlayable).toList();
    if (playable.isEmpty) return;
    if (shuffle) await _controller.setShuffle(true);
    await _replace(
      playable,
      // Shuffled, the start item comes first in play order.
      start: shuffle ? _random.nextInt(playable.length) : 0,
      context: context,
    );
  }

  Future<void> _replace(
    List<Track> tracks, {
    required int start,
    required QueueContext context,
  }) async {
    if (tracks.isEmpty) return;
    if (tracks.length > QueueReducer.maxItems) _truncated();
    await _controller.playItems(
      _items(tracks, context),
      startIndex: start,
      context: context,
    );
  }

  Future<void> _add(List<Track> tracks, {required bool next}) async {
    final playable = tracks.where(_isPlayable).toList();
    if (playable.isEmpty) return;
    final queued = _controller.snapshot.queue.items.length;
    if (queued + playable.length > QueueReducer.maxItems) _truncated();
    final items = _items(
      playable,
      const QueueContext(kind: QueueContextKind.single),
    );
    await (next ? _controller.playNext(items) : _controller.append(items));
  }

  List<QueueItem> _items(List<Track> tracks, QueueContext context) => [
    for (final track in tracks)
      QueueItem.track(queueItemId: Uuid.v4(), track: track, context: context),
  ];

  void _truncated() => _notify(const QueueTruncated(QueueReducer.maxItems));

  void _failed(Object error, StackTrace stackTrace) {
    _log.warning(
      'Loading a collection to play failed',
      const {},
      error,
      stackTrace,
    );
    _notify(PlayLoadFailed(error));
  }

  static bool _isPlayable(Track track) => track.playbackId != null;

  /// The first value of a cache-first read.
  static Future<T> _first<T>(Stream<Cached<T>> reads) async =>
      (await reads.first).value;

  /// Every item of [source], up to one more than the queue holds, in
  /// order. After [pageWait] it stops at the first gap and plays what has
  /// loaded.
  static Future<List<Track>> _loadAll(PagedSource<Track> source) async {
    const limit = QueueReducer.maxItems + 1;
    PagedSnapshot<Track>? latest;
    final done = Completer<void>();
    void finish([Object? error]) {
      if (done.isCompleted) return;
      error == null ? done.complete() : done.completeError(error);
    }

    final subscription = source.watch().listen(
      (snapshot) {
        latest = snapshot;
        final total = snapshot.total;
        if (total != null && snapshot.loadedCount >= min(total, limit)) {
          finish();
        } else if (snapshot.refreshError case final error?) {
          // A failed page ends the load; with nothing loaded it fails.
          snapshot.loadedCount == 0 ? finish(error) : finish();
        }
      },
      onError: finish,
      onDone: finish,
    );
    source.ensureVisible(0, limit - 1);
    try {
      await done.future.timeout(pageWait);
    } on TimeoutException {
      // Play what has loaded.
    } finally {
      unawaited(subscription.cancel());
    }
    final loaded = <Track>[];
    for (var index = 0; index < limit; index++) {
      final track = latest?.itemAt(index);
      if (track == null) break;
      loaded.add(track);
    }
    return loaded;
  }
}

/// The [PlayNotice]s of the profile's [PlayActions], for the shell's
/// snackbars; listening does not create the playback controller.
final Provider<StreamController<PlayNotice>> playNoticesProvider =
    Provider<StreamController<PlayNotice>>((ref) {
      // Read only to tie the instance to the profile scope.
      ref.watch(profileContextProvider);
      final notices = StreamController<PlayNotice>.broadcast();
      ref.onDispose(() => unawaited(notices.close()));
      return notices;
    }, dependencies: [profileContextProvider]);

/// The profile's [PlayActions].
final Provider<PlayActions> playActionsProvider = Provider<PlayActions>(
  (ref) {
    // Kept, so a command still reaches the repositories.
    final library = ref.watch(libraryRepositoryProvider.future);
    final playlists = ref.watch(playlistRepositoryProvider.future);
    final notices = ref.watch(playNoticesProvider);
    return PlayActions(
      controller: ref.watch(playbackControllerProvider),
      library: () => library,
      playlists: () => playlists,
      notify: (notice) {
        if (!notices.isClosed) notices.add(notice);
      },
    );
  },
  dependencies: [
    playbackControllerProvider,
    libraryRepositoryProvider,
    playlistRepositoryProvider,
    playNoticesProvider,
  ],
);
