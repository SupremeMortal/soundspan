// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// What is on this device, as the library's domain types: the read-only
/// queries over `state.db` behind the Library's "Downloaded only" filter
/// and local search (doc 07, Reachability and Offline Mode).
///
/// A track is on the device when its item is `completed`. Every list
/// emits again whenever downloads, collections or memberships change.
class DownloadedLibrary {
  /// Queries over [_db].
  new(this._db);

  final StateDatabase _db;

  /// Completed track items, each once whatever collections hold it,
  /// ordered by title (case-insensitive).
  Stream<List<Track>> watchTracks() => _watch(_tracks);

  /// Album collections, then every album with at least one completed
  /// item, once each, ordered by title. A collection's title, subtitle and
  /// artwork win over those of its items.
  Stream<List<Album>> watchAlbums() => _watch(() async {
    final tracks = await _tracks();
    final albums = <String, Album>{};
    for (final row in await _collections(DownloadCollectionKind.album)) {
      final meta = _decode(row.metaJson);
      final first = tracks.where((t) => t.albumId == row.refId).firstOrNull;
      albums[row.refId] = Album(
        id: row.refId,
        title: row.title,
        artistName: _string(meta['subtitle']) ?? first?.meta.artist ?? '',
        artistId: first?.artistId ?? '',
        artworkRef: _string(meta['artworkRef']) ?? first?.meta.artworkRef,
      );
    }
    for (final track in tracks) {
      final id = track.albumId;
      if (id == null || albums.containsKey(id)) continue;
      albums[id] = Album(
        id: id,
        title: track.meta.album,
        artistName: track.meta.artist,
        artistId: track.artistId ?? '',
        artworkRef: track.meta.artworkRef,
      );
    }
    return albums.values.toList()..sort((a, b) => _byText(a.title, b.title));
  });

  /// The distinct artists of completed items, ordered by name.
  Stream<List<Artist>> watchArtists() => _watch(() async {
    final artists = <String, Artist>{};
    for (final track in await _tracks()) {
      final id = track.artistId;
      if (id == null || id.isEmpty || artists.containsKey(id)) continue;
      artists[id] = Artist(id: id, name: track.meta.artist);
    }
    return artists.values.toList()..sort((a, b) => _byText(a.name, b.name));
  });

  /// Playlist collections in request order, each with the number of
  /// items it holds.
  Stream<List<PlaylistSummary>> watchPlaylists() => _watch(() async {
    final summaries = <PlaylistSummary>[];
    for (final row in await _collections(DownloadCollectionKind.playlist)) {
      final meta = _decode(row.metaJson);
      final m = _db.downloadMembership;
      final count = m.itemKey.count();
      final items =
          await (_db.selectOnly(m)
                ..addColumns([count])
                ..where(
                  m.kind.equals(DownloadCollectionKind.playlist.name) &
                      m.refId.equals(row.refId),
                ))
              .map((r) => r.read(count) ?? 0)
              .getSingle();
      summaries.add(
        PlaylistSummary(
          id: row.refId,
          name: row.title,
          trackCount: items,
          isOwner: false,
          isPublic: false,
          coverRefs: [?_string(meta['artworkRef'])],
        ),
      );
    }
    return summaries;
  });

  /// Whether there is at least one download collection, again whenever
  /// that changes.
  Stream<bool> watchHasCollections() => _watch(() async {
    final row = await (_db.select(
      _db.downloadCollections,
    )..limit(1)).getSingleOrNull();
    return row != null;
  }).distinct();

  /// Completed track items, each once, ordered by title.
  Future<List<Track>> tracks() => _tracks();

  /// The album [albumId] built from this device: its downloaded tracks in
  /// disc and track order, under the album collection's title when it is
  /// pinned; null when no track of it is downloaded and it is not pinned.
  Future<AlbumDetail?> albumDetail(String albumId) async {
    final album = (await watchAlbums().first)
        .where((a) => a.id == albumId)
        .firstOrNull;
    if (album == null) return null;
    final tracks = [
      for (final track in await _tracks())
        if (track.albumId == albumId) track,
    ]..sort(_byPosition);
    return AlbumDetail(album: album, tracks: tracks, owned: true);
  }

  /// The artist [artistId] built from this device: its downloaded tracks
  /// by title and the albums they belong to; null when none is downloaded.
  Future<ArtistDetail?> artistDetail(String artistId) async {
    final tracks = [
      for (final track in await _tracks())
        if (track.artistId == artistId) track,
    ];
    if (tracks.isEmpty) return null;
    final albumIds = {for (final track in tracks) ?track.albumId};
    return ArtistDetail(
      artist: Artist(id: artistId, name: tracks.first.meta.artist),
      topTracks: tracks,
      albums: [
        for (final album in await watchAlbums().first)
          if (albumIds.contains(album.id)) album,
      ],
    );
  }

  /// The pinned playlist [playlistId] built from this device: its
  /// downloaded items in playlist order; null when it is not pinned.
  Future<PlaylistDetail?> playlistDetail(String playlistId) async {
    final summary = (await watchPlaylists().first)
        .where((p) => p.id == playlistId)
        .firstOrNull;
    if (summary == null) return null;
    final m = _db.downloadMembership;
    final i = _db.downloadItems;
    final rows =
        await (_db.select(m).join([
                innerJoin(i, i.itemKey.equalsExp(m.itemKey)),
              ])
              ..where(
                m.kind.equals(DownloadCollectionKind.playlist.name) &
                    m.refId.equals(playlistId) &
                    i.status.equals(DownloadStatus.completed.name),
              )
              ..orderBy([OrderingTerm.asc(m.position)]))
            .get();
    final items = <PlaylistItem>[];
    for (final row in rows) {
      final item = row.readTable(i);
      final DownloadItemKey key;
      try {
        key = DownloadItemKey.decode(item.itemKey);
      } on FormatException {
        continue;
      }
      if (key is! TrackItemKey) continue;
      items.add(
        PlaylistItem(
          id: item.itemKey,
          sort: row.readTable(m).position,
          track: trackOfDownload(key, item.metaJson),
          isPlayable: true,
        ),
      );
    }
    return PlaylistDetail(summary: summary, items: items);
  }

  /// The playback ids of every completed track item.
  Future<Set<PlaybackId>> downloadedPlaybackIds() async => {
    for (final track in await _tracks()) ?track.playbackId,
  };

  Future<List<Track>> _tracks() async {
    final rows =
        await (_db.select(_db.downloadItems)..where(
              (i) =>
                  i.status.equals(DownloadStatus.completed.name) &
                  i.mediaType.equals(MediaType.track.name),
            ))
            .get();
    final tracks = <Track>[];
    for (final row in rows) {
      final DownloadItemKey key;
      try {
        key = DownloadItemKey.decode(row.itemKey);
      } on FormatException {
        continue;
      }
      if (key is! TrackItemKey) continue;
      tracks.add(trackOfDownload(key, row.metaJson));
    }
    return tracks..sort((a, b) => _byText(a.meta.title, b.meta.title));
  }

  Future<List<DownloadCollection>> _collections(DownloadCollectionKind kind) =>
      (_db.select(_db.downloadCollections)
            ..where((c) => c.kind.equals(kind.name))
            ..orderBy([(c) => OrderingTerm.asc(c.requestedAt)]))
          .get();

  Stream<T> _watch<T>(Future<T> Function() read) async* {
    yield await read();
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.downloadItems,
        _db.downloadCollections,
        _db.downloadMembership,
      ]),
    )) {
      yield await read();
    }
  }

  static int _byPosition(Track a, Track b) {
    final disc = (a.discNumber ?? 1).compareTo(b.discNumber ?? 1);
    if (disc != 0) return disc;
    return (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
  }

  static int _byText(String a, String b) {
    final order = a.toLowerCase().compareTo(b.toLowerCase());
    return order != 0 ? order : a.compareTo(b);
  }
}

/// The [Track] a downloaded item [key] stands for, from its stored
/// `metaJson` (written by `downloadMetaOf`); unreadable metadata gives
/// empty texts.
Track trackOfDownload(TrackItemKey key, String metaJson) {
  final meta = _decode(metaJson);
  final loudness = meta['loudness'];
  return Track(
    meta: TrackMeta(
      title: _string(meta['title']) ?? '',
      artist: _string(meta['artist']) ?? '',
      album: _string(meta['album']) ?? '',
      durationSec: switch (meta['durationSec']) {
        final num value => value.toInt(),
        _ => 0,
      },
      artworkRef: _string(meta['artworkRef']),
      isrc: _string(meta['isrc']),
    ),
    playbackId: PlaybackId(key.playbackId),
    albumId: _string(meta['albumId']),
    artistId: _string(meta['artistId']),
    loudness: loudness is Map<String, Object?>
        ? Loudness.fromJson(loudness)
        : null,
    discNumber: switch (meta['discNumber']) {
      final num value => value.toInt(),
      _ => null,
    },
    trackNumber: switch (meta['trackNumber']) {
      final num value => value.toInt(),
      _ => null,
    },
  );
}

Map<String, Object?> _decode(String json) {
  try {
    final decoded = jsonDecode(json);
    return decoded is Map<String, Object?> ? decoded : const {};
  } on FormatException {
    return const {};
  }
}

String? _string(Object? value) => value is String ? value : null;

/// The profile's [DownloadedLibrary].
final Provider<DownloadedLibrary> downloadedLibraryProvider =
    Provider<DownloadedLibrary>(
      (ref) => DownloadedLibrary(ref.watch(stateDatabaseProvider)),
      dependencies: [stateDatabaseProvider],
    );
