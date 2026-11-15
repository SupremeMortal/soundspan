// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/core/sync/data/preference_repository.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockLibraryClient extends Mock implements api.LibraryClient;

const _meta = TrackMeta(
  title: 'Aster Tone',
  artist: 'Contract Aurora',
  album: 'First Light',
  durationSec: 30,
  artworkRef: 'cover-1',
  isrc: 'XX0000000001',
);

const _signals = {
  Preference.liked: 'thumbs_up',
  Preference.disliked: 'thumbs_down',
  Preference.neutral: 'clear',
};

api.TrackPreferenceResponse _trackAnswer(String signal, String state) =>
    api.TrackPreferenceResponse.fromJson({
      'playbackId': 'p-1',
      'trackId': 't-1',
      'signal': signal,
      'state': state,
      'score': 0,
      'likedAt': state == 'liked' ? '2026-01-01T00:00:00.000Z' : null,
      'dislikedAt': null,
      'updatedAt': '2026-01-01T00:00:00.000Z',
    });

api.AlbumPreferenceResponse _albumAnswer(String signal, String state) =>
    api.AlbumPreferenceResponse.fromJson({
      'albumId': 'al-1',
      'trackCount': 10,
      'signal': signal,
      'state': state,
      'score': 0,
      'likedAt': null,
      'dislikedAt': null,
      'updatedAt': '2026-01-01T00:00:00.000Z',
    });

void main() {
  late _MockLibraryClient client;
  late PreferenceRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const api.TrackPreferenceRequest(
        playbackId: '',
        signal: api.PreferenceSignal.clear,
      ),
    );
    registerFallbackValue(
      const api.AlbumPreferenceRequest(signal: api.PreferenceSignal.clear),
    );
  });

  setUp(() {
    client = _MockLibraryClient();
    repository = PreferenceRepository(client);
  });

  api.TrackPreferenceRequest capturedTrackBody() =>
      verify(() => client.setTrackPreference(body: captureAny(named: 'body')))
              .captured
              .single
          as api.TrackPreferenceRequest;

  for (final MapEntry(key: value, value: signal) in _signals.entries) {
    test('a track set to ${value.name} sends signal $signal', () async {
      when(() => client.setTrackPreference(body: any(named: 'body')))
          .thenAnswer((_) async => _trackAnswer(signal, value.name));

      final state = await repository.setTrackPreference(
        const PlaybackId('p-1'),
        value,
        meta: _meta,
      );

      final body = capturedTrackBody();
      expect(body.playbackId, 'p-1');
      expect(body.signal.toJson(), signal);
      expect(state, value);
    });

    test('an album set to ${value.name} sends signal $signal', () async {
      when(
        () => client.setAlbumPreference(
          id: any(named: 'id'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _albumAnswer(signal, value.name));

      final state = await repository.setAlbumPreference('al-1', value);

      final captured = verify(
        () => client.setAlbumPreference(
          id: captureAny(named: 'id'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect(captured[0], 'al-1');
      expect((captured[1] as api.AlbumPreferenceRequest).toJson(), {
        'signal': signal,
      });
      expect(state, value);
    });
  }

  test('the track request carries metadata built from TrackMeta', () async {
    when(() => client.setTrackPreference(body: any(named: 'body')))
        .thenAnswer((_) async => _trackAnswer('thumbs_up', 'liked'));

    await repository.setTrackPreference(
      const PlaybackId('p-1'),
      Preference.liked,
      meta: _meta,
    );

    expect(capturedTrackBody().toJson()['metadata'], {
      'title': 'Aster Tone',
      'artist': 'Contract Aurora',
      'album': 'First Light',
      'durationSec': 30,
      'artworkUrl': 'cover-1',
      'isrc': 'XX0000000001',
    });
  });

  test(
    'the state the server answers is returned, not the one asked for',
    () async {
      when(() => client.setTrackPreference(body: any(named: 'body')))
          .thenAnswer((_) async => _trackAnswer('thumbs_down', 'neutral'));

      final state = await repository.setTrackPreference(
        const PlaybackId('p-1'),
        Preference.disliked,
        meta: _meta,
      );

      expect(state, Preference.neutral);
    },
  );

  test('an ApiException propagates unchanged', () async {
    const failure = api.NotFound(status: 404, code: 'TRACK_NOT_FOUND');
    when(() => client.setTrackPreference(body: any(named: 'body')))
        .thenThrow(failure);

    await expectLater(
      repository.setTrackPreference(
        const PlaybackId('p-1'),
        Preference.liked,
        meta: _meta,
      ),
      throwsA(same(failure)),
    );
  });
}
