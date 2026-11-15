// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Playback, plays, state, lyrics" of doc 03's endpoint
/// inventory: every operation of that table through the generated client,
/// the stream through a plain HTTP client with `StreamUrls`, and the P7 and
/// P8 behaviours, against the seeded server with response validation on.
@Tags(['contract'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

/// The fixture track of 30 seconds, for Range cases.
const _longTrack = 'Aster Tone';

/// A 3-second fixture track for the quality variants.
const _shortTrack = 'Birch Tone';

/// The fixture track with embedded LRC lyrics.
const _lyricsTrack = 'Opal Tone';

/// A track no other contract test plays, and its artist, for P7.
const _p7Track = 'North Tone';
const _p7Artist = 'Contract Cinder';

/// One answer of a plain HTTP request.
typedef _Answer = ({int status, HttpHeaders headers, Uint8List body});

/// GETs [uri] with [headers] through a plain HTTP client.
Future<_Answer> _get(Uri uri, [Map<String, String> headers = const {}]) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    headers.forEach(request.headers.set);
    final response = await request.close();
    final builder = await response.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );
    return (
      status: response.statusCode,
      headers: response.headers,
      body: builder.takeBytes(),
    );
  } finally {
    client.close(force: true);
  }
}

/// The `code` of a JSON error body.
Object? _code(_Answer answer) =>
    (jsonDecode(utf8.decode(answer.body)) as Map<String, Object?>)['code'];

/// A device id no earlier run used.
String _deviceId() =>
    'contract-${Random().nextInt(1 << 32).toRadixString(16)}-'
    '${DateTime.now().microsecondsSinceEpoch}';

void main() {
  late ContractCredentials credentials;
  late JwtCredentials session;
  late SoundspanApi api;
  late StreamUrls urls;

  setUp(() async {
    credentials = ContractCredentials.load();
    final login = await logIn(credentials, credentials.listener);
    session = JwtCredentials(
      accessToken: login.token,
      refreshToken: login.refreshToken,
    );
    api = credentialedApi(credentials, InMemoryCredentialProvider(session));
    urls = StreamUrls(credentials.baseUrl);
  });

  Future<LibraryTrack> fixtureTrack(String title) async {
    final page = await api.send((rest) => rest.library2.listTracks(limit: 100));
    return page.tracks.singleWhere((track) => track.title == title);
  }

  Future<String> playbackIdOf(String title) async =>
      (await fixtureTrack(title)).playbackId!;

  group('stream', () {
    test('answers 200 with the audio bytes, a strong ETag and 206 for a '
        'Range', () async {
      final uri = urls.track(
        await playbackIdOf(_longTrack),
        quality: 'original',
      );
      final headers = urls.authHeaders(session);

      final full = await _get(uri, headers);
      expect(full.status, 200);
      expect(full.headers.contentType?.primaryType, 'audio');
      expect(full.body.length, greaterThan(1000));
      final etag = full.headers.value(HttpHeaders.etagHeader);
      expect(etag, isNotNull);
      expect(etag, isNot(startsWith('W/')));

      final range = await _get(uri, {...headers, 'Range': 'bytes=0-99'});
      expect(range.status, 206);
      expect(range.body, full.body.sublist(0, 100));
      expect(
        range.headers.value(HttpHeaders.contentRangeHeader),
        'bytes 0-99/${full.body.length}',
      );
    });

    test('If-Range with the ETag answers 206; with another tag 200', () async {
      final uri = urls.track(
        await playbackIdOf(_longTrack),
        quality: 'original',
      );
      final headers = urls.authHeaders(session);
      final etag = (await _get(
        uri,
        headers,
      )).headers.value(HttpHeaders.etagHeader)!;

      final matching = await _get(uri, {
        ...headers,
        'Range': 'bytes=100-199',
        'If-Range': etag,
      });
      final other = await _get(uri, {
        ...headers,
        'Range': 'bytes=100-199',
        'If-Range': '"not-the-tag"',
      });

      expect(matching.status, 206);
      expect(matching.body, hasLength(100));
      expect(other.status, 200);
      expect(other.body.length, greaterThan(100));
    });

    test('each quality and the server default answer 200', () async {
      final playbackId = await playbackIdOf(_shortTrack);
      for (final quality in [null, 'original', 'high', 'medium', 'low']) {
        final answer = await _get(
          urls.track(playbackId, quality: quality),
          urls.authHeaders(session),
        );

        expect(answer.status, 200, reason: 'quality $quality');
        expect(answer.body, isNotEmpty, reason: 'quality $quality');
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('an id the server cannot parse is 400 INVALID_PLAYBACK_ID', () async {
      final answer = await _get(
        urls.track('not a playback id'),
        urls.authHeaders(session),
      );

      expect(answer.status, 400);
      expect(_code(answer), 'INVALID_PLAYBACK_ID');
    });

    test('an unknown quality is 400 INVALID_QUALITY', () async {
      final answer = await _get(
        urls.track(await playbackIdOf(_shortTrack), quality: 'lossless'),
        urls.authHeaders(session),
      );

      expect(answer.status, 400);
      expect(_code(answer), 'INVALID_QUALITY');
    });

    test('a request without a credential is 401', () async {
      final answer = await _get(urls.track(await playbackIdOf(_shortTrack)));

      expect(answer.status, 401);
    });

    test(
      'a track whose source is disabled is 409 SOURCE_UNAVAILABLE',
      () async {
        final unavailable = credentials.unavailablePlaybackId;
        if (unavailable == null) {
          markTestSkipped('the seed found no unavailable playbackId');
          return;
        }

        final answer = await _get(
          urls.track(unavailable),
          urls.authHeaders(session),
        );

        expect(answer.status, 409);
        final body =
            jsonDecode(utf8.decode(answer.body)) as Map<String, Object?>;
        expect(body['code'], 'SOURCE_UNAVAILABLE');
        expect(body['error'], isA<String>());
      },
    );
  });

  test('stream-info describes a library track', () async {
    final playbackId = await playbackIdOf(_longTrack);

    final info = await api.send(
      (rest) => rest.playback.getStreamInfo(
        playbackId: playbackId,
        quality: PlaybackQuality.original,
      ),
    );

    expect(info.playbackId, playbackId);
    expect(info.quality, PlaybackQuality.original);
    expect(info.contentType, startsWith('audio/'));
    expect(info.contentLength, greaterThan(0));
    expect(info.durationMs, closeTo(30000, 1000));
  });

  test('P7: a stream with report=0 records no play; the same stream with '
      'reportPlay: true does', () async {
    Future<DateTime?> lastPlayed() async {
      final recent = await api.send(
        (rest) => rest.library2.listRecentlyListened(limit: 100),
      );
      return recent.items
          .where((item) => item.name == _p7Artist)
          .firstOrNull
          ?.lastPlayedAt;
    }

    final playbackId = await playbackIdOf(_p7Track);
    final before = await lastPlayed();

    final silent = await _get(
      urls.track(playbackId),
      urls.authHeaders(session),
    );
    expect(silent.status, 200);
    expect(await lastPlayed(), before);

    final reported = await _get(
      urls.track(playbackId, reportPlay: true),
      urls.authHeaders(session),
    );
    expect(reported.status, 200);
    final after = await lastPlayed();
    expect(after, isNotNull);
    if (before != null) expect(after!.isAfter(before), isTrue);
  });

  group('P8 plays', () {
    /// An instant an hour ago, in whole milliseconds, unique per call.
    var offsetMs = 0;
    DateTime playedAt() {
      final now = DateTime.now().toUtc();
      offsetMs += 1000;
      return DateTime.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch - 3600 * 1000 - offsetMs,
        isUtc: true,
      );
    }

    Future<RecordPlayResponse200> record(
      String title, {
      required DateTime playedAt,
      required int listenedMs,
    }) async {
      final track = await fixtureTrack(title);
      return await api.send(
        (rest) => rest.playback.recordPlay(
          body: RecordPlayRequest(
            playbackId: track.playbackId!,
            playedAt: playedAt,
            listenedMs: listenedMs,
            metadata: PlaybackMetadata(
              title: track.title,
              artist: track.artist?.name ?? '',
              album: track.album.title,
              durationSec: track.duration,
            ),
          ),
        ),
      );
    }

    /// The plays of the history (`GET /plays`, not part of the client
    /// surface) that began at [at].
    Future<int> playsAt(DateTime at) async {
      final answer = await _get(
        credentials.baseUrl.replace(
          path: '${credentials.baseUrl.path}/api/plays',
          queryParameters: {'limit': '200'},
        ),
        urls.authHeaders(session),
      );
      expect(answer.status, 200);
      final plays = jsonDecode(utf8.decode(answer.body)) as List<Object?>;
      return plays
          .cast<Map<String, Object?>>()
          .where((play) => DateTime.parse(play['playedAt']! as String) == at)
          .length;
    }

    test('a play with playedAt and listenedMs is recorded with both; the '
        'identical request returns the same row and the history shows one '
        'play', () async {
      final at = playedAt();

      final first = await record('Vale Tone', playedAt: at, listenedMs: 20000);
      final again = await record('Vale Tone', playedAt: at, listenedMs: 20000);

      final row = first.asPlayRecord!;
      expect(row.playedAt, at);
      expect(row.listenedMs, 20000);
      expect(again.asPlayRecord!.id, row.id);
      expect(await playsAt(at), 1);
    });

    test(
      'listenedMs 4999 answers recorded: false and records nothing',
      () async {
        final at = playedAt();

        final answer = await record(
          'Willow Tone',
          playedAt: at,
          listenedMs: 4999,
        );

        expect(answer.hasPlayNotRecorded, isTrue);
        expect(answer.asPlayNotRecorded!.recorded.toJson(), isFalse);
        expect(await playsAt(at), 0);
      },
    );

    test('a playedAt beyond the clock-skew allowance is INVALID_PLAYED_AT', () {
      expect(
        record(
          'Xenon Tone',
          playedAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
          listenedMs: 20000,
        ),
        throwsA(
          isA<InvalidRequest>().having(
            (error) => error.code,
            'code',
            'INVALID_PLAYED_AT',
          ),
        ),
      );
    });

    test('a negative listenedMs is INVALID_LISTENED_MS', () {
      expect(
        record('Xenon Tone', playedAt: playedAt(), listenedMs: -1),
        throwsA(
          isA<InvalidRequest>().having(
            (error) => error.code,
            'code',
            'INVALID_LISTENED_MS',
          ),
        ),
      );
    });
  });

  group('playback state', () {
    SoundspanApi deviceApi(String deviceId) => credentialedApi(
      credentials,
      InMemoryCredentialProvider(session),
      playbackDeviceId: deviceId,
    );

    Future<List<SavePlaybackStateRequestQueueItem>> queueOf(int length) async {
      final page = await api.send(
        (rest) => rest.library2.listTracks(limit: 100),
      );
      final tracks = page.tracks;
      return [
        for (var i = 0; i < length; i++)
          SavePlaybackStateRequestQueueItem(
            itemType: SavePlaybackStateRequestQueueItemItemType.track,
            playbackId: tracks[i % tracks.length].playbackId,
            metadata: PlaybackMetadata(
              title: tracks[i % tracks.length].title,
              artist: tracks[i % tracks.length].artist?.name ?? '',
              album: tracks[i % tracks.length].album.title,
              durationSec: tracks[i % tracks.length].duration,
            ),
          ),
      ];
    }

    test('save then fetch round-trips for one device; another device sees '
        'none; clear then fetch gives null', () async {
      final device = deviceApi(_deviceId());
      final other = deviceApi(_deviceId());
      final queue = await queueOf(3);

      await device.send(
        (rest) => rest.playback.savePlaybackState(
          body: SavePlaybackStateRequest(
            playbackType: SavePlaybackStateRequestPlaybackType.track,
            playbackId: queue[1].playbackId,
            queue: queue,
            currentIndex: 1,
            currentTime: 12.5,
            isShuffle: true,
            isPlaying: false,
          ),
        ),
      );
      final stored = await device.send(
        (rest) => rest.playback.getPlaybackState(),
      );

      expect(stored, isNotNull);
      expect(stored!.currentIndex, 1);
      expect(stored.currentTime, 12.5);
      expect(stored.isShuffle, isTrue);
      expect(stored.isPlaying, isFalse);
      expect(
        [for (final item in stored.queue!) item.playbackId],
        [for (final item in queue) item.playbackId],
      );

      // Clearing also clears the shared legacy state, which a device without
      // a state of its own would otherwise be given.
      await other.send((rest) => rest.playback.clearPlaybackState());
      expect(
        await other.send((rest) => rest.playback.getPlaybackState()),
        isNull,
      );

      await device.send((rest) => rest.playback.clearPlaybackState());
      expect(
        await device.send((rest) => rest.playback.getPlaybackState()),
        isNull,
      );
    });

    test('a queue of 120 items is stored as 100', () async {
      final device = deviceApi(_deviceId());
      addTearDown(
        () => device.send((rest) => rest.playback.clearPlaybackState()),
      );

      final queue = await queueOf(120);
      await device.send(
        (rest) => rest.playback.savePlaybackState(
          body: SavePlaybackStateRequest(
            playbackType: SavePlaybackStateRequestPlaybackType.track,
            queue: queue,
            currentIndex: 0,
          ),
        ),
      );
      final stored = await device.send(
        (rest) => rest.playback.getPlaybackState(),
      );

      expect(stored!.queue, hasLength(100));
    });
  });

  test('lyrics of the fixture track with embedded lyrics decode', () async {
    final track = await fixtureTrack(_lyricsTrack);

    final lyrics = await api.send(
      (rest) => rest.playback.getLyrics(
        trackId: track.id,
        artist: track.artist?.name,
        title: track.title,
        album: track.album.title,
        duration: track.duration,
      ),
    );

    expect(lyrics.source, isNotNull);
  });
}
