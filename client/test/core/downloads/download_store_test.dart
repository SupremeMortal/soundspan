// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/paths/paths.dart';

final DateTime _at = DateTime.utc(2026, 5, 1, 12);

const DownloadCollectionKind _album = DownloadCollectionKind.album;
const DownloadCollectionKind _playlist = DownloadCollectionKind.playlist;

void main() {
  late StateDatabase db;
  late DownloadStore store;
  final profile = ProfilePaths.derive(
    appSupport: '/support',
    appCache: '/cache',
    profileId: 'p1',
  );

  setUp(() {
    db = StateDatabase(NativeDatabase.memory());
    store = DownloadStore(db, paths: DownloadPaths(profile));
  });
  tearDown(() => db.close());

  Future<void> collection(
    DownloadCollectionKind kind,
    String refId, {
    DownloadCollectionStatus status = DownloadCollectionStatus.ready,
  }) => store.upsertCollection(
    kind: kind,
    refId: refId,
    title: 'T $refId',
    metaJson: '{}',
    status: status,
    requestedAt: _at,
  );

  Future<void> item(
    DownloadItemKey key, {
    DownloadStatus status = DownloadStatus.queued,
    int? expectedBytes,
    int? sizeBytes,
    String? relativePath,
  }) => store.upsertItem(
    key,
    DownloadItemsCompanion(
      metaJson: const Value('{}'),
      status: Value(status),
      expectedBytes: Value(expectedBytes),
      sizeBytes: Value(sizeBytes),
      relativePath: Value(relativePath),
      requestedAt: Value(_at),
    ),
  );

  group('collections', () {
    test('upsert, read, watch and delete', () async {
      final watched = store.watchCollections();
      await collection(
        _album,
        'a1',
        status: DownloadCollectionStatus.resolving,
      );
      var row = (await store.collection(_album, 'a1'))!;
      expect(row.title, 'T a1');
      expect(DownloadStore.statusOf(row), DownloadCollectionStatus.resolving);
      expect(await watched.first, hasLength(1));

      await collection(_album, 'a1');
      row = (await store.collection(_album, 'a1'))!;
      expect(DownloadStore.statusOf(row), DownloadCollectionStatus.ready);

      await store.deleteCollection(_album, 'a1');
      expect(await store.collection(_album, 'a1'), isNull);
    });

    test('a blocked collection records its reason and detail', () async {
      await collection(_playlist, 'p1');
      await store.setCollectionStatus(
        _playlist,
        'p1',
        DownloadCollectionStatus.blocked,
        block: CollectionBlock.serverQuota,
        detail: const {'requiredBytes': 3, 'limitBytes': 2, 'usedBytes': 1},
      );
      var row = (await store.collection(_playlist, 'p1'))!;
      expect(DownloadStore.statusOf(row), DownloadCollectionStatus.blocked);
      expect(DownloadStore.blockOf(row), CollectionBlock.serverQuota);
      expect(DownloadStore.detailOf(row), {
        'requiredBytes': 3,
        'limitBytes': 2,
        'usedBytes': 1,
      });

      await store.setCollectionStatus(
        _playlist,
        'p1',
        DownloadCollectionStatus.ready,
        resolvedAt: _at,
      );
      row = (await store.collection(_playlist, 'p1'))!;
      expect(DownloadStore.blockOf(row), isNull);
      expect(DownloadStore.detailOf(row), isEmpty);
      expect(row.resolvedAt, _at);
    });
  });

  group('membership', () {
    test('an item in two collections survives removing one membership and '
        'is reported orphaned after the second', () async {
      const key = TrackItemKey('pb1');
      await collection(_album, 'a1');
      await collection(_playlist, 'p1');
      await item(key);
      await store.addMembership(_album, 'a1', key, 0);
      await store.addMembership(_playlist, 'p1', key, 3);
      expect(await store.membershipCount(key), 2);

      expect(await store.removeMembershipsOf(_album, 'a1'), isEmpty);
      expect(await store.membershipCount(key), 1);
      expect(await store.item(key), isNotNull);

      expect(await store.removeMembershipsOf(_playlist, 'p1'), [key]);
      expect(await store.membershipCount(key), 0);
    });

    test('watchItemsOf keeps track order', () async {
      await collection(_album, 'a1');
      for (final (id, position) in [('c', 2), ('a', 0), ('b', 1)]) {
        await item(TrackItemKey(id));
        await store.addMembership(_album, 'a1', TrackItemKey(id), position);
      }
      final rows = await store.watchItemsOf(_album, 'a1').first;
      expect([for (final r in rows) r.itemKey], ['t:a', 't:b', 't:c']);
    });

    test('upsertItem derives the media type from the key', () async {
      const episode = EpisodeItemKey(podcastId: 'p', episodeId: 'e');
      await item(episode);
      expect((await store.item(episode))!.mediaType, MediaType.episode);
      await item(const TrackItemKey('t'));
      expect(
        (await store.item(const TrackItemKey('t')))!.mediaType,
        MediaType.track,
      );
    });
  });

  group('completedFile', () {
    test('is null unless the item is completed', () async {
      const key = TrackItemKey('pb1');
      final relative = p.join('media', 'ab', 'x.mp3');
      expect(await store.completedFile(key), isNull);

      await item(key, status: DownloadStatus.verifying, relativePath: relative);
      expect(await store.completedFile(key), isNull);

      await item(key, status: DownloadStatus.completed, relativePath: relative);
      expect(
        await store.completedFile(key),
        p.join('/support', 'profiles', 'p1', relative),
      );
    });

    test('is null without profile paths', () async {
      final noFiles = DownloadStore(db);
      await item(
        const TrackItemKey('pb1'),
        status: DownloadStatus.completed,
        relativePath: 'media/ab/x.mp3',
      );
      expect(await noFiles.completedFile(const TrackItemKey('pb1')), isNull);
    });
  });

  test('committedBytes uses the 8 MB estimate for unknown sizes', () async {
    await item(
      const TrackItemKey('done'),
      status: DownloadStatus.completed,
      sizeBytes: 100,
      expectedBytes: 999,
    );
    await item(const TrackItemKey('q'), expectedBytes: 10);
    await item(const TrackItemKey('unknown'), status: DownloadStatus.running);
    await item(
      const TrackItemKey('paused'),
      status: DownloadStatus.paused,
      expectedBytes: 1,
    );
    await item(
      const TrackItemKey('verifying'),
      status: DownloadStatus.verifying,
      expectedBytes: 2,
    );
    await item(
      const TrackItemKey('failed'),
      status: DownloadStatus.failedPermanent,
      expectedBytes: 1000,
    );
    expect(await store.committedBytes(), 100 + 10 + kUnknownItemBytes + 1 + 2);
    expect(kUnknownItemBytes, 8 * 1024 * 1024);
  });

  group('applyTransition', () {
    test('persists the next state and returns the effects', () async {
      const key = TrackItemKey('pb1');
      await item(key, status: DownloadStatus.verifying);
      final row = (await store.item(key))!;
      final transition = reduce(
        DownloadStore.stateOf(row),
        const VerificationPassed(42, 'media/ab/x.mp3'),
        now: _at,
      );

      final effects = await store.applyTransition(key, transition);

      expect(effects, transition.effects);
      final stored = (await store.item(key))!;
      expect(stored.status, DownloadStatus.completed);
      expect(stored.sizeBytes, 42);
      expect(stored.relativePath, 'media/ab/x.mp3');
      expect(stored.completedAt, _at);
      expect(DownloadStore.stateOf(stored), transition.next);
    });

    test('records waitingFor and failure fields', () async {
      const key = TrackItemKey('pb1');
      await item(key, status: DownloadStatus.running);
      await store.applyTransition(
        key,
        const DownloadTransition(
          DownloadItemState(
            status: DownloadStatus.paused,
            waitingFor: DownloadWaitReason.wifi,
            attempts: 2,
            taskId: 't',
          ),
          [],
        ),
      );
      final stored = (await store.item(key))!;
      expect(stored.waitingFor, 'wifi');
      expect(stored.attempts, 2);
      expect(stored.taskId, 't');
      expect(DownloadStore.stateOf(stored).waitingFor, DownloadWaitReason.wifi);
    });

    test('changes nothing when the item does not exist', () async {
      await expectLater(
        store.applyTransition(
          const TrackItemKey('none'),
          const DownloadTransition(
            DownloadItemState(status: DownloadStatus.completed),
            [],
          ),
        ),
        throwsStateError,
      );
      expect(await store.item(const TrackItemKey('none')), isNull);
    });
  });

  test('itemsByStatus, watchItem, progress and last played', () async {
    const key = TrackItemKey('pb1');
    await item(key, status: DownloadStatus.running);
    await item(const TrackItemKey('other'));
    expect(
      [
        for (final r in await store.itemsByStatus(DownloadStatus.running))
          r.itemKey,
      ],
      ['t:pb1'],
    );

    await store.updateProgress(key, 512);
    await store.touchLastPlayed(key, _at);
    final watched = (await store.watchItem(key).first)!;
    expect(watched.receivedBytes, 512);
    expect(watched.lastPlayedAt, _at);
  });
}
