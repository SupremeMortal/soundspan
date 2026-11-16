// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/data/plays_repository.dart';
import 'package:soundspan/core/sync/data/preference_remote_source.dart';
import 'package:soundspan/core/sync/data/preference_repository.dart';
import 'package:soundspan/core/sync/data/sync_outbox_handlers.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/library/cached_library_repository.dart';
import 'package:soundspan/shared/data/library/library_remote_source.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/data/preference_overlay.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';
import '../outbox/outbox_test_support.dart' show ManualTimer;

const _album = Album(
  id: 'al-1',
  title: 'First Light',
  artistName: 'Contract Aurora',
  artistId: 'ar-1',
);

Track _track(String id, {Preference preference = Preference.neutral}) => Track(
  meta: TrackMeta(
    title: 'Song $id',
    artist: 'Contract Aurora',
    album: 'First Light',
    durationSec: 30,
  ),
  playbackId: PlaybackId(id),
  albumId: 'al-1',
  preference: preference,
);

/// The album detail as the server answers it; counts the fetches.
final class _LibrarySource implements LibraryRemoteSource {
  int albumFetches = 0;

  @override
  Future<AlbumDetail> album(String id) async {
    albumFetches++;
    return AlbumDetail(
      album: _album,
      tracks: [_track('p1'), _track('p2')],
      owned: true,
    );
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final class _NoPlayback implements api.PlaybackClient {
  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A profile's outbox, cache and library repository over in-memory
/// databases, with [FakeApi] behind the preference endpoints.
final class _Rig {
  new()
    : state = StateDatabase(NativeDatabase.memory()),
      cacheDb = CacheDatabase(NativeDatabase.memory()),
      clock = FakeClock(),
      reachability = FakeReachability(),
      fakeApi = FakeApi(),
      source = _LibrarySource() {
    cache = CacheStore(cacheDb, clock);
    store = OutboxStore(state, clock);
    library = CachedLibraryRepository(
      source,
      cache,
      Swr(clock: clock, reachability: reachability),
      PagedSources(cache, clock, reachability),
      pending: (opTypes) => store.watchPending(opTypes: opTypes),
    );
    worker = OutboxWorker(
      store,
      OutboxHandlerRegistry(
        syncOutboxHandlers(
          PreferenceRemoteSource(fakeApi.library),
          PlaysRepository(_NoPlayback()),
          (store: () async => cache, library: () async => library),
        ),
      ),
      reachability,
      clock,
      AppLogger.scope('PreferenceTest'),
      rewriter: TempIdRewriter(state, () async => cacheDb),
      periodicTimer: ManualTimer.new,
    );
    repository = PreferenceRepository(Outbox(store, worker));
  }

  final StateDatabase state;
  final CacheDatabase cacheDb;
  final FakeClock clock;
  final FakeReachability reachability;
  final FakeApi fakeApi;
  final _LibrarySource source;
  late final CacheStore cache;
  late final OutboxStore store;
  late final CachedLibraryRepository library;
  late final OutboxWorker worker;
  late final PreferenceRepository repository;

  /// Caches the songs list (p1, p2), the liked list (p3) and the album.
  Future<void> seed({Preference p1 = Preference.neutral}) async {
    await cache.writePage(
      const TrackQuery().listKey,
      offset: 0,
      items: [
        _track('p1', preference: p1),
        _track('p2'),
      ],
      total: 2,
      complete: true,
    );
    await cache.writePage(
      'liked',
      offset: 0,
      items: [_track('p3', preference: Preference.liked)],
      total: 1,
      complete: true,
    );
    await cache.upsertAlbums([_album], detail: true);
    await cache.putBlob(
      'album:al-1',
      AlbumDetail(
        album: _album,
        tracks: [
          _track('p1', preference: p1),
          _track('p2'),
        ],
        owned: true,
      ),
    );
  }

  /// Waits for the worker's pass and the cache's watch queries.
  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await worker.idle;
      await pumpEventQueue();
    }
  }

  Future<void> close() async {
    await worker.dispose();
    await state.close();
    await cacheDb.close();
  }
}

/// Every emission of a paged list, read as the preference of [id] (null
/// when the track is not in the list) and the list's ids.
final class _ListLog {
  new(PagedSource<Track> source, this.id) {
    _sub = source.watch().listen(snapshots.add);
  }

  final String id;
  final List<PagedSnapshot<Track>> snapshots = [];
  late final StreamSubscription<PagedSnapshot<Track>> _sub;

  Preference? preferenceIn(PagedSnapshot<Track> snapshot) {
    for (final track in snapshot.loaded.values) {
      if (track.playbackId == PlaybackId(id)) return track.preference;
    }
    return null;
  }

  List<Preference?> get preferences => [
    for (final snapshot in snapshots) preferenceIn(snapshot),
  ];

  Preference? get latest => preferenceIn(snapshots.last);

  List<String> get latestIds {
    final snapshot = snapshots.last;
    return [
      for (var i = 0; i < (snapshot.total ?? 0); i++)
        ?snapshot.itemAt(i)?.playbackId?.value,
    ];
  }

  Future<void> cancel() => _sub.cancel();
}

/// Waits until a dropped op is no longer held (`preferenceHold`).
Future<void> _afterHold() async {
  await Future<void>.delayed(preferenceHold + const Duration(milliseconds: 50));
  await pumpEventQueue();
}

void main() {
  late _Rig rig;

  setUp(() async {
    rig = _Rig();
    await rig.seed();
  });

  tearDown(() => rig.close());

  Future<List<PreferenceOp>> pendingPreferenceOps() async => [
    for (final entry in await rig.store.pending())
      if (entry.op case final PreferenceOp op) op,
  ];

  test('a like enqueues one thumbs_up op with the track metadata', () async {
    await rig.repository.setTrackLiked(_track('p1'), liked: true);

    final ops = await pendingPreferenceOps();
    expect(ops, hasLength(1));
    expect(ops.single.playbackId, 'p1');
    expect(ops.single.signal, PreferenceSignal.thumbsUp);
    expect(ops.single.metadata, _track('p1').meta.toJson());
  });

  test('an unlike enqueues clear', () async {
    await rig.repository.setTrackLiked(
      _track('p3', preference: Preference.liked),
      liked: false,
    );

    expect(
      (await pendingPreferenceOps()).single.signal,
      PreferenceSignal.clear,
    );
  });

  test('a like then an unlike before sending leaves one clear op', () async {
    await rig.repository.setTrackLiked(_track('p1'), liked: true);
    await rig.repository.setTrackLiked(_track('p1'), liked: false);

    final ops = await pendingPreferenceOps();
    expect(ops, hasLength(1));
    expect(ops.single.signal, PreferenceSignal.clear);
  });

  test('a track without a playbackId cannot be liked', () async {
    final track = _track('p1').copyWith(playbackId: null);

    await expectLater(
      rig.repository.setTrackLiked(track, liked: true),
      throwsStateError,
    );
    expect(await rig.store.pending(), isEmpty);
  });

  test('a disliked track liked sends thumbs_up, never thumbs_down', () async {
    final disliked = _track('p1', preference: Preference.disliked);

    await rig.repository.setTrackLiked(disliked, liked: true);

    expect(
      (await pendingPreferenceOps()).single.signal,
      PreferenceSignal.thumbsUp,
    );
  });

  test('a track list shows the like before the server answers', () async {
    final gate = rig.fakeApi.library.gate = Completer<void>();
    unawaited(rig.worker.start());
    final log = _ListLog(rig.library.tracks(const TrackQuery()), 'p1');
    await rig.settle();
    expect(log.latest, Preference.neutral);

    await rig.repository.setTrackLiked(_track('p1'), liked: true);
    await pumpEventQueue();

    expect(rig.fakeApi.library.requests, hasLength(1));
    expect(rig.fakeApi.library.tracks, isEmpty, reason: 'not answered yet');
    expect(log.latest, Preference.liked);
    gate.complete();
    await rig.settle();
    await log.cancel();
  });

  test('on success the cache holds the server state and the list never '
      'flips back', () async {
    unawaited(rig.worker.start());
    final log = _ListLog(rig.library.tracks(const TrackQuery()), 'p1');
    await rig.settle();

    await rig.repository.setTrackLiked(_track('p1'), liked: true);
    await rig.settle();

    expect(rig.fakeApi.library.tracks['p1'], 'liked');
    expect(await rig.store.pending(), isEmpty);
    final row = await rig.cache.watchTrack('p1').first;
    expect(row!.value.preference, Preference.liked);
    expect(log.latest, Preference.liked);
    final firstLiked = log.preferences.indexOf(Preference.liked);
    expect(
      log.preferences.skip(firstLiked),
      everyElement(Preference.liked),
      reason: 'no intermediate unliked emission',
    );
    await log.cancel();
  });

  test('on success the album detail blob holds the server state', () async {
    unawaited(rig.worker.start());
    await rig.settle();

    await rig.repository.setTrackLiked(_track('p1'), liked: true);
    await rig.settle();

    final detail = await rig.library.album('al-1').first;
    expect(detail.value.tracks.first.preference, Preference.liked);
  });

  for (final (name, error) in [
    ('404', const api.NotFound(status: 404) as api.ApiException),
    ('409', const api.Conflict(status: 409)),
  ]) {
    test('a $name rolls the like back', () async {
      rig.fakeApi.library.failures.add(error);
      unawaited(rig.worker.start());
      final log = _ListLog(rig.library.tracks(const TrackQuery()), 'p1');
      await rig.settle();

      await rig.repository.setTrackLiked(_track('p1'), liked: true);
      await rig.settle();
      await _afterHold();

      expect(await rig.store.pending(), isEmpty);
      expect(log.latest, Preference.neutral);
      expect(log.preferences, contains(Preference.liked));
      expect(rig.source.albumFetches, name == '409' ? 1 : 0);
      await log.cancel();
    });
  }

  test('offline the op stays pending with its overlay and is sent when the '
      'server is reachable again', () async {
    rig.reachability.set(Reachability.noNetwork);
    unawaited(rig.worker.start());
    final log = _ListLog(rig.library.tracks(const TrackQuery()), 'p1');
    await rig.settle();

    await rig.repository.setTrackLiked(_track('p1'), liked: true);
    await rig.settle();

    expect(await rig.store.pending(), hasLength(1));
    expect(log.latest, Preference.liked);
    expect(rig.fakeApi.library.requests, isEmpty);

    rig.reachability.set(Reachability.online);
    await rig.settle();

    expect(rig.fakeApi.library.requests, hasLength(1));
    expect(await rig.store.pending(), isEmpty);
    expect(log.latest, Preference.liked);
    await log.cancel();
  });

  test('the liked list gains a track liked and loses one unliked while '
      'pending', () async {
    rig.reachability.set(Reachability.serverUnreachable);
    final log = _ListLog(rig.library.likedTracks(), 'p1');
    await rig.settle();
    expect(log.latestIds, ['p3']);

    await rig.repository.setTrackLiked(_track('p1'), liked: true);
    await rig.settle();
    expect(log.latestIds, ['p1', 'p3']);
    expect(log.latest, Preference.liked);

    await rig.repository.setTrackLiked(
      _track('p3', preference: Preference.liked),
      liked: false,
    );
    await rig.settle();
    expect(log.latestIds, ['p1']);
    expect(log.snapshots.last.total, 1);
    await log.cancel();
  });

  test('a like marks the liked list stale on success', () async {
    unawaited(rig.worker.start());
    await rig.settle();
    rig.clock.set(DateTime.utc(2025, 1, 1, 0, 1));

    await rig.repository.setTrackLiked(_track('p1'), liked: true);
    await rig.settle();

    final list = await rig.cache.watchList('liked').first;
    expect(list!.fetchedAt, DateTime.utc(1970));
  });

  group('album', () {
    Future<Preference> albumPreference() async =>
        (await rig.library.album('al-1').first).value.album.preference;

    test(
      'a like enqueues one albumPreference op; an unlike sends clear',
      () async {
        await rig.repository.setAlbumLiked('al-1', liked: true);
        var ops = await rig.store.pending();
        expect(
          ops.single.op,
          const AlbumPreferenceOp(
            albumId: 'al-1',
            signal: PreferenceSignal.thumbsUp,
          ),
        );

        await rig.repository.setAlbumLiked('al-1', liked: false);
        ops = await rig.store.pending();
        expect(
          ops.single.op,
          const AlbumPreferenceOp(
            albumId: 'al-1',
            signal: PreferenceSignal.clear,
          ),
        );
      },
    );

    test('the album shows the like before the server answers', () async {
      await rig.repository.setAlbumLiked('al-1', liked: true);

      expect(await albumPreference(), Preference.liked);
    });

    test('on success the album row and detail hold the server state', () async {
      unawaited(rig.worker.start());
      await rig.settle();

      await rig.repository.setAlbumLiked('al-1', liked: true);
      await rig.settle();

      expect(rig.fakeApi.library.albums['al-1'], 'liked');
      expect(await rig.store.pending(), isEmpty);
      expect(await albumPreference(), Preference.liked);
      final row = await rig.cache.watchAlbum('al-1').first;
      expect(row!.value.preference, Preference.liked);
    });

    for (final (name, error) in [
      ('404', const api.NotFound(status: 404) as api.ApiException),
      ('409', const api.Conflict(status: 409)),
    ]) {
      test('a $name rolls the album like back', () async {
        rig.fakeApi.library.failures.add(error);
        unawaited(rig.worker.start());
        await rig.settle();

        await rig.repository.setAlbumLiked('al-1', liked: true);
        await rig.settle();
        await _afterHold();

        expect(await rig.store.pending(), isEmpty);
        expect(await albumPreference(), Preference.neutral);
        expect(rig.source.albumFetches, name == '409' ? 1 : 0);
      });
    }
  });

  test('handlers write nothing for drops other than a conflict', () async {
    final handler = TrackPreferenceHandler(
      PreferenceRemoteSource(rig.fakeApi.library),
      (
        store: () => throw StateError('not read'),
        library: () => throw StateError('not read'),
      ),
    );

    await handler.onDropped(
      PreferenceOp(
        playbackId: 'p1',
        signal: PreferenceSignal.thumbsUp,
        metadata: _track('p1').meta.toJson(),
      ),
      OutboxDropReason.notFound,
    );
  });
}
