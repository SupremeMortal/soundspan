// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/features/player/data/cached_lyrics_repository.dart';
import 'package:soundspan/features/player/domain/lrc.dart';
import 'package:soundspan/features/player/domain/lyrics.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';

Track _track({String? playbackId = 'pb-1', String? libraryTrackId}) => Track(
  meta: const TrackMeta(
    title: 'Song',
    artist: 'Band',
    album: 'Record',
    durationSec: 215,
  ),
  playbackId: playbackId == null ? null : PlaybackId(playbackId),
  libraryTrackId: libraryTrackId,
);

api.Lyrics _answer({String? synced, String? plain}) => api.Lyrics(
  plainLyrics: plain,
  source: api.LyricsSource.lrclib,
  synced: synced != null,
  syncedLyrics: synced,
);

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late FakeReachability reachability;
  late FakePlaybackClient server;
  late CachedLyricsRepository repository;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    reachability = FakeReachability();
    server = FakeApi().playback;
    repository = CachedLyricsRepository(
      server,
      CacheStore(db, clock),
      Swr(clock: clock, reachability: reachability),
      clock,
    );
  });

  tearDown(() => db.close());

  Future<(List<Cached<Lyrics>>, List<Object>)> listenOnce(Track track) async {
    final values = <Cached<Lyrics>>[];
    final errors = <Object>[];
    final subscription = repository
        .lyrics(track)
        .listen(values.add, onError: errors.add);
    await pumpEventQueue();
    await subscription.cancel();
    return (values, errors);
  }

  group('mapping', () {
    test('synced lyrics', () async {
      server.lyrics['pb-1'] = _answer(
        synced: '[00:01.00]One\n[00:02.00]Two',
        plain: 'One\nTwo',
      );

      final (values, errors) = await listenOnce(_track());

      expect(errors, isEmpty);
      expect(
        values.single.value,
        const SyncedLyrics([
          LyricLine(time: Duration(seconds: 1), text: 'One'),
          LyricLine(time: Duration(seconds: 2), text: 'Two'),
        ]),
      );
    });

    test('plain lyrics', () async {
      server.lyrics['pb-1'] = _answer(plain: 'One\nTwo');

      final (values, _) = await listenOnce(_track());

      expect(values.single.value, const PlainLyrics('One\nTwo'));
    });

    test('synced with unparsable text falls back to plain', () async {
      server.lyrics['pb-1'] = _answer(synced: 'no stamps', plain: 'Words');

      final (values, _) = await listenOnce(_track());

      expect(values.single.value, const PlainLyrics('Words'));
    });

    test('nothing found is NoLyrics', () async {
      server.lyrics['pb-1'] = _answer(plain: '   ');

      final (values, _) = await listenOnce(_track());

      expect(values.single.value, const NoLyrics());
    });

    test('NotFound is NoLyrics, not an error', () async {
      server.failures.add(const api.NotFound(status: 404));

      final (values, errors) = await listenOnce(_track());

      expect(errors, isEmpty);
      expect(values.single.value, const NoLyrics());
    });

    test('another failure with nothing cached errors the stream', () async {
      server.failures.add(const api.ServerError(status: 503));

      final (values, errors) = await listenOnce(_track());

      expect(values, isEmpty);
      expect(errors, [isA<api.ServerError>()]);
    });
  });

  group('request', () {
    test('metadata parameters come from TrackMeta', () async {
      await listenOnce(_track());

      final request = server.requests.single;
      expect(request.trackId, 'pb-1');
      expect(request.artist, 'Band');
      expect(request.title, 'Song');
      expect(request.album, 'Record');
      expect(request.duration, 215);
    });

    test('the library id is preferred over playbackId', () async {
      await listenOnce(_track(libraryTrackId: 'lib-9'));

      expect(server.requests.single.trackId, 'lib-9');
      expect(server.requests.single.title, 'Song');
    });

    test('a library id without playbackId is enough', () async {
      await listenOnce(_track(playbackId: null, libraryTrackId: 'lib-9'));

      expect(server.requests.single.trackId, 'lib-9');
    });

    test(
      'no playbackId and no library id is NoLyrics without a request',
      () async {
        final (values, errors) = await listenOnce(_track(playbackId: null));

        expect(errors, isEmpty);
        expect(values.single.value, const NoLyrics());
        expect(server.requests, isEmpty);
      },
    );
  });

  group('cache', () {
    test('a hit within 30 days makes no request', () async {
      server.lyrics['pb-1'] = _answer(plain: 'Words');
      await listenOnce(_track());

      clock.advance(const Duration(days: 30) - const Duration(seconds: 1));
      final (values, _) = await listenOnce(_track());

      expect(server.requests, hasLength(1));
      expect(values.single.value, const PlainLyrics('Words'));
    });

    test('lyrics are refetched after 30 days', () async {
      server.lyrics['pb-1'] = _answer(plain: 'Words');
      await listenOnce(_track());
      server.lyrics['pb-1'] = _answer(plain: 'New words');

      clock.advance(const Duration(days: 30, seconds: 1));
      final (values, _) = await listenOnce(_track());

      expect(server.requests, hasLength(2));
      expect(values.last.value, const PlainLyrics('New words'));
    });

    test('NoLyrics is refetched after 24 hours', () async {
      await listenOnce(_track());
      clock.advance(const Duration(hours: 24) - const Duration(seconds: 1));
      await listenOnce(_track());
      expect(server.requests, hasLength(1));

      server.lyrics['pb-1'] = _answer(plain: 'Added');
      clock.advance(const Duration(seconds: 2));
      final (values, _) = await listenOnce(_track());

      expect(server.requests, hasLength(2));
      expect(values.first.value, const NoLyrics());
      expect(values.last.value, const PlainLyrics('Added'));
    });

    test('offline serves the cache whatever its age', () async {
      server.lyrics['pb-1'] = _answer(plain: 'Words');
      await listenOnce(_track());
      reachability.set(Reachability.serverUnreachable);
      clock.advance(const Duration(days: 365));

      final (values, errors) = await listenOnce(_track());

      expect(errors, isEmpty);
      expect(values.single.value, const PlainLyrics('Words'));
      expect(server.requests, hasLength(1));
    });

    test('synced lyrics survive the cache', () async {
      server.lyrics['pb-1'] = _answer(synced: '[00:01.50]One\n[00:02.00]');
      await listenOnce(_track());
      server.failures.add(const api.ServerError(status: 503));

      final (values, _) = await listenOnce(_track());

      expect(
        values.single.value,
        const SyncedLyrics([
          LyricLine(time: Duration(milliseconds: 1500), text: 'One'),
          LyricLine(time: Duration(seconds: 2), text: ''),
        ]),
      );
    });
  });
}
