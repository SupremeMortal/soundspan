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
/// | `root` | browsable | `recent`, `playlists`, `albums` |
/// | `recent` | browsable | `recent/tracks/<index>` |
/// | `playlists` | browsable | `playlist/<id>` |
/// | `playlist/<id>` | browsable | `playlist/<id>/<index>` |
/// | `albums` | browsable | `album/<id>` |
/// | `album/<id>` | browsable | `album/<id>/<index>` |
/// | `…/<index>` | playable | the whole parent list from `<index>` |
/// | `search/<query>/<index>` | playable | the same over the search result |
///
/// `<id>` and `<query>` are percent-encoded. Unplayable tracks (no
/// playback id) are left out of every list, and `<index>` counts the list
/// without them.
library;

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';

/// The localized titles of the root's children; `core` has no
/// `BuildContext`, so the handler passes them in.
final class BrowseRootTitles {
  /// Creates the titles.
  const new({
    required this.recent,
    required this.playlists,
    required this.albums,
  });

  /// The title of `recent`.
  final String recent;

  /// The title of `playlists`.
  final String playlists;

  /// The title of `albums`.
  final String albums;
}

/// One entry of a browse list.
final class BrowseNode {
  /// Creates a node.
  const new({
    required this.id,
    required this.title,
    required this.playable,
    this.subtitle,
  });

  /// The media id.
  final String id;

  /// What the list shows.
  final String title;

  /// The line under [title]: the artist of a track or an album.
  final String? subtitle;

  /// Whether selecting it plays; otherwise it lists children.
  final bool playable;
}

/// What a playable media id plays: [tracks] from [startIndex], queued
/// from [context].
final class PlayRequest {
  /// Creates a request.
  const new({
    required this.tracks,
    required this.startIndex,
    required this.context,
  });

  /// The playable tracks of the list, in order.
  final List<Track> tracks;

  /// The index in [tracks] to start at.
  final int startIndex;

  /// Where the tracks are queued from.
  final QueueContext context;

  /// The kind of [context].
  QueueContextKind get kind => context.kind;
}

/// The browse tree over [_source], with the root titles [_titles].
final class BrowseTree {
  /// Creates the tree.
  new({required this._source, required this._titles});

  /// The id of the tree's root.
  static const String rootId = 'root';

  /// The most albums `albums` lists.
  static const int albumLimit = 200;

  static final AppLogger _log = AppLogger.scope('AndroidAuto');
  static final RegExp _digits = RegExp(r'^\d+$');
  static final RegExp _badEscape = RegExp('%(?![0-9A-Fa-f]{2})');

  final MediaBrowseSource _source;
  final BrowseRootTitles _titles;

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
