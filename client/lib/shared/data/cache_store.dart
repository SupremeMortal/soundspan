// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/cache/cache_pruner.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// A cached value and when it was fetched, in UTC.
typedef CacheEntry<T> = ({T value, DateTime fetchedAt});

/// A cached list: its entities in position order and the list's metadata.
///
/// `items` are domain values: [Track], [Album], [Artist], [PlaylistSummary],
/// [Podcast] or [Episode]. An entry whose entity is missing or cannot be decoded
/// is left out. `positions` holds the list position of each item of
/// `items`, so a list cached with gaps between its pages keeps them, and
/// `itemFetchedAt` when each item's entity was last stored, which dates the
/// page that holds it.
typedef CacheListSnapshot = ({
  List<Object> items,
  List<int> positions,
  List<DateTime> itemFetchedAt,
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

  /// The cached tracks, albums, artists and playlists whose title or name
  /// contains [text], ignoring case, up to [limit] of each, ordered by
  /// title or name: the device's half of search while offline (doc 05,
  /// Read Policy). `%` and `_` in [text] match literally.
  Future<LocalSearchMatches> searchLocal(String text, {int limit = 50}) async {
    final escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final pattern = '%$escaped%';
    Future<List<T>> find<T>(
      String table,
      String column,
      T Function(Map<String, Object?> json) decode,
    ) async {
      final rows = await _db
          .customSelect(
            'SELECT json FROM $table '
            "WHERE $column LIKE ?1 ESCAPE '\\' "
            'ORDER BY $column COLLATE NOCASE LIMIT ?2',
            variables: [Variable.withString(pattern), Variable.withInt(limit)],
            readsFrom: {},
          )
          .get();
      return [
        for (final row in rows) ?_decode(row.read<String>('json'), decode),
      ];
    }

    return LocalSearchMatches(
      tracks: await find('tracks', 'title', Track.fromJson),
      albums: await find('albums', 'title', Album.fromJson),
      artists: await find('artists', 'name', Artist.fromJson),
      playlists: await find('playlists', 'name', PlaylistSummary.fromJson),
    );
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

  /// Stores [podcasts], replacing rows with the same id.
  Future<void> upsertPodcasts(Iterable<Podcast> podcasts) {
    final now = _clock.now();
    return _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.podcasts, [
        for (final podcast in podcasts)
          PodcastsCompanion.insert(
            id: podcast.id,
            json: jsonEncode(podcast),
            fetchedAt: now,
          ),
      ]),
    );
  }

  /// Stores [episodes], replacing rows with the same id.
  Future<void> upsertEpisodes(Iterable<Episode> episodes) {
    final now = _clock.now();
    return _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.episodes, [
        for (final episode in episodes)
          EpisodesCompanion.insert(
            id: episode.id,
            podcastId: episode.podcastId,
            json: jsonEncode(episode),
            fetchedAt: now,
          ),
      ]),
    );
  }

  /// The podcast [id] as stored now, or null when it is missing or fails to
  /// decode.
  Future<CacheEntry<Podcast>?> readPodcast(String id) async {
    final row = await (_db.select(
      _db.podcasts,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    return _entry(row?.json, row?.fetchedAt, Podcast.fromJson);
  }

  /// Replaces the cached episode [id] with what [change] makes of it,
  /// keeping its fetch time. Answers false, changing nothing, when the
  /// episode is not cached or fails to decode.
  Future<bool> updateEpisode(String id, Episode Function(Episode) change) =>
      _db.transaction(() async {
        final row = await (_db.select(
          _db.episodes,
        )..where((e) => e.id.equals(id))).getSingleOrNull();
        final episode = row == null
            ? null
            : _decode(row.json, Episode.fromJson);
        if (episode == null) return false;
        await (_db.update(_db.episodes)..where((e) => e.id.equals(id))).write(
          EpisodesCompanion(json: Value(jsonEncode(change(episode)))),
        );
        return true;
      });

  /// Removes the cached episode [id]. A list that holds it no longer reads
  /// whole, so its next read fetches it again.
  Future<void> removeEpisode(String id) =>
      (_db.delete(_db.episodes)..where((e) => e.id.equals(id))).go();

  /// Writes [preference] into every cached copy of the track [playbackId]:
  /// its row and each blob holding it (details, search results), keeping
  /// their fetch times. Lists read the rows, so they show it too.
  Future<void> setTrackPreference(String playbackId, Preference preference) =>
      _db.transaction(() async {
        final rows = await (_db.select(
          _db.tracks,
        )..where((t) => t.playbackId.equals(playbackId))).get();
        for (final row in rows) {
          final track = _decode(row.json, Track.fromJson);
          if (track == null || track.preference == preference) continue;
          await (_db.update(
            _db.tracks,
          )..where((t) => t.key.equals(row.key))).write(
            TracksCompanion(
              json: Value(jsonEncode(track.copyWith(preference: preference))),
            ),
          );
        }
        await _patchBlobs(
          jsonEncode(playbackId),
          (node) => node['playbackId'] == playbackId && node['meta'] is Map,
          preference,
        );
      });

  /// Writes [preference] into every cached copy of the album [albumId]: its
  /// row and each blob holding it, keeping their fetch times.
  Future<void> setAlbumPreference(String albumId, Preference preference) =>
      _db.transaction(() async {
        final row = await (_db.select(
          _db.albums,
        )..where((a) => a.id.equals(albumId))).getSingleOrNull();
        final album = row == null ? null : _decode(row.json, Album.fromJson);
        if (album != null && album.preference != preference) {
          await (_db.update(
            _db.albums,
          )..where((a) => a.id.equals(albumId))).write(
            AlbumsCompanion(
              json: Value(jsonEncode(album.copyWith(preference: preference))),
            ),
          );
        }
        await _patchBlobs(
          jsonEncode(albumId),
          (node) => node['id'] == albumId && node.containsKey('artistName'),
          preference,
        );
      });

  /// Sets `preference` on each JSON object [matches] accepts inside the
  /// blobs whose text holds [needle].
  Future<void> _patchBlobs(
    String needle,
    bool Function(Map<String, Object?> node) matches,
    Preference preference,
  ) async {
    final blobs = await (_db.select(
      _db.blobs,
    )..where((b) => b.json.contains(needle))).get();
    for (final blob in blobs) {
      final Object? json;
      try {
        json = jsonDecode(blob.json);
      } on FormatException {
        continue;
      }
      if (!_patchPreference(json, matches, preference.name)) continue;
      await (_db.update(_db.blobs)..where((b) => b.key.equals(blob.key))).write(
        BlobsCompanion(json: Value(jsonEncode(json))),
      );
    }
  }

  static bool _patchPreference(
    Object? node,
    bool Function(Map<String, Object?> node) matches,
    String value,
  ) {
    var changed = false;
    if (node is Map<String, Object?>) {
      if (matches(node) && node['preference'] != value) {
        node['preference'] = value;
        changed = true;
      }
      for (final child in node.values) {
        changed = _patchPreference(child, matches, value) || changed;
      }
    } else if (node is List<Object?>) {
      for (final child in node) {
        changed = _patchPreference(child, matches, value) || changed;
      }
    }
    return changed;
  }

  /// Marks the list [listKey] as fetched at the epoch, so the next read
  /// fetches it whatever its TTL. Its entries stay for offline reads.
  Future<void> markListStale(String listKey) async {
    await (_db.update(_db.lists)..where((l) => l.listKey.equals(listKey)))
        .write(ListsCompanion(fetchedAt: Value(DateTime.utc(1970))));
  }

  /// Rewrites the cached detail `playlist:<id>` with [change] and marks it
  /// fetched at the epoch, so the next read fetches it (doc 05, Read
  /// Policy: a local edit invalidates the detail). The playlist's row takes
  /// the changed summary. Nothing happens when no detail is cached.
  Future<void> editPlaylistDetail(
    String id,
    PlaylistDetail Function(PlaylistDetail detail) change,
  ) => _db.transaction(() async {
    final key = 'playlist:$id';
    final cached = await readBlob(
      key,
      (json) => PlaylistDetail.fromJson(json! as Map<String, Object?>),
    );
    if (cached == null) return;
    final detail = change(cached.value);
    await _db
        .into(_db.blobs)
        .insertOnConflictUpdate(
          BlobsCompanion.insert(
            key: key,
            json: jsonEncode(detail),
            fetchedAt: DateTime.utc(1970),
          ),
        );
    await (_db.update(_db.playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(
        json: Value(jsonEncode(detail.summary)),
        name: Value(detail.summary.name),
      ),
    );
    await markListStale(key);
  });

  /// Puts [playlist] first in the list [listKey], moving the other entries
  /// down by one, when the list is cached and does not hold it yet; the
  /// playlist's row is stored either way.
  Future<void> prependPlaylist(String listKey, PlaylistSummary playlist) =>
      _db.transaction(() async {
        await upsertPlaylists([playlist]);
        final list = await (_db.select(
          _db.lists,
        )..where((l) => l.listKey.equals(listKey))).getSingleOrNull();
        if (list == null) return;
        final present =
            await (_db.select(_db.listEntries)..where(
                  (e) =>
                      e.listKey.equals(listKey) &
                      e.entityKind.equalsValue(CacheEntityKind.playlist) &
                      e.entityKey.equals(playlist.id),
                ))
                .get();
        if (present.isNotEmpty) return;
        // Two steps, so no intermediate row collides with the key
        // (listKey, position).
        await _db.customUpdate(
          'UPDATE list_entries SET position = -position - 1 '
          'WHERE list_key = ?',
          variables: [Variable(listKey)],
          updates: {_db.listEntries},
        );
        await _db.customUpdate(
          'UPDATE list_entries SET position = -position '
          'WHERE list_key = ? AND position < 0',
          variables: [Variable(listKey)],
          updates: {_db.listEntries},
        );
        await _db
            .into(_db.listEntries)
            .insert(
              ListEntriesCompanion.insert(
                listKey: listKey,
                position: 0,
                entityKind: CacheEntityKind.playlist,
                entityKey: playlist.id,
              ),
            );
        if (list.total case final total?) {
          await (_db.update(_db.lists)..where((l) => l.listKey.equals(listKey)))
              .write(ListsCompanion(total: Value(total + 1)));
        }
      });

  /// Removes the playlist [id] from the cache: its row, its detail and
  /// track list, and its entries in other lists, which close up behind it.
  Future<void> removePlaylist(String id) => _db.transaction(() async {
    final key = 'playlist:$id';
    final entries =
        await (_db.select(_db.listEntries)..where(
              (e) =>
                  e.entityKind.equalsValue(CacheEntityKind.playlist) &
                  e.entityKey.equals(id),
            ))
            .get();
    for (final entry in entries) {
      await (_db.delete(_db.listEntries)..where(
            (e) =>
                e.listKey.equals(entry.listKey) &
                e.position.equals(entry.position),
          ))
          .go();
      await _db.customUpdate(
        'UPDATE list_entries SET position = -position '
        'WHERE list_key = ? AND position > ?',
        variables: [Variable(entry.listKey), Variable(entry.position)],
        updates: {_db.listEntries},
      );
      await _db.customUpdate(
        'UPDATE list_entries SET position = -position - 1 '
        'WHERE list_key = ? AND position < 0',
        variables: [Variable(entry.listKey)],
        updates: {_db.listEntries},
      );
      await _db.customUpdate(
        'UPDATE lists SET total = total - 1 '
        'WHERE list_key = ? AND total IS NOT NULL AND total > 0',
        variables: [Variable(entry.listKey)],
        updates: {_db.lists},
      );
    }
    await (_db.delete(_db.playlists)..where((p) => p.id.equals(id))).go();
    await (_db.delete(_db.lists)..where((l) => l.listKey.equals(key))).go();
    await (_db.delete(_db.blobs)..where((b) => b.key.equals(key))).go();
  });

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

  /// The blob [key] as stored now, decoded by [decode]; null when it is
  /// missing or fails to decode.
  Future<CacheEntry<T>?> readBlob<T>(
    String key,
    T Function(Object? json) decode,
  ) async {
    final row = await (_db.select(
      _db.blobs,
    )..where((b) => b.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    try {
      return (value: decode(jsonDecode(row.json)), fetchedAt: row.fetchedAt);
    } on Object {
      return null;
    }
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
  /// [Album], [Artist], [PlaylistSummary], [Podcast] or [Episode]) and
  /// replaces the entries from
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
    final podcasts = <Podcast>[];
    final episodes = <Episode>[];
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
        case final Podcast podcast:
          podcasts.add(podcast);
          refs.add((CacheEntityKind.podcast, podcast.id));
        case final Episode episode:
          episodes.add(episode);
          refs.add((CacheEntityKind.episode, episode.id));
        default:
          throw ArgumentError.value(item, 'items', 'not a cacheable entity');
      }
    }
    await upsertTracks(tracks);
    await upsertAlbums(albums);
    await upsertArtists(artists);
    await upsertPlaylists(playlists);
    await upsertPodcasts(podcasts);
    await upsertEpisodes(episodes);

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
            _db.podcasts,
            _db.episodes,
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
    final decoded = <(CacheEntityKind, String), (Object, DateTime)>{};
    Future<void> load<R>(
      CacheEntityKind kind,
      Future<List<R>> rows,
      String Function(R row) key,
      String Function(R row) json,
      DateTime Function(R row) fetchedAt,
      Object Function(Map<String, Object?> json) decode,
    ) async {
      for (final row in await rows) {
        final value = _decode(json(row), decode);
        if (value != null) decoded[(kind, key(row))] = (value, fetchedAt(row));
      }
    }

    if (keysByKind[CacheEntityKind.track] case final keys?) {
      await load(
        CacheEntityKind.track,
        (_db.select(_db.tracks)..where((t) => t.key.isIn(keys))).get(),
        (row) => row.key,
        (row) => row.json,
        (row) => row.fetchedAt,
        Track.fromJson,
      );
    }
    if (keysByKind[CacheEntityKind.album] case final keys?) {
      await load(
        CacheEntityKind.album,
        (_db.select(_db.albums)..where((a) => a.id.isIn(keys))).get(),
        (row) => row.id,
        (row) => row.json,
        (row) => row.fetchedAt,
        Album.fromJson,
      );
    }
    if (keysByKind[CacheEntityKind.artist] case final keys?) {
      await load(
        CacheEntityKind.artist,
        (_db.select(_db.artists)..where((a) => a.id.isIn(keys))).get(),
        (row) => row.id,
        (row) => row.json,
        (row) => row.fetchedAt,
        Artist.fromJson,
      );
    }
    if (keysByKind[CacheEntityKind.playlist] case final keys?) {
      await load(
        CacheEntityKind.playlist,
        (_db.select(_db.playlists)..where((p) => p.id.isIn(keys))).get(),
        (row) => row.id,
        (row) => row.json,
        (row) => row.fetchedAt,
        PlaylistSummary.fromJson,
      );
    }
    if (keysByKind[CacheEntityKind.podcast] case final keys?) {
      await load(
        CacheEntityKind.podcast,
        (_db.select(_db.podcasts)..where((p) => p.id.isIn(keys))).get(),
        (row) => row.id,
        (row) => row.json,
        (row) => row.fetchedAt,
        Podcast.fromJson,
      );
    }
    if (keysByKind[CacheEntityKind.episode] case final keys?) {
      await load(
        CacheEntityKind.episode,
        (_db.select(_db.episodes)..where((e) => e.id.isIn(keys))).get(),
        (row) => row.id,
        (row) => row.json,
        (row) => row.fetchedAt,
        Episode.fromJson,
      );
    }
    final items = <Object>[];
    final positions = <int>[];
    final fetchedAts = <DateTime>[];
    for (final entry in entries) {
      if (decoded[(entry.entityKind, entry.entityKey)] case (
        final item,
        final fetchedAt,
      )) {
        items.add(item);
        positions.add(entry.position);
        fetchedAts.add(fetchedAt);
      }
    }
    return (
      items: items,
      positions: positions,
      itemFetchedAt: fetchedAts,
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
        const ListEquality<int>().equals(a.positions, b.positions) &&
        const ListEquality<DateTime>().equals(
          a.itemFetchedAt,
          b.itemFetchedAt,
        ) &&
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

/// What [CacheStore.searchLocal] found.
@immutable
final class LocalSearchMatches {
  /// The matches of each kind.
  const new({
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.playlists,
  });

  /// Tracks by title.
  final List<Track> tracks;

  /// Albums by title.
  final List<Album> albums;

  /// Artists by name.
  final List<Artist> artists;

  /// Playlists by name.
  final List<PlaylistSummary> playlists;
}
