// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/collection_upkeep.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/downloads/pinned_playlist_listener.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/shared/domain/track.dart';

import 'download_controller_rig.dart';

String _task(String playbackId) => itemKeyHash(TrackItemKey(playbackId));

void main() {
  late Directory dir;
  late DownloadControllerRig rig;
  late List<RigTimer> timers;
  late PinnedPlaylistRelay relay;
  late CollectionUpkeep upkeep;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('collection_upkeep');
    rig = DownloadControllerRig(dir);
    await rig.start();
    timers = [];
    relay = PinnedPlaylistRelay();
    upkeep = CollectionUpkeep(
      controller: rig.controller,
      reachability: rig.reachability,
      clock: rig.clock,
      relay: relay,
      createTimer: (delay, callback) {
        final timer = RigTimer(delay, callback);
        timers.add(timer);
        return timer;
      },
    );
  });
  tearDown(() async {
    await upkeep.dispose();
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  List<Track> tracksOf(List<String> ids) => [
    for (final id in ids) rigTrack(id),
  ];

  CollectionSnapshot snapshotOf(List<String> ids) =>
      CollectionSnapshot(title: 'Mix', tracks: tracksOf(ids));

  Future<void> pinPlaylist(List<String> ids, {String id = 'pl'}) async {
    rig.server.offline.playlists[id] = ids;
    await rig.controller.pin(
      CollectionKind.playlist,
      id,
      snapshot: snapshotOf(ids),
    );
    await rig.settle();
  }

  Future<List<String>> membersOf(String refId) async => [
    for (final m
        in (await rig.memberships()).where((m) => m.refId == refId).toList()
          ..sort((a, b) => a.position.compareTo(b.position)))
      m.itemKey,
  ];

  Future<void> fireDebounce() async {
    rig.clock.advance(kPlaylistUpkeepDebounce);
    for (final timer in [...timers]) {
      if (timer.delay == kPlaylistUpkeepDebounce) timer.fire();
    }
    await upkeep.settle();
    await rig.settle();
  }

  Future<void> changed(String id, List<String> ids) =>
      upkeep.onPlaylistTracksChanged(id, tracksOf(ids), title: 'Mix');

  test('a playlist that gains two tracks on the server queues two new '
      'items, in the new membership order', () async {
    await pinPlaylist(['t1', 't2']);
    rig.server.offline.playlists['pl'] = ['t3', 't1', 't2', 't4'];

    final result = await upkeep.refresh(CollectionKind.playlist, 'pl');
    await rig.settle();

    expect(result, UpkeepResult.refreshed);
    // t1 and t2 hold both slots; the new items wait their turn.
    expect((await rig.item('t3'))!.status, DownloadStatus.queued);
    expect((await rig.item('t4'))!.status, DownloadStatus.queued);
    expect(await membersOf('pl'), ['t:t3', 't:t1', 't:t2', 't:t4']);
  });

  test('a track the playlist loses is deleted with its file and reported '
      'once, unless a pinned album also holds it', () async {
    rig.server.offline.albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await pinPlaylist(['t1', 't3', 't4']);
    final t1File = await rig.completeOnDisk('t1');
    final t3File = await rig.completeOnDisk('t3');
    rig.server.offline.playlists['pl'] = ['t4'];

    await upkeep.refresh(CollectionKind.playlist, 'pl');
    await rig.settle();

    expect(await rig.item('t3'), isNull);
    expect(File(t3File).existsSync(), isFalse);
    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect(File(t1File).existsSync(), isTrue);
    expect(await membersOf('pl'), ['t:t4']);
    expect(await membersOf('al'), ['t:t1']);
    final reported = [
      for (final op in await rig.pendingDeletes()) op.playbackIds,
      for (final request in rig.deleteRequests)
        [for (final id in request.playbackIds) id],
    ];
    expect(reported, [
      ['t3'],
    ]);
  });

  test('a reordered playlist rewrites the membership order and neither '
      'downloads nor deletes', () async {
    await pinPlaylist(['t1', 't2', 't3']);
    final requested = rig.requested.length;
    final items = (await rig.items()).length;
    rig.server.offline.playlists['pl'] = ['t3', 't1', 't2'];

    await upkeep.refresh(CollectionKind.playlist, 'pl');
    await rig.settle();

    expect(await membersOf('pl'), ['t:t3', 't:t1', 't:t2']);
    expect(rig.requested, hasLength(requested));
    expect(await rig.items(), hasLength(items));
    expect(await rig.pendingDeletes(), isEmpty);
    expect(rig.deleteRequests, isEmpty);
  });

  test('a change to an unpinned playlist, or one that matches what is '
      'pinned, sends nothing', () async {
    await pinPlaylist(['t1', 't2']);
    final before = rig.resolveRequests.length;

    await changed('other', ['t1']);
    await changed('pl', ['t1', 't2']);
    await fireDebounce();

    expect(timers, isEmpty);
    expect(rig.resolveRequests, hasLength(before));
  });

  test('five local edits within two seconds make one resolve', () async {
    await pinPlaylist(['t1']);
    final before = rig.resolveRequests.length;

    for (var n = 2; n <= 6; n++) {
      rig.clock.advance(const Duration(milliseconds: 300));
      await changed('pl', [for (var i = 1; i <= n; i++) 't$i']);
    }
    rig.server.offline.playlists['pl'] = ['t1', 't2', 't3', 't4', 't5', 't6'];
    await fireDebounce();

    expect(rig.resolveRequests, hasLength(before + 1));
    expect(await membersOf('pl'), [for (var i = 1; i <= 6; i++) 't:t$i']);
  });

  test("the relay forwards the playlist layer's calls once started", () async {
    await pinPlaylist(['t1']);
    rig.server.offline.playlists['pl'] = ['t1', 't2'];
    await upkeep.start();
    final before = rig.resolveRequests.length;

    await relay.onPlaylistTracksChanged(
      'pl',
      tracksOf(['t1', 't2']),
      title: 'Mix',
    );
    await fireDebounce();

    expect(rig.resolveRequests, hasLength(before + 1));
    expect(await membersOf('pl'), ['t:t1', 't:t2']);
  });

  test('a local edit made offline is refreshed when online returns', () async {
    await upkeep.start();
    await pinPlaylist(['t1']);
    final before = rig.resolveRequests.length;
    rig.setReachability(Reachability.noNetwork);

    await changed('pl', ['t1', 't2']);
    await fireDebounce();
    expect(rig.resolveRequests, hasLength(before));

    rig.server.offline.playlists['pl'] = ['t1', 't2'];
    rig.setReachability(Reachability.online);
    await upkeep.settle();
    await rig.settle();

    expect(rig.resolveRequests, hasLength(before + 1));
    expect(await membersOf('pl'), ['t:t1', 't:t2']);
  });

  test('an item the server now refuses: queued becomes unavailable, '
      'completed is left in place', () async {
    await pinPlaylist(['t1', 't2', 't3']);
    // t1 and t2 run; t3 is still queued.
    expect((await rig.item('t3'))!.status, DownloadStatus.queued);
    await rig.completeOnDisk('t1');
    rig.server.offline.unavailable
      ..['t1'] = 'TRACK_UNAVAILABLE'
      ..['t3'] = 'SOURCE_UNAVAILABLE';

    await upkeep.refresh(CollectionKind.playlist, 'pl');
    await rig.settle();

    final t3 = (await rig.item('t3'))!;
    expect(t3.status, DownloadStatus.unavailable);
    expect(t3.failureCode, 'SOURCE_UNAVAILABLE');
    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
  });

  test('an unavailable item the server now accepts is queued', () async {
    rig.server.offline.unavailable['t1'] = 'TRACK_UNAVAILABLE';
    await pinPlaylist(['t1']);
    expect((await rig.item('t1'))!.status, DownloadStatus.unavailable);
    rig.server.offline.unavailable.clear();

    await upkeep.refresh(CollectionKind.playlist, 'pl');
    await rig.settle();

    expect((await rig.item('t1'))!.status, isNot(DownloadStatus.unavailable));
    expect(rig.requested, contains(_task('t1')));
  });

  group('daily album pass', () {
    Future<void> pinAlbum(String id, List<String> ids) async {
      rig.server.offline.albums[id] = ids;
      await rig.controller.pin(CollectionKind.album, id);
      await rig.settle();
    }

    List<String> resolvedIds() => [
      for (final request in rig.resolveRequests) request.id,
    ];

    test('refreshes an album resolved 25 hours ago, not one resolved 2 hours '
        'ago', () async {
      await pinAlbum('old', ['t1']);
      rig.clock.advance(const Duration(hours: 23));
      await pinAlbum('new', ['t2']);
      rig.clock.advance(const Duration(hours: 2));
      final before = resolvedIds().length;

      await upkeep.runDailyAlbumPass();

      expect(resolvedIds().skip(before), ['old']);
    });

    test('runs nothing offline', () async {
      await pinAlbum('old', ['t1']);
      rig.clock.advance(const Duration(hours: 25));
      rig.setReachability(Reachability.noNetwork);
      final before = resolvedIds().length;

      await upkeep.runDailyAlbumPass();

      expect(resolvedIds(), hasLength(before));
    });

    test('runs at start and again after 24 hours', () async {
      await pinAlbum('old', ['t1']);
      rig.clock.advance(const Duration(hours: 23));
      await pinAlbum('new', ['t2']);
      rig.clock.advance(const Duration(hours: 2));
      final before = resolvedIds().length;

      await upkeep.start();
      await upkeep.settle();
      expect(resolvedIds().skip(before), ['old']);

      rig.clock.advance(kAlbumUpkeepInterval);
      timers
          .singleWhere((t) => t.delay == kAlbumUpkeepInterval && t.isActive)
          .fire();
      await upkeep.settle();

      expect(resolvedIds().skip(before), ['old', 'old', 'new']);
      // The next pass is armed.
      expect(
        timers.where((t) => t.delay == kAlbumUpkeepInterval && t.isActive),
        hasLength(1),
      );
    });

    test('a manual refresh ignores the 24-hour rule', () async {
      await pinAlbum('al', ['t1']);
      final before = resolvedIds().length;

      final result = await upkeep.refresh(CollectionKind.album, 'al');

      expect(result, UpkeepResult.refreshed);
      expect(resolvedIds().skip(before), ['al']);
    });
  });

  test('an album deleted on the server keeps its files and is marked as no '
      'longer on the server', () async {
    rig.server.offline.albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    final file = await rig.completeOnDisk('t1');
    rig.server.offline.albums.remove('al');

    final result = await upkeep.refresh(CollectionKind.album, 'al');
    await rig.settle();

    expect(result, UpkeepResult.sourceGone);
    expect(File(file).existsSync(), isTrue);
    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    final state = await rig.controller
        .watchCollection(CollectionKind.album, 'al')
        .first;
    expect(state!.status, DownloadCollectionStatus.ready);
    expect(state.sourceGone, isTrue);

    // The flag goes once the server knows the album again.
    rig.server.offline.albums['al'] = ['t1'];
    await upkeep.refresh(CollectionKind.album, 'al');
    final again = await rig.controller
        .watchCollection(CollectionKind.album, 'al')
        .first;
    expect(again!.sourceGone, isFalse);
  });

  test('an item with empty metadata is filled from the snapshot', () async {
    rig.server.offline.playlists['pl'] = ['t1'];
    await rig.controller.pin(CollectionKind.playlist, 'pl');
    await rig.settle();
    expect((await rig.meta('t1'))['title'], '');

    await upkeep.refresh(
      CollectionKind.playlist,
      'pl',
      snapshot: snapshotOf(['t1']),
    );

    expect((await rig.meta('t1'))['title'], 'Song t1');
    expect((await rig.collections()).single.title, 'Mix');
  });

  test('a cache-limit refusal keeps completed files and blocks the '
      'collection', () async {
    await pinPlaylist(['t1', 't2']);
    final file = await rig.completeOnDisk('t1');
    rig.server.offline
      ..playlists['pl'] = ['t1', 't2', 't3']
      ..cacheLimitBytes = 0;

    final result = await upkeep.refresh(CollectionKind.playlist, 'pl');
    await rig.settle();

    expect(result, UpkeepResult.blocked);
    expect(File(file).existsSync(), isTrue);
    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    final state = await rig.controller
        .watchCollection(CollectionKind.playlist, 'pl')
        .first;
    expect(state!.status, DownloadCollectionStatus.blocked);
    expect(state.blockedReason, CollectionBlock.serverQuota);
  });

  test('refreshing a collection that is not pinned sends nothing', () async {
    final result = await upkeep.refresh(CollectionKind.album, 'nope');

    expect(result, UpkeepResult.notPinned);
    expect(rig.resolveRequests, isEmpty);
  });

  test('an unreachable server leaves everything unchanged', () async {
    await pinPlaylist(['t1']);
    rig.setReachability(Reachability.noNetwork);

    final result = await upkeep.refresh(CollectionKind.playlist, 'pl');

    expect(result, UpkeepResult.unchanged);
    expect(await membersOf('pl'), ['t:t1']);
  });
}
