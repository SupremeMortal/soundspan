// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' show CancelToken, Options;
import 'package:soundspan_api/soundspan_api.dart' as api;

/// In-memory stand-ins for the generated resource clients of `SoundspanApi`
/// (doc 11, Test Doubles), so repository tests exercise real request
/// sequences against a small server model.
final class FakeApi {
  /// The offline resource: `rest.offline`.
  final FakeOfflineClient offline = FakeOfflineClient();

  /// The podcasts resource: `rest.podcasts`.
  final FakePodcastsClient podcasts = FakePodcastsClient();

  /// The discovery resource: `rest.discovery`.
  final FakeDiscoveryClient discovery = FakeDiscoveryClient();

  /// The library resource's preference endpoints: `rest.library2`.
  final FakeLibraryClient library = FakeLibraryClient();

  /// The playlists resource: `rest.playlists`.
  final FakePlaylistsClient playlists = FakePlaylistsClient();

  /// The session resource's settings endpoints: `rest.session`.
  final FakeSessionClient session = FakeSessionClient();

  /// The playback resource's lyrics endpoint: `rest.playback`.
  final FakePlaybackClient playback = FakePlaybackClient();

  /// The Listen Together resource: `rest.listenTogether`.
  final FakeListenTogetherClient listenTogether = FakeListenTogetherClient();

  /// The social resource's presence endpoints: `rest.social`.
  final FakeSocialClient social = FakeSocialClient();
}

/// An in-memory model of the server's settings endpoints (doc 03,
/// `GET /settings`, `POST /settings`): the stored [loudnessMode] and
/// [playbackQuality], every update body in [updates], and per-call
/// failures in [failures]. While [gate] is set every call waits for it.
/// Other session calls are not modelled.
final class FakeSessionClient implements api.SessionClient {
  /// The stored levelling mode, as its wire string.
  String loudnessMode = 'off';

  /// The stored stream quality.
  String playbackQuality = 'high';

  /// Every `POST /settings` body, in order.
  final List<api.UpdateSettingsRequest> updates = [];

  /// Calls by operation name.
  final Map<String, int> calls = {};

  /// Exceptions to throw, by operation name (`getSettings`,
  /// `updateSettings`).
  final Map<String, api.ApiException> failures = {};

  /// When set, every call waits for it before answering.
  Completer<void>? gate;

  Future<void> _call(String name) async {
    calls.update(name, (n) => n + 1, ifAbsent: () => 1);
    await gate?.future;
    if (failures[name] case final error?) throw error;
  }

  api.UserSettings get _settings => api.UserSettings.fromJson({
    'userId': 'user-1',
    'displayName': null,
    'playbackQuality': playbackQuality,
    'loudnessMode': loudnessMode,
    'maxCacheSizeMb': 2048,
    'offlineEnabled': false,
    'shareListeningStatus': true,
    'shareOnlinePresence': true,
    'showTidalExplore': false,
    'showYtMusicExplore': false,
    'tidalStreamingQuality': 'HIGH',
    'wifiOnly': false,
    'ytMusicQuality': 'HIGH',
  });

  @override
  Future<api.UserSettings> getSettings({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    await _call('getSettings');
    return _settings;
  }

  @override
  Future<api.UserSettings> updateSettings({
    required api.UpdateSettingsRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    updates.add(body);
    await _call('updateSettings');
    final json = jsonDecode(jsonEncode(body)) as Map<String, Object?>;
    if (json['loudnessMode'] case final String mode) loudnessMode = mode;
    if (json['playbackQuality'] case final String quality) {
      playbackQuality = quality;
    }
    return _settings;
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// One `GET /lyrics/:trackId` request [FakePlaybackClient] received.
typedef FakeLyricsRequest = ({
  String trackId,
  String? artist,
  String? title,
  String? album,
  num? duration,
});

/// An in-memory model of the server's lyrics endpoint (doc 03,
/// `GET /lyrics/:trackId`): the answer by path value in [lyrics], every
/// request in [requests], and per-call failures in [failures]. A path value
/// without an answer gets `source: none`. The other playback operations
/// throw [UnimplementedError].
final class FakePlaybackClient implements api.PlaybackClient {
  /// The answers by path value.
  final Map<String, api.Lyrics> lyrics = {};

  /// Every lyrics request, in order.
  final List<FakeLyricsRequest> requests = [];

  /// Exceptions the next calls throw, oldest first; a call takes one when
  /// any is left.
  final List<api.ApiException> failures = [];

  /// The `source: none` answer.
  static const api.Lyrics none = api.Lyrics(
    plainLyrics: null,
    source: api.LyricsSource.none,
    synced: false,
    syncedLyrics: null,
  );

  @override
  Future<api.Lyrics> getLyrics({
    required String trackId,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    String? artist,
    String? title,
    String? album,
    num? duration,
  }) async {
    requests.add((
      trackId: trackId,
      artist: artist,
      title: title,
      album: album,
      duration: duration,
    ));
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return lyrics[trackId] ?? none;
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// One request [FakePlaylistsClient] received: the operation and its
/// arguments.
typedef FakePlaylistRequest = ({String op, String? id, Object? body});

/// One entry of a playlist in [FakePlaylistsClient].
typedef FakePlaylistEntry = ({String itemId, String playbackId, String title});

/// One playlist of [FakePlaylistsClient].
final class FakePlaylist {
  /// Creates the playlist [name].
  new(this.name);

  /// Its name.
  String name;

  /// Its entries in order.
  final List<FakePlaylistEntry> entries = [];
}

/// An in-memory model of the server's playlist endpoints (doc 03): the
/// user's playlists by id, every request in [requests] and per-call
/// failures in [failures]. Ids are `pl-1`, `pl-2`, … in creation order.
final class FakePlaylistsClient implements api.PlaylistsClient {
  /// The playlists by id.
  final Map<String, FakePlaylist> playlists = {};

  /// Every request, in order.
  final List<FakePlaylistRequest> requests = [];

  /// Exceptions the next calls throw, oldest first; a call takes one when
  /// any is left.
  final List<api.ApiException> failures = [];

  int _nextId = 0;
  int _nextItem = 0;

  /// The requests other than reads, as `op id` strings.
  List<String> get writes => [
    for (final request in requests)
      if (request.op != 'list' && request.op != 'get')
        '${request.op} ${request.id}',
  ];

  /// Adds a playlist named [name] directly, as if created elsewhere, with
  /// the tracks [playbackIds]; answers its id.
  String seed(String name, {List<String> playbackIds = const []}) {
    final id = 'pl-${++_nextId}';
    final playlist = FakePlaylist(name);
    for (final playbackId in playbackIds) {
      playlist.entries.add((
        itemId: 'item-${++_nextItem}',
        playbackId: playbackId,
        title: 'Song $playbackId',
      ));
    }
    playlists[id] = playlist;
    return id;
  }

  void _record(String op, String? id, [Object? body]) {
    requests.add((op: op, id: id, body: body));
    if (failures.isNotEmpty) throw failures.removeAt(0);
  }

  FakePlaylist _find(String id) =>
      playlists[id] ??
      (throw const api.NotFound(status: 404, code: 'PLAYLIST_NOT_FOUND'));

  Map<String, Object?> _base(String id, FakePlaylist playlist) => {
    'id': id,
    'name': playlist.name,
    'trackCount': playlist.entries.length,
    'isOwner': true,
    'isPublic': false,
    'isHidden': false,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    'user': {'username': 'me'},
    'userId': 'u-1',
  };

  static Map<String, Object?> _itemJson(
    String playlistId,
    FakePlaylistEntry entry,
    int sort,
  ) => {
    'id': entry.itemId,
    'playlistId': playlistId,
    'sort': sort,
    'type': 'track',
    'playback': {'isPlayable': true, 'reason': null, 'message': null},
    'track': {
      'id': 'track-${entry.playbackId}',
      'title': entry.title,
      'duration': 30,
      'trackNo': 1,
      'source': 'local',
      'albumId': 'al-1',
      'artistId': 'ar-1',
      'playbackId': entry.playbackId,
      'album': {'id': 'al-1', 'title': 'First Light', 'coverArt': null},
      'artist': {'id': 'ar-1', 'name': 'Contract Aurora'},
    },
  };

  api.PlaylistRecord _recordOf(String id, FakePlaylist playlist) =>
      api.PlaylistRecord.fromJson({
        'id': id,
        'name': playlist.name,
        'isPublic': false,
        'userId': 'u-1',
        'mixId': null,
        'spotifyPlaylistId': null,
        'spotifyPlaylistUrl': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });

  static const _written = api.PlaylistWriteResult(message: 'ok');

  @override
  Future<List<api.PlaylistSummary>> listPlaylists({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    int? limit,
    int? offset,
  }) async {
    _record('list', null);
    final ids = playlists.keys.toList().reversed.toList();
    final start = (offset ?? 0).clamp(0, ids.length);
    final end = (start + (limit ?? 500)).clamp(0, ids.length);
    return [
      for (final id in ids.sublist(start, end))
        api.PlaylistSummary.fromJson({
          ..._base(id, playlists[id]!),
          'items': <Object?>[],
        }),
    ];
  }

  @override
  Future<api.PlaylistDetail> getPlaylist({
    required String id,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _record('get', id);
    final playlist = _find(id);
    return api.PlaylistDetail.fromJson({
      ..._base(id, playlist),
      'items': [
        for (final (index, entry) in playlist.entries.indexed)
          _itemJson(id, entry, index),
      ],
      'pendingCount': 0,
      'totalItemCount': playlist.entries.length,
      'truncated': false,
    });
  }

  @override
  Future<api.PlaylistRecord> createPlaylist({
    required api.CreatePlaylistRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _record('create', null, body);
    final id = seed(body.name);
    return _recordOf(id, playlists[id]!);
  }

  @override
  Future<api.PlaylistRecord> updatePlaylist({
    required String id,
    required api.UpdatePlaylistRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _record('rename', id, body);
    final playlist = _find(id);
    if (body.name case final name?) playlist.name = name;
    return _recordOf(id, playlist);
  }

  @override
  Future<api.PlaylistWriteResult> deletePlaylist({
    required String id,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _record('delete', id);
    _find(id);
    playlists.remove(id);
    return _written;
  }

  @override
  Future<api.AddPlaylistItemResponse200> addPlaylistItem({
    required String id,
    required api.AddPlaylistItemRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _record('add', id, body);
    final playlist = _find(id);
    final entry = (
      itemId: 'item-${++_nextItem}',
      playbackId: body.playbackId,
      title: body.metadata?.title ?? 'Song ${body.playbackId}',
    );
    playlist.entries.add(entry);
    return api.AddPlaylistItemResponse200.fromJson(
      _itemJson(id, entry, playlist.entries.length - 1),
    );
  }

  @override
  Future<api.PlaylistWriteResult> reorderPlaylistItems({
    required String id,
    required api.ReorderPlaylistItemsRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _record('reorder', id, body);
    final playlist = _find(id);
    final rank = {
      for (final (index, playbackId) in body.playbackIds.indexed)
        playbackId: index,
    };
    final sorted = [...playlist.entries]
      ..sort(
        (a, b) => (rank[a.playbackId] ?? rank.length).compareTo(
          rank[b.playbackId] ?? rank.length,
        ),
      );
    playlist.entries
      ..clear()
      ..addAll(sorted);
    return _written;
  }

  @override
  Future<api.PlaylistWriteResult> removePlaylistItem({
    required String id,
    required String playbackId,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    final decoded = Uri.decodeComponent(playbackId);
    _record('remove', id, decoded);
    _find(id).entries.removeWhere((entry) => entry.playbackId == decoded);
    return _written;
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// An in-memory model of the server's preference endpoints (doc 03,
/// `POST /library/preferences`, `POST /library/albums/:id/preference`):
/// the state of each track and album, every request body in [requests],
/// and per-call failures in [failures]. Other library calls are not
/// modelled.
final class FakeLibraryClient implements api.LibraryClient {
  /// The state of each track, by `playbackId`; absent is `neutral`.
  final Map<String, String> tracks = {};

  /// The state of each album, by album id; absent is `neutral`.
  final Map<String, String> albums = {};

  /// Every preference request body, in order.
  final List<Object> requests = [];

  /// Exceptions the next preference calls throw, oldest first; a call takes
  /// one when any is left.
  final List<api.ApiException> failures = [];

  /// While set, preference calls wait for it before answering, so a test
  /// can look at the client before the server answers.
  Completer<void>? gate;

  static String _state(api.PreferenceSignal signal) =>
      switch (signal.toJson()) {
        'thumbs_up' => 'liked',
        'thumbs_down' => 'disliked',
        _ => 'neutral',
      };

  static int _score(String state) => switch (state) {
    'liked' => 1,
    'disliked' => -1,
    _ => 0,
  };

  Future<void> _answer() async {
    await gate?.future;
    if (failures.isNotEmpty) throw failures.removeAt(0);
  }

  @override
  Future<api.TrackPreferenceResponse> setTrackPreference({
    required api.TrackPreferenceRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add(body);
    await _answer();
    final state = _state(body.signal);
    tracks[body.playbackId] = state;
    return api.TrackPreferenceResponse.fromJson({
      'playbackId': body.playbackId,
      'trackId': 'track-${body.playbackId}',
      'signal': body.signal.toJson(),
      'state': state,
      'score': _score(state),
      'likedAt': state == 'liked' ? '2026-01-01T00:00:00.000Z' : null,
      'dislikedAt': state == 'disliked' ? '2026-01-01T00:00:00.000Z' : null,
      'updatedAt': '2026-01-01T00:00:00.000Z',
    });
  }

  @override
  Future<api.AlbumPreferenceResponse> setAlbumPreference({
    required String id,
    required api.AlbumPreferenceRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add(body);
    await _answer();
    final state = _state(body.signal);
    albums[id] = state;
    return api.AlbumPreferenceResponse.fromJson({
      'albumId': id,
      'trackCount': 0,
      'signal': body.signal.toJson(),
      'state': state,
      'score': _score(state),
      'likedAt': state == 'liked' ? '2026-01-01T00:00:00.000Z' : null,
      'dislikedAt': state == 'disliked' ? '2026-01-01T00:00:00.000Z' : null,
      'updatedAt': '2026-01-01T00:00:00.000Z',
    });
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// One file a device reported as written.
typedef FakeHeldItem = ({String quality, int sizeBytes});

/// An in-memory model of the server's offline API (doc 07): per-device item
/// sets, the user's cache limit, the admin "downloads disabled" switch and
/// per-track unavailability. Every request body and query is kept in
/// [requests].
final class FakeOfflineClient implements api.OfflineClient {
  /// Bytes in one megabyte, as the server counts them.
  static const int bytesPerMb = 1024 * 1024;

  /// The tracks of each album, by album id.
  final Map<String, List<String>> albums = {};

  /// The tracks of each playlist, by playlist id.
  final Map<String, List<String>> playlists = {};

  /// The wire `reason` of each track the server refuses, by `playbackId`:
  /// `TRACK_UNAVAILABLE`, `SOURCE_UNAVAILABLE`, or any other string.
  final Map<String, String> unavailable = {};

  /// The bytes the server would send for each track; [defaultTrackBytes]
  /// when absent. A null value means the server cannot say.
  final Map<String, int?> trackBytes = {};

  /// The size of a track missing from [trackBytes].
  int defaultTrackBytes = 1000;

  /// The user's server-side cache limit.
  int cacheLimitBytes = 10 * 1024 * bytesPerMb;

  /// The admin switch: when true every item is refused with
  /// `SOURCE_DOWNLOADS_DISABLED` and every held item is revoked.
  bool downloadsDisabled = false;

  /// When true and [downloadsDisabled], `POST /items` answers 409
  /// `SOURCE_DOWNLOADS_DISABLED` instead of listing refused items.
  bool rejectWhenDisabled = false;

  /// The items each device holds, by device id and `playbackId`.
  final Map<String, Map<String, FakeHeldItem>> devices = {};

  /// Every request body (or, for queries, a map of the query), in order.
  final List<Object> requests = [];

  /// When set, `POST /items/complete` records the request and throws it
  /// instead of answering.
  api.ApiException? completeError;

  /// When set, `DELETE /items` records the request and throws it instead
  /// of answering.
  api.ApiException? deleteError;

  /// When set, `GET /items` records the request and throws it instead of
  /// answering.
  api.ApiException? listError;

  int get _usedBytes => devices.values
      .expand((items) => items.values)
      .fold(0, (sum, item) => sum + item.sizeBytes);

  @override
  Future<api.OfflineItemsResponse> requestOfflineItems({
    required api.RequestOfflineItemsRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add(body);
    if (downloadsDisabled && rejectWhenDisabled) {
      throw const api.DownloadsDisabled(
        status: 409,
        code: 'SOURCE_DOWNLOADS_DISABLED',
      );
    }
    final kind = body.kind.toJson();
    final ids = switch (kind) {
      'album' => albums[body.id],
      'playlist' => playlists[body.id],
      _ => [body.id],
    };
    if (ids == null) {
      throw api.NotFound(
        status: 404,
        code: kind == 'album' ? 'ALBUM_NOT_FOUND' : 'PLAYLIST_NOT_FOUND',
      );
    }
    final quality = body.quality?.toJson() ?? 'original';
    var estimate = 0;
    final items = <api.OfflineItem>[];
    for (final id in ids) {
      final reason = downloadsDisabled
          ? 'SOURCE_DOWNLOADS_DISABLED'
          : unavailable[id];
      if (reason != null) {
        items.add(
          api.OfflineItem(
            playbackId: id,
            downloadable: false,
            reason: api.OfflineItemReason.fromJson(reason),
          ),
        );
        continue;
      }
      final size = trackBytes.containsKey(id)
          ? trackBytes[id]
          : defaultTrackBytes;
      estimate += size ?? 0;
      items.add(
        api.OfflineItem(
          playbackId: id,
          downloadable: true,
          downloadUrl: '/api/playback/stream/$id?quality=$quality&report=0',
          expectedSize: size,
          quality: api.OfflineItemQuality.fromJson(quality),
          contentType: 'FLAC',
        ),
      );
    }
    final used = _usedBytes;
    if (used + estimate > cacheLimitBytes) {
      throw api.CacheLimitExceeded(
        limitBytes: cacheLimitBytes,
        usedBytes: used,
        estimatedBytes: estimate,
        status: 409,
        code: 'CACHE_LIMIT_EXCEEDED',
      );
    }
    return api.OfflineItemsResponse(
      items: items,
      estimatedTotalBytes: estimate,
      cacheLimitBytes: cacheLimitBytes,
      cacheUsedBytes: used,
    );
  }

  @override
  Future<api.CompletedOfflineItem> completeOfflineItem({
    required api.CompleteOfflineItemRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add(body);
    final error = completeError;
    if (error != null) throw error;
    final quality = body.quality.toJson();
    (devices[body.deviceId] ??= {})[body.playbackId] = (
      quality: quality,
      sizeBytes: body.sizeBytes,
    );
    return api.CompletedOfflineItem(
      playbackId: body.playbackId,
      quality: api.CompletedOfflineItemQuality.fromJson(quality),
      sizeBytes: body.sizeBytes,
    );
  }

  @override
  Future<api.DeleteOfflineItemsResponse> deleteOfflineItems({
    required api.DeleteOfflineItemsRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add(body);
    if (deleteError case final error?) throw error;
    final held = devices[body.deviceId] ?? {};
    var deleted = 0;
    for (final id in body.playbackIds.toSet()) {
      if (held.remove(id) != null) deleted++;
    }
    return api.DeleteOfflineItemsResponse(deletedCount: deleted);
  }

  @override
  Future<api.DeviceOfflineItemsResponse> listOfflineItems({
    required String deviceId,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add({'deviceId': deviceId});
    final error = listError;
    if (error != null) throw error;
    final held = devices[deviceId] ?? {};
    return api.DeviceOfflineItemsResponse(
      items: [
        for (final MapEntry(key: id, value: item) in held.entries)
          api.DeviceOfflineItem(
            playbackId: id,
            quality: api.DeviceOfflineItemQuality.fromJson(item.quality),
            sizeBytes: item.sizeBytes,
            revoked:
                downloadsDisabled || unavailable[id] == 'TRACK_UNAVAILABLE',
          ),
      ],
    );
  }

  @override
  Future<api.OfflineStats> getOfflineStats({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    String? deviceId,
  }) async {
    requests.add({'deviceId': deviceId});
    final used = _usedBytes;
    final held = devices[deviceId] ?? const {};
    final deviceBytes = held.values.fold(0, (sum, i) => sum + i.sizeBytes);
    final maxMb = cacheLimitBytes ~/ bytesPerMb;
    return api.OfflineStats(
      usedMb: used / bytesPerMb,
      maxMb: maxMb,
      availableMb: maxMb - used / bytesPerMb,
      percentUsed: maxMb == 0 ? 0 : used / bytesPerMb / maxMb * 100,
      trackCount: devices.values.fold(0, (sum, items) => sum + items.length),
      device: deviceId == null
          ? null
          : api.OfflineStatsDevice(
              deviceId: deviceId,
              usedMb: deviceBytes / bytesPerMb,
              trackCount: held.length,
            ),
    );
  }
}

/// One episode of a [FakePodcast].
typedef FakeEpisode = ({
  String id,
  String title,
  int durationSec,
  DateTime publishedAt,
});

/// One podcast the fake server knows, subscribed or not.
final class FakePodcast {
  /// Creates a podcast at [feedUrl] with [episodes], newest first.
  new({
    required this.id,
    required this.title,
    required this.feedUrl,
    this.itunesId,
    this.author,
    this.episodes = const [],
  });

  /// The server's podcast id.
  final String id;

  /// The title; tests change it to see a refresh land.
  String title;

  /// The RSS feed URL.
  final String feedUrl;

  /// The iTunes directory id, if the directory knows the podcast.
  final String? itunesId;

  /// The author.
  final String? author;

  /// The episodes, newest first.
  List<FakeEpisode> episodes;
}

/// An in-memory model of the server's podcast API: known podcasts, the
/// user's subscriptions (most recent first) and episode progress. Every
/// call is counted in [calls]; an exception in [failures] is thrown by the
/// call of that name instead of answering.
final class FakePodcastsClient implements api.PodcastsClient {
  /// Every podcast the server knows, by id.
  final Map<String, FakePodcast> podcasts = {};

  /// The ids of the subscribed podcasts, most recently subscribed first.
  final List<String> subscriptions = [];

  /// The user's progress, by episode id.
  final Map<String, api.UpdateEpisodeProgressRequest> progress = {};

  /// Calls by operation name.
  final Map<String, int> calls = {};

  /// Exceptions to throw, by operation name.
  final Map<String, Exception> failures = {};

  /// Adds [podcast] to the server and subscribes the user to it.
  void addSubscribed(FakePodcast podcast) {
    podcasts[podcast.id] = podcast;
    subscriptions.insert(0, podcast.id);
  }

  void _call(String name) {
    calls.update(name, (n) => n + 1, ifAbsent: () => 1);
    if (failures[name] case final error?) throw error;
  }

  FakePodcast _subscribed(String id) {
    if (!subscriptions.contains(id)) {
      throw const api.NotFound(status: 404, code: 'NOT_FOUND');
    }
    return podcasts[id]!;
  }

  api.EpisodeProgress? _progressOf(String episodeId) {
    final saved = progress[episodeId];
    if (saved == null) return null;
    return api.EpisodeProgress(
      currentTime: saved.currentTime,
      isFinished: saved.isFinished ?? false,
      lastPlayedAt: DateTime.utc(2024),
      progress: saved.duration == 0
          ? 0
          : saved.currentTime / saved.duration * 100,
    );
  }

  @override
  Future<List<api.SubscribedPodcast>> listPodcasts({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('listPodcasts');
    return [
      for (final id in subscriptions)
        api.SubscribedPodcast(
          id: id,
          title: podcasts[id]!.title,
          author: podcasts[id]!.author,
          coverUrl: '/podcasts/$id/cover',
          description: null,
          autoDownloadEpisodes: false,
          episodeCount: podcasts[id]!.episodes.length,
          episodes: const [],
        ),
    ];
  }

  @override
  Future<api.PodcastDetail> getPodcast({
    required String id,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('getPodcast');
    final podcast = _subscribed(id);
    return api.PodcastDetail(
      id: id,
      title: podcast.title,
      author: podcast.author,
      coverUrl: '/podcasts/$id/cover',
      description: null,
      feedUrl: podcast.feedUrl,
      genres: const [],
      isSubscribed: true,
      autoDownloadEpisodes: false,
      episodes: [
        for (final episode in podcast.episodes)
          api.PodcastEpisode(
            id: episode.id,
            title: episode.title,
            description: null,
            duration: episode.durationSec,
            publishedAt: episode.publishedAt,
            episodeNumber: null,
            season: null,
            imageUrl: null,
            isDownloaded: false,
            progress: _progressOf(episode.id),
          ),
      ],
    );
  }

  @override
  Future<api.SubscribePodcastResponse> subscribePodcast({
    required api.SubscribePodcastRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('subscribePodcast');
    final podcast = podcasts.values.firstWhere(
      (p) => body.feedUrl != null
          ? p.feedUrl == body.feedUrl
          : p.itunesId != null && p.itunesId == body.itunesId,
      orElse: () => throw const api.NotFound(status: 404),
    );
    final already = subscriptions.contains(podcast.id);
    if (!already) subscriptions.insert(0, podcast.id);
    return api.SubscribePodcastResponse(
      success: true,
      message: already ? 'Already subscribed' : 'Subscribed',
      podcast: api.SubscribedPodcastRef(id: podcast.id, title: podcast.title),
    );
  }

  @override
  Future<api.UnsubscribePodcastResponse> unsubscribePodcast({
    required String id,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('unsubscribePodcast');
    final podcast = _subscribed(id);
    subscriptions.remove(id);
    for (final episode in podcast.episodes) {
      progress.remove(episode.id);
    }
    return const api.UnsubscribePodcastResponse(
      success: true,
      message: 'Unsubscribed',
    );
  }

  @override
  Future<api.UpdateEpisodeProgressResponse> updateEpisodeProgress({
    required String podcastId,
    required String episodeId,
    required api.UpdateEpisodeProgressRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('updateEpisodeProgress');
    final podcast = _subscribed(podcastId);
    if (!podcast.episodes.any((e) => e.id == episodeId)) {
      throw const api.NotFound(status: 404);
    }
    progress[episodeId] = body;
    final saved = _progressOf(episodeId)!;
    return api.UpdateEpisodeProgressResponse(
      success: true,
      progress: api.SavedEpisodeProgress(
        currentTime: saved.currentTime,
        isFinished: saved.isFinished,
        progress: saved.progress,
      ),
    );
  }

  @override
  Future<List<api.PodcastSummary>> listTopPodcasts({
    int? limit,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('listTopPodcasts');
    return const [];
  }
}

/// An in-memory model of the server's discovery reads: the recommended
/// artists, the popular artists and this week's discovery playlist. Every
/// call is counted in [calls]; an exception in [failures] is thrown by the
/// call of that name instead of answering. The operations this model does
/// not cover throw [UnimplementedError].
final class FakeDiscoveryClient implements api.DiscoveryClient {
  /// The answer of `GET /recommendations/for-you`.
  List<api.RecommendedArtist> recommended = [];

  /// The answer of `GET /discover/popular-artists`.
  List<api.PopularArtist> popular = [];

  /// The tracks of `GET /discover/current`; empty when there is none.
  List<api.DiscoverTrack> current = [];

  /// The answers of `GET /mixes/:id`, by mix id; an unknown id is
  /// `NotFound`.
  final Map<String, api.MixDetail> mixes = {};

  /// The ids of every `GET /mixes/:id`, in order.
  final List<String> mixIds = [];

  /// The answer of `GET /library/genres`.
  List<api.RadioGenre> radioGenres = [];

  /// The answer of `GET /library/decades`.
  List<api.RadioDecade> radioDecades = [];

  /// The tracks of every `GET /library/radio`.
  List<api.RadioTrack> radioTracks = [];

  /// The `(type, value, limit)` of every `GET /library/radio`, in order.
  final List<(String, String?, int?)> radioRequests = [];

  /// The tracks of every `GET /vibe/similar/:trackId`.
  List<api.SimilarTrack> similarTracks = [];

  /// The `(trackId, limit)` of every `GET /vibe/similar/:trackId`, in
  /// order.
  final List<(String, int?)> similarRequests = [];

  /// The tracks of every `POST /vibe/search`.
  List<api.VibeSearchTrack> vibeTracks = [];

  /// The `(query, limit)` of every `POST /vibe/search`, in order.
  final List<(String, int?)> vibeSearches = [];

  /// Calls by operation name.
  final Map<String, int> calls = {};

  /// The `limit` of each call that takes one, by operation name.
  final Map<String, int?> limits = {};

  /// Exceptions to throw, by operation name.
  final Map<String, Exception> failures = {};

  void _call(String name) {
    calls.update(name, (n) => n + 1, ifAbsent: () => 1);
    if (failures[name] case final error?) throw error;
  }

  @override
  Future<api.RecommendationsForYou> getRecommendationsForYou({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    int? limit,
  }) async {
    _call('getRecommendationsForYou');
    limits['getRecommendationsForYou'] = limit;
    return api.RecommendationsForYou(artists: List.of(recommended));
  }

  @override
  Future<api.PopularArtistsResponse> listPopularArtists({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    int? limit,
  }) async {
    _call('listPopularArtists');
    limits['listPopularArtists'] = limit;
    return api.PopularArtistsResponse(artists: List.of(popular));
  }

  @override
  Future<api.DiscoverCurrent> getCurrentDiscover({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('getCurrentDiscover');
    return api.DiscoverCurrent(
      totalCount: current.length,
      tracks: List.of(current),
      unavailableCount: 0,
      weekStart: DateTime.utc(2026, 11, 9),
      weekEnd: DateTime.utc(2026, 11, 15, 23, 59, 59),
    );
  }

  @override
  Future<api.RadioGenresResponse> listRadioGenres({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('listRadioGenres');
    return api.RadioGenresResponse(genres: List.of(radioGenres));
  }

  @override
  Future<api.RadioDecadesResponse> listRadioDecades({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('listRadioDecades');
    return api.RadioDecadesResponse(decades: List.of(radioDecades));
  }

  @override
  Future<api.RadioResponse> getRadio({
    required api.RadioType type,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    String? value,
    int? limit,
  }) async {
    _call('getRadio');
    radioRequests.add((type.toJson(), value, limit));
    return api.RadioResponse(tracks: List.of(radioTracks));
  }

  @override
  Future<api.SimilarTracksResponse> getSimilarTracks({
    required String trackId,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    int? limit,
  }) async {
    similarRequests.add((trackId, limit));
    _call('getSimilarTracks');
    return api.SimilarTracksResponse(
      sourceFeatures: null,
      sourceTrackId: trackId,
      tracks: List.of(similarTracks),
    );
  }

  @override
  Future<api.VibeSearchResponse> searchVibe({
    required api.VibeSearchRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    vibeSearches.add((body.query, body.limit));
    _call('searchVibe');
    return api.VibeSearchResponse(
      minSimilarity: body.minSimilarity ?? 0.6,
      query: body.query,
      totalAboveThreshold: vibeTracks.length,
      tracks: List.of(vibeTracks),
    );
  }

  @override
  Future<api.MixDetail> getMix({
    required String id,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('getMix');
    mixIds.add(id);
    return mixes[id] ?? (throw const api.NotFound(status: 404));
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// The JSON of a `ListenGroupSnapshot` with the given fields; each queue
/// entry is `(id, playbackId)`.
Map<String, Object?> listenGroupJson({
  String id = 'g1',
  String name = 'Group',
  String joinCode = 'ABC123',
  String groupType = 'host-follower',
  String visibility = 'private',
  String hostUserId = 'host',
  List<String> memberIds = const ['host'],
  List<(String, String?)> queue = const [],
  int currentIndex = 0,
  bool isPlaying = false,
  num positionMs = 0,
  int serverTime = 1000,
  int stateVersion = 1,
}) => {
  'id': id,
  'name': name,
  'joinCode': joinCode,
  'groupType': groupType,
  'visibility': visibility,
  'isActive': true,
  'hostUserId': hostUserId,
  'syncState': isPlaying ? 'playing' : 'paused',
  'members': [
    for (final member in memberIds)
      {
        'userId': member,
        'username': 'user $member',
        'isConnected': true,
        'isHost': member == hostUserId,
        'joinedAt': '2025-01-01T00:00:00.000Z',
      },
  ],
  'playback': {
    'queue': [
      for (final (trackId, playbackId) in queue)
        {
          'id': trackId,
          'title': 'Song $trackId',
          'duration': 180,
          'playbackId': ?playbackId,
          'artist': {'id': 'ar-1', 'name': 'Band'},
          'album': {'id': 'al-1', 'title': 'Record', 'coverArt': 'cover-1'},
        },
    ],
    'currentIndex': currentIndex,
    'trackId': queue.isEmpty ? null : queue[currentIndex].$1,
    'isPlaying': isPlaying,
    'positionMs': positionMs,
    'serverTime': serverTime,
    'stateVersion': stateVersion,
  },
};

/// An in-memory model of the server's Listen Together endpoints (doc 03,
/// "Home, discovery, social"): the [group] create and join answer, every
/// call in [calls] (`create`, `join:<code>`, `discover`, `mine`,
/// `leave:<id>`, `end:<id>`), every create body in [creates], and per-call
/// failures in [failures] by operation name.
final class FakeListenTogetherClient implements api.ListenTogetherClient {
  /// The snapshot JSON create and join answer; create takes its queue from
  /// the request's `queueTracks`.
  Map<String, Object?> group = listenGroupJson();

  /// The summaries discover answers, as JSON.
  final List<Map<String, Object?>> summaries = [];

  /// Whether `mine` answers [group] (else null).
  bool member = false;

  /// Every call, in order.
  final List<String> calls = [];

  /// Every `POST /listen-together` body, in order.
  final List<api.CreateListenGroupRequest> creates = [];

  /// Exceptions to throw, by operation name (`create`, `join`, `discover`,
  /// `mine`, `leave`, `end`).
  final Map<String, Exception> failures = {};

  void _call(String name, [String? argument]) {
    calls.add(argument == null ? name : '$name:$argument');
    if (failures[name] case final error?) throw error;
  }

  @override
  Future<api.ListenGroupSnapshot?> createListenGroup({
    required api.CreateListenGroupRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    creates.add(body);
    _call('create');
    member = true;
    final json = jsonDecode(jsonEncode(group)) as Map<String, Object?>;
    final playback = json['playback']! as Map<String, Object?>;
    playback['queue'] = [
      for (final (i, track) in (body.queueTracks ?? const []).indexed)
        {
          'id': 'q$i',
          'title': track.metadata?.title ?? 'Song $i',
          'duration': track.metadata?.durationSec ?? 0,
          'playbackId': track.playbackId,
          'artist': {'id': 'ar', 'name': track.metadata?.artist ?? ''},
          'album': {
            'id': 'al',
            'title': track.metadata?.album ?? '',
            'coverArt': null,
          },
        },
    ];
    return api.ListenGroupSnapshot.fromJson(json);
  }

  @override
  Future<api.ListenGroupSnapshot?> joinListenGroup({
    required api.JoinListenGroupRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('join', body.joinCode);
    member = true;
    return api.ListenGroupSnapshot.fromJson(group);
  }

  @override
  Future<List<api.ListenGroupSummary>> discoverListenGroups({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('discover');
    return [
      for (final json in summaries) api.ListenGroupSummary.fromJson(json),
    ];
  }

  @override
  Future<api.ListenGroupSnapshot?> getMyListenGroup({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('mine');
    return member ? api.ListenGroupSnapshot.fromJson(group) : null;
  }

  @override
  Future<api.LeaveListenGroupResponse> leaveListenGroup({
    required String groupId,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('leave', groupId);
    member = false;
    return const api.LeaveListenGroupResponse(ended: false, success: true);
  }

  @override
  Future<api.EndListenGroupResponse> endListenGroup({
    required String groupId,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _call('end', groupId);
    member = false;
    return const api.EndListenGroupResponse(success: true);
  }
}

/// An `online` roster user as the server sends it; [track] adds a
/// `listeningTrack`.
Map<String, Object?> onlineUserJson(
  String id, {
  String? displayName,
  String status = 'idle',
  Map<String, Object?>? track,
}) => {
  'id': id,
  'username': id,
  'displayName': displayName ?? 'User $id',
  'hasProfilePicture': false,
  'isInListenTogetherGroup': false,
  'listeningStatus': status,
  'listeningTrack': track,
  'lastHeartbeatAt': '2025-01-01T00:00:00.000Z',
};

/// A `listeningTrack` as the server sends it.
Map<String, Object?> onlineTrackJson(String title, {String artist = 'Band'}) =>
    {
      'id': 'track-$title',
      'title': title,
      'artistName': artist,
      'artistId': null,
      'albumTitle': 'Record',
      'albumId': null,
      'coverArt': 'art-$title',
      'duration': 200,
    };

/// An in-memory model of the server's presence endpoints (doc 03,
/// `POST /social/presence/heartbeat`, `GET /social/online`): every call in
/// [calls], the roster `online` answers in [users] and [peers], and
/// per-call failures in [failures].
final class FakeSocialClient implements api.SocialClient {
  /// The roster users, as JSON.
  final List<Map<String, Object?>> users = [];

  /// The `peers` value of the roster, as JSON; null leaves it out.
  List<Object?>? peers;

  /// Every call, in order: `heartbeat` or `online`.
  final List<String> calls = [];

  /// Exceptions to throw, by operation name (`heartbeat`, `online`).
  final Map<String, Exception> failures = {};

  /// When set, `online` waits for it before answering.
  Completer<void>? gate;

  /// How many heartbeats were sent.
  int get heartbeats => calls.where((c) => c == 'heartbeat').length;

  /// How many rosters were requested.
  int get onlineCalls => calls.where((c) => c == 'online').length;

  @override
  Future<api.PresenceHeartbeatResponse> sendPresenceHeartbeat({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    calls.add('heartbeat');
    if (failures['heartbeat'] case final error?) throw error;
    return api.PresenceHeartbeatResponse.fromJson({
      'success': true,
      'ttlSeconds': 90,
    });
  }

  @override
  Future<api.OnlineUsersResponse> listOnlineUsers({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    calls.add('online');
    await gate?.future;
    if (failures['online'] case final error?) throw error;
    return api.OnlineUsersResponse.fromJson(
      jsonDecode(jsonEncode({'users': users, 'peers': ?peers}))
          as Map<String, Object?>,
    );
  }
}
