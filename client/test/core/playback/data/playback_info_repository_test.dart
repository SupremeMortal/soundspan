// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockPlaybackClient extends Mock implements api.PlaybackClient;

api.StreamInfo _info(String playbackId, {String quality = 'medium'}) =>
    api.StreamInfo.fromJson({
      'playbackId': playbackId,
      'quality': quality,
      'contentType': 'audio/flac',
      'codec': 'flac',
      'bitrate': 900,
      'sampleRate': 44100,
      'bitDepth': 16,
      'durationMs': 30000,
      'contentLength': 1234567,
    });

void main() {
  late _MockPlaybackClient client;
  late PlaybackInfoRepository repository;

  setUpAll(() => registerFallbackValue(api.PlaybackQuality.medium));

  setUp(() {
    client = _MockPlaybackClient();
    repository = PlaybackInfoRepository(client);
    when(
      () => client.getStreamInfo(
        playbackId: any(named: 'playbackId'),
        quality: any(named: 'quality'),
      ),
    ).thenAnswer(
      (invocation) async => _info(
        invocation.namedArguments[#playbackId] as String,
        quality:
            (invocation.namedArguments[#quality] as api.PlaybackQuality?)
                ?.toJson() ??
            'medium',
      ),
    );
  });

  test('maps every field of the wire model', () async {
    final info = await repository.streamInfo(
      const PlaybackId('p-1'),
      quality: 'high',
    );

    expect(
      info,
      const StreamQualityInfo(
        quality: 'high',
        contentType: 'audio/flac',
        codec: 'flac',
        bitrate: 900,
        sampleRate: 44100,
        bitDepth: 16,
        durationMs: 30000,
        contentLength: 1234567,
      ),
    );
    verify(
      () => client.getStreamInfo(
        playbackId: 'p-1',
        quality: api.PlaybackQuality.high,
      ),
    ).called(1);
  });

  test('null fields stay null', () async {
    when(() => client.getStreamInfo(playbackId: 'p-2')).thenAnswer(
      (_) async => api.StreamInfo.fromJson({
        'playbackId': 'p-2',
        'quality': 'original',
        'contentType': null,
        'codec': null,
        'bitrate': null,
        'sampleRate': null,
        'bitDepth': null,
        'durationMs': null,
        'contentLength': null,
      }),
    );

    final info = await repository.streamInfo(const PlaybackId('p-2'));

    expect(info, const StreamQualityInfo(quality: 'original'));
  });

  test(
    'a second call for the same id and quality does not hit the API',
    () async {
      await repository.streamInfo(const PlaybackId('p-1'), quality: 'low');
      await repository.streamInfo(const PlaybackId('p-1'), quality: 'low');

      verify(
        () => client.getStreamInfo(
          playbackId: 'p-1',
          quality: api.PlaybackQuality.low,
        ),
      ).called(1);
    },
  );

  test('a different quality or id does hit the API', () async {
    await repository.streamInfo(const PlaybackId('p-1'), quality: 'low');
    await repository.streamInfo(const PlaybackId('p-1'), quality: 'high');
    await repository.streamInfo(const PlaybackId('p-1'));
    await repository.streamInfo(const PlaybackId('p-3'), quality: 'low');

    verify(
      () => client.getStreamInfo(
        playbackId: any(named: 'playbackId'),
        quality: any(named: 'quality'),
      ),
    ).called(4);
  });

  test('a failure propagates and is not cached', () async {
    when(() => client.getStreamInfo(playbackId: 'p-4'))
        .thenThrow(const api.ServerError(status: 500));

    await expectLater(
      repository.streamInfo(const PlaybackId('p-4')),
      throwsA(isA<api.ServerError>()),
    );

    when(() => client.getStreamInfo(playbackId: 'p-4'))
        .thenAnswer((_) async => _info('p-4'));
    final info = await repository.streamInfo(const PlaybackId('p-4'));

    expect(info.quality, 'medium');
    verify(() => client.getStreamInfo(playbackId: 'p-4')).called(2);
  });
}
