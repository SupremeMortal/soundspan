// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_artwork.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_reconciler.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/episode_download_meta.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/platform/artwork_store/artwork_store_io.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_api.dart';
import 'download_controller_rig.dart';

const _podcast = Podcast(
  id: 'pod1',
  title: 'Night Shift',
  artworkRef: 'pod-art',
);

final _episode = Episode(
  id: 'ep1',
  podcastId: 'pod1',
  title: 'Episode One',
  description: 'The first one.',
  durationSec: 1800,
  publishedAt: DateTime.utc(2026, 2, 3),
);

const _key = EpisodeItemKey(podcastId: 'pod1', episodeId: 'ep1');

String get _task => itemKeyHash(_key);

void main() {
  late Directory dir;
  late DownloadControllerRig rig;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('episode_download');
    rig = DownloadControllerRig(dir);
    await rig.start();
  });
  tearDown(() async {
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  Future<void> pin() async {
    await rig.controller.pinEpisode(_podcast, _episode);
    await rig.settle();
  }

  Future<void> finish({required int bytes, int? contentLength}) async {
    await rig.downloader.complete(
      _task,
      bytes: bytes,
      contentType: 'audio/mpeg',
      contentLength: contentLength,
    );
    await rig.settle();
  }

  Future<DownloadItem?> row() => rig.store.item(_key);

  test('pinEpisode records collection, item and membership with no API '
      'call, and downloads the episode stream URL', () async {
    await pin();

    expect(rig.server.offline.requests, isEmpty);
    final collections = await rig.collections();
    expect(collections, hasLength(1));
    final collection = collections.single;
    expect(collection.kind, DownloadCollectionKind.episode.name);
    expect(collection.refId, 'pod1:ep1');
    expect(collection.title, 'Episode One');
    expect(jsonDecode(collection.metaJson), {
      'subtitle': 'Night Shift',
      'artworkRef': 'pod-art',
    });

    final item = (await row())!;
    expect(item.mediaType, MediaType.episode);
    expect(item.downloadUrl, isNull);
    expect(item.quality, isNull);
    final meta = EpisodeDownloadMeta.fromJson(item.metaJson)!;
    expect(meta.episodeId, 'ep1');
    expect(meta.podcastId, 'pod1');
    expect(meta.title, 'Episode One');
    expect(meta.podcastTitle, 'Night Shift');
    expect(meta.durationSec, 1800);
    expect(meta.publishedAt, DateTime.utc(2026, 2, 3));
    expect(meta.artworkRef, 'pod-art');
    expect(meta.description, 'The first one.');

    final memberships = await rig.memberships();
    expect(memberships.single.itemKey, _key.encode());

    final request = rig.downloader.requests.single;
    expect(request.taskId, _task);
    expect(
      request.url,
      Uri.parse(
        'https://music.example.com/api/podcasts/pod1/episodes/ep1/stream',
      ),
    );
    expect(request.headers, {'X-API-Key': 'key-1'});
    expect(request.highPriority, isTrue);
  });

  test('pinning the same episode again keeps one row of each', () async {
    await pin();
    await pin();
    expect(await rig.collections(), hasLength(1));
    expect(await rig.items(), hasLength(1));
    expect(await rig.memberships(), hasLength(1));
  });

  test('a matching Content-Length completes the episode with no complete '
      'call and no offlineComplete op', () async {
    await pin();
    await finish(bytes: 1200, contentLength: 1200);

    final item = (await row())!;
    expect(item.status, DownloadStatus.completed);
    expect(item.sizeBytes, 1200);
    expect(item.serverConfirmed, isFalse);
    expect(
      rig.server.offline.requests.whereType<api.CompleteOfflineItemRequest>(),
      isEmpty,
    );
    final pending = await rig.outboxStore.pending();
    expect(pending.where((e) => e.op is OfflineCompleteOp), isEmpty);
  });

  test('a response without Content-Length is accepted', () async {
    await pin();
    await finish(bytes: 900);
    expect((await row())!.status, DownloadStatus.completed);
  });

  test('a zero-byte response fails verification', () async {
    await pin();
    await finish(bytes: 0);
    expect((await row())!.status, isNot(DownloadStatus.completed));
  });

  test('unpinEpisode deletes the file and the row and enqueues no '
      'offlineDelete', () async {
    await pin();
    await finish(bytes: 1200, contentLength: 1200);
    final path = rig.paths.resolve((await row())!.relativePath!);
    expect(File(path).existsSync(), isTrue);

    await rig.controller.unpinEpisode('pod1', 'ep1');
    await rig.settle();

    expect(File(path).existsSync(), isFalse);
    expect(await row(), isNull);
    expect(await rig.collections(), isEmpty);
    expect(await rig.pendingDeletes(), isEmpty);
    expect(rig.deleteRequests, isEmpty);
  });

  test('a 404 fails the episode permanently and resolves nothing', () async {
    await pin();
    rig.downloader.fail(
      _task,
      kind: DownloaderFailureKind.http,
      httpStatus: 404,
    );
    await rig.settle();

    expect((await row())!.status, DownloadStatus.failedPermanent);
    expect(rig.resolveRequests, isEmpty);
    expect(await rig.collections(), hasLength(1));
  });

  test('OfflineRepository.resolve refuses episodes', () {
    final offline = OfflineRepository(FakeOfflineClient());
    expect(
      () => offline.resolve(
        CollectionKind.episode,
        'pod1:ep1',
        deviceId: rigDeviceId,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('retrying an episode collection never resolves it with the '
      'server', () async {
    await pin();
    rig.downloader.fail(
      _task,
      kind: DownloaderFailureKind.http,
      httpStatus: 410,
    );
    await rig.settle();
    await rig.controller.retryCollection(CollectionKind.episode, 'pod1:ep1');
    await rig.controller.retryPendingCollections();
    await rig.settle();

    expect(rig.resolveRequests, isEmpty);
    expect(rig.downloader.requests, hasLength(2));
  });

  test('refreshing an episode collection resolves nothing', () async {
    await pin();
    final result = await rig.controller.refreshCollection(
      CollectionKind.episode,
      'pod1:ep1',
    );
    expect(result, UpkeepResult.unchanged);
    expect(rig.resolveRequests, isEmpty);
  });

  test(
    'pinned while offline, the episode waits and starts when online',
    () async {
      rig.setReachability(Reachability.forcedOffline);
      await pin();

      expect((await row())!.status, DownloadStatus.queued);
      expect(rig.downloader.requests, isEmpty);

      rig.setReachability(Reachability.online);
      await rig.settle();

      expect(rig.requested, [_task]);
      expect(rig.server.offline.requests, isEmpty);
    },
  );

  test('an episode is scheduled ahead of a queued album', () async {
    rig.server.offline.albums['al1'] = ['t1', 't2', 't3', 't4'];
    await rig.controller.pin(
      CollectionKind.album,
      'al1',
      snapshot: CollectionSnapshot(
        title: 'First',
        tracks: [
          for (final id in ['t1', 't2', 't3', 't4']) rigTrack(id),
        ],
      ),
    );
    await rig.settle();
    await pin();

    // Two transfers run at a time; the episode takes the first free slot.
    await rig.downloader.complete(
      itemKeyHash(const TrackItemKey('t1')),
      bytes: 1000,
      contentType: 'audio/flac',
    );
    await rig.settle();

    expect(rig.requested.take(3), [
      itemKeyHash(const TrackItemKey('t1')),
      itemKeyHash(const TrackItemKey('t2')),
      _task,
    ]);
  });

  test('the episode position is kept in its metadata', () async {
    await pin();
    await rig.controller.recordEpisodePosition('pod1', 'ep1', 754);
    final meta = EpisodeDownloadMeta.fromJson((await row())!.metaJson)!;
    expect(meta.positionSec, 754);
    expect(meta.toEpisode().progress?.currentTimeSec, 754);
  });

  group('reconciliation', () {
    late DownloadReconciler reconciler;

    setUp(() {
      reconciler = DownloadReconciler(
        store: rig.store,
        offline: rig.offline,
        scheduler: rig.scheduler,
        controller: rig.controller,
        deleteQueue: OutboxOfflineDeleteQueue(
          Outbox(rig.outboxStore, rig.worker).enqueue,
        ),
        downloader: rig.downloader,
        reachability: rig.reachability,
        settings: rig.settings,
        mediaFiles: rig.mediaFiles,
        artwork: ProfileDownloadArtwork(
          downloads: rig.store,
          events: rig.controller.events,
          reachability: rig.reachability,
          urls: api.ImageUrls(Uri.parse('https://music.example.com')),
          credentials: () => const api.ApiKeyCredentials(apiKey: 'key-1'),
          fetch: (_) async => throw UnimplementedError(),
          store: const IoArtworkStore(),
          artDirectory: '${dir.path}/art',
          clock: rig.clock,
        ),
        clock: rig.clock,
        deviceId: rigDeviceId,
        profileId: 'p1',
        paths: rig.paths,
        createTimer: RigTimer.new,
      );
    });
    tearDown(() => reconciler.dispose());

    test('the server pass neither confirms nor deletes an episode', () async {
      await pin();
      await finish(bytes: 1200, contentLength: 1200);

      final report = await reconciler.runServerPass();
      await rig.settle();

      expect(report.resent, 0);
      expect(report.deletedOnServer, 0);
      final item = (await row())!;
      expect(item.status, DownloadStatus.completed);
      expect(item.serverConfirmed, isFalse);
      expect(
        rig.server.offline.requests.whereType<api.CompleteOfflineItemRequest>(),
        isEmpty,
      );
      expect(await rig.pendingDeletes(), isEmpty);
    });

    test('the local scan marks a missing episode file missing', () async {
      await pin();
      await finish(bytes: 1200, contentLength: 1200);
      File(rig.paths.resolve((await row())!.relativePath!)).deleteSync();

      final report = await reconciler.runLocalScan();
      await rig.settle();

      expect(report.missing, 1);
      expect((await row())!.status, isNot(DownloadStatus.completed));
    });
  });
}
