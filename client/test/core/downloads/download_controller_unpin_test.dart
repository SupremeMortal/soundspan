// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/storage/state/enums.dart';

import 'download_controller_rig.dart';

String _task(String playbackId) => itemKeyHash(TrackItemKey(playbackId));

void main() {
  late Directory dir;
  late DownloadControllerRig rig;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('download_controller_unpin');
    rig = DownloadControllerRig(dir);
    await rig.start();
  });
  tearDown(() async {
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  test('an item in two collections stays until the second is unpinned; '
      'then its file and row are deleted and one offlineDelete op holds '
      'its playbackId', () async {
    rig.server.offline
      ..albums['al'] = ['t1', 't2']
      ..playlists['pl'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.controller.pin(CollectionKind.playlist, 'pl');
    await rig.settle();
    final file = await rig.completeOnDisk('t1');
    rig.setReachability(Reachability.serverUnreachable);

    await rig.controller.unpin(CollectionKind.album, 'al');

    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect(File(file).existsSync(), isTrue);
    expect(await rig.item('t2'), isNull);
    expect(
      [for (final m in await rig.memberships()) '${m.refId}/${m.itemKey}'],
      ['pl/t:t1'],
    );

    await rig.controller.unpin(CollectionKind.playlist, 'pl');

    expect(await rig.item('t1'), isNull);
    expect(File(file).existsSync(), isFalse);
    expect(await rig.collections(), isEmpty);
    final ops = await rig.pendingDeletes();
    expect(ops, hasLength(1));
    expect(ops.single.deviceId, rigDeviceId);
    expect(ops.single.playbackIds, containsAll(['t1', 't2']));
    expect(rig.deleteRequests, isEmpty);
  });

  test('1,200 orphaned items produce batches of 500, 500 and 200', () async {
    final ids = [for (var i = 0; i < 1200; i++) 't$i'];
    rig.server.offline.albums['big'] = ids;
    await rig.controller.pin(CollectionKind.album, 'big');
    await rig.settle();
    rig.setReachability(Reachability.noNetwork);

    await rig.controller.unpin(CollectionKind.album, 'big');

    final ops = await rig.pendingDeletes();
    expect([for (final op in ops) op.playbackIds.length], [500, 500, 200]);
    expect({for (final op in ops) ...op.playbackIds}, ids.toSet());
    expect(await rig.items(), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('unpinning a running item cancels its task and deletes the .part '
      'file', () async {
    rig.server.offline.albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    expect((await rig.item('t1'))!.status, DownloadStatus.running);
    final part = File(rig.paths.partFile(_task('t1')))
      ..createSync(recursive: true)
      ..writeAsStringSync('partial');

    await rig.controller.unpin(CollectionKind.album, 'al');
    await rig.settle();

    expect(rig.downloader.cancelled, contains(_task('t1')));
    expect(part.existsSync(), isFalse);
    expect(await rig.item('t1'), isNull);
    expect(rig.requested, [_task('t1')]);
  });

  test('a file delete that throws leaves the row deleted and does not fail '
      'unpin', () async {
    rig.server.offline.albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    final file = await rig.completeOnDisk('t1');
    rig.mediaFiles.failWith = const FileSystemException('in use');

    await expectLater(
      rig.controller.unpin(CollectionKind.album, 'al'),
      completes,
    );

    expect(await rig.item('t1'), isNull);
    expect(rig.mediaFiles.deleted, contains(file));
    expect(File(file).existsSync(), isTrue);
  });

  test('offline unpin leaves the offlineDelete op pending; back online it '
      'is sent to the server', () async {
    rig.server.offline.albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    rig.setReachability(Reachability.forcedOffline);

    await rig.controller.unpin(CollectionKind.album, 'al');
    await rig.settle();

    expect((await rig.pendingDeletes()).single.playbackIds, ['t1']);
    expect(rig.deleteRequests, isEmpty);

    rig.setReachability(Reachability.online);
    await rig.settle();

    expect(await rig.pendingDeletes(), isEmpty);
    expect(rig.deleteRequests.single.playbackIds, ['t1']);
    expect(rig.deleteRequests.single.deviceId, rigDeviceId);
  });

  test('unavailable items are removed with their membership and not '
      'reported', () async {
    rig.server.offline
      ..albums['al'] = ['t1']
      ..unavailable['t1'] = 'TRACK_UNAVAILABLE';
    await rig.controller.pin(CollectionKind.album, 'al');
    rig.setReachability(Reachability.serverUnreachable);

    await rig.controller.unpin(CollectionKind.album, 'al');

    expect(await rig.items(), isEmpty);
    expect(await rig.memberships(), isEmpty);
    expect(await rig.pendingDeletes(), isEmpty);
    expect(rig.mediaFiles.deleted, isEmpty);
  });

  test('unpinning an unknown collection does nothing', () async {
    await rig.controller.unpin(CollectionKind.album, 'nothing');

    expect(rig.downloader.cancelled, isEmpty);
    expect(await rig.pendingDeletes(), isEmpty);
  });
}
