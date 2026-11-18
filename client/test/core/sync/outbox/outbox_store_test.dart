// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';

import '../../../helpers/fake_clock.dart';
import '../../logging/recording_sink.dart';
import '../../profile/profile_harness.dart';

const _meta = <String, Object?>{'title': 'Song'};

PreferenceOp _pref(String id, PreferenceSignal signal) =>
    PreferenceOp(playbackId: id, signal: signal, metadata: _meta);

PlaylistAddOp _add(String playlistId, String opUuid) => PlaylistAddOp(
  playlistId: playlistId,
  opUuid: opUuid,
  playbackId: 'pb:$opUuid',
  metadata: _meta,
);

PlaylistRemoveOp _remove(String playlistId, String opUuid) => PlaylistRemoveOp(
  playlistId: playlistId,
  opUuid: opUuid,
  playbackId: 'pb:$opUuid',
);

OfflineDeleteOp _offlineDelete(
  Iterable<int> ids, {
  String batchUuid = 'b',
  String deviceId = 'd1',
}) => OfflineDeleteOp(
  batchUuid: batchUuid,
  deviceId: deviceId,
  playbackIds: [for (final i in ids) 'pb:$i'],
);

void main() {
  late StateDatabase db;
  late FakeClock clock;
  late OutboxStore store;

  setUp(() {
    db = StateDatabase(NativeDatabase.memory());
    clock = FakeClock();
    store = OutboxStore(db, clock);
  });
  tearDown(() => db.close());

  Future<List<OutboxOp>> ops() async => [
    for (final e in await store.pending()) e.op,
  ];

  group('coalescing', () {
    test('preference: the second write for the same playbackId replaces the '
        'first; different ids both stay', () async {
      await store.enqueue(_pref('pb:1', PreferenceSignal.thumbsUp));
      await store.enqueue(_pref('pb:2', PreferenceSignal.thumbsUp));
      await store.enqueue(_pref('pb:1', PreferenceSignal.clear));
      expect(await ops(), [
        _pref('pb:2', PreferenceSignal.thumbsUp),
        _pref('pb:1', PreferenceSignal.clear),
      ]);
    });

    test('albumPreference: last write wins', () async {
      await store.enqueue(
        const AlbumPreferenceOp(
          albumId: 'a',
          signal: PreferenceSignal.thumbsUp,
        ),
      );
      await store.enqueue(
        const AlbumPreferenceOp(albumId: 'a', signal: PreferenceSignal.clear),
      );
      expect(await ops(), [
        const AlbumPreferenceOp(albumId: 'a', signal: PreferenceSignal.clear),
      ]);
    });

    test('play: two ops with the same payload both stay', () async {
      final play = PlayOp(
        sessionId: 's',
        playbackId: 'pb:1',
        metadata: _meta,
        playedAt: DateTime.utc(2025),
        listenedMs: 1000,
      );
      final first = await store.enqueue(play);
      final second = await store.enqueue(play);
      expect(second, isNot(first));
      expect(await ops(), [play, play]);
    });

    test('playlistCreate: stored; two creates with different temporary ids '
        'both stay', () async {
      const a = PlaylistCreateOp(tempId: 'tmp_a', name: 'A');
      const b = PlaylistCreateOp(tempId: 'tmp_b', name: 'B', isPublic: false);
      expect(await store.enqueue(a), isNotNull);
      await store.enqueue(b);
      expect(await ops(), [a, b]);
    });

    test('playlistRename: last write wins and moves to the tail', () async {
      await store.enqueue(const PlaylistRenameOp(playlistId: 'p', name: 'x'));
      await store.enqueue(_add('p', 'u1'));
      await store.enqueue(const PlaylistRenameOp(playlistId: 'p', name: 'y'));
      expect(await ops(), [
        _add('p', 'u1'),
        const PlaylistRenameOp(playlistId: 'p', name: 'y'),
      ]);
    });

    test('playlistDelete: removes pending rename, add, remove and reorder for '
        "that playlist and keeps other playlists' ops", () async {
      await store.enqueue(const PlaylistRenameOp(playlistId: 'p', name: 'x'));
      await store.enqueue(_add('p', 'u1'));
      await store.enqueue(_remove('p', 'u2'));
      await store.enqueue(
        const PlaylistReorderOp(playlistId: 'p', playbackIds: ['a']),
      );
      await store.enqueue(const PlaylistRenameOp(playlistId: 'q', name: 'z'));
      await store.enqueue(_add('q', 'u3'));
      await store.enqueue(_pref('p', PreferenceSignal.thumbsUp));

      final seq = await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));

      expect(seq, isNotNull);
      expect(await ops(), [
        const PlaylistRenameOp(playlistId: 'q', name: 'z'),
        _add('q', 'u3'),
        _pref('p', PreferenceSignal.thumbsUp),
        const PlaylistDeleteOp(playlistId: 'p'),
      ]);
    });

    test('playlistDelete: with a pending create for the same temporary id, '
        'nothing remains and enqueue returns null', () async {
      await store.enqueue(const PlaylistCreateOp(tempId: 'tmp_a', name: 'A'));
      await store.enqueue(
        const PlaylistRenameOp(playlistId: 'tmp_a', name: 'B'),
      );
      await store.enqueue(_add('tmp_a', 'u1'));
      await store.enqueue(const PlaylistCreateOp(tempId: 'tmp_b', name: 'B'));

      final seq = await store.enqueue(
        const PlaylistDeleteOp(playlistId: 'tmp_a'),
      );

      expect(seq, isNull);
      expect(await ops(), [const PlaylistCreateOp(tempId: 'tmp_b', name: 'B')]);
    });

    test('playlistAdd + playlistRemove with the same opUuid: both gone; '
        'remove with another opUuid: both stay', () async {
      await store.enqueue(_add('p', 'u1'));
      expect(await store.enqueue(_remove('p', 'u1')), isNull);
      expect(await ops(), isEmpty);

      await store.enqueue(_add('p', 'u1'));
      expect(await store.enqueue(_remove('p', 'u2')), isNotNull);
      expect(await ops(), [_add('p', 'u1'), _remove('p', 'u2')]);
    });

    test('playlistAdd + playlistRemove: the same opUuid on another playlist '
        'does not cancel', () async {
      await store.enqueue(_add('p', 'u1'));
      await store.enqueue(_remove('q', 'u1'));
      expect(await ops(), [_add('p', 'u1'), _remove('q', 'u1')]);
    });

    test('playlistRemove alone: stored', () async {
      expect(await store.enqueue(_remove('p', 'u1')), isNotNull);
      expect(await ops(), [_remove('p', 'u1')]);
    });

    test('playlistReorder: last write wins and takes a seq after an add '
        'enqueued in between', () async {
      await store.enqueue(
        const PlaylistReorderOp(playlistId: 'p', playbackIds: ['a', 'b']),
      );
      await store.enqueue(_add('p', 'u1'));
      await store.enqueue(
        const PlaylistReorderOp(playlistId: 'p', playbackIds: ['b', 'a']),
      );
      expect(await ops(), [
        _add('p', 'u1'),
        const PlaylistReorderOp(playlistId: 'p', playbackIds: ['b', 'a']),
      ]);
    });

    test('episodeProgress: last write wins per episode', () async {
      EpisodeProgressOp progress(String episodeId, double at) =>
          EpisodeProgressOp(
            podcastId: 'pod',
            episodeId: episodeId,
            currentTime: at,
            duration: 100,
            isFinished: false,
          );
      await store.enqueue(progress('e1', 1));
      await store.enqueue(progress('e2', 2));
      await store.enqueue(progress('e1', 3));
      expect(await ops(), [progress('e2', 2), progress('e1', 3)]);
    });

    test('offlineComplete: last write wins per playbackId', () async {
      OfflineCompleteOp complete(String id, int size) => OfflineCompleteOp(
        deviceId: 'd1',
        playbackId: id,
        quality: 'original',
        sizeBytes: size,
      );
      await store.enqueue(complete('pb:1', 1));
      await store.enqueue(complete('pb:2', 2));
      await store.enqueue(complete('pb:1', 3));
      expect(await ops(), [complete('pb:2', 2), complete('pb:1', 3)]);
    });

    test('a replaced op starts again with no attempts', () async {
      final seq = await store.enqueue(_pref('pb:1', PreferenceSignal.thumbsUp));
      await store.recordFailure(seq!, nextAttemptAt: DateTime.utc(2030));
      await store.enqueue(_pref('pb:1', PreferenceSignal.clear));
      final [entry] = await store.pending();
      expect(entry.seq, greaterThan(seq));
      expect(entry.attempts, 0);
      expect(entry.nextAttemptAt, isNull);
    });

    group('offlineDelete', () {
      test('300 + 150 ids merge into one op', () async {
        await store.enqueue(_offlineDelete(List.generate(300, (i) => i)));
        await store.enqueue(
          _offlineDelete(List.generate(150, (i) => 300 + i), batchUuid: 'c'),
        );
        final all = await ops();
        expect(all, hasLength(1));
        final op = all.single as OfflineDeleteOp;
        expect(op.batchUuid, 'b');
        expect(op.playbackIds, [for (var i = 0; i < 450; i++) 'pb:$i']);
      });

      test('450 + 100 leaves one op of 500 and one of 50', () async {
        await store.enqueue(_offlineDelete(List.generate(450, (i) => i)));
        await store.enqueue(
          _offlineDelete(List.generate(100, (i) => 450 + i), batchUuid: 'c'),
        );
        final all = (await ops()).cast<OfflineDeleteOp>();
        expect(all.map((o) => o.playbackIds.length), [500, 50]);
        expect(all.first.playbackIds.last, 'pb:499');
        expect(all.last.playbackIds.first, 'pb:500');
        expect(all.last.batchUuid, isNot(all.first.batchUuid));
        expect(all.map((o) => o.entityKey).toSet(), hasLength(2));
      });

      test('duplicates are dropped', () async {
        await store.enqueue(_offlineDelete([1, 2, 2, 3]));
        await store.enqueue(_offlineDelete([3, 4, 1], batchUuid: 'c'));
        final op = (await ops()).single as OfflineDeleteOp;
        expect(op.playbackIds, ['pb:1', 'pb:2', 'pb:3', 'pb:4']);
      });

      test('a full batch is not merged into', () async {
        await store.enqueue(_offlineDelete(List.generate(500, (i) => i)));
        await store.enqueue(_offlineDelete([600], batchUuid: 'c'));
        final all = (await ops()).cast<OfflineDeleteOp>();
        expect(all.map((o) => o.batchUuid), ['b', 'c']);
      });

      test('more than 500 ids in one op are split into batches', () async {
        await store.enqueue(_offlineDelete(List.generate(1200, (i) => i)));
        final all = (await ops()).cast<OfflineDeleteOp>();
        expect(all.map((o) => o.playbackIds.length), [500, 500, 200]);
        expect(all.map((o) => o.batchUuid).toSet(), hasLength(3));
        expect(all.first.batchUuid, 'b');
      });

      test('batches of another device are not merged', () async {
        await store.enqueue(_offlineDelete([1]));
        await store.enqueue(
          _offlineDelete([2], batchUuid: 'c', deviceId: 'd2'),
        );
        expect(await ops(), hasLength(2));
      });

      test('a batch followed by an offlineComplete of the same device is not '
          'merged into, so a delete never overtakes a completion', () async {
        await store.enqueue(_offlineDelete([1]));
        await store.enqueue(
          const OfflineCompleteOp(
            deviceId: 'd1',
            playbackId: 'pb:2',
            quality: 'original',
            sizeBytes: 1,
          ),
        );
        await store.enqueue(_offlineDelete([2], batchUuid: 'c'));
        expect((await ops()).map((o) => o.opType), [
          'offlineDelete',
          'offlineComplete',
          'offlineDelete',
        ]);
      });

      test('the merged batch moves to the tail with a new seq', () async {
        final first = await store.enqueue(_offlineDelete([1]));
        final merged = await store.enqueue(_offlineDelete([2], batchUuid: 'c'));
        expect(merged, greaterThan(first!));
        expect((await store.pending()).single.seq, merged);
      });
    });
  });

  group('store', () {
    test('pending() is in seq order and records createdAt', () async {
      final a = await store.enqueue(_pref('pb:1', PreferenceSignal.thumbsUp));
      clock.advance(const Duration(seconds: 5));
      final b = await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
      final pending = await store.pending();
      expect(pending.map((e) => e.seq), [a, b]);
      expect(a, lessThan(b!));
      expect(pending.first.createdAt, FakeClock.defaultStart);
      expect(
        pending.last.createdAt,
        FakeClock.defaultStart.add(const Duration(seconds: 5)),
      );
      expect(pending.first.attempts, 0);
      expect(pending.first.lastError, isNull);
    });

    test('head() is the oldest pending op, or null', () async {
      expect(await store.head(), isNull);
      await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
      await store.enqueue(const PlaylistDeleteOp(playlistId: 'q'));
      expect((await store.head())!.op, const PlaylistDeleteOp(playlistId: 'p'));
    });

    test(
      'recordFailure increments attempts and stores the time and error',
      () async {
        final seq = await store.enqueue(
          const PlaylistDeleteOp(playlistId: 'p'),
        );
        await store.recordFailure(
          seq!,
          nextAttemptAt: DateTime.utc(2025, 1, 1, 0, 0, 5),
          lastError: 'Offline',
        );
        await store.recordFailure(seq, nextAttemptAt: DateTime.utc(2025, 1, 2));
        final entry = (await store.head())!;
        expect(entry.attempts, 2);
        expect(entry.nextAttemptAt, DateTime.utc(2025, 1, 2));
        expect(entry.lastError, isNull);
      },
    );

    test('delete removes the op', () async {
      final seq = await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
      await store.delete(seq!);
      expect(await store.pending(), isEmpty);
    });

    test('delete and recordFailure on a missing seq do nothing', () async {
      await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
      await store.delete(999);
      await store.recordFailure(999, nextAttemptAt: DateTime.utc(2030));
      final [entry] = await store.pending();
      expect(entry.attempts, 0);
    });

    test('watchCount emits on every change', () async {
      final counts = <int>[];
      final sub = store.watchCount().listen(counts.add);
      addTearDown(sub.cancel);
      Future<void> settle() => pumpEventQueue();

      await settle();
      final seq = await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
      await settle();
      await store.enqueue(const PlaylistDeleteOp(playlistId: 'q'));
      await settle();
      await store.delete(seq!);
      await settle();
      expect(counts, [0, 1, 2, 1]);
    });

    test('watchPending emits the pending ops, filtered by opType', () async {
      final all = <List<String>>[];
      final deletes = <List<String>>[];
      final subs = [
        store.watchPending().listen(
          (e) => all.add([for (final x in e) x.op.opType]),
        ),
        store
            .watchPending(opTypes: {'playlistDelete'})
            .listen((e) => deletes.add([for (final x in e) x.op.entityKey])),
      ];
      addTearDown(() => Future.wait(subs.map((s) => s.cancel())));

      await pumpEventQueue();
      await store.enqueue(_pref('pb:1', PreferenceSignal.thumbsUp));
      await pumpEventQueue();
      await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
      await pumpEventQueue();

      expect(all.last, ['preference', 'playlistDelete']);
      expect(deletes.last, ['pl:p']);
    });

    test(
      'an undecodable row is logged at severe and removed on read',
      () async {
        final sink = RecordingSink();
        AppLogging.configure(sinks: [sink], releaseMode: false);
        addTearDown(AppLogging.reset);
        await db
            .into(db.outbox)
            .insert(
              OutboxCompanion.insert(
                opType: 'bogus',
                entityKey: 'x',
                payloadJson: '{}',
                createdAt: DateTime.utc(2025),
              ),
            );
        await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));

        final pending = await store.pending();

        expect(pending.map((e) => e.op), [
          const PlaylistDeleteOp(playlistId: 'p'),
        ]);
        expect(await db.select(db.outbox).get(), hasLength(1));
        expect(
          sink.entries.where((e) => e.level == 'severe' && e.scope == 'Outbox'),
          hasLength(1),
        );
      },
    );

    test(
      "enqueue joins a caller's transaction and rolls back with it",
      () async {
        await expectLater(
          db.transaction(() async {
            await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
            throw StateError('rollback');
          }),
          throwsStateError,
        );
        expect(await store.pending(), isEmpty);

        await db.transaction(() async {
          await store.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
          await store.enqueue(const PlaylistDeleteOp(playlistId: 'q'));
        });
        expect(await store.pending(), hasLength(2));
      },
    );

    test('rows survive closing and reopening the database', () async {
      final dir = Directory.systemTemp.createTempSync('outbox_store_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/state.db');

      final first = StateDatabase(NativeDatabase(file));
      final seq = await OutboxStore(
        first,
        clock,
      ).enqueue(_pref('pb:1', PreferenceSignal.thumbsUp));
      await first.close();

      final second = StateDatabase(NativeDatabase(file));
      addTearDown(second.close);
      final [entry] = await OutboxStore(second, clock).pending();
      expect(entry.seq, seq);
      expect(entry.op, _pref('pb:1', PreferenceSignal.thumbsUp));
      expect(entry.createdAt, FakeClock.defaultStart);
    });
  });

  test(
    'outboxStoreProvider is profile-scoped over the profile state.db',
    () async {
      final harness = await ProfileHarness.create();
      final runtime = harness.root.read(profileRuntimeProvider);
      addTearDown(runtime.dispose);

      await runtime.switchTo(harness.a);
      final a = runtime.container!.read(outboxStoreProvider);
      await a.enqueue(const PlaylistDeleteOp(playlistId: 'p'));
      expect(await a.pending(), hasLength(1));

      await runtime.switchTo(harness.b);
      final b = runtime.container!.read(outboxStoreProvider);
      expect(b, isNot(same(a)));
      expect(await b.pending(), isEmpty);
    },
  );
}
