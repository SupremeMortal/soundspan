// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/core/sync/data/playback_state_repository.dart';
import 'package:soundspan/core/sync/playback_state.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockPlaybackClient extends Mock implements api.PlaybackClient;

Map<String, Object?> _stateJson({
  String playbackType = 'track',
  List<Object?>? queue,
  String? podcastId,
}) => {
  'userId': 'u-1',
  'deviceId': 'device-1',
  'playbackType': playbackType,
  'trackId': null,
  'audiobookId': null,
  'podcastId': podcastId,
  'queue': queue,
  'currentIndex': 1,
  'isShuffle': true,
  'isPlaying': false,
  'currentTime': 12.5,
  'updatedAt': '2025-01-01T12:00:00.000Z',
  'createdAt': '2025-01-01T11:00:00.000Z',
};

void main() {
  late _MockPlaybackClient client;
  late PlaybackStateRepository repository;

  setUpAll(
    () => registerFallbackValue(
      const api.SavePlaybackStateRequest(
        playbackType: api.SavePlaybackStateRequestPlaybackType.track,
      ),
    ),
  );

  setUp(() {
    client = _MockPlaybackClient();
    repository = PlaybackStateRepository(client);
    when(() => client.savePlaybackState(body: any(named: 'body')))
        .thenAnswer((_) async => api.PlaybackState.fromJson(_stateJson()));
  });

  Future<Object?> savedBody(PlaybackStateDraft draft) async {
    await repository.save(draft);
    final body = verify(
      () => client.savePlaybackState(body: captureAny(named: 'body')),
    ).captured.single;
    return jsonDecode(jsonEncode(body));
  }

  test('the body of a track state', () async {
    final body = await savedBody(
      const PlaybackStateDraft(
        playbackType: PlaybackStateType.track,
        playbackId: PlaybackId('p-2'),
        currentIndex: 1,
        currentTime: 12.5,
        isShuffle: true,
        isPlaying: true,
        queue: [
          PlaybackStateEntry.track(
            playbackId: PlaybackId('p-1'),
            meta: TrackMeta(
              title: 'One',
              artist: 'A',
              album: 'B',
              durationSec: 3,
            ),
          ),
          PlaybackStateEntry.track(
            playbackId: PlaybackId('p-2'),
            meta: TrackMeta(
              title: 'Two',
              artist: 'A',
              album: 'B',
              durationSec: 4,
              artworkRef: 'cover',
            ),
          ),
        ],
      ),
    );

    expect(body, {
      'playbackType': 'track',
      'playbackId': 'p-2',
      'currentIndex': 1,
      'currentTime': 12.5,
      'isShuffle': true,
      'isPlaying': true,
      'queue': [
        {
          'itemType': 'track',
          'playbackId': 'p-1',
          'metadata': {
            'title': 'One',
            'artist': 'A',
            'album': 'B',
            'durationSec': 3,
          },
        },
        {
          'itemType': 'track',
          'playbackId': 'p-2',
          'metadata': {
            'title': 'Two',
            'artist': 'A',
            'album': 'B',
            'durationSec': 4,
            'artworkUrl': 'cover',
          },
        },
      ],
    });
  });

  test('the body of a podcast state', () async {
    final body = await savedBody(
      const PlaybackStateDraft(
        playbackType: PlaybackStateType.podcast,
        podcastId: 'pod-1',
        currentIndex: 0,
        currentTime: 300,
        isShuffle: false,
        isPlaying: false,
        queue: [
          PlaybackStateEntry.episode(
            podcastId: 'pod-1',
            episodeId: 'ep-1',
            title: 'Episode one',
            podcastTitle: 'The Show',
            durationSec: 1800,
            coverUrl: 'https://img.example/show.png',
          ),
        ],
      ),
    );

    expect(body, {
      'playbackType': 'podcast',
      'podcastId': 'pod-1',
      'currentIndex': 0,
      'currentTime': 300.0,
      'isShuffle': false,
      'isPlaying': false,
      'queue': [
        {
          'itemType': 'episode',
          'id': 'pod-1:ep-1',
          'episodeId': 'ep-1',
          'podcastId': 'pod-1',
          'title': 'Episode one',
          'podcastTitle': 'The Show',
          'duration': 1800,
          'coverUrl': 'https://img.example/show.png',
        },
      ],
    });
  });

  test('a null response maps to null', () async {
    when(client.getPlaybackState).thenAnswer((_) async => null);

    expect(await repository.fetch(), isNull);
  });

  test('a stored state maps tracks and episodes', () async {
    when(client.getPlaybackState).thenAnswer(
      (_) async => api.PlaybackState.fromJson(
        _stateJson(
          queue: [
            {
              'itemType': 'track',
              'id': 'library-1',
              'playbackId': 'p-1',
              'title': 'One',
              'duration': 3,
              'artist': {'id': 'ar-1', 'name': 'A'},
              'album': {'id': 'al-1', 'title': 'B', 'coverArt': 'cover'},
            },
            {'id': 'library-2', 'title': 'Two', 'duration': 4.4},
            {
              'itemType': 'episode',
              'id': 'pod-1:ep-1',
              'title': 'Episode one',
              'duration': 1800,
              'podcastTitle': 'The Show',
              'podcastId': 'pod-1',
              'episodeId': 'ep-1',
              'coverUrl': null,
            },
          ],
        ),
      ),
    );

    expect(
      await repository.fetch(),
      RemotePlaybackState(
        playbackType: PlaybackStateType.track,
        currentIndex: 1,
        currentTime: 12.5,
        isShuffle: true,
        isPlaying: false,
        updatedAt: DateTime.utc(2025, 1, 1, 12),
        queue: const [
          PlaybackStateEntry.track(
            playbackId: PlaybackId('p-1'),
            meta: TrackMeta(
              title: 'One',
              artist: 'A',
              album: 'B',
              durationSec: 3,
              artworkRef: 'cover',
            ),
          ),
          PlaybackStateEntry.track(
            playbackId: null,
            meta: TrackMeta(
              title: 'Two',
              artist: '',
              album: '',
              durationSec: 4,
            ),
          ),
          PlaybackStateEntry.episode(
            podcastId: 'pod-1',
            episodeId: 'ep-1',
            title: 'Episode one',
            podcastTitle: 'The Show',
            durationSec: 1800,
          ),
        ],
      ),
    );
  });

  test('a podcast state keeps its podcast; a null queue is empty', () async {
    when(client.getPlaybackState).thenAnswer(
      (_) async => api.PlaybackState.fromJson(
        _stateJson(playbackType: 'podcast', podcastId: 'pod-1'),
      ),
    );

    final state = await repository.fetch();

    expect(state?.playbackType, PlaybackStateType.podcast);
    expect(state?.podcastId, 'pod-1');
    expect(state?.queue, isEmpty);
  });

  test('an audiobook or unknown state maps to null', () async {
    for (final type in ['audiobook', 'radio']) {
      when(client.getPlaybackState).thenAnswer(
        (_) async => api.PlaybackState.fromJson(_stateJson(playbackType: type)),
      );

      expect(await repository.fetch(), isNull, reason: type);
    }
  });

  test('clear calls DELETE', () async {
    when(client.clearPlaybackState).thenAnswer(
      (_) async => const api.ClearPlaybackStateResponse(success: true),
    );

    await repository.clear();

    verify(client.clearPlaybackState).called(1);
  });

  test('ApiException propagates', () async {
    when(client.getPlaybackState).thenThrow(const api.Offline());

    await expectLater(repository.fetch(), throwsA(isA<api.Offline>()));
  });
}
