// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart'
    show kDiskReserveBytes;
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/platform/downloader/downloader.dart';

import 'download_controller_rig.dart';

String _task(String playbackId) => itemKeyHash(TrackItemKey(playbackId));

void main() {
  late Directory dir;
  late DownloadControllerRig rig;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('download_controller_ui');
    rig = DownloadControllerRig(dir);
    await rig.start();
  });
  tearDown(() async {
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  test('watchItems answers the state of every item by its key', () async {
    rig.server.offline.albums['al'] = ['t1', 't2'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    await rig.completeOnDisk('t1');

    final states = await rig.controller.watchItems().first;

    expect(
      states.keys,
      unorderedEquals(const [TrackItemKey('t1'), TrackItemKey('t2')]),
    );
    expect(states[const TrackItemKey('t1')]!.status, DownloadStatus.completed);
    expect(states[const TrackItemKey('t2')]!.status, DownloadStatus.running);
  });

  test('watchCollectionEntries lists collections in request order with '
      'the snapshot texts, the album of a single track and active and '
      'failed counts', () async {
    rig.server.offline.albums['al'] = ['t1', 't2'];
    await rig.controller.pin(
      CollectionKind.album,
      'al',
      snapshot: CollectionSnapshot(
        title: 'First Light',
        subtitle: 'Contract Aurora',
        artworkRef: 'art-al',
        tracks: [rigTrack('t1'), rigTrack('t2')],
      ),
    );
    rig.clock.advance(const Duration(seconds: 1));
    await rig.controller.pin(
      CollectionKind.track,
      't9',
      snapshot: CollectionSnapshot(
        title: 'Song t9',
        tracks: [rigTrack('t9', albumId: 'al-9')],
      ),
    );
    await rig.settle();
    rig.downloader.fail(
      _task('t1'),
      kind: DownloaderFailureKind.http,
      httpStatus: 400,
    );
    await rig.settle();

    final entries = await rig.controller.watchCollectionEntries().first;

    expect([for (final e in entries) e.refId], ['al', 't9']);
    final album = entries.first;
    expect(album.kind, CollectionKind.album);
    expect(album.title, 'First Light');
    expect(album.subtitle, 'Contract Aurora');
    expect(album.artworkRef, 'art-al');
    expect(album.state.itemCount, 2);
    expect(album.state.failedCount, 1);
    expect(album.state.activeCount, 1);
    expect(entries.last.albumId, 'al-9');
  });

  test('retry queues a failed item again with no attempts', () async {
    rig.server.offline.albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    rig.downloader.fail(
      _task('t1'),
      kind: DownloaderFailureKind.http,
      httpStatus: 400,
    );
    await rig.settle();
    expect((await rig.item('t1'))!.status, DownloadStatus.failedPermanent);

    await rig.controller.retry(const TrackItemKey('t1'));
    await rig.settle();

    final row = (await rig.item('t1'))!;
    expect(row.status, DownloadStatus.running);
    expect(row.attempts, 0);
  });

  test('retryCollection retries each failed item of the collection', () async {
    rig.server.offline.albums['al'] = ['t1', 't2'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    for (final id in ['t1', 't2']) {
      rig.downloader.fail(
        _task(id),
        kind: DownloaderFailureKind.http,
        httpStatus: 400,
      );
    }
    await rig.settle();

    await rig.controller.retryCollection(CollectionKind.album, 'al');
    await rig.settle();

    expect([
      for (final row in await rig.items()) row.status,
    ], everyElement(DownloadStatus.running));
  });

  test('pauseCollection holds its items for the user and resumeCollection '
      'lets them run again', () async {
    rig.server.offline.albums['al'] = ['t1', 't2', 't3'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();

    await rig.controller.pauseCollection(CollectionKind.album, 'al');
    await rig.settle();

    for (final row in await rig.items()) {
      expect(row.status, isIn([DownloadStatus.paused, DownloadStatus.queued]));
      expect(row.waitingFor, 'user');
    }
    final paused = await rig.controller
        .watchCollection(CollectionKind.album, 'al')
        .first;
    expect(paused!.pausedCount, 3);

    await rig.controller.resumeCollection(CollectionKind.album, 'al');
    await rig.settle();

    final statuses = [for (final row in await rig.items()) row.status];
    expect(statuses.where((s) => s == DownloadStatus.running), hasLength(2));
    expect([
      for (final row in await rig.items()) row.waitingFor,
    ], everyElement(isNull));
  });

  test('pauseAll and resumeAll pause and resume every item', () async {
    rig.server.offline.albums['al'] = ['t1', 't2'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();

    await rig.controller.pauseAll();
    await rig.settle();
    expect([
      for (final row in await rig.items()) row.status,
    ], everyElement(DownloadStatus.paused));

    await rig.controller.resumeAll();
    await rig.settle();
    expect([
      for (final row in await rig.items()) row.status,
    ], everyElement(DownloadStatus.running));
  });

  test('unavailableItems answers the title and reason of each unavailable '
      'item in membership order', () async {
    rig.server.offline
      ..albums['al'] = ['t1', 't2', 't3']
      ..unavailable['t1'] = 'TRACK_UNAVAILABLE'
      ..unavailable['t3'] = 'SOURCE_UNAVAILABLE';
    await rig.controller.pin(
      CollectionKind.album,
      'al',
      snapshot: CollectionSnapshot(
        title: 'First Light',
        tracks: [rigTrack('t1'), rigTrack('t2'), rigTrack('t3')],
      ),
    );
    await rig.settle();

    final items = await rig.controller.unavailableItems(
      CollectionKind.album,
      'al',
    );

    expect([for (final i in items) i.title], ['Song t1', 'Song t3']);
    expect(
      [for (final i in items) i.reason],
      [
        DownloadUnavailableReason.trackUnavailable,
        DownloadUnavailableReason.sourceUnavailable,
      ],
    );
  });

  test('deviceLimitToFitAll answers the bytes every download needs, and '
      'null when free disk space is the bound', () async {
    rig.server.offline
      ..albums['al'] = ['t1', 't2', 't3']
      ..defaultTrackBytes = 1000;
    await rig.settings.write(downloadsQuotaKey, 1500);
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    final state = await rig.controller
        .watchCollection(CollectionKind.album, 'al')
        .first;
    expect(state!.quotaShortfall, isNotNull);

    expect(await rig.controller.deviceLimitToFitAll(), 3000);

    rig.diskSpace.free = kDiskReserveBytes + 1000;
    expect(await rig.controller.deviceLimitToFitAll(), isNull);
  });
}
