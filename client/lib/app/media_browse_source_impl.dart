// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The [MediaBrowseSource] of the profile scope: Android Auto's lists read
/// through the profile's cached repositories (doc 10, Android Auto).
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';

final AppLogger _log = AppLogger.scope('AndroidAuto');

/// [MediaBrowseSource] over the cached repositories: every read is cache
/// first, so lists loaded before are served without a network.
///
/// Recent is the top tracks of the Continue Listening artists, in that
/// order: the server lists recently listened artists and podcasts, not
/// tracks. An artist that fails to load is skipped. Playlists and albums
/// load page by page up to their limits; a read that takes longer than
/// [readWait] ends with what has loaded.
final class MediaBrowseSourceImpl implements MediaBrowseSource {
  /// Creates the source over the repositories the functions open.
  new({
    required this._library,
    required this._playlists,
    required this._home,
    required this._search,
  });

  /// How long one read waits for the cache or the network.
  static const Duration readWait = Duration(seconds: 10);

  /// The most playlists listed.
  static const int playlistLimit = 500;

  final Future<LibraryRepository> Function() _library;
  final Future<PlaylistRepository> Function() _playlists;
  final Future<HomeRepository> Function() _home;
  final Future<SearchRepository> Function() _search;

  @override
  Future<List<Track>> recent({int limit = 50}) async {
    final recent = await _first((await _home()).recentlyListened());
    final library = await _library();
    final tracks = <Track>[];
    for (final item in recent) {
      if (tracks.length >= limit) break;
      if (item is! RecentArtist) continue;
      try {
        final detail = await _first(library.artist(item.artist.id));
        tracks.addAll(detail.topTracks.take(limit - tracks.length));
      } on Object catch (error, stackTrace) {
        _log.warning('Recent artist not loaded', const {}, error, stackTrace);
      }
    }
    return tracks;
  }

  @override
  Future<List<BrowsePlaylist>> playlists() async => [
    for (final playlist in await _loadAll(
      (await _playlists()).playlists(),
      playlistLimit,
    ))
      BrowsePlaylist(
        id: playlist.id,
        name: playlist.name,
        trackCount: playlist.trackCount,
      ),
  ];

  @override
  Future<List<Track>> playlistTracks(String playlistId) async {
    final detail = await _first((await _playlists()).playlist(playlistId));
    return [
      for (final item in detail.items)
        if (item.isPlayable) item.track,
    ];
  }

  @override
  Future<List<BrowseAlbum>> albums({int limit = 200}) async => [
    for (final album in await _loadAll(
      (await _library()).albums(const AlbumQuery(sortBy: AlbumSort.name)),
      limit,
    ))
      BrowseAlbum(id: album.id, title: album.title, artist: album.artistName),
  ];

  @override
  Future<List<Track>> albumTracks(String albumId) async =>
      (await _first((await _library()).album(albumId))).tracks;

  @override
  Future<List<Track>> searchTracks(String query, {int limit = 25}) async {
    final page = await _first(
      (await _search()).search(query, SearchFilter.songs),
    );
    return [
      for (final item in page.items)
        if (item.hit case TrackHit(:final track)) track,
    ].take(limit).toList();
  }

  /// The first value of a cache-first read.
  static Future<T> _first<T>(Stream<Cached<T>> reads) async =>
      (await reads.first.timeout(readWait)).value;

  /// The first [limit] items of [source], in order, which is disposed
  /// after. A failed page or [readWait] ends the load with what has
  /// loaded; a failure with nothing loaded throws.
  static Future<List<T>> _loadAll<T>(PagedSource<T> source, int limit) async {
    PagedSnapshot<T>? latest;
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
          snapshot.loadedCount == 0 ? finish(error) : finish();
        }
      },
      onError: finish,
      onDone: finish,
    );
    source.ensureVisible(0, limit - 1);
    try {
      await done.future.timeout(readWait);
    } on TimeoutException {
      // Serve what has loaded.
    } finally {
      unawaited(subscription.cancel());
      source.dispose();
    }
    final loaded = <T>[];
    for (var index = 0; index < limit; index++) {
      final item = latest?.itemAt(index);
      if (item == null) break;
      loaded.add(item);
    }
    return loaded;
  }
}

/// The profile's [MediaBrowseSource]. Creating it opens no repository:
/// each read opens the ones it needs.
final Provider<MediaBrowseSource> mediaBrowseSourceProvider =
    Provider<MediaBrowseSource>(
      (ref) => MediaBrowseSourceImpl(
        library: () => ref.read(libraryRepositoryProvider.future),
        playlists: () => ref.read(playlistRepositoryProvider.future),
        home: () => ref.read(homeRepositoryProvider.future),
        search: () => ref.read(searchRepositoryProvider.future),
      ),
      dependencies: [
        libraryRepositoryProvider,
        playlistRepositoryProvider,
        homeRepositoryProvider,
        searchRepositoryProvider,
      ],
    );
