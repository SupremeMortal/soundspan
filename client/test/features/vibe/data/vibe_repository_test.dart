// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/features/vibe/data/vibe_repository.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';

const _features = api.VibeAudioFeatures(
  arousal: null,
  danceability: null,
  energy: null,
  valence: null,
);

api.SimilarTrack _similar(String id, {String? playbackId}) => api.SimilarTrack(
  id: id,
  title: 'Song $id',
  duration: 200,
  distance: 0.1,
  similarity: 0.9,
  audioFeatures: _features,
  playbackId: playbackId ?? 'pb-$id',
  albumId: 'al-1',
  album: const api.TrackAlbumRef(id: 'al-1', title: 'Record', coverArt: 'c1'),
  artist: const api.TrackArtistRef(id: 'ar-1', name: 'Band'),
  trackNo: 2,
);

api.VibeSearchTrack _found(String id, {String? playbackId}) =>
    api.VibeSearchTrack(
      id: id,
      title: 'Found $id',
      duration: 180,
      distance: 0.2,
      similarity: 0.8,
      trackNo: 1,
      playbackId: playbackId,
      artist: const api.TrackArtistRef(id: 'ar-2', name: 'Other'),
    );

void main() {
  late FakeDiscoveryClient server;
  late FakeClock clock;
  late ApiVibeRepository repository;

  setUp(() {
    clock = FakeClock();
    server = FakeApi().discovery
      ..similarTracks = [_similar('t2'), _similar('t3')]
      ..vibeTracks = [_found('t4', playbackId: 'pb-t4'), _found('t5')];
    repository = ApiVibeRepository(server, clock);
  });

  int calls(String name) => server.calls[name] ?? 0;

  group('similar', () {
    test('sends the library id and limit and maps the tracks', () async {
      final tracks = await repository.similar('t1', limit: 20);

      expect(server.similarRequests, [('t1', 20)]);
      expect([for (final t in tracks) t.meta.title], ['Song t2', 'Song t3']);
      final first = tracks.first;
      expect(first.playbackId, const PlaybackId('pb-t2'));
      expect(first.libraryTrackId, 't2');
      expect(first.meta.artist, 'Band');
      expect(first.meta.album, 'Record');
      expect(first.meta.durationSec, 200);
      expect(first.albumId, 'al-1');
    });

    test('a 404 is an empty list', () async {
      server.failures['getSimilarTracks'] = const api.NotFound(status: 404);

      expect(await repository.similar('t1'), isEmpty);
    });

    test('is memoised per id for five minutes', () async {
      await repository.similar('t1');
      clock.advance(const Duration(minutes: 4, seconds: 59));
      await repository.similar('t1');
      expect(calls('getSimilarTracks'), 1);

      await repository.similar('t9');
      expect(calls('getSimilarTracks'), 2);

      clock.advance(const Duration(seconds: 2));
      await repository.similar('t1');
      expect(calls('getSimilarTracks'), 3);
    });

    test('a failure is not memoised', () async {
      server.failures['getSimilarTracks'] = const api.ServerError(status: 500);
      await expectLater(
        repository.similar('t1'),
        throwsA(isA<api.ServerError>()),
      );
      server.failures.clear();

      expect(await repository.similar('t1'), hasLength(2));
    });
  });

  group('search', () {
    test(
      'trims the query and maps the tracks, unplayable ones included',
      () async {
        final tracks = await repository.search('  calm piano  ', limit: 30);

        expect(server.vibeSearches, [('calm piano', 30)]);
        expect(
          [for (final t in tracks) t.meta.title],
          ['Found t4', 'Found t5'],
        );
        expect(tracks.first.playbackId, const PlaybackId('pb-t4'));
        expect(tracks.last.playbackId, isNull);
        expect(tracks.last.libraryTrackId, 't5');
      },
    );

    test('a one-character query makes no request', () async {
      expect(await repository.search(' a '), isEmpty);
      expect(calls('searchVibe'), 0);
    });

    test('a query over 200 characters makes no request', () async {
      expect(await repository.search('x' * 201), isEmpty);
      expect(calls('searchVibe'), 0);
    });

    test('errors propagate', () async {
      server.failures['searchVibe'] = const api.Upstream(status: 503);

      await expectLater(
        repository.search('calm'),
        throwsA(isA<api.Upstream>()),
      );
    });
  });
}
