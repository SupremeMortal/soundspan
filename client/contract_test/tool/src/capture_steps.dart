// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The declared capture steps of `tool/capture_fixtures.dart`, in the order
/// they run. A step may use values an earlier step left in
/// [CaptureContext.values].
///
/// Steps change only what they create themselves (a playlist, a listen
/// group, an offline device) or write back what they read, so the
/// destructive contract tests that run after the capture see the seeded
/// state.
library;

import 'package:dio/dio.dart';

import 'capture.dart';

export 'capture.dart';

/// The offline device id of every offline step.
const _deviceId = '6f1d6c8e-3a52-4b7e-9c41-0d2b8f6a7e15';

/// Every declared step, in run order.
final List<CaptureStep> captureSteps = [
  // Session and server.
  CaptureStep('getHealth', (c) => c.anonymous.get('/health')),
  CaptureStep('getAuthConfig', (c) => c.anonymous.get('/auth/config')),
  CaptureStep(
    'getOnboardingStatus',
    (c) => c.anonymous.get('/onboarding/status'),
  ),
  CaptureStep('getApiDocument', (c) => c.listener.get('/docs.json')),
  CaptureStep('getSystemFeatures', (c) => c.listener.get('/system/features')),
  CaptureStep(
    'login',
    (c) => c.anonymous.post(
      '/auth/login',
      data: {
        'username': c.credentials.listener.username,
        'password': c.credentials.listener.password,
      },
    ),
  ),
  CaptureStep(
    'login',
    variant: 'requires2FA',
    (c) => c.anonymous.post(
      '/auth/login',
      data: {
        'username': c.credentials.twofa.username,
        'password': c.credentials.twofa.password,
      },
    ),
  ),
  CaptureStep('refreshSession', (c) async {
    final login = await c.logIn(c.credentials.listener);
    return await c.anonymous.post(
      '/auth/refresh',
      data: {'refreshToken': login['refreshToken']},
    );
  }),
  CaptureStep(
    'logout',
    (c) async =>
        await (await c.freshSession(c.credentials.listener))
            .post<String>('/auth/logout'),
  ),
  CaptureStep('getCurrentUser', (c) => c.listener.get('/auth/me')),
  CaptureStep('listApiKeys', (c) => c.listener.get('/api-keys')),
  CaptureStep('getSettings', (c) async {
    final response = await c.listener.get<String>('/settings');
    c.values['settings'] = c.decode(response);
    return response;
  }),
  CaptureStep('updateSettings', (c) async {
    final settings = c.values['settings']! as Map<String, Object?>;
    return await c.listener.post(
      '/settings',
      data: {
        for (final key in const ['playbackQuality', 'loudnessMode'])
          if (settings[key] != null) key: settings[key],
      },
    );
  }),

  // Library.
  CaptureStep('listArtists', (c) async {
    final response = await c.listener.get<String>(
      '/library/artists',
      queryParameters: {'limit': 3},
    );
    c.values['artistId'] = _firstId(c.decode(response), 'artists');
    return response;
  }),
  CaptureStep(
    'getArtist',
    (c) => c.listener.get('/library/artists/${c.values['artistId']}'),
  ),
  CaptureStep('listAlbums', (c) async {
    final response = await c.listener.get<String>(
      '/library/albums',
      queryParameters: {'limit': 3},
    );
    c.values['albumId'] = _firstId(c.decode(response), 'albums');
    return response;
  }),
  CaptureStep(
    'getAlbum',
    (c) => c.listener.get(
      '/library/albums/${c.values['albumId']}',
      queryParameters: {'includeTracks': true},
    ),
  ),
  CaptureStep('setAlbumPreference', (c) async {
    final listener = c.listener;
    final path = '/library/albums/${c.values['albumId']}/preference';
    final response = await listener.post<String>(
      path,
      data: {'signal': 'thumbs_up'},
    );
    await listener.post<String>(path, data: {'signal': 'clear'});
    return response;
  }),
  CaptureStep('listTracks', (c) async {
    final response = await c.listener.get<String>(
      '/library/tracks',
      queryParameters: {'limit': 3},
    );
    final tracks = _list(c.decode(response), 'tracks');
    c.values['trackIds'] = [
      for (final track in tracks) (track! as Map<String, Object?>)['id'],
    ];
    c.values['playbackIds'] = [
      for (final track in tracks)
        (track! as Map<String, Object?>)['playbackId'] ??
            (track as Map<String, Object?>)['id'],
    ];
    return response;
  }),
  CaptureStep('setTrackPreference', (c) async {
    final listener = c.listener;
    final playbackId = _playbackId(c, 0);
    final response = await listener.post<String>(
      '/library/preferences',
      data: {'playbackId': playbackId, 'signal': 'thumbs_up'},
    );
    c.values['likedPlaybackId'] = playbackId;
    return response;
  }),
  // Two liked tracks and a page of one, so the page carries a next cursor.
  CaptureStep('listLikedTracks', (c) async {
    final listener = c.listener;
    final liked = [c.values['likedPlaybackId'], _playbackId(c, 1)];
    await listener.post<String>(
      '/library/preferences',
      data: {'playbackId': liked.last, 'signal': 'thumbs_up'},
    );
    final response = await listener.get<String>(
      '/library/liked',
      queryParameters: {'limit': 1},
    );
    for (final playbackId in liked) {
      await listener.post<String>(
        '/library/preferences',
        data: {'playbackId': playbackId, 'signal': 'clear'},
      );
    }
    return response;
  }),
  CaptureStep(
    'listShuffledTracks',
    (c) => c.listener.get(
      '/library/tracks/shuffle',
      queryParameters: {'limit': 3},
    ),
  ),
  CaptureStep(
    'listRecentlyAdded',
    (c) => c.listener.get(
      '/library/recently-added',
      queryParameters: {'limit': 3},
    ),
  ),

  // Playback.
  CaptureStep(
    'getStreamInfo',
    (c) => c.listener.get('/playback/stream-info/${_playbackId(c, 0)}'),
  ),
  CaptureStep(
    'recordPlay',
    (c) => c.listener.post(
      '/plays',
      data: {'playbackId': _playbackId(c, 0), 'listenedMs': 60000},
    ),
  ),
  CaptureStep(
    'recordPlay',
    variant: 'notRecorded',
    (c) => c.listener.post(
      '/plays',
      data: {'playbackId': _playbackId(c, 0), 'listenedMs': 1000},
    ),
  ),
  CaptureStep(
    'listRecentlyListened',
    (c) => c.listener.get(
      '/library/recently-listened',
      queryParameters: {'limit': 3},
    ),
  ),
  CaptureStep(
    'savePlaybackState',
    (c) => c.listener.post(
      '/playback-state',
      data: {
        'playbackType': 'track',
        'playbackId': _playbackId(c, 0),
        'currentIndex': 0,
        'currentTime': 12.5,
        'isShuffle': false,
        'queue': [
          {'id': _playbackId(c, 0)},
        ],
      },
    ),
  ),
  CaptureStep('getPlaybackState', (c) => c.listener.get('/playback-state')),
  CaptureStep(
    'clearPlaybackState',
    (c) => c.listener.delete('/playback-state'),
  ),

  // Playlists: a playlist of the capture's own, deleted at the end.
  CaptureStep('createPlaylist', (c) async {
    final response = await c.listener.post<String>(
      '/playlists',
      data: {'name': 'Captured fixtures'},
    );
    c.values['playlistId'] =
        (c.decode(response)! as Map<String, Object?>)['id'];
    return response;
  }),
  CaptureStep(
    'updatePlaylist',
    (c) => c.listener.put(
      '/playlists/${c.values['playlistId']}',
      data: {'name': 'Captured fixtures (renamed)'},
    ),
  ),
  CaptureStep('addPlaylistItem', (c) => _addItem(c, 0)),
  CaptureStep('addPlaylistItem', variant: 'duplicate', (c) => _addItem(c, 0)),
  CaptureStep('reorderPlaylistItems', (c) async {
    await _addItem(c, 1);
    return await c.listener.put(
      '/playlists/${c.values['playlistId']}/items/reorder',
      data: {
        'playbackIds': [_playbackId(c, 1), _playbackId(c, 0)],
      },
    );
  }),
  CaptureStep('listPlaylists', (c) => c.listener.get('/playlists')),
  CaptureStep(
    'getPlaylist',
    (c) => c.listener.get('/playlists/${c.values['playlistId']}'),
  ),
  CaptureStep(
    'removePlaylistItem',
    (c) => c.listener.delete(
      '/playlists/${c.values['playlistId']}/items/'
      '${Uri.encodeComponent(_playbackId(c, 1))}',
    ),
  ),
  CaptureStep(
    'deletePlaylist',
    (c) => c.listener.delete('/playlists/${c.values['playlistId']}'),
  ),

  // Search and discovery over the local library.
  CaptureStep(
    'search',
    (c) => c.listener.get('/search', queryParameters: {'q': 'a', 'limit': 3}),
  ),
  CaptureStep('listRadioGenres', (c) => c.listener.get('/library/genres')),
  CaptureStep('listRadioDecades', (c) => c.listener.get('/library/decades')),
  CaptureStep(
    'getRadio',
    (c) => c.listener.get(
      '/library/radio',
      queryParameters: {'type': 'discovery', 'limit': 3},
    ),
  ),
  CaptureStep(
    'getRecommendationsForYou',
    (c) => c.listener.get(
      '/recommendations/for-you',
      queryParameters: {'limit': 3},
    ),
  ),
  CaptureStep('listMixes', (c) async {
    final response = await c.listener.get<String>('/mixes');
    final mixes = c.decode(response)! as List<Object?>;
    c.values['mixId'] = mixes.isEmpty
        ? null
        : (mixes.first! as Map<String, Object?>)['id'];
    return response;
  }),
  CaptureStep('getMix', (c) async {
    final mixId = c.values['mixId'];
    if (mixId == null) throw StateError('listMixes returned no mix');
    return await c.listener.get('/mixes/$mixId');
  }),
  CaptureStep('getCurrentDiscover', (c) => c.listener.get('/discover/current')),

  // Listen together: a group of the listener's that the admin joins.
  CaptureStep('createListenGroup', (c) async {
    final response = await c.listener.post<String>(
      '/listen-together',
      data: {
        'name': 'Captured fixtures',
        'visibility': 'public',
        'queueTrackIds': c.values['trackIds'],
      },
    );
    final group = c.decode(response)! as Map<String, Object?>;
    c.values['groupId'] = group['id'];
    c.values['joinCode'] = group['joinCode'];
    return response;
  }),
  CaptureStep(
    'getMyListenGroup',
    (c) => c.listener.get('/listen-together/mine'),
  ),
  CaptureStep(
    'discoverListenGroups',
    (c) => c.admin.get('/listen-together/discover'),
  ),
  CaptureStep(
    'joinListenGroup',
    (c) => c.admin.post(
      '/listen-together/join',
      data: {'joinCode': c.values['joinCode']},
    ),
  ),
  CaptureStep(
    'leaveListenGroup',
    (c) => c.admin.post('/listen-together/${c.values['groupId']}/leave'),
  ),
  CaptureStep(
    'endListenGroup',
    (c) => c.listener.post('/listen-together/${c.values['groupId']}/end'),
  ),

  // Offline items of a device of the capture's own, removed at the end.
  CaptureStep(
    'requestOfflineItems',
    (c) => c.listener.post(
      '/offline/items',
      data: {'deviceId': _deviceId, 'kind': 'track', 'id': _playbackId(c, 0)},
    ),
  ),
  CaptureStep(
    'completeOfflineItem',
    (c) => c.listener.post(
      '/offline/items/complete',
      data: {
        'deviceId': _deviceId,
        'playbackId': _playbackId(c, 0),
        'quality': 'original',
        'sizeBytes': 1024,
      },
    ),
  ),
  CaptureStep(
    'listOfflineItems',
    (c) => c.listener.get(
      '/offline/items',
      queryParameters: {'deviceId': _deviceId},
    ),
  ),
  CaptureStep(
    'getOfflineStats',
    (c) => c.listener.get(
      '/offline/stats',
      queryParameters: {'deviceId': _deviceId},
    ),
  ),
  CaptureStep(
    'deleteOfflineItems',
    (c) => c.listener.delete(
      '/offline/items',
      data: {
        'deviceId': _deviceId,
        'playbackIds': [_playbackId(c, 0)],
      },
    ),
  ),

  // Podcasts: the seeded subscription; unsubscribing and subscribing again
  // restores it.
  CaptureStep('listPodcasts', (c) async {
    final response = await c.listener.get<String>('/podcasts');
    final podcast = (c.decode(response)! as List<Object?>).first!;
    c.values['podcastId'] = (podcast as Map<String, Object?>)['id'];
    return response;
  }),
  CaptureStep('getPodcast', (c) async {
    final response = await c.listener.get<String>(
      '/podcasts/${c.values['podcastId']}',
    );
    c.values['episodeId'] = _firstId(c.decode(response), 'episodes');
    c.values['feedUrl'] =
        (c.decode(response)! as Map<String, Object?>)['feedUrl'];
    return response;
  }),
  CaptureStep(
    'updateEpisodeProgress',
    (c) => c.listener.post(
      '/podcasts/${c.values['podcastId']}/episodes/${c.values['episodeId']}'
      '/progress',
      data: {'currentTime': 2, 'duration': 8, 'isFinished': false},
    ),
  ),
  CaptureStep(
    'unsubscribePodcast',
    (c) => c.listener.delete('/podcasts/${c.values['podcastId']}/unsubscribe'),
  ),
  CaptureStep(
    'subscribePodcast',
    (c) => c.listener.post(
      '/podcasts/subscribe',
      data: {'feedUrl': c.values['feedUrl']},
    ),
  ),

  // Social.
  CaptureStep(
    'sendPresenceHeartbeat',
    (c) => c.listener.post('/social/presence/heartbeat'),
  ),
  CaptureStep('listOnlineUsers', (c) => c.listener.get('/social/online')),
];

/// The `id` of the first element of the array under [key] of [body].
Object? _firstId(Object? body, String key) =>
    (_list(body, key).first! as Map<String, Object?>)['id'];

/// The array under [key] of [body]; throws when there is none or it is
/// empty.
List<Object?> _list(Object? body, String key) {
  final list = body is Map<String, Object?> ? body[key] : null;
  if (list is! List<Object?> || list.isEmpty) {
    throw StateError('the response has no "$key"');
  }
  return list;
}

/// The playbackId of the [index]th track `listTracks` returned.
String _playbackId(CaptureContext c, int index) =>
    (c.values['playbackIds']! as List<Object?>)[index]! as String;

Future<Response<String>> _addItem(CaptureContext c, int index) =>
    c.listener.post(
      '/playlists/${c.values['playlistId']}/items',
      data: {'playbackId': _playbackId(c, index)},
    );
