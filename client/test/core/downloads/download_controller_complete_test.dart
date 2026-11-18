// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import 'download_controller_rig.dart';

String _task(String playbackId) => itemKeyHash(TrackItemKey(playbackId));

void main() {
  late Directory dir;
  late DownloadControllerRig rig;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('download_controller_complete');
    rig = DownloadControllerRig(dir);
    await rig.start();
  });
  tearDown(() async {
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  CollectionSnapshot snapshotOf(List<String> ids) => CollectionSnapshot(
    title: 'First',
    tracks: [for (final id in ids) rigTrack(id)],
  );

  Future<void> pinAlbum(String id, List<String> tracks) async {
    rig.server.offline.albums[id] = tracks;
    await rig.controller.pin(
      CollectionKind.album,
      id,
      snapshot: snapshotOf(tracks),
    );
    await rig.settle();
  }

  Future<void> finish(
    String playbackId, {
    int bytes = 1000,
    String? contentType = 'audio/flac',
    int? contentLength,
  }) async {
    await rig.downloader.complete(
      _task(playbackId),
      bytes: bytes,
      contentType: contentType,
      contentLength: contentLength,
    );
    await rig.settle();
  }

  String partOf(String playbackId) =>
      rig.paths.partFile(itemKeyHash(TrackItemKey(playbackId)));

  List<api.CompleteOfflineItemRequest> completeRequests() => rig
      .server
      .offline
      .requests
      .whereType<api.CompleteOfflineItemRequest>()
      .toList();

  Future<List<OfflineCompleteOp>> pendingCompletes() async => [
    for (final entry in await rig.outboxStore.pending())
      if (entry.op case final OfflineCompleteOp op) op,
  ];

  Future<CollectionDownloadState> albumState(String id) async =>
      (await rig.controller.watchCollection(CollectionKind.album, id).first)!;

  test('mixed album, end to end: the downloadable items are verified, '
      'renamed for their content type and confirmed with the server', () async {
    rig.server.offline
      ..unavailable['t2'] = 'TRACK_UNAVAILABLE'
      ..unavailable['t4'] = 'SOURCE_UNAVAILABLE';
    await pinAlbum('al', ['t1', 't2', 't3', 't4', 't5']);
    expect(rig.requested, [_task('t1'), _task('t3')]);

    await finish('t1');
    await finish('t3', contentType: 'audio/mpeg');
    expect(rig.requested.last, _task('t5'));
    await finish('t5', contentType: 'audio/mp4; codecs=alac');

    for (final (id, ext) in [('t1', 'flac'), ('t3', 'mp3'), ('t5', 'm4a')]) {
      final row = (await rig.item(id))!;
      expect(row.status, DownloadStatus.completed, reason: id);
      expect(row.sizeBytes, 1000);
      expect(row.completedAt, rig.clock.now());
      expect(row.serverConfirmed, isTrue, reason: id);
      expect(row.relativePath, endsWith('.$ext'));
      expect(File(rig.paths.resolve(row.relativePath!)).lengthSync(), 1000);
      expect(File(partOf(id)).existsSync(), isFalse);
    }
    expect(
      [
        for (final r in completeRequests())
          '${r.deviceId}/${r.playbackId}/${r.quality.toJson()}/${r.sizeBytes}',
      ],
      [
        '$rigDeviceId/t1/original/1000',
        '$rigDeviceId/t3/original/1000',
        '$rigDeviceId/t5/original/1000',
      ],
    );
    expect(await pendingCompletes(), isEmpty);
    for (final id in ['t2', 't4']) {
      final row = (await rig.item(id))!;
      expect(row.status, DownloadStatus.unavailable);
      expect(row.relativePath, isNull);
    }
    final state = await albumState('al');
    expect(state.completedCount, 3);
    expect(state.quotaShortfall, isNull);
  });

  test('a final file already at the target path is replaced', () async {
    await pinAlbum('al', ['t1']);
    final target =
        File(
            rig.paths.finalFile(
              itemKeyHash(const TrackItemKey('t1')),
              'audio/flac',
            ),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync('stale');

    await finish('t1');

    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect(target.lengthSync(), 1000);
  });

  group('disk full', () {
    test(
      'free space for 2 of 4: 2 run, 2 wait for space with a shortfall; '
      'unpinning another collection lets recheckSpace release them',
      () async {
        await rig.settings.write(downloadsQuotaKey, 20 * 1024 * 1024 * 1024);
        rig.server.offline.albums['solo'] = ['x'];
        await rig.controller.pin(CollectionKind.album, 'solo');
        await rig.settle();
        await finish('x');
        expect((await rig.item('x'))!.status, DownloadStatus.completed);

        rig.diskSpace.free = kDiskReserveBytes + 2500;
        await pinAlbum('al', ['t1', 't2', 't3', 't4']);

        expect(rig.requested.sublist(1), [_task('t1'), _task('t2')]);
        for (final id in ['t3', 't4']) {
          final row = (await rig.item(id))!;
          expect(row.status, DownloadStatus.queued);
          expect(row.waitingFor, DownloadWaitReason.space.name);
        }
        expect(
          (await albumState('al')).quotaShortfall,
          const QuotaShortfall(neededBytes: 2000, availableBytes: 500),
        );

        rig.diskSpace.free = kDiskReserveBytes + 4500;
        await rig.controller.unpin(CollectionKind.album, 'solo');
        await rig.settle();

        for (final id in ['t3', 't4']) {
          expect((await rig.item(id))!.waitingFor, isNull, reason: id);
        }
        expect((await albumState('al')).quotaShortfall, isNull);
        await finish('t1');
        expect(rig.requested.last, _task('t3'));
        expect((await rig.item('t3'))!.status, DownloadStatus.running);
      },
    );

    test('a noSpace failure mid-transfer pauses the item without counting an '
        'attempt, and its collection reports the shortfall', () async {
      await pinAlbum('al', ['t1']);
      rig.diskSpace.free = kDiskReserveBytes;

      rig.downloader.fail(_task('t1'), kind: DownloaderFailureKind.noSpace);
      await rig.settle();

      final row = (await rig.item('t1'))!;
      expect(row.status, DownloadStatus.paused);
      expect(row.waitingFor, DownloadWaitReason.space.name);
      expect(row.attempts, 0);
      expect(
        (await albumState('al')).quotaShortfall,
        const QuotaShortfall(neededBytes: 1000, availableBytes: 0),
      );
    });
  });

  test('a cache-limit error creates no quota state', () async {
    rig.server.offline
      ..cacheLimitBytes = 10
      ..albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();

    final state = await albumState('al');
    expect(state.status, DownloadCollectionStatus.blocked);
    expect(state.blockedReason, CollectionBlock.serverQuota);
    expect(state.quotaShortfall, isNull);
    expect(await rig.items(), isEmpty);
  });

  test('a truncated file fails retryably, its .part is deleted and it is '
      'retried after the backoff', () async {
    await pinAlbum('al', ['t1']);

    await rig.downloader.completeTruncated(
      _task('t1'),
      bytes: 500,
      contentLength: 1000,
    );
    await rig.settle();

    final row = (await rig.item('t1'))!;
    expect(row.status, DownloadStatus.failedRetryable);
    expect(row.failureCode, DownloadFailureCodes.verificationFailed);
    expect(row.attempts, 1);
    expect(File(partOf('t1')).existsSync(), isFalse);
    expect(completeRequests(), isEmpty);

    rig.fireRetries();
    await rig.settle();
    expect((await rig.item('t1'))!.status, DownloadStatus.running);
    expect(rig.requested, [_task('t1'), _task('t1')]);
  });

  test('a zero-byte file fails even when the size is unknown', () async {
    rig.server.offline.trackBytes['t1'] = null;
    await pinAlbum('al', ['t1']);

    await finish('t1', bytes: 0);

    expect((await rig.item('t1'))!.status, DownloadStatus.failedRetryable);
  });

  test('with no announced size the response Content-Length decides', () async {
    rig.server.offline
      ..trackBytes['t1'] = null
      ..trackBytes['t2'] = null;
    await pinAlbum('al', ['t1', 't2']);

    await finish('t1', contentLength: 1000);
    await finish('t2', bytes: 900, contentLength: 1000);

    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect((await rig.item('t1'))!.sizeBytes, 1000);
    expect((await rig.item('t2'))!.status, DownloadStatus.failedRetryable);
  });

  test(
    'with no size and no Content-Length any non-empty file is accepted',
    () async {
      rig.server.offline.trackBytes['t1'] = null;
      await pinAlbum('al', ['t1']);

      await finish('t1', bytes: 321);

      expect((await rig.item('t1'))!.status, DownloadStatus.completed);
      expect((await rig.item('t1'))!.sizeBytes, 321);
    },
  );

  test('offline at completion: an offlineComplete op is queued and the item '
      'is confirmed when the worker sends it', () async {
    await pinAlbum('al', ['t1']);
    rig.setReachability(Reachability.serverUnreachable);

    await finish('t1');

    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect((await rig.item('t1'))!.serverConfirmed, isFalse);
    expect(await pendingCompletes(), [
      const OfflineCompleteOp(
        deviceId: rigDeviceId,
        playbackId: 't1',
        quality: 'original',
        sizeBytes: 1000,
      ),
    ]);

    rig.setReachability(Reachability.online);
    await rig.settle();

    expect(await pendingCompletes(), isEmpty);
    expect(completeRequests(), hasLength(1));
    expect((await rig.item('t1'))!.serverConfirmed, isTrue);
  });

  test('a direct confirmation that fails for the network goes through the '
      'outbox', () async {
    await pinAlbum('al', ['t1']);
    rig.server.offline.completeError = const api.ServerError(status: 503);

    await finish('t1');

    expect((await rig.item('t1'))!.serverConfirmed, isFalse);
    expect(await pendingCompletes(), hasLength(1));
  });

  test(
    'complete answering 404 leaves the item completed and unconfirmed',
    () async {
      await pinAlbum('al', ['t1']);
      rig.server.offline.completeError = const api.NotFound(status: 404);

      await finish('t1');

      final row = (await rig.item('t1'))!;
      expect(row.status, DownloadStatus.completed);
      expect(row.serverConfirmed, isFalse);
      expect(await pendingCompletes(), isEmpty);
    },
  );

  test(
    'an offlineComplete op answered 404 is dropped without a notice',
    () async {
      final notices = <OutboxNotice>[];
      rig.worker.notices.listen(notices.add);
      await pinAlbum('al', ['t1']);
      rig.setReachability(Reachability.serverUnreachable);
      await finish('t1');
      rig.server.offline.completeError = const api.NotFound(status: 404);

      rig.setReachability(Reachability.online);
      await rig.settle();

      expect(await pendingCompletes(), isEmpty);
      expect((await rig.item('t1'))!.serverConfirmed, isFalse);
      expect(notices, isEmpty);
    },
  );

  test('the quality.download setting is sent when the server named no '
      'quality', () async {
    await pinAlbum('al', ['t1']);
    await (rig.state.update(rig.state.downloadItems)
          ..where((i) => i.itemKey.equals('t:t1')))
        .write(const DownloadItemsCompanion(quality: Value(null)));
    await rig.settings.write(downloadQualityKey, 'high');

    await finish('t1');

    expect(completeRequests().single.quality.toJson(), 'high');
  });

  test('raiseDeviceLimit releases waiting items in schedule order', () async {
    await rig.settings.write(downloadsQuotaKey, 2500);
    await pinAlbum('al', ['t1', 't2', 't3', 't4']);
    expect(rig.requested, [_task('t1'), _task('t2')]);
    expect((await rig.item('t3'))!.waitingFor, DownloadWaitReason.space.name);
    expect((await rig.item('t4'))!.waitingFor, DownloadWaitReason.space.name);
    expect(
      (await albumState('al')).quotaShortfall,
      const QuotaShortfall(neededBytes: 2000, availableBytes: 500),
    );

    await rig.controller.raiseDeviceLimit(3500);
    await rig.settle();

    expect(await rig.settings.read(downloadsQuotaKey), 3500);
    expect((await rig.item('t3'))!.waitingFor, isNull);
    expect((await rig.item('t4'))!.waitingFor, DownloadWaitReason.space.name);

    await finish('t1');
    expect(rig.requested.last, _task('t3'));
  });

  test(
    'the default device limit is written the first time it is needed',
    () async {
      rig.diskSpace.free = 40 * 1024 * 1024 * 1024;

      await pinAlbum('al', ['t1']);

      expect(
        await rig.settings.read(downloadsQuotaKey),
        10 * 1024 * 1024 * 1024,
      );
    },
  );

  test(
    'a change of the device-limit setting releases items that now fit',
    () async {
      await rig.settings.write(downloadsQuotaKey, 1000);
      await pinAlbum('al', ['t1', 't2']);
      expect((await rig.item('t2'))!.waitingFor, DownloadWaitReason.space.name);
      await rig.settings.write(downloadsQuotaKey, 10000);
      await rig.settle();

      expect((await rig.item('t2'))!.waitingFor, isNull);
    },
  );

  group('start-up with an item left verifying', () {
    late DownloadControllerRig restarted;

    setUp(() {
      // A rig that has not started yet, as the app finds it after being
      // killed between the transfer's completion and its verification.
      restarted = DownloadControllerRig(
        Directory('${dir.path}/restarted')..createSync(),
      );
    });
    tearDown(() => restarted.dispose());

    Future<void> leaveVerifying(String playbackId) =>
        restarted.store.upsertItem(
          TrackItemKey(playbackId),
          DownloadItemsCompanion(
            metaJson: const Value('{}'),
            status: const Value(DownloadStatus.verifying),
            downloadUrl: Value('/api/offline/download/$playbackId'),
            expectedBytes: const Value(1000),
            requestedAt: Value(restarted.clock.now()),
            taskId: Value(_task(playbackId)),
          ),
        );

    // The order of startDownloads: the controller listens before the
    // scheduler starts.
    Future<void> startLikeTheApp() async {
      restarted.controller.start();
      await restarted.scheduler.start();
      await restarted.worker.start();
      await restarted.settle();
    }

    test('a .part of the expected size is completed and confirmed', () async {
      await leaveVerifying('t1');
      final part = restarted.paths.partFile(
        itemKeyHash(const TrackItemKey('t1')),
      );
      File(part)
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(1000, 1));

      await startLikeTheApp();

      final row = (await restarted.item('t1'))!;
      expect(row.status, DownloadStatus.completed);
      expect(row.sizeBytes, 1000);
      expect(row.relativePath, endsWith('.bin'));
      expect(
        File(restarted.paths.resolve(row.relativePath!)).existsSync(),
        isTrue,
      );
      expect(File(part).existsSync(), isFalse);
      expect(row.serverConfirmed, isTrue);
      expect(
        restarted.server.offline.requests
            .whereType<api.CompleteOfflineItemRequest>()
            .map((request) => request.sizeBytes),
        [1000],
      );
    });

    test('with no .part it fails retryably', () async {
      await leaveVerifying('t1');

      await startLikeTheApp();

      final row = (await restarted.item('t1'))!;
      expect(row.status, DownloadStatus.failedRetryable);
      expect(row.failureCode, DownloadFailureCodes.verificationFailed);
    });

    // The app died just after renaming the .part file to its final name,
    // before the row was marked completed.
    String writeFinal(String playbackId, int bytes) {
      final path = restarted.paths.finalFile(
        itemKeyHash(TrackItemKey(playbackId)),
        'audio/flac',
      );
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(bytes, 1));
      return path;
    }

    test('a verifying row with no .part file but a final file of the expected '
        'size is completed at start-up', () async {
      await leaveVerifying('t1');
      final path = writeFinal('t1', 1000);

      await startLikeTheApp();

      final row = (await restarted.item('t1'))!;
      expect(row.status, DownloadStatus.completed);
      expect(row.sizeBytes, 1000);
      expect(row.relativePath, endsWith('.flac'));
      expect(
        p.normalize(restarted.paths.resolve(row.relativePath!)),
        p.normalize(path),
      );
      expect(File(path).existsSync(), isTrue);
      expect(row.serverConfirmed, isTrue);
    });

    test('a verifying row with no .part file but a final file of the wrong '
        'size fails and the file is deleted', () async {
      await leaveVerifying('t1');
      final path = writeFinal('t1', 999);

      await startLikeTheApp();

      final row = (await restarted.item('t1'))!;
      expect(row.status, DownloadStatus.failedRetryable);
      expect(row.failureCode, DownloadFailureCodes.verificationFailed);
      expect(row.relativePath, isNull);
      expect(File(path).existsSync(), isFalse);
    });
  });
}
