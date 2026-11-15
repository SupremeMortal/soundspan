// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/stream_auth/stream_auth_io.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_reachability.dart';

/// Hands out [next] and records every requested lifetime.
class _Credentials {
  Credentials next = const JwtCredentials(
    accessToken: 'fresh',
    refreshToken: 'r',
  );
  final List<Duration> asked = [];

  Future<Credentials> ensureFresh({required Duration minRemaining}) async {
    asked.add(minRemaining);
    return next;
  }
}

QueueItem _track(String id, {String? playbackId, int durationSec = 215}) =>
    QueueItem.track(
      queueItemId: id,
      track: Track(
        meta: TrackMeta(
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          durationSec: durationSec,
        ),
        playbackId: playbackId == null ? null : PlaybackId(playbackId),
      ),
      context: const QueueContext(kind: QueueContextKind.album),
    );

void main() {
  late StateDatabase db;
  late DeviceSettingsDao settings;
  late _Credentials credentials;
  late SourceResolver resolver;

  setUp(() {
    db = StateDatabase(NativeDatabase.memory());
    settings = DeviceSettingsDao(db);
    credentials = _Credentials();
    resolver = SourceResolver(
      ensureFresh: credentials.ensureFresh,
      urls: StreamUrls(Uri.parse('https://music.example.com/sub')),
      quality: StreamQualityPolicy(settings, FakeReachability()),
      auth: const HeaderStreamAuth(),
    );
  });
  tearDown(() => db.close());

  test('a track URL carries report=0 and the chosen quality', () async {
    await settings.write(qualityWifiKey, 'high');
    final source = await resolver.resolve(_track('q1', playbackId: 'p1'));
    expect(source.queueItemId, 'q1');
    expect(source.uri.path, '/sub/api/playback/stream/p1');
    expect(source.uri.queryParameters, {'quality': 'high', 'report': '0'});
  });

  test('the server-default quality leaves the parameter out', () async {
    await settings.write(qualityWifiKey, serverDefaultQuality);
    final source = await resolver.resolve(_track('q1', playbackId: 'p1'));
    expect(source.uri.queryParameters, {'report': '0'});
  });

  test('an episode URL names the podcast and the episode', () async {
    await settings.write(qualityWifiKey, 'high');
    final source = await resolver.resolve(
      const QueueItem.episode(
        queueItemId: 'q2',
        episode: Episode(
          id: 'e1',
          podcastId: 'pod1',
          title: 'Episode',
          durationSec: 3600,
        ),
        podcast: Podcast(id: 'pod1', title: 'Podcast'),
      ),
    );
    expect(
      source.uri.toString(),
      'https://music.example.com/sub/api/podcasts/pod1/episodes/e1/stream',
    );
    expect(source.knownDuration, const Duration(hours: 1));
  });

  test('startAt and knownDuration are carried', () async {
    final source = await resolver.resolve(
      _track('q1', playbackId: 'p1'),
      startAt: const Duration(seconds: 42),
    );
    expect(source.startAt, const Duration(seconds: 42));
    expect(source.knownDuration, const Duration(seconds: 215));
  });

  test('an unknown duration is left null', () async {
    final source = await resolver.resolve(
      _track('q1', playbackId: 'p1', durationSec: 0),
    );
    expect(source.knownDuration, isNull);
  });

  test('headers come from the credential ensureFresh returns', () async {
    credentials.next = const JwtCredentials(
      accessToken: 'refreshed',
      refreshToken: 'r2',
    );
    final source = await resolver.resolve(_track('q1', playbackId: 'p1'));
    expect(source.headers, {'Authorization': 'Bearer refreshed'});
  });

  test('ensureFresh is asked for two hours', () async {
    await resolver.resolve(_track('q1', playbackId: 'p1'));
    expect(credentials.asked, [const Duration(hours: 2)]);
  });

  test('a track without playbackId throws NotPlayable', () async {
    await expectLater(
      resolver.resolve(_track('q9')),
      throwsA(isA<NotPlayable>().having((e) => e.queueItemId, 'id', 'q9')),
    );
    expect(credentials.asked, isEmpty);
  });

  test('differently shaped playbackIds differ only in the encoded id '
      'segment', () async {
    final a = await resolver.resolve(_track('q1', playbackId: 'abc123'));
    final b = await resolver.resolve(_track('q2', playbackId: 'tidal:9 8/7?x'));
    expect(a.uri.replace(path: '/'), b.uri.replace(path: '/'));
    final aSegments = a.uri.pathSegments;
    final bSegments = b.uri.pathSegments;
    expect(aSegments.length, bSegments.length);
    expect(
      aSegments.take(aSegments.length - 1),
      bSegments.take(bSegments.length - 1),
    );
    expect(aSegments.last, 'abc123');
    expect(bSegments.last, 'tidal:9 8/7?x');
    expect(a.headers, b.headers);
  });
}
