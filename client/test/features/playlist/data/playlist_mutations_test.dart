// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/data/playlist/cached_playlist_repository.dart';
import 'package:soundspan/shared/data/playlist/playlist_outbox_handlers.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/data/preference_overlay.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../core/sync/outbox/outbox_test_support.dart' show ManualTimer;
import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';

Track _track(String id) => Track(
  meta: TrackMeta(
    title: 'Song $id',
    artist: 'Contract Aurora',
    album: 'First Light',
    durationSec: 30,
  ),
  playbackId: PlaybackId(id),
);

/// A profile's outbox, cache and playlist repository over in-memory
/// databases, with [FakePlaylistsClient] as the server.
final class _Rig {
  new()
    : state = StateDatabase(NativeDatabase.memory()),
      cacheDb = CacheDatabase(NativeDatabase.memory()),
      clock = FakeClock(),
      reachability = FakeReachability(),
      fakeApi = FakeApi() {
    cache = CacheStore(cacheDb, clock);
    store = OutboxStore(state, clock);
    final remote = PlaylistRemoteSource(fakeApi.playlists);
    worker = OutboxWorker(
      store,
      OutboxHandlerRegistry(playlistOutboxHandlers(remote, () async => cache)),
      reachability,
      clock,
      AppLogger.scope('PlaylistTest'),
      rewriter: TempIdRewriter(state, () async => cacheDb),
      periodicTimer: ManualTimer.new,
    );
    worker.resolved.listen(resolved.add);
    repository = CachedPlaylistRepository(
      remote,
      cache,
      Swr(clock: clock, reachability: reachability),
      PagedSources(cache, clock, reachability),
      pending: (opTypes) => store.watchPending(opTypes: opTypes),
      outbox: Outbox(store, worker),
    );
  }

  final StateDatabase state;
  final CacheDatabase cacheDb;
  final FakeClock clock;
  final FakeReachability reachability;
  final FakeApi fakeApi;
  final List<TempIdResolved> resolved = [];
  late final CacheStore cache;
  late final OutboxStore store;
  late final OutboxWorker worker;
  late final CachedPlaylistRepository repository;

  FakePlaylistsClient get server => fakeApi.playlists;

  /// The server's writes, as `op id` strings.
  List<String> get writes => server.writes;

  void offline() => reachability.set(Reachability.noNetwork);

  /// Goes online and waits for the worker to drain.
  Future<void> online() async {
    reachability.set(Reachability.online);
    worker.trigger();
    await settle();
  }

  /// Waits for the worker's pass and the cache's watch queries.
  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await worker.idle;
      await pumpEventQueue();
    }
  }

  /// Seeds the server playlist [name] with [playbackIds] and caches its
  /// detail and the playlists list.
  Future<String> seedPlaylist(
    String name, {
    List<String> playbackIds = const [],
  }) async {
    final id = server.seed(name, playbackIds: playbackIds);
    await repository.refreshPlaylist(id);
    final source = repository.playlists()..ensureVisible(0, 0);
    await source.refresh();
    source.dispose();
    server.requests.clear();
    return id;
  }

  Future<void> close() async {
    await worker.dispose();
    await state.close();
    await cacheDb.close();
  }
}

/// Every value of a stream, for reading the latest one.
final class _Log<T> {
  new(Stream<T> stream) {
    _sub = stream.listen(values.add, onError: errors.add);
  }

  final List<T> values = [];
  final List<Object> errors = [];
  late final StreamSubscription<T> _sub;

  T get latest => values.last;

  Future<void> cancel() => _sub.cancel();
}

/// The names of a playlists snapshot, in order.
List<String> _names(PagedSnapshot<PlaylistSummary> snapshot) => [
  for (var i = 0; i < (snapshot.total ?? snapshot.loadedCount); i++)
    ?snapshot.itemAt(i)?.name,
];

/// The track ids of a detail, in order.
List<String> _ids(PlaylistDetail detail) => [
  for (final item in detail.items) ?item.track.playbackId?.value,
];

/// Waits until a dropped op is no longer held.
Future<void> _afterHold() async {
  await Future<void>.delayed(preferenceHold + const Duration(milliseconds: 50));
  await pumpEventQueue();
}

void main() {
  late _Rig rig;

  setUp(() => rig = _Rig());
  tearDown(() => rig.close());

  _Log<PagedSnapshot<PlaylistSummary>> watchList() {
    final source = rig.repository.playlists()..ensureVisible(0, 20);
    addTearDown(source.dispose);
    final log = _Log(source.watch());
    addTearDown(log.cancel);
    return log;
  }

  _Log<PlaylistDetail> watchDetail(String id) {
    final log = _Log(rig.repository.playlist(id).map((c) => c.value));
    addTearDown(log.cancel);
    return log;
  }

  group('create', () {
    test('answers a temporary id the list shows at once', () async {
      await rig.seedPlaylist('Old');
      rig.offline();
      final list = watchList();

      final id = await rig.repository.create('  Road  ');
      await rig.settle();

      expect(id, startsWith(TempIdRewriter.prefix));
      expect(_names(list.latest), ['Road', 'Old']);
      expect(list.latest.itemAt(0)!.isOwner, isTrue);
      final detail = watchDetail(id);
      await rig.settle();
      expect(detail.latest.summary.name, 'Road');
      expect(detail.latest.items, isEmpty);
      expect(rig.server.requests, isEmpty);
    });

    test('the server id replaces the temporary one', () async {
      final list = watchList();

      final tempId = await rig.repository.create('Road');
      await rig.settle();

      expect(rig.writes, ['create null']);
      expect(rig.resolved.single.tempId, tempId);
      final realId = rig.resolved.single.realId;
      expect(realId, 'pl-1');
      expect(list.latest.itemAt(0)!.id, realId);
      expect(_names(list.latest), ['Road']);
      final detail = watchDetail(realId);
      await rig.settle();
      expect(detail.latest.summary.name, 'Road');
      expect(rig.server.requests.where((r) => r.op == 'get'), isEmpty);
    });

    test('a 400 from the server removes it again', () async {
      final list = watchList();
      await rig.settle();
      rig.server.failures.add(const api.InvalidRequest(status: 400));

      final id = await rig.repository.create('Road');
      await rig.settle();
      await _afterHold();

      expect(_names(list.latest), isEmpty);
      expect(await rig.cache.watchPlaylist(id).first, isNull);
      expect(await rig.store.pending(), isEmpty);
    });

    test('offline: create, add two, rename and reorder send in order with '
        'the real id', () async {
      rig.offline();
      final id = await rig.repository.create('Road');
      expect(await rig.repository.addTracks(id, [_track('a'), _track('b')]), 2);
      await rig.repository.rename(id, 'Trip');
      await rig.repository.reorder(id, const [
        PlaybackId('b'),
        PlaybackId('a'),
      ]);
      final detail = watchDetail(id);
      await rig.settle();
      expect(detail.latest.summary.name, 'Trip');
      expect(_ids(detail.latest), ['b', 'a']);
      expect(rig.server.requests, isEmpty);

      await rig.online();

      expect(rig.writes, [
        'create null',
        'add pl-1',
        'add pl-1',
        'rename pl-1',
        'reorder pl-1',
      ]);
      final server = rig.server.playlists['pl-1']!;
      expect(server.name, 'Trip');
      expect([for (final e in server.entries) e.playbackId], ['b', 'a']);
      expect(await rig.store.pending(), isEmpty);
    });

    test('create then delete before sending sends nothing', () async {
      rig.offline();
      final list = watchList();
      final id = await rig.repository.create('Road');
      await rig.repository.addTracks(id, [_track('a')]);

      await rig.repository.delete(id);
      await rig.online();
      await _afterHold();

      expect(rig.server.requests.where((r) => r.op != 'list'), isEmpty);
      expect(await rig.store.pending(), isEmpty);
      expect(_names(list.latest), isEmpty);
      expect(await rig.cache.watchPlaylist(id).first, isNull);
    });

    test('an empty name is rejected before enqueue', () async {
      await expectLater(rig.repository.create('   '), throwsArgumentError);
      expect(await rig.store.pending(), isEmpty);
    });
  });

  group('rename', () {
    test('shows at once in the list and the detail, then is sent', () async {
      final id = await rig.seedPlaylist('Old');
      rig.offline();
      final list = watchList();
      final detail = watchDetail(id);

      await rig.repository.rename(id, ' New ');
      await rig.settle();

      expect(_names(list.latest), ['New']);
      expect(detail.latest.summary.name, 'New');

      await rig.online();
      expect(rig.writes, ['rename $id']);
      expect(rig.server.playlists[id]!.name, 'New');
      await _afterHold();
      expect(detail.latest.summary.name, 'New');
      expect(_names(list.latest), ['New']);
    });

    test('the last write wins', () async {
      final id = await rig.seedPlaylist('Old');
      rig.offline();

      await rig.repository.rename(id, 'One');
      await rig.repository.rename(id, 'Two');
      await rig.online();

      expect(rig.writes, ['rename $id']);
      expect(rig.server.playlists[id]!.name, 'Two');
    });

    test('a 404 rolls back by removing the playlist', () async {
      final id = await rig.seedPlaylist('Old');
      final list = watchList();
      await rig.settle();
      rig.server.failures.add(const api.NotFound(status: 404));

      await rig.repository.rename(id, 'New');
      await rig.settle();
      await _afterHold();

      expect(_names(list.latest), isEmpty);
      expect(await rig.cache.watchPlaylist(id).first, isNull);
    });

    test('an empty name is rejected', () async {
      final id = await rig.seedPlaylist('Old');
      await expectLater(rig.repository.rename(id, ''), throwsArgumentError);
      expect(await rig.store.pending(), isEmpty);
    });
  });

  group('delete', () {
    test('hides the row at once and drops pending edits', () async {
      final id = await rig.seedPlaylist('Old', playbackIds: ['a']);
      final keep = await rig.seedPlaylist('Keep');
      rig.offline();
      final list = watchList();
      await rig.repository.rename(id, 'New');
      await rig.repository.addTracks(id, [_track('b')]);

      await rig.repository.delete(id);
      await rig.settle();

      expect(_names(list.latest), ['Keep']);
      final pending = await rig.store.pending();
      expect(pending.single.op, PlaylistDeleteOp(playlistId: id));

      await rig.online();
      expect(rig.writes, ['delete $id']);
      expect(rig.server.playlists.keys, [keep]);
      expect(await rig.cache.watchPlaylist(id).first, isNull);
    });

    test('a 404 is treated as gone', () async {
      final id = await rig.seedPlaylist('Old');
      final list = watchList();
      await rig.settle();
      rig.server.failures.add(const api.NotFound(status: 404));

      await rig.repository.delete(id);
      await rig.settle();
      await _afterHold();

      expect(_names(list.latest), isEmpty);
      expect(await rig.cache.watchPlaylist(id).first, isNull);
    });
  });

  group('add', () {
    test('appends at once and sends the metadata', () async {
      final id = await rig.seedPlaylist('Road', playbackIds: ['a']);
      rig.offline();
      final detail = watchDetail(id);

      await rig.repository.addTracks(id, [_track('b')]);
      await rig.settle();

      expect(_ids(detail.latest), ['a', 'b']);
      final pendingItem = detail.latest.items.last;
      expect(pendingItem.pendingOpUuid, isNotNull);

      await rig.online();
      final body =
          rig.server.requests.single.body! as api.AddPlaylistItemRequest;
      expect(body.playbackId, 'b');
      expect(body.metadata?.title, 'Song b');
      await _afterHold();
      expect(_ids(detail.latest), ['a', 'b']);
      expect(detail.latest.items.last.pendingOpUuid, isNull);
    });

    test('skips tracks without a playbackId', () async {
      final id = await rig.seedPlaylist('Road');
      rig.offline();

      final added = await rig.repository.addTracks(id, [
        _track('a'),
        _track('x').copyWith(playbackId: null),
      ]);

      expect(added, 1);
      expect(await rig.store.pending(), hasLength(1));
    });

    test('a 409 rolls back and refetches', () async {
      final id = await rig.seedPlaylist('Road', playbackIds: ['a']);
      final detail = watchDetail(id);
      await rig.settle();
      rig.server.failures.add(const api.Conflict(status: 409));

      await rig.repository.addTracks(id, [_track('b')]);
      await rig.settle();
      await _afterHold();

      expect(_ids(detail.latest), ['a']);
      expect(rig.server.requests.map((r) => r.op), ['add', 'get']);
    });
  });

  group('remove', () {
    test('a server item is hidden at once and sent', () async {
      final id = await rig.seedPlaylist('Road', playbackIds: ['a', 'b']);
      rig.offline();
      final detail = watchDetail(id);
      await rig.settle();

      await rig.repository.removeItem(id, detail.latest.items.first);
      await rig.settle();

      expect(_ids(detail.latest), ['b']);
      await rig.online();
      expect(rig.writes, ['remove $id']);
      expect(rig.server.requests.single.body, 'a');
      await _afterHold();
      expect(_ids(detail.latest), ['b']);
    });

    test('a pending add is cancelled with it and nothing is sent; a stale '
        'pending reorder is re-issued without it', () async {
      final id = await rig.seedPlaylist('Road', playbackIds: ['a']);
      rig.offline();
      final detail = watchDetail(id);
      await rig.repository.addTracks(id, [_track('b')]);
      await rig.repository.reorder(id, const [
        PlaybackId('b'),
        PlaybackId('a'),
      ]);
      await rig.settle();
      final pendingItem = detail.latest.items.firstWhere(
        (item) => item.pendingOpUuid != null,
      );

      await rig.repository.removeItem(id, pendingItem);
      await rig.settle();
      await _afterHold();

      expect(_ids(detail.latest), ['a']);
      final pending = await rig.store.pending();
      expect(
        pending.single.op,
        PlaylistReorderOp(playlistId: id, playbackIds: const ['a']),
      );
      await rig.online();
      expect(rig.writes, ['reorder $id']);
      expect(
        (rig.server.requests.single.body! as api.ReorderPlaylistItemsRequest)
            .playbackIds,
        ['a'],
      );
    });
  });

  group('reorder', () {
    test('orders the items at once and sends the full order', () async {
      final id = await rig.seedPlaylist('Road', playbackIds: ['a', 'b', 'c']);
      rig.offline();
      final detail = watchDetail(id);

      await rig.repository.reorder(id, const [
        PlaybackId('c'),
        PlaybackId('a'),
        PlaybackId('b'),
      ]);
      await rig.settle();

      expect(_ids(detail.latest), ['c', 'a', 'b']);
      await rig.online();
      expect(
        (rig.server.requests.single.body! as api.ReorderPlaylistItemsRequest)
            .playbackIds,
        ['c', 'a', 'b'],
      );
      await _afterHold();
      expect(_ids(detail.latest), ['c', 'a', 'b']);
    });

    test('a later add stays at the end', () async {
      final id = await rig.seedPlaylist('Road', playbackIds: ['a', 'b']);
      rig.offline();
      final detail = watchDetail(id);

      await rig.repository.reorder(id, const [
        PlaybackId('b'),
        PlaybackId('a'),
      ]);
      await rig.repository.addTracks(id, [_track('c')]);
      await rig.settle();

      expect(_ids(detail.latest), ['b', 'a', 'c']);
    });

    test('the last write wins', () async {
      final id = await rig.seedPlaylist('Road', playbackIds: ['a', 'b']);
      rig.offline();

      await rig.repository.reorder(id, const [
        PlaybackId('b'),
        PlaybackId('a'),
      ]);
      await rig.repository.reorder(id, const [
        PlaybackId('a'),
        PlaybackId('b'),
      ]);
      await rig.online();

      expect(rig.writes, ['reorder $id']);
      expect(
        (rig.server.requests.single.body! as api.ReorderPlaylistItemsRequest)
            .playbackIds,
        ['a', 'b'],
      );
    });

    test('is not offered when an item lacks a playbackId', () {
      const summary = PlaylistSummary(
        id: 'pl-1',
        name: 'Road',
        trackCount: 2,
        isOwner: true,
        isPublic: false,
      );
      PlaylistItem item(Track track) =>
          PlaylistItem(id: 'i', sort: 0, track: track, isPlayable: true);

      expect(
        canReorderPlaylist(
          PlaylistDetail(summary: summary, items: [item(_track('a'))]),
        ),
        isTrue,
      );
      expect(
        canReorderPlaylist(
          PlaylistDetail(
            summary: summary,
            items: [
              item(_track('a')),
              item(_track('b').copyWith(playbackId: null)),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        canReorderPlaylist(
          PlaylistDetail(
            summary: summary.copyWith(isOwner: false),
            items: [item(_track('a'))],
          ),
        ),
        isFalse,
      );
    });
  });

  test('liked rejects all six', () async {
    final repository = rig.repository;
    const liked = 'liked';
    final item = PlaylistItem(
      id: 'i',
      sort: 0,
      track: _track('a'),
      isPlayable: true,
    );
    for (final call in <Future<Object?> Function()>[
      () => repository.rename(liked, 'x'),
      () => repository.delete(liked),
      () => repository.addTracks(liked, [_track('a')]),
      () => repository.removeItem(liked, item),
      () => repository.reorder(liked, const [PlaybackId('a')]),
    ]) {
      await expectLater(call(), throwsArgumentError);
    }
    // create never takes an id; it can never produce `liked`.
    expect(await repository.create('Liked'), isNot(liked));
    expect([
      for (final entry in await rig.store.pending())
        if (entry.op is! PlaylistCreateOp) entry,
    ], isEmpty);
  });
}
