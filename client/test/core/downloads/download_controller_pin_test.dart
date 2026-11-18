// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/l10n/generated/app_localizations_en.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_api.dart';
import 'download_controller_rig.dart';

String _task(String playbackId) => itemKeyHash(TrackItemKey(playbackId));

void main() {
  late Directory dir;
  late DownloadControllerRig rig;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('download_controller_pin');
    rig = DownloadControllerRig(dir);
    await rig.start();
  });
  tearDown(() async {
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  CollectionSnapshot snapshotOf(List<String> ids, {String title = 'First'}) =>
      CollectionSnapshot(
        title: title,
        subtitle: 'Contract Aurora',
        artworkRef: 'art-1',
        tracks: [for (final id in ids) rigTrack(id)],
      );

  test('mixed album: three downloadable items are queued and handed to the '
      'scheduler, two are unavailable with the server reasons', () async {
    rig.server.offline
      ..albums['al'] = ['t1', 't2', 't3', 't4', 't5']
      ..unavailable['t2'] = 'TRACK_UNAVAILABLE'
      ..unavailable['t4'] = 'SOURCE_UNAVAILABLE';

    await rig.controller.pin(
      CollectionKind.album,
      'al',
      snapshot: snapshotOf(['t1', 't2', 't3', 't4', 't5']),
    );
    await rig.settle();

    // Two slots: the first two downloadable items run, the third waits.
    expect(rig.requested, [_task('t1'), _task('t3')]);
    expect((await rig.item('t1'))!.status, DownloadStatus.running);
    expect((await rig.item('t3'))!.status, DownloadStatus.running);
    expect((await rig.item('t5'))!.status, DownloadStatus.queued);
    final t5 = (await rig.item('t5'))!;
    expect(t5.downloadUrl, '/api/playback/stream/t5?quality=original&report=0');
    expect(t5.expectedBytes, 1000);
    expect(t5.quality, 'original');
    expect(t5.requestedAt, rig.clock.now());
    final t2 = (await rig.item('t2'))!;
    expect(t2.status, DownloadStatus.unavailable);
    expect(t2.failureCode, 'TRACK_UNAVAILABLE');
    final t4 = (await rig.item('t4'))!;
    expect(t4.status, DownloadStatus.unavailable);
    expect(t4.failureCode, 'SOURCE_UNAVAILABLE');
    expect([
      for (final m in await rig.memberships()) '${m.itemKey}@${m.position}',
    ], unorderedEquals(['t:t1@0', 't:t2@1', 't:t3@2', 't:t4@3', 't:t5@4']));

    final state = await rig.controller
        .watchCollection(CollectionKind.album, 'al')
        .first;
    expect(state!.status, DownloadCollectionStatus.ready);
    expect(state.blockedReason, isNull);
    expect(state.itemCount, 5);
    expect(state.unavailableCount, 2);
    expect(state.completedCount, 0);
    expect(state.totalBytes, 3000);
    final collection = (await rig.collections()).single;
    expect(collection.title, 'First');
    expect(
      collection.metaJson,
      '{"subtitle":"Contract Aurora","artworkRef":"art-1"}',
    );
    expect(collection.resolvedAt, rig.clock.now());
  });

  test('the unavailable reasons map to l10n ids', () {
    expect(
      DownloadUnavailableReason.fromCode('SOURCE_DOWNLOADS_DISABLED')
          ?.messageId,
      'downloadUnavailableDisabled',
    );
    expect(
      DownloadUnavailableReason.fromCode('TRACK_UNAVAILABLE')?.messageId,
      'downloadUnavailableGone',
    );
    expect(
      DownloadUnavailableReason.fromCode('SOURCE_UNAVAILABLE')?.messageId,
      'downloadUnavailableAccount',
    );
    expect(DownloadUnavailableReason.fromCode('SOMETHING_NEW'), isNull);
    // The ids name these English messages.
    final l10n = AppLocalizationsEn();
    expect(
      l10n.downloadUnavailableDisabled,
      'Downloads are turned off on this server',
    );
    expect(l10n.downloadUnavailableGone, 'No longer available');
    expect(l10n.downloadUnavailableAccount, 'Not available for your account');
  });

  test('a reason the client does not know is stored as UNKNOWN', () async {
    rig.server.offline
      ..albums['al'] = ['t1']
      ..unavailable['t1'] = 'SOMETHING_NEW';

    await rig.controller.pin(CollectionKind.album, 'al');

    expect((await rig.item('t1'))!.failureCode, unknownUnavailableCode);
  });

  test('cache-limit error: the collection is blocked by the server quota '
      'with the three byte values, and no items are created', () async {
    rig.server.offline
      ..albums['al'] = ['t1', 't2']
      ..cacheLimitBytes = 500;

    await rig.controller.pin(CollectionKind.album, 'al');

    final collection = (await rig.collections()).single;
    expect(
      DownloadStore.statusOf(collection),
      DownloadCollectionStatus.blocked,
    );
    expect(DownloadStore.blockOf(collection), CollectionBlock.serverQuota);
    expect(DownloadStore.detailOf(collection), {
      'limitBytes': 500,
      'usedBytes': 0,
      'estimatedBytes': 2000,
    });
    expect(await rig.items(), isEmpty);
    expect(await rig.memberships(), isEmpty);
    final state = await rig.controller
        .watchCollection(CollectionKind.album, 'al')
        .first;
    expect(state!.blockedReason, CollectionBlock.serverQuota);
    expect(state.blockedDetail, {
      'limitBytes': 500,
      'usedBytes': 0,
      'estimatedBytes': 2000,
    });
  });

  test('downloads disabled: blocked by the server; a later successful pin '
      'clears the reason', () async {
    rig.server.offline
      ..albums['al'] = ['t1']
      ..downloadsDisabled = true
      ..rejectWhenDisabled = true;

    await rig.controller.pin(CollectionKind.album, 'al');

    var collection = (await rig.collections()).single;
    expect(
      DownloadStore.statusOf(collection),
      DownloadCollectionStatus.blocked,
    );
    expect(DownloadStore.blockOf(collection), CollectionBlock.disabledByServer);

    rig.server.offline.downloadsDisabled = false;
    await rig.controller.pin(CollectionKind.album, 'al');

    collection = (await rig.collections()).single;
    expect(DownloadStore.statusOf(collection), DownloadCollectionStatus.ready);
    expect(collection.blockedReason, isNull);
    expect(collection.detailJson, isNull);
  });

  test(
    'the collection row exists as resolving before the server answers',
    () async {
      final dir2 = Directory.systemTemp.createTempSync('download_gated');
      addTearDown(() => dir2.deleteSync(recursive: true));
      final gated = GatedOfflineClient(FakeOfflineClient());
      final gatedRig = DownloadControllerRig(dir2, offlineClient: gated);
      addTearDown(gatedRig.dispose);
      await gatedRig.start();
      gated.inner.albums['al'] = ['t1'];

      final pinning = gatedRig.controller.pin(
        CollectionKind.album,
        'al',
        snapshot: snapshotOf(['t1']),
      );
      final resolving = await gatedRig.controller
          .watchCollection(CollectionKind.album, 'al')
          .firstWhere((s) => s != null);

      expect(resolving!.status, DownloadCollectionStatus.resolving);
      expect(await gatedRig.items(), isEmpty);

      gated.gate.complete();
      await pinning;
      expect(
        DownloadStore.statusOf((await gatedRig.collections()).single),
        DownloadCollectionStatus.ready,
      );
    },
  );

  test('a track already completed through another collection gains a '
      'membership and is not downloaded again', () async {
    rig.server.offline
      ..albums['al'] = ['t1']
      ..playlists['pl'] = ['t1', 't2'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    await rig.completeOnDisk('t1');
    // A different download quality keeps the completed file (v1).
    await rig.settings.write(downloadQualityKey, 'high');

    await rig.controller.pin(CollectionKind.playlist, 'pl');
    await rig.settle();

    final t1 = (await rig.item('t1'))!;
    expect(t1.status, DownloadStatus.completed);
    expect(t1.quality, 'original');
    expect(rig.requested.where((t) => t == _task('t1')), hasLength(1));
    expect(rig.requested, contains(_task('t2')));
    expect(await rig.store.membershipCount(const TrackItemKey('t1')), 2);
  });

  test('pin while offline: pendingNetwork with no request and an empty '
      'outbox; back online the collection is resolved', () async {
    rig.server.offline.albums['al'] = ['t1'];
    rig.setReachability(Reachability.serverUnreachable);

    await rig.controller.pin(
      CollectionKind.album,
      'al',
      snapshot: snapshotOf(['t1'], title: 'Offline album'),
    );

    expect(
      DownloadStore.statusOf((await rig.collections()).single),
      DownloadCollectionStatus.pendingNetwork,
    );
    expect(rig.resolveRequests, isEmpty);
    expect(await rig.outboxStore.pending(), isEmpty);

    rig.setReachability(Reachability.online);
    final state = await rig.controller
        .watchCollection(CollectionKind.album, 'al')
        .firstWhere((s) => s?.status == DownloadCollectionStatus.ready)
        .timeout(const Duration(seconds: 5));

    expect(state!.itemCount, 1);
    expect(rig.resolveRequests, hasLength(1));
    expect((await rig.collections()).single.title, 'Offline album');
  });

  test('a network failure from the server leaves the collection '
      'pendingNetwork without adding to the outbox', () async {
    final dir2 = Directory.systemTemp.createTempSync('download_failing');
    addTearDown(() => dir2.deleteSync(recursive: true));
    for (final error in <api.ApiException>[
      const api.Offline(),
      const api.ServerError(status: 503),
      const api.Upstream(status: 502),
      const api.RateLimited(retryAfter: Duration(seconds: 3), status: 429),
    ]) {
      final failing = DownloadControllerRig(
        dir2,
        offlineClient: _FailingOfflineClient(error),
      );
      await failing.start();
      await failing.controller.pin(CollectionKind.album, 'al');
      expect(
        DownloadStore.statusOf((await failing.collections()).single),
        DownloadCollectionStatus.pendingNetwork,
        reason: '$error',
      );
      expect(await failing.outboxStore.pending(), isEmpty);
      await failing.dispose();
    }
  });

  test('another server error leaves the collection pendingNetwork and '
      'reaches the caller', () async {
    final dir2 = Directory.systemTemp.createTempSync('download_forbidden');
    addTearDown(() => dir2.deleteSync(recursive: true));
    final failing = DownloadControllerRig(
      dir2,
      offlineClient: _FailingOfflineClient(const api.Forbidden(status: 403)),
    );
    addTearDown(failing.dispose);
    await failing.start();

    await expectLater(
      failing.controller.pin(CollectionKind.album, 'al'),
      throwsA(isA<api.Forbidden>()),
    );
    expect(
      DownloadStore.statusOf((await failing.collections()).single),
      DownloadCollectionStatus.pendingNetwork,
    );
  });

  test('NotFound removes the collection and reaches the caller', () async {
    await expectLater(
      rig.controller.pin(CollectionKind.album, 'missing'),
      throwsA(isA<api.NotFound>()),
    );
    expect(await rig.collections(), isEmpty);
  });

  test(
    'metadata comes from the snapshot, then from cache.db, then empty',
    () async {
      rig.server.offline.playlists['pl'] = ['t1', 't2', 't3'];
      await rig.cache.upsertTracks([rigTrack('t2', title: 'Cached 2')]);

      await rig.controller.pin(
        CollectionKind.playlist,
        'pl',
        snapshot: CollectionSnapshot(
          title: 'Mix',
          tracks: [rigTrack('t1', title: 'Snap 1', albumId: 'al-1')],
        ),
      );

      expect(await rig.meta('t1'), {
        'title': 'Snap 1',
        'artist': 'Contract Aurora',
        'album': 'First Light',
        'durationSec': 30,
        'artworkRef': null,
        'isrc': null,
        'albumId': 'al-1',
        'artistId': 'ar-1',
        'loudness': {
          'loudnessLufs': -9.0,
          'truePeakDb': null,
          'albumLoudnessLufs': null,
          'albumTruePeakDb': null,
        },
        'discNumber': 1,
        'trackNumber': 2,
      });
      expect((await rig.meta('t2'))['title'], 'Cached 2');
      expect(await rig.meta('t3'), {
        'title': '',
        'artist': '',
        'album': '',
        'durationSec': 0,
        'artworkRef': null,
        'isrc': null,
      });
    },
  );

  test(
    'quality.download high is sent; serverDefault sends no quality',
    () async {
      rig.server.offline
        ..albums['a1'] = ['t1']
        ..albums['a2'] = ['t2'];

      await rig.settings.write(downloadQualityKey, 'high');
      await rig.controller.pin(CollectionKind.album, 'a1');
      await rig.settings.write(downloadQualityKey, 'serverDefault');
      await rig.controller.pin(CollectionKind.album, 'a2');

      expect(rig.resolveRequests.map((r) => r.quality?.toJson()), [
        'high',
        null,
      ]);
      expect(rig.resolveRequests.map((r) => r.deviceId), [
        rigDeviceId,
        rigDeviceId,
      ]);
      expect((await rig.item('t1'))!.quality, 'high');
    },
  );

  test('pinning twice creates no duplicate rows', () async {
    rig.server.offline.albums['al'] = ['t1', 't2', 't3'];
    await rig.controller.pin(
      CollectionKind.album,
      'al',
      snapshot: snapshotOf(['t1', 't2', 't3']),
    );
    final requestedAt = (await rig.collections()).single.requestedAt;
    rig.clock.advance(const Duration(minutes: 5));

    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();

    final collections = await rig.collections();
    expect(collections, hasLength(1));
    expect(collections.single.requestedAt, requestedAt);
    expect(collections.single.title, 'First');
    expect(await rig.items(), hasLength(3));
    expect(await rig.memberships(), hasLength(3));
    expect(rig.requested.toSet(), hasLength(rig.requested.length));
  });

  test('an item the server refuses with 404 is re-resolved and becomes unavailable', () async {
    rig.server.offline.albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();

    // The server no longer serves the file: 404 re-resolves the album.
    rig.server.offline.unavailable['t1'] = 'TRACK_UNAVAILABLE';
    rig.downloader.fail(
      _task('t1'),
      kind: DownloaderFailureKind.http,
      httpStatus: 404,
    );
    await rig.settle();
    await rig.controller.retryPendingCollections();

    expect(rig.resolveRequests, hasLength(2));
    final t1 = (await rig.item('t1'))!;
    expect(t1.status, DownloadStatus.unavailable);
    expect(t1.failureCode, 'TRACK_UNAVAILABLE');
  });

  test('watchItem reports the item state', () async {
    rig.server.offline.albums['al'] = ['t1', 't2', 't3'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();

    final state = await rig.controller
        .watchItem(const TrackItemKey('t3'))
        .first;

    expect(state, isNotNull);
    expect(state!.status, DownloadStatus.queued);
    expect(state.expectedBytes, 1000);
    expect(state.receivedBytes, 0);
    expect(state.failureCode, isNull);
    expect(
      await rig.controller.watchItem(const TrackItemKey('nope')).first,
      isNull,
    );
  });
}

/// An offline client whose `POST /offline/items` always throws [error].
final class _FailingOfflineClient implements api.OfflineClient {
  new(this.error);

  final api.ApiException error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #requestOfflineItems) {
      return Future<api.OfflineItemsResponse>.error(error);
    }
    throw UnimplementedError('${invocation.memberName}');
  }
}
