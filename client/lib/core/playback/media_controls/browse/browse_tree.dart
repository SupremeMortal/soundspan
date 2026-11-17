// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The Android Auto browse tree (doc 10, Android Auto): which nodes a
/// media id lists and what a playable id plays, over a
/// [MediaBrowseSource]. Pure Dart; the `audio_service` handler maps its
/// nodes to media items.
///
/// Media ids are client-defined, never a playback id:
///
/// | Id | Kind | Children or action |
/// |---|---|---|
/// | `root` | browsable | `recent`, `playlists`, `albums`, `downloads` |
/// | `recent` | browsable | `recent/tracks/<index>` |
/// | `playlists` | browsable | `playlist/<id>` |
/// | `playlist/<id>` | browsable | `playlist/<id>/<index>` |
/// | `albums` | browsable | `album/<id>` |
/// | `album/<id>` | browsable | `album/<id>/<index>` |
/// | `…/<index>` | playable | the whole parent list from `<index>` |
/// | `search/<query>/<index>` | playable | the same over the search result |
/// | `downloads` | browsable | `downloads/<kind>/<refId>`, or `…/0` for a song or an episode |
/// | `downloads/<kind>/<refId>` | browsable | `downloads/<kind>/<refId>/<index>` |
/// | `downloads/episode/<refId>/0` | playable | the downloaded episode alone |
///
/// `<id>`, `<query>` and `<refId>` are percent-encoded. Unplayable tracks
/// (no playback id) are left out of every list, and `<index>` counts the
/// list without them.
///
/// `downloads` is served from the [DownloadStore] alone, so it works with
/// no network: a collection is listed while it has a completed item, and
/// lists only its completed items, in membership order. An episode
/// collection (`<refId>` is `<podcastId>:<episodeId>`) plays its episode
/// alone, built from the item's [EpisodeDownloadMeta]. Its covers are the
/// pinned files, as content URIs.
library;

import 'dart:convert';

import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/episode_download_meta.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/artwork_content_uri/artwork_content_uri.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';

/// The subtitle of a download collection under `downloads`: its [kind] and
/// how many of its items are downloaded.
typedef DownloadsSubtitle = String Function(
  DownloadCollectionKind kind,
  int completed,
);

/// The localized titles of the root's children; `core` has no
/// `BuildContext`, so the handler passes them in.
final class BrowseRootTitles {
  /// Creates the titles.
  const new({
    required this.recent,
    required this.playlists,
    required this.albums,
    required this.downloads,
    required this.downloadsSubtitle,
  });

  /// The title of `recent`.
  final String recent;

  /// The title of `playlists`.
  final String playlists;

  /// The title of `albums`.
  final String albums;

  /// The title of `downloads`.
  final String downloads;

  /// The subtitle of each collection under `downloads`.
  final DownloadsSubtitle downloadsSubtitle;
}

/// What the `downloads` root reads: the profile's [store] and the content
/// URIs of its pinned covers.
final class DownloadsBrowse {
  /// Creates it.
  const new({required this.store, required this.artwork});

  /// The profile's downloads.
  final DownloadStore store;

  /// The content URIs of the pinned covers.
  final ArtworkContentUri artwork;
}

/// One entry of a browse list.
final class BrowseNode {
  /// Creates a node.
  const new({
    required this.id,
    required this.title,
    required this.playable,
    this.subtitle,
    this.album,
    this.duration,
    this.artUri,
  });

  /// The media id.
  final String id;

  /// What the list shows.
  final String title;

  /// The line under [title]: the artist of a track or an album.
  final String? subtitle;

  /// Whether selecting it plays; otherwise it lists children.
  final bool playable;

  /// The album of a downloaded track.
  final String? album;

  /// The duration of a downloaded track.
  final Duration? duration;

  /// The cover's content URI; only downloads carry one.
  final Uri? artUri;
}

/// What a playable media id plays: [tracks] from [startIndex], queued
/// from [context], or, with no tracks, [episode] of [podcast] alone.
final class PlayRequest {
  /// Creates a request.
  const new({
    required this.tracks,
    required this.startIndex,
    required this.context,
  }) : episode = null,
       podcast = null;

  /// A request that plays [episode] of [podcast] alone.
  const new ofEpisode({
    required Episode this.episode,
    required Podcast this.podcast,
  }) : tracks = const [],
       startIndex = 0,
       context = const QueueContext(kind: QueueContextKind.single);

  /// The episode to play alone; null for a track request.
  final Episode? episode;

  /// The podcast of [episode]; null for a track request.
  final Podcast? podcast;

  /// The playable tracks of the list, in order.
  final List<Track> tracks;

  /// The index in [tracks] to start at.
  final int startIndex;

  /// Where the tracks are queued from.
  final QueueContext context;

  /// The kind of [context].
  QueueContextKind get kind => context.kind;
}

/// The browse tree over [_source], with the root titles [_titles]; with
/// [_downloads] the root also lists `downloads`.
final class BrowseTree {
  /// Creates the tree.
  new({required this._source, required this._titles, this._downloads});

  /// The id of the tree's root.
  static const String rootId = 'root';

  /// The most albums `albums` lists.
  static const int albumLimit = 200;

  static final AppLogger _log = AppLogger.scope('AndroidAuto');
  static final RegExp _digits = RegExp(r'^\d+$');
  static final RegExp _badEscape = RegExp('%(?![0-9A-Fa-f]{2})');

  /// The id of the downloads root.
  static const String downloadsId = 'downloads';

  final MediaBrowseSource _source;
  final BrowseRootTitles _titles;
  final DownloadsBrowse? _downloads;

  /// The children of [parentId]; empty for an unknown or malformed id, a
  /// playable id, or a source that fails.
  Future<List<BrowseNode>> children(String parentId) async {
    try {
      return await _children(parentId);
    } on Object catch (error, stackTrace) {
      _log.warning('Browse list failed', const {}, error, stackTrace);
      return const [];
    }
  }

  Future<List<BrowseNode>> _children(String parentId) async {
    switch (parentId) {
      case rootId:
        return [
          BrowseNode(id: 'recent', title: _titles.recent, playable: false),
          BrowseNode(
            id: 'playlists',
            title: _titles.playlists,
            playable: false,
          ),
          BrowseNode(id: 'albums', title: _titles.albums, playable: false),
          if (_downloads != null)
            BrowseNode(
              id: downloadsId,
              title: _titles.downloads,
              playable: false,
            ),
        ];
      case 'recent':
        return _trackNodes('recent/tracks', await _recent());
      case 'playlists':
        return [
          for (final playlist in await _source.playlists())
            BrowseNode(
              id: 'playlist/${_encode(playlist.id)}',
              title: playlist.name,
              playable: false,
            ),
        ];
      case 'albums':
        final albums = await _source.albums();
        return [
          for (final album in albums.take(albumLimit))
            BrowseNode(
              id: 'album/${_encode(album.id)}',
              title: album.title,
              subtitle: album.artist,
              playable: false,
            ),
        ];
    }
    final parts = parentId.split('/');
    if (parts.first == downloadsId) return await _downloadChildren(parts);
    if (parts.length != 2) return const [];
    final id = _decode(parts[1]);
    if (id == null) return const [];
    final prefix = '${parts[0]}/${parts[1]}';
    return switch (parts[0]) {
      'playlist' => _trackNodes(
        prefix,
        _playable(await _source.playlistTracks(id)),
      ),
      'album' => _trackNodes(prefix, _playable(await _source.albumTracks(id))),
      _ => const [],
    };
  }

  /// What the playable [mediaId] plays; null for an id that is not
  /// playable, an index out of range, or a source that fails.
  Future<PlayRequest?> resolve(String mediaId) async {
    try {
      return await _resolve(mediaId);
    } on Object catch (error, stackTrace) {
      _log.warning('Browse item not resolved', const {}, error, stackTrace);
      return null;
    }
  }

  Future<PlayRequest?> _resolve(String mediaId) async {
    final parts = mediaId.split('/');
    if (parts.first == downloadsId) return await _resolveDownload(parts);
    if (parts.length != 3 || !_digits.hasMatch(parts[2])) return null;
    final index = int.parse(parts[2]);
    if (parts[0] == 'recent') {
      if (parts[1] != 'tracks') return null;
      return _request(
        await _recent(),
        index,
        const QueueContext(kind: QueueContextKind.library),
      );
    }
    final id = _decode(parts[1]);
    if (id == null) return null;
    return switch (parts[0]) {
      'playlist' => _request(
        _playable(await _source.playlistTracks(id)),
        index,
        QueueContext(kind: QueueContextKind.playlist, id: id),
      ),
      'album' => _request(
        _playable(await _source.albumTracks(id)),
        index,
        QueueContext(kind: QueueContextKind.album, id: id),
      ),
      'search' => _request(
        await _search(id),
        index,
        const QueueContext(kind: QueueContextKind.search),
      ),
      _ => null,
    };
  }

  /// What a voice search for [query] plays: the recent list for a blank
  /// query, otherwise the tracks it finds, from the first; null when
  /// there is nothing to play.
  Future<PlayRequest?> search(String query) async {
    try {
      if (query.trim().isEmpty) {
        return _request(
          await _recent(),
          0,
          const QueueContext(kind: QueueContextKind.library),
        );
      }
      return _request(
        await _search(query),
        0,
        const QueueContext(kind: QueueContextKind.search),
      );
    } on Object catch (error, stackTrace) {
      _log.warning('Voice search failed', const {}, error, stackTrace);
      return null;
    }
  }

  /// The playable tracks [query] finds, as `search/<query>/<index>` nodes;
  /// empty when the source fails.
  Future<List<BrowseNode>> searchResults(String query) async {
    try {
      return _trackNodes('search/${_encode(query)}', await _search(query));
    } on Object catch (error, stackTrace) {
      _log.warning('Search failed', const {}, error, stackTrace);
      return const [];
    }
  }

  /// The children of a `downloads` id split into [parts].
  Future<List<BrowseNode>> _downloadChildren(List<String> parts) async {
    final downloads = _downloads;
    if (downloads == null) return const [];
    if (parts.length == 1) return await _downloadCollections(downloads);
    final collection = parts.length == 3
        ? await _downloadCollection(downloads, parts[1], parts[2])
        : null;
    if (collection == null) {
      _log.info('Downloads id not understood', {'parts': parts.length});
      return const [];
    }
    final prefix = parts.join('/');
    return [
      for (final (index, item) in collection.items.indexed)
        _downloadItemNode('$prefix/$index', item, downloads.artwork),
    ];
  }

  /// One node per collection with a completed track, in request order; a
  /// song is playable at once.
  Future<List<BrowseNode>> _downloadCollections(
    DownloadsBrowse downloads,
  ) async {
    final rows = await downloads.store.watchCollectionsWithItems().first;
    final nodes = <BrowseNode>[];
    for (final row in rows) {
      final kind = _collectionKind(row.collection.kind);
      if (kind == null) continue;
      final items = _completedItems(kind, row.items);
      if (items.isEmpty) continue;
      final id = '$downloadsId/${kind.name}/${_encode(row.collection.refId)}';
      final subtitle = _titles.downloadsSubtitle(kind, items.length);
      if (kind == DownloadCollectionKind.track ||
          kind == DownloadCollectionKind.episode) {
        final track = _downloadItemNode(
          '$id/0',
          items.first,
          downloads.artwork,
        );
        nodes.add(
          BrowseNode(
            id: track.id,
            title: track.title,
            subtitle: subtitle,
            album: track.album,
            duration: track.duration,
            artUri: track.artUri,
            playable: true,
          ),
        );
        continue;
      }
      final ref =
          _artworkRef(row.collection.metaJson) ??
          _artworkRef(items.first.metaJson);
      nodes.add(
        BrowseNode(
          id: id,
          title: row.collection.title,
          subtitle: subtitle,
          artUri: ref == null ? null : downloads.artwork.forArtRef(ref),
          playable: false,
        ),
      );
    }
    return nodes;
  }

  /// What a `downloads` id split into [parts] plays.
  Future<PlayRequest?> _resolveDownload(List<String> parts) async {
    final downloads = _downloads;
    if (downloads == null) return null;
    final collection = parts.length == 4 && _digits.hasMatch(parts[3])
        ? await _downloadCollection(downloads, parts[1], parts[2])
        : null;
    final request = collection == null
        ? null
        : collection.kind == DownloadCollectionKind.episode
        ? _episodeRequest(collection.items, int.parse(parts[3]))
        : _request(
            [for (final item in collection.items) _downloadTrack(item)],
            int.parse(parts[3]),
            switch (collection.kind) {
              DownloadCollectionKind.album => QueueContext(
                kind: QueueContextKind.album,
                id: collection.refId,
              ),
              DownloadCollectionKind.playlist => QueueContext(
                kind: QueueContextKind.playlist,
                id: collection.refId,
              ),
              _ => QueueContext(
                kind: QueueContextKind.single,
                id: collection.refId,
              ),
            },
          );
    if (request == null) {
      _log.info('Downloads id not played', {'parts': parts.length});
    }
    return request;
  }

  /// The collection of the encoded [kindName] and [encodedRefId] with its
  /// completed tracks; null when the id is malformed or there is no such
  /// collection.
  Future<
    ({DownloadCollectionKind kind, String refId, List<DownloadItem> items})?
  >
  _downloadCollection(
    DownloadsBrowse downloads,
    String kindName,
    String encodedRefId,
  ) async {
    final kind = _collectionKind(kindName);
    final refId = _decode(encodedRefId);
    if (kind == null || refId == null) return null;
    final row = await downloads.store
        .watchCollectionWithItems(kind, refId)
        .first;
    if (row == null) return null;
    return (kind: kind, refId: refId, items: _completedItems(kind, row.items));
  }

  /// The downloaded episode at [index] of [items], played alone; null when
  /// there is none.
  static PlayRequest? _episodeRequest(List<DownloadItem> items, int index) {
    final meta = index < items.length
        ? EpisodeDownloadMeta.fromJson(items[index].metaJson)
        : null;
    return meta == null
        ? null
        : PlayRequest.ofEpisode(
            episode: meta.toEpisode(),
            podcast: meta.toPodcast(),
          );
  }

  static DownloadCollectionKind? _collectionKind(String name) {
    for (final kind in DownloadCollectionKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }

  /// The completed items of [items] that a collection of [kind] plays,
  /// in order: episodes for an episode collection, tracks otherwise.
  static List<DownloadItem> _completedItems(
    DownloadCollectionKind kind,
    List<DownloadItem> items,
  ) {
    final prefix = kind == DownloadCollectionKind.episode ? 'e:' : 't:';
    return [
      for (final item in items)
        if (item.status == DownloadStatus.completed &&
            item.itemKey.startsWith(prefix))
          item,
    ];
  }

  /// The playable node [id] of the completed track or episode [item].
  static BrowseNode _downloadItemNode(
    String id,
    DownloadItem item,
    ArtworkContentUri artwork,
  ) {
    if (item.itemKey.startsWith('e:')) {
      final meta = EpisodeDownloadMeta.fromJson(item.metaJson);
      final ref = meta?.artworkRef;
      final duration = meta?.durationSec;
      return BrowseNode(
        id: id,
        title: meta?.title ?? '',
        subtitle: meta?.podcastTitle,
        duration: duration == null ? null : Duration(seconds: duration),
        artUri: ref == null || ref.isEmpty ? null : artwork.forArtRef(ref),
        playable: true,
      );
    }
    final meta = _downloadTrack(item).meta;
    final ref = meta.artworkRef;
    return BrowseNode(
      id: id,
      title: meta.title,
      subtitle: meta.artist,
      album: meta.album,
      duration: Duration(seconds: meta.durationSec),
      artUri: ref == null || ref.isEmpty ? null : artwork.forArtRef(ref),
      playable: true,
    );
  }

  /// The track of the completed item [item], from its `metaJson` alone.
  static Track _downloadTrack(DownloadItem item) {
    final key = DownloadItemKey.decode(item.itemKey) as TrackItemKey;
    final json = _decodeObject(item.metaJson);
    TrackMeta meta;
    try {
      meta = TrackMeta.fromJson(json);
    } on Object {
      meta = const TrackMeta(title: '', artist: '', album: '', durationSec: 0);
    }
    final loudness = json['loudness'];
    return Track(
      meta: meta,
      playbackId: PlaybackId(key.playbackId),
      albumId: json['albumId'] as String?,
      artistId: json['artistId'] as String?,
      loudness: loudness is Map<String, Object?>
          ? Loudness.fromJson(loudness)
          : null,
      discNumber: json['discNumber'] as int?,
      trackNumber: json['trackNumber'] as int?,
    );
  }

  static String? _artworkRef(String metaJson) =>
      switch (_decodeObject(metaJson)['artworkRef']) {
        final String ref when ref.isNotEmpty => ref,
        _ => null,
      };

  static Map<String, Object?> _decodeObject(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Not JSON: no fields.
    }
    return const {};
  }

  Future<List<Track>> _recent() async => _playable(await _source.recent());

  Future<List<Track>> _search(String query) async =>
      _playable(await _source.searchTracks(query));

  static PlayRequest? _request(
    List<Track> tracks,
    int index,
    QueueContext context,
  ) => index < tracks.length
      ? PlayRequest(tracks: tracks, startIndex: index, context: context)
      : null;

  static List<BrowseNode> _trackNodes(String prefix, List<Track> tracks) => [
    for (var index = 0; index < tracks.length; index++)
      BrowseNode(
        id: '$prefix/$index',
        title: tracks[index].meta.title,
        subtitle: tracks[index].meta.artist,
        playable: true,
      ),
  ];

  static List<Track> _playable(List<Track> tracks) =>
      tracks.where((track) => track.playbackId != null).toList();

  static String _encode(String value) => Uri.encodeComponent(value);

  /// [value] decoded; null when it is empty or not valid percent-encoding.
  static String? _decode(String value) {
    if (value.isEmpty || _badEscape.hasMatch(value)) return null;
    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      // Escapes that are not UTF-8.
      return null;
    }
  }
}
