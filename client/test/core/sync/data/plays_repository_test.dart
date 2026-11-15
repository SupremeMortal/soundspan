// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/core/sync/data/plays_repository.dart';
import 'package:soundspan/core/sync/play_report_result.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockPlaybackClient extends Mock implements api.PlaybackClient;

const _meta = TrackMeta(
  title: 'Aster Tone',
  artist: 'Contract Aurora',
  album: 'First Light',
  durationSec: 30,
  artworkRef: 'cover-1',
  isrc: 'XX0000000001',
);

void main() {
  late _MockPlaybackClient client;
  late PlaysRepository repository;

  setUpAll(
    () => registerFallbackValue(const api.RecordPlayRequest(playbackId: '')),
  );

  setUp(() {
    client = _MockPlaybackClient();
    repository = PlaysRepository(client);
  });

  Future<PlayReportResult> report() => repository.report(
    playbackId: const PlaybackId('p-1'),
    meta: _meta,
    // A local time: the body carries it in UTC.
    playedAt: DateTime.utc(2025, 1, 1, 12).toLocal(),
    listenedMs: 20000,
  );

  test('the body carries metadata from TrackMeta, playedAt in UTC and '
      'listenedMs', () async {
    when(() => client.recordPlay(body: any(named: 'body'))).thenAnswer(
      (_) async => api.RecordPlayResponse200.fromJson({'recorded': false}),
    );

    await report();

    final body =
        verify(() => client.recordPlay(body: captureAny(named: 'body')))
                .captured
                .single
            as api.RecordPlayRequest;
    expect(jsonDecode(jsonEncode(body)), {
      'playbackId': 'p-1',
      'playedAt': '2025-01-01T12:00:00.000Z',
      'listenedMs': 20000,
      'metadata': {
        'title': 'Aster Tone',
        'artist': 'Contract Aurora',
        'album': 'First Light',
        'durationSec': 30,
        'artworkUrl': 'cover-1',
        'isrc': 'XX0000000001',
      },
    });
  });

  test('metadata without artwork or ISRC leaves both out', () async {
    when(() => client.recordPlay(body: any(named: 'body'))).thenAnswer(
      (_) async => api.RecordPlayResponse200.fromJson({'recorded': false}),
    );

    await repository.report(
      playbackId: const PlaybackId('p-1'),
      meta: const TrackMeta(
        title: 't',
        artist: 'a',
        album: 'b',
        durationSec: 3,
      ),
      playedAt: DateTime.utc(2025),
      listenedMs: 5000,
    );

    final body =
        verify(() => client.recordPlay(body: captureAny(named: 'body')))
                .captured
                .single
            as api.RecordPlayRequest;
    expect(jsonDecode(jsonEncode(body.metadata)), {
      'title': 't',
      'artist': 'a',
      'album': 'b',
      'durationSec': 3,
    });
  });

  test('metadata with a blank artist, title or album is left out', () async {
    when(() => client.recordPlay(body: any(named: 'body'))).thenAnswer(
      (_) async => api.RecordPlayResponse200.fromJson({'recorded': false}),
    );

    for (final meta in const [
      TrackMeta(title: 't', artist: '', album: 'b', durationSec: 3),
      TrackMeta(title: ' ', artist: 'a', album: 'b', durationSec: 3),
      TrackMeta(title: 't', artist: 'a', album: '', durationSec: 3),
    ]) {
      await repository.report(
        playbackId: const PlaybackId('p-1'),
        meta: meta,
        playedAt: DateTime.utc(2025),
        listenedMs: 5000,
      );
      final body =
          verify(() => client.recordPlay(body: captureAny(named: 'body')))
                  .captured
                  .single
              as api.RecordPlayRequest;
      expect(jsonDecode(jsonEncode(body)), isNot(contains('metadata')));
    }
  });

  test('a play row maps to recorded', () async {
    when(() => client.recordPlay(body: any(named: 'body'))).thenAnswer(
      (_) async => api.RecordPlayResponse200.fromJson({
        'id': 'play-1',
        'playedAt': '2025-01-01T12:00:00.000Z',
        'listenedMs': 20000,
        'source': 'LIBRARY',
      }),
    );

    expect(await report(), PlayReportResult.recorded);
  });

  test('{ recorded: false } maps to notRecorded', () async {
    when(() => client.recordPlay(body: any(named: 'body'))).thenAnswer(
      (_) async => api.RecordPlayResponse200.fromJson({'recorded': false}),
    );

    expect(await report(), PlayReportResult.notRecorded);
  });

  test('ApiException propagates', () async {
    when(() => client.recordPlay(body: any(named: 'body'))).thenThrow(
      const api.InvalidRequest(status: 400, code: 'INVALID_PLAYED_AT'),
    );

    await expectLater(
      report(),
      throwsA(
        isA<api.InvalidRequest>().having(
          (error) => error.code,
          'code',
          'INVALID_PLAYED_AT',
        ),
      ),
    );
  });
}
