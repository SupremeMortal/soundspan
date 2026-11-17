// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/episode_download_meta.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/platform/stream_auth/stream_auth_io.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/fakes/fake_media_files.dart';
import 'controller/controller_harness.dart';

final DateTime _start = DateTime.utc(2026, 5, 1, 12);

void main() {
  late Directory dir;
  late StateDatabase db;
  late DownloadPaths paths;
  late DownloadStore store;
  late FakeReachability reachability;
  late ControllerHarness h;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('episode_offline_playback');
    db = StateDatabase(NativeDatabase.memory());
    paths = DownloadPaths(
      ProfilePaths.derive(
        appSupport: p.join(dir.path, 'support'),
        appCache: p.join(dir.path, 'cache'),
        profileId: 'p1',
      ),
    );
    store = DownloadStore(db, paths: paths);
    reachability = FakeReachability();
    final clock = FakeClock(start: _start);
    h = ControllerHarness(
      clock: clock,
      playAny: true,
      sourceResolver: SourceResolver(
        ensureFresh: ({required minRemaining}) async =>
            const api.JwtCredentials(accessToken: 'a', refreshToken: 'r'),
        urls: api.StreamUrls(Uri.parse('https://music.example.com')),
        quality: StreamQualityPolicy(DeviceSettingsDao(db), reachability),
        auth: const HeaderStreamAuth(),
        downloads: store,
        files: FakeMediaFiles(),
        reachability: reachability,
        clock: clock,
      ),
    );
  });
  tearDown(() async {
    await h.controller.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  /// Downloads episode [episodeId] of `pod1`, last played on this device
  /// up to [positionSec], and answers the file's path.
  Future<String> download(String episodeId, {double? positionSec}) async {
    final key = EpisodeItemKey(podcastId: 'pod1', episodeId: episodeId);
    final relative = paths.relativeFinalFile(itemKeyHash(key), 'audio/mpeg');
    await store.upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: Value(
          EpisodeDownloadMeta(
            episodeId: episodeId,
            podcastId: 'pod1',
            title: 'Episode $episodeId',
            podcastTitle: 'Night Shift',
            durationSec: 1800,
            positionSec: positionSec,
          ).toJson(),
        ),
        status: const Value(DownloadStatus.completed),
        sizeBytes: const Value(4),
        relativePath: Value(relative),
        requestedAt: Value(_start),
        completedAt: Value(_start),
      ),
    );
    final absolute = paths.resolve(relative);
    File(absolute)
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3, 4]);
    return absolute;
  }

  /// The queue item of the episode as the offline podcast page builds it,
  /// from the download's metadata.
  Future<QueueItem> offlineItem(String episodeId) async {
    final row = await store.item(
      EpisodeItemKey(podcastId: 'pod1', episodeId: episodeId),
    );
    final meta = EpisodeDownloadMeta.fromJson(row!.metaJson)!;
    return QueueItem.episode(
      queueItemId: 'q-$episodeId',
      podcast: meta.toPodcast(),
      episode: meta.toEpisode(),
    );
  }

  test('offline, a downloaded episode plays its file from the stored '
      'position', () async {
    final file = await download('e1', positionSec: 754);
    reachability.set(Reachability.forcedOffline);

    await h.controller.playItems([await offlineItem('e1')]);
    await h.settle();

    final source = h.fake.requested.single;
    expect(source.uri, Uri.file(file));
    expect(source.startAt, const Duration(seconds: 754));
    expect(h.controller.snapshot.playing, isTrue);
  });

  test('offline, an episode that is not downloaded is skipped', () async {
    await download('e2');
    reachability.set(Reachability.forcedOffline);

    await h.controller.playItems([
      const QueueItem.episode(
        queueItemId: 'q-e1',
        podcast: Podcast(id: 'pod1', title: 'Night Shift'),
        episode: Episode(id: 'e1', podcastId: 'pod1', title: 'Episode e1'),
      ),
      await offlineItem('e2'),
    ]);
    await h.settle();

    expect([for (final s in h.fake.requested) s.queueItemId], ['q-e2']);
    expect(h.controller.snapshot.current?.queueItemId, 'q-e2');
  });
}
