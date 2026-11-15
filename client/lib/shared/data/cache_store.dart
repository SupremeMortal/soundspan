// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/cache/cache_pruner.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// A cached value and when it was fetched, in UTC.
typedef CacheEntry<T> = ({T value, DateTime fetchedAt});

/// A cached list: its entities in position order and the list's metadata.
///
/// `items` are domain values: [Track], [Album], [Artist] or
/// [PlaylistSummary]. An entry whose entity is missing or cannot be decoded
/// is left out.
typedef CacheListSnapshot = ({
  List<Object> items,
  int? total,
  DateTime fetchedAt,
  bool complete,
});

/// Every read and write against one profile's [CacheDatabase] (doc 05).
///
/// Entities are stored as a JSON blob plus the columns queried locally; a
/// row whose JSON cannot be decoded is a miss. Every read is a drift watch
/// query.
class CacheStore {
  /// A store over [_db] that stamps rows with the time of [_clock].
  new(this._db, this._clock) : _pruner = CachePruner(_db, _clock);

  final CacheDatabase _db;
  final Clock _clock;
  final CachePruner _pruner;

  /// The cache key of [track]: its playback id, else `"x:"` and the SHA-1 of
  /// `title|artist|album|duration`, so a track that cannot be played still
  /// has a stable identity.
  static String trackKey(Track track) {
    if (track.playbackId case final playbackId?) return playbackId.value;
    final meta = track.meta;
    final digest = sha1.convert(
      utf8.encode(
        '${meta.title}|${meta.artist}|${meta.album}|${meta.durationSec}',
      ),
    );
    return 'x:$digest';
  }

  /// Runs [action] in one transaction.
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  /// Stores [tracks], replacing rows with the same key.
  Future<void> upsertTracks(Iterable<Track> tracks) {
    final now = _clock.now();
    return _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.tracks, [
        for (final track in tracks)
          TracksCompanion.insert(
            key: trackKey(track),
            playbackId: Value(track.playbackId?.value),
            json: jsonEncode(track),
            albumId: Value(track.albumId),
            artistId: Value(track.artistId),
            title: track.meta.title,
            fetchedAt: now,
          ),
      ]),
    );
  }

  /// Stores [albums]. With [detail], their detail is marked as fetched now;
  /// otherwise a stored detail time is kept.
  Future<void> upsertAlbums(Iterable<Album> albums, {bool detail = false}) {
    final now = _clock.now();
    return _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.albums, [
        for (final album in albums)
          AlbumsCompanion(
            id: Value(album.id),
            json: Value(jsonEncode(album)),
            title: Value(album.title),
            artistName: Value(album.artistName),
            year: Value(album.year),
            fetchedAt: Value(now),
            detailFetchedAt: detail ? Value(now) : const Value.absent(),
          ),
      ]),
    );
  }

  /// Stores [artists]. With [detail], their detail is marked as fetched now;
  /// otherwise a stored detail time is kept.
  Future<void> upsertArtists(Iterable<Artist> artists, {bool detail = false}) {
    final now = _clock.now();
    return _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.artists, [
        for (final artist in artists)
          ArtistsCompanion(
            id: Value(artist.id),
            json: Value(jsonEncode(artist)),
            name: Value(artist.name),
            fetchedAt: Value(now),
            detailFetchedAt: detail ? Value(now) : const Value.absent(),
          ),
      ]),
    );
  }

  /// Stores [playlists]. With [detail], their detail is marked as fetched
  /// now; otherwise a stored detail time is kept.
  Future<void> upsertPlaylists(
    Iterable<PlaylistSummary> playlists, {
    bool detail = false,
  }) {
    final now = _clock.now();
    return _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.playlists, [
        for (final playlist in playlists)
          PlaylistsCompanion(
            id: Value(playlist.id),
            json: Value(jsonEncode(playlist)),
            name: Value(playlist.name),
            fetchedAt: Value(now),
            detailFetchedAt: detail ? Value(now) : const Value.absent(),
          ),
      ]),
    );
  }

  /// The track stored under [key], or null.
  Stream<CacheEntry<Track>?> watchTrack(String key) =>
      (_db.select(_db.tracks)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .distinct()
          .map((row) => _entry(row?.json, row?.fetchedAt, Track.fromJson));

  /// The album [id], or null.
  Stream<CacheEntry<Album>?> watchAlbum(String id) =>
      (_db.select(_db.albums)..where((a) => a.id.equals(id)))
          .watchSingleOrNull()
          .distinct()
          .map((row) => _entry(row?.json, row?.fetchedAt, Album.fromJson));

  /// The artist [id], or null.
  Stream<CacheEntry<Artist>?> watchArtist(String id) =>
      (_db.select(_db.artists)..where((a) => a.id.equals(id)))
          .watchSingleOrNull()
          .distinct()
          .map((row) => _entry(row?.json, row?.fetchedAt, Artist.fromJson));

  /// The playlist [id], or null.
  Stream<CacheEntry<PlaylistSummary>?> watchPlaylist(String id) =>
      (_db.select(
        _db.playlists,
      )..where((p) => p.id.equals(id))).watchSingleOrNull().distinct().map(
        (row) => _entry(row?.json, row?.fetchedAt, PlaylistSummary.fromJson),
      );

  /// Stores [json] (anything `jsonEncode` accepts) as the blob [key],
  /// fetched now.
  Future<void> putBlob(String key, Object? json) async {
    await _db
        .into(_db.blobs)
        .insertOnConflictUpdate(
          BlobsCompanion.insert(
            key: key,
            json: jsonEncode(json),
            fetchedAt: _clock.now(),
          ),
        );
  }

  /// The blob [key] decoded by [decode], or null.
  ///
  /// A blob that fails to decode is a miss: its row is deleted and null is
  /// emitted.
  Stream<CacheEntry<T>?> watchBlob<T>(
    String key,
    T Function(Object? json) decode,
  ) => (_db.select(_db.blobs)..where((b) => b.key.equals(key)))
      .watchSingleOrNull()
      .distinct()
      .asyncMap((row) async {
        if (row == null) return null;
        try {
          return (
            value: decode(jsonDecode(row.json)),
            fetchedAt: row.fetchedAt,
          );
        } on Object {
          // An undecodable blob is a cache miss (doc 05).
          await (_db.delete(_db.blobs)..where((b) => b.key.equals(key))).go();
          return null;
        }
      })
      .distinct();

  /// Writes one page of the list [listKey]: upserts [items] ([Track],
  /// [Album], [Artist] or [PlaylistSummary]) and replaces the entries from
  /// [offset] to `offset + items.length`, in one transaction.
  ///
  /// The list records [total], [complete] and the fetch time; when [total]
  /// is known, entries at or beyond it are dropped.
  Future<void> writePage(
    String listKey, {
    required int offset,
    required List<Object> items,
    int? total,
    bool complete = false,
  }) => _db.transaction(() async {
    final now = _clock.now();
    final refs = <(CacheEntityKind, String)>[];
    final tracks = <Track>[];
    final albums = <Album>[];
    final artists = <Artist>[];
    final playlists = <PlaylistSummary>[];
    for (final item in items) {
      switch (item) {
        case final Track track:
          tracks.add(track);
          refs.add((CacheEntityKind.track, trackKey(track)));
        case final Album album:
          albums.add(album);
          refs.add((CacheEntityKind.album, album.id));
        case final Artist artist:
          artists.add(artist);
          refs.add((CacheEntityKind.artist, artist.id));
        case final PlaylistSummary playlist:
          playlists.add(playlist);
          refs.add((CacheEntityKind.playlist, playlist.id));
        default:
          throw ArgumentError.value(item, 'items', 'not a cacheable entity');
      }
    }
    await upsertTracks(tracks);
    await upsertAlbums(albums);
    await upsertArtists(artists);
    await upsertPlaylists(playlists);

    await _db
        .into(_db.lists)
        .insertOnConflictUpdate(
          ListsCompanion.insert(
            listKey: listKey,
            total: Value(total),
            fetchedAt: now,
            complete: Value(complete),
            lastReadAt: now,
          ),
        );
    await (_db.delete(_db.listEntries)..where(
          (e) =>
              e.listKey.equals(listKey) &
              e.position.isBetweenValues(offset, offset + items.length - 1),
        ))
        .go();
    if (total != null) {
      await (_db.delete(_db.listEntries)..where(
            (e) =>
                e.listKey.equals(listKey) &
                e.position.isBiggerOrEqualValue(total),
          ))
          .go();
    }
    await _db.batch(
      (batch) => batch.insertAll(_db.listEntries, [
        for (final (index, (kind, key)) in refs.indexed)
          ListEntriesCompanion.insert(
            listKey: listKey,
            position: offset + index,
            entityKind: kind,
            entityKey: key,
          ),
      ]),
    );
  });

  /// The list [listKey], or null when it is not cached.
  ///
  /// Listening marks the list as read, which keeps it from being pruned.
  Stream<CacheListSnapshot?> watchList(String listKey) async* {
    await _pruner.touchList(listKey);
    yield* _db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            _db.lists,
            _db.listEntries,
            _db.tracks,
            _db.albums,
            _db.artists,
            _db.playlists,
          },
        )
        .watch()
        .asyncMap((_) => _readList(listKey))
        .distinct(_sameList);
  }

  Future<CacheListSnapshot?> _readList(String listKey) async {
    final list = await (_db.select(
      _db.lists,
    )..where((l) => l.listKey.equals(listKey))).getSingleOrNull();
    if (list == null) return null;
    final entries =
        await (_db.select(_db.listEntries)
              ..where((e) => e.listKey.equals(listKey))
              ..orderBy([(e) => OrderingTerm.asc(e.position)]))
            .get();
    final keysByKind = <CacheEntityKind, Set<String>>{};
    for (final entry in entries) {
      (keysByKind[entry.entityKind] ??= {}).add(entry.entityKey);
    }
    final decoded = <(CacheEntityKind, String), Object>{};
    Future<void> load<R>(
      CacheEntityKind kind,
      Future<List<R>> rows,
      String Function(R row) key,
      String Function(R row) json,
      Object Function(Map<String, Object?> json) decode,
    ) async {
      for (final row in await rows) {
        final value = _decode(json(row), decode);
        if (value != null) decoded[(kind, key(row))] = value;
      }
    }

    if (keysByKind[CacheEntityKind.track] case final keys?) {
      await load(
        CacheEntityKind.track,
        (_db.select(_db.tracks)..where((t) => t.key.isIn(keys))).get(),
        (row) => row.key,
        (row) => row.json,
        Track.fromJson,
      );
    }
    if (keysByKind[CacheEntityKind.album] case final keys?) {
      await load(
        CacheEntityKind.album,
        (_db.select(_db.albums)..where((a) => a.id.isIn(keys))).get(),
        (row) => row.id,
        (row) => row.json,
        Album.fromJson,
      );
    }
    if (keysByKind[CacheEntityKind.artist] case final keys?) {
      await load(
        CacheEntityKind.artist,
        (_db.select(_db.artists)..where((a) => a.id.isIn(keys))).get(),
        (row) => row.id,
        (row) => row.json,
        Artist.fromJson,
      );
    }
    if (keysByKind[CacheEntityKind.playlist] case final keys?) {
      await load(
        CacheEntityKind.playlist,
        (_db.select(_db.playlists)..where((p) => p.id.isIn(keys))).get(),
        (row) => row.id,
        (row) => row.json,
        PlaylistSummary.fromJson,
      );
    }
    return (
      items: [
        for (final entry in entries)
          ?decoded[(entry.entityKind, entry.entityKey)],
      ],
      total: list.total,
      fetchedAt: list.fetchedAt,
      complete: list.complete,
    );
  }

  static bool _sameList(CacheListSnapshot? a, CacheListSnapshot? b) {
    if (a == null || b == null) return a == b;
    return a.total == b.total &&
        a.fetchedAt == b.fetchedAt &&
        a.complete == b.complete &&
        const ListEquality<Object>().equals(a.items, b.items);
  }

  static CacheEntry<T>? _entry<T>(
    String? json,
    DateTime? fetchedAt,
    T Function(Map<String, Object?> json) decode,
  ) {
    if (json == null || fetchedAt == null) return null;
    final value = _decode(json, decode);
    return value == null ? null : (value: value, fetchedAt: fetchedAt);
  }

  static T? _decode<T>(
    String json,
    T Function(Map<String, Object?> json) decode,
  ) {
    try {
      return decode(jsonDecode(json) as Map<String, Object?>);
    } on Object {
      // A row that cannot be decoded is a cache miss (doc 05).
      return null;
    }
  }
}
