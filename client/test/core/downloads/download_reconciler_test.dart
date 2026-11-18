// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_artwork.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_reconciler.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/platform/artwork_store/artwork_store_io.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import 'download_controller_rig.dart';

String _task(String playbackId) => itemKeyHash(TrackItemKey(playbackId));

void main() {
  late Directory dir;
  late DownloadControllerRig rig;
  late ProfileDownloadArtwork artwork;
  late String art;
  late List<RigTimer> timers;
  late DownloadReconciler reconciler;

  DownloadReconciler create() => DownloadReconciler(
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
    artwork: artwork,
    clock: rig.clock,
    deviceId: rigDeviceId,
    profileId: 'p1',
    paths: rig.paths,
    createTimer: (delay, callback) {
      final timer = RigTimer(delay, callback);
      timers.add(timer);
      return timer;
    },
  );

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('download_reconciler');
    rig = DownloadControllerRig(dir);
    timers = [];
    art = '${dir.path}/profiles/p1/art';
    await rig.start();
    artwork = ProfileDownloadArtwork(
      downloads: rig.store,
      events: rig.controller.events,
      reachability: rig.reachability,
      urls: api.ImageUrls(Uri.parse('https://music.example.com')),
      credentials: () => const api.ApiKeyCredentials(apiKey: 'key-1'),
      fetch: (_) async => Uint8List.fromList([1]),
      store: const IoArtworkStore(),
      artDirectory: art,
      clock: rig.clock,
    );
    reconciler = create();
  });
  tearDown(() async {
    await reconciler.dispose();
    await artwork.dispose();
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  /// Records that the server holds track [id] for this device.
  void serverHolds(String id) =>
      rig.server.offline.devices.putIfAbsent(rigDeviceId, () => {})[id] = (
        quality: 'original',
        sizeBytes: 10,
      );

  /// The `GET /offline/items` requests the server received.
  int listRequests() =>
      rig.server.offline.requests.whereType<Map<String, Object?>>().length;

  /// The `POST /offline/items/complete` bodies for track [id].
  List<api.CompleteOfflineItemRequest> completes(String id) => [
    for (final request in rig.server.offline.requests)
      if (request is api.CompleteOfflineItemRequest && request.playbackId == id)
        request,
  ];

  /// Pins album `al` with [ids] and completes [completed] on disk.
  Future<Map<String, String>> pinAndComplete(
    List<String> ids, {
    List<String>? completed,
  }) async {
    rig.server.offline.albums['al'] = ids;
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    return {
      for (final id in completed ?? ids) id: await rig.completeOnDisk(id),
    };
  }

  /// Leaves track [id] `verifying`, as a crash after the rename would.
  Future<void> verifying(String id) =>
      (rig.state.update(
        rig.state.downloadItems,
      )..where((i) => i.itemKey.equals(TrackItemKey(id).encode()))).write(
        const DownloadItemsCompanion(status: Value(DownloadStatus.verifying)),
      );

  File mediaFile(String name) =>
      File('${dir.path}/profiles/p1/media/${name.substring(0, 2)}/$name')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);

  group('server pass', () {
    test('rule 2: revoked server item deletes the local file and row and '
        'is sent in DELETE', () async {
      final files = await pinAndComplete(['t1']);
      serverHolds('t1');
      rig.server.offline.unavailable['t1'] = 'TRACK_UNAVAILABLE';

      final report = await reconciler.runServerPass();
      await rig.settle();

      expect(report.revoked, 1);
      expect(await rig.item('t1'), isNull);
      expect(await rig.memberships(), isEmpty);
      expect(File(files['t1']!).existsSync(), isFalse);
      expect(rig.deleteRequests.single.playbackIds, ['t1']);
      // The collection stays, empty, so the user sees why.
      expect((await rig.collections()).single.refId, 'al');
    });

    test('rule 2: a revoked server item with no local row is deleted on '
        'the server too', () async {
      serverHolds('gone');
      rig.server.offline.unavailable['gone'] = 'TRACK_UNAVAILABLE';

      await reconciler.runServerPass();
      await rig.settle();

      expect(rig.deleteRequests.single.playbackIds, ['gone']);
    });

    test('rule 3: completed item unknown to the server is confirmed '
        'again', () async {
      await pinAndComplete(['t1']);
      // Confirmed once, then the server lost its record (a restore).
      await rig.store.markServerConfirmed(
        const TrackItemKey('t1'),
        rig.clock.now(),
      );

      final report = await reconciler.runServerPass();
      await rig.settle();

      expect(report.resent, 1);
      expect(completes('t1'), hasLength(1));
      expect(completes('t1').single.sizeBytes, 10);
      expect((await rig.item('t1'))!.serverConfirmed, isTrue);
      expect(rig.server.offline.devices[rigDeviceId], contains('t1'));
    });

    test('rule 3: an unknown item goes to the outbox when the server '
        'cannot record it', () async {
      await pinAndComplete(['t1']);
      rig.server.offline.completeError = const api.ServerError(status: 503);
      rig.setReachability(Reachability.online);

      await reconciler.runServerPass();
      await rig.controller.settle();

      final pending = await rig.outboxStore.pending();
      expect([
        for (final entry in pending) entry.op.runtimeType.toString(),
      ], contains('OfflineCompleteOp'));
    });

    test('rule 3: known item is marked serverConfirmed', () async {
      await pinAndComplete(['t1']);
      serverHolds('t1');
      expect((await rig.item('t1'))!.serverConfirmed, isFalse);

      final report = await reconciler.runServerPass();

      expect(report.confirmed, 1);
      expect((await rig.item('t1'))!.serverConfirmed, isTrue);
      expect(completes('t1'), isEmpty);
      expect(rig.deleteRequests, isEmpty);
    });

    test('rule 4: server item unknown locally is deleted on the '
        'server', () async {
      await pinAndComplete(['t1']);
      serverHolds('t1');
      serverHolds('stranger');

      final report = await reconciler.runServerPass();
      await rig.settle();

      expect(report.deletedOnServer, 1);
      expect(rig.deleteRequests.single.playbackIds, ['stranger']);
      expect(rig.server.offline.devices[rigDeviceId]!.keys, ['t1']);
    });

    test('1,100 ids to delete produce three ops', () async {
      for (var i = 0; i < 1100; i++) {
        serverHolds('s$i');
      }
      rig.setReachability(Reachability.serverUnreachable);

      await reconciler.runServerPass();

      final ops = await rig.pendingDeletes();
      expect([for (final op in ops) op.playbackIds.length], [500, 500, 100]);
      expect(ops.every((op) => op.deviceId == rigDeviceId), isTrue);
    });

    test('an API failure leaves local state untouched and does not record '
        'lastReconciledAt', () async {
      final files = await pinAndComplete(['t1']);
      serverHolds('t1');
      serverHolds('stranger');
      rig.server.offline.unavailable['t1'] = 'TRACK_UNAVAILABLE';
      rig.server.offline.listError = const api.ServerError(status: 500);

      await expectLater(
        reconciler.runServerPass(),
        throwsA(isA<api.ServerError>()),
      );
      await reconciler.runIfDue(force: true);
      await rig.settle();

      final row = (await rig.item('t1'))!;
      expect(row.status, DownloadStatus.completed);
      expect(row.serverConfirmed, isFalse);
      expect(File(files['t1']!).existsSync(), isTrue);
      expect(await rig.pendingDeletes(), isEmpty);
      expect(rig.deleteRequests, isEmpty);
      expect(await reconciler.lastReconciledAt(), isNull);
    });

    test('episode items are ignored by the server pass', () async {
      const episode = EpisodeItemKey(podcastId: 'pod', episodeId: 'ep');
      await rig.store.upsertItem(
        episode,
        DownloadItemsCompanion(
          metaJson: const Value('{}'),
          requestedAt: Value(rig.clock.now()),
          status: const Value(DownloadStatus.completed),
          sizeBytes: const Value(10),
          relativePath: const Value('media/aa/ep.mp3'),
        ),
      );
      serverHolds('ep');

      final report = await reconciler.runServerPass();
      await rig.settle();

      expect(report.resent, 0);
      expect(report.confirmed, 0);
      expect(
        rig.server.offline.requests.whereType<api.CompleteOfflineItemRequest>(),
        isEmpty,
      );
      // The server's "ep" is a track id it holds; no local track has it.
      expect(rig.deleteRequests.single.playbackIds, ['ep']);
      final row = (await rig.store.item(episode))!;
      expect(row.status, DownloadStatus.completed);
      expect(row.serverConfirmed, isFalse);
    });
  });

  group('runIfDue', () {
    test('records lastReconciledAt and skips within 6 hours, then runs '
        'after', () async {
      await reconciler.runIfDue();
      expect(listRequests(), 1);
      expect(await reconciler.lastReconciledAt(), rig.clock.now());

      rig.clock.advance(const Duration(hours: 5, minutes: 59));
      await reconciler.runIfDue();
      expect(listRequests(), 1);

      rig.clock.advance(const Duration(minutes: 2));
      await reconciler.runIfDue();
      expect(listRequests(), 2);
    });

    test('force ignores the interval', () async {
      await reconciler.runIfDue();
      await reconciler.runIfDue(force: true);

      expect(listRequests(), 2);
    });

    test('does nothing while not online', () async {
      rig.setReachability(Reachability.noNetwork);

      await reconciler.runIfDue(force: true);

      expect(listRequests(), 0);
    });

    test('concurrent triggers run once', () async {
      await Future.wait([
        reconciler.runIfDue(force: true),
        reconciler.runIfDue(force: true),
        reconciler.runIfDue(),
      ]);

      expect(listRequests(), 1);
    });
  });

  group('start', () {
    test('offline start-up runs only the scan; the return to online runs '
        'the pass', () async {
      rig.setReachability(Reachability.noNetwork);
      final orphan = mediaFile('${_task('nobody')}.mp3');

      await reconciler.start();

      expect(orphan.existsSync(), isFalse);
      expect(listRequests(), 0);

      rig.setReachability(Reachability.online);
      await Future<void>.delayed(Duration.zero);
      await reconciler.settle();

      expect(listRequests(), 1);
    });

    test('online start-up runs the pass even within the interval, and the '
        'timer runs the next one 6 hours later', () async {
      await reconciler.runIfDue();
      rig.clock.advance(const Duration(hours: 1));

      await reconciler.start();

      expect(listRequests(), 2);
      expect(timers.last.delay, kReconcileInterval);

      rig.clock.advance(kReconcileInterval);
      timers.last.fire();
      await Future<void>.delayed(Duration.zero);
      await reconciler.settle();

      expect(listRequests(), 3);
    });

    test('a return to online within the interval does not run the '
        'pass', () async {
      await reconciler.start();
      rig
        ..setReachability(Reachability.serverUnreachable)
        ..setReachability(Reachability.online);
      await Future<void>.delayed(Duration.zero);
      await reconciler.settle();

      expect(listRequests(), 1);
    });
  });

  group('local scan', () {
    test('rule 5: completed row with a missing file becomes queued', () async {
      final files = await pinAndComplete(['t1']);
      final before = rig.requested.where((t) => t == _task('t1')).length;
      File(files['t1']!).deleteSync();

      final report = await reconciler.runLocalScan();
      await rig.settle();

      expect(report.missing, 1);
      final row = (await rig.item('t1'))!;
      expect(row.status, isNot(DownloadStatus.completed));
      expect(row.relativePath, isNull);
      expect(row.sizeBytes, isNull);
      // The scheduler was pumped and started it again.
      expect(rig.requested.where((t) => t == _task('t1')).length, before + 1);
    });

    test('rule 5: completed row with a wrong-size file becomes '
        'queued', () async {
      final files = await pinAndComplete(['t1']);
      File(files['t1']!).writeAsBytesSync([1, 2, 3]);
      rig.setReachability(Reachability.noNetwork);

      final report = await reconciler.runLocalScan();

      expect(report.missing, 1);
      expect((await rig.item('t1'))!.status, DownloadStatus.queued);
      // With no row pointing at it, the short file is an orphan.
      expect(File(files['t1']!).existsSync(), isFalse);
    });

    test('a completed row whose file is right is left alone', () async {
      final files = await pinAndComplete(['t1']);

      final report = await reconciler.runLocalScan();

      expect(report.missing, 0);
      expect(report.orphansDeleted, 0);
      expect((await rig.item('t1'))!.status, DownloadStatus.completed);
      expect(File(files['t1']!).existsSync(), isTrue);
    });

    test('rule 5: file with no row is deleted', () async {
      final orphan = mediaFile('${_task('nobody')}.flac');

      final report = await reconciler.runLocalScan();

      expect(report.orphansDeleted, 1);
      expect(orphan.existsSync(), isFalse);
      // The emptied fan-out directory goes too; media/ stays.
      expect(orphan.parent.existsSync(), isFalse);
      expect(Directory(rig.paths.profile.media).existsSync(), isTrue);
    });

    test('rule 5: .part file with no live task is deleted; one with a live '
        'task is kept', () async {
      await pinAndComplete(['t1', 't2'], completed: const []);
      expect((await rig.item('t1'))!.status, DownloadStatus.running);
      expect((await rig.item('t2'))!.status, DownloadStatus.running);
      final dead = File(rig.paths.partFile(_task('t1')))
        ..createSync(recursive: true);
      final live = File(rig.paths.partFile(_task('t2')))
        ..createSync(recursive: true);
      rig.downloader.dropTask(_task('t1'));

      await reconciler.runLocalScan();

      expect(dead.existsSync(), isFalse);
      expect(live.existsSync(), isTrue);
    });

    test('rule 5: renamed file with a verifying row is adopted when the '
        'size matches', () async {
      rig.server.offline.trackBytes['t1'] = 10;
      await pinAndComplete(['t1'], completed: const []);
      await verifying('t1');
      rig.downloader.dropTask(_task('t1'));
      final relative = rig.paths.relativeFinalFile(_task('t1'), 'audio/mpeg');
      final file = File(rig.paths.resolve(relative))
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(10, 1));

      final report = await reconciler.runLocalScan();
      await rig.settle();

      expect(report.adopted, 1);
      final row = (await rig.item('t1'))!;
      expect(row.status, DownloadStatus.completed);
      expect(row.relativePath, relative);
      expect(row.sizeBytes, 10);
      expect(file.existsSync(), isTrue);
      // The adopted download is reported like any other.
      expect(completes('t1'), hasLength(1));
    });

    test('a renamed file of the wrong size is deleted and its verifying row '
        'fails', () async {
      rig.server.offline.trackBytes['t1'] = 10;
      await pinAndComplete(['t1'], completed: const []);
      await verifying('t1');
      final file = File(rig.paths.finalFile(_task('t1'), 'audio/mpeg'))
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);

      final report = await reconciler.runLocalScan();

      expect(report.adopted, 0);
      expect(file.existsSync(), isFalse);
      expect((await rig.item('t1'))!.status, DownloadStatus.failedRetryable);
    });

    test('rule 5: unreferenced art file is deleted; now-playing.img is '
        'kept', () async {
      final unreferenced = File('$art/${downloadArtworkFileName('img-x')}')
        ..createSync(recursive: true);
      final nowPlaying = File('$art/now-playing.img')..createSync();

      final report = await reconciler.runLocalScan();

      expect(report.artworkRemoved, 1);
      expect(unreferenced.existsSync(), isFalse);
      expect(nowPlaying.existsSync(), isTrue);
    });
  });
}
