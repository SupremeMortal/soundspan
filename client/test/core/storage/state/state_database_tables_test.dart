// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

final _at = DateTime.utc(2025, 1, 2, 3, 4, 5, 678);

DownloadItemsCompanion _item(
  String itemKey, {
  MediaType mediaType = MediaType.track,
  DownloadStatus status = DownloadStatus.queued,
}) => DownloadItemsCompanion.insert(
  itemKey: itemKey,
  mediaType: mediaType,
  metaJson: '{}',
  status: status,
  requestedAt: _at,
);

DownloadCollectionsCompanion _collection(String kind, String refId) =>
    DownloadCollectionsCompanion.insert(
      kind: kind,
      refId: refId,
      title: 'Title $refId',
      metaJson: '{}',
      status: 'resolving',
      requestedAt: _at,
    );

DownloadMembershipCompanion _member(
  String kind,
  String refId,
  String itemKey,
) => DownloadMembershipCompanion.insert(
  kind: kind,
  refId: refId,
  itemKey: itemKey,
  position: 0,
);

void main() {
  late StateDatabase db;

  setUp(() => db = StateDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('device_settings: upsert by key replaces the value', () async {
    await db
        .into(db.deviceSettings)
        .insertOnConflictUpdate(
          DeviceSettingsCompanion.insert(key: 'playback.volume', value: '0.5'),
        );
    await db
        .into(db.deviceSettings)
        .insertOnConflictUpdate(
          DeviceSettingsCompanion.insert(key: 'playback.volume', value: '0.8'),
        );

    final rows = await db.select(db.deviceSettings).get();
    expect(rows.map((r) => (r.key, r.value)), [('playback.volume', '0.8')]);
  });

  test('queue_snapshot: 5,000 rows insert in one transaction and read back in '
      'position order; a duplicate queueItemId is rejected', () async {
    await db.transaction(() async {
      await db.batch((b) {
        // Inserted in reverse so the read order comes from `position`.
        for (var i = 4999; i >= 0; i--) {
          b.insert(
            db.queueSnapshot,
            QueueSnapshotCompanion.insert(
              position: Value(i),
              queueItemId: 'q$i',
              kind: i.isEven ? 'track' : 'episode',
              itemJson: '{"i":$i}',
            ),
          );
        }
      });
    });

    final rows = await (db.select(
      db.queueSnapshot,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    expect(rows, hasLength(5000));
    expect(rows.first.queueItemId, 'q0');
    expect(rows.last.queueItemId, 'q4999');
    expect(rows.map((r) => r.position), List.generate(5000, (i) => i));

    await expectLater(
      db
          .into(db.queueSnapshot)
          .insert(
            QueueSnapshotCompanion.insert(
              position: const Value(5000),
              queueItemId: 'q0',
              kind: 'track',
              itemJson: '{}',
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('queue_meta: a row with id 2 is rejected; defaults hold', () async {
    await expectLater(
      db
          .into(db.queueMeta)
          .insert(
            QueueMetaCompanion.insert(id: const Value(2), updatedAt: _at),
          ),
      throwsA(isA<SqliteException>()),
    );

    await db
        .into(db.queueMeta)
        .insert(QueueMetaCompanion.insert(id: const Value(1), updatedAt: _at));
    final row = await db.select(db.queueMeta).getSingle();
    expect(row.id, 1);
    expect(row.positionMs, 0);
    expect(row.repeatMode, 'off');
    expect(row.revision, 0);
    expect(row.currentQueueItemId, isNull);
    expect(row.shuffleOrderJson, isNull);
    expect(row.contextJson, isNull);
    expect(row.updatedAt, _at);
  });

  test('download_collections: a duplicate (kind, refId) is rejected; '
      'blockedReason and detailJson default to null and round-trip', () async {
    await db.into(db.downloadCollections).insert(_collection('album', 'a1'));
    // Same refId under another kind is a different collection.
    await db.into(db.downloadCollections).insert(_collection('playlist', 'a1'));
    await expectLater(
      db.into(db.downloadCollections).insert(_collection('album', 'a1')),
      throwsA(isA<SqliteException>()),
    );

    final plain = await (db.select(
      db.downloadCollections,
    )..where((t) => t.kind.equals('album'))).getSingle();
    expect(plain.blockedReason, isNull);
    expect(plain.detailJson, isNull);
    expect(plain.quality, isNull);
    expect(plain.resolvedAt, isNull);

    const detail = '{"usedBytes":1,"quotaBytes":2,"requestedBytes":3}';
    await (db.update(
      db.downloadCollections,
    )..where((t) => t.kind.equals('playlist'))).write(
      DownloadCollectionsCompanion(
        status: const Value('blocked'),
        blockedReason: const Value('serverQuota'),
        detailJson: const Value(detail),
        resolvedAt: Value(_at),
      ),
    );
    final blocked = await (db.select(
      db.downloadCollections,
    )..where((t) => t.kind.equals('playlist'))).getSingle();
    expect(blocked.status, 'blocked');
    expect(blocked.blockedReason, 'serverQuota');
    expect(blocked.detailJson, detail);
    expect(blocked.resolvedAt, _at);
  });

  test('download_items: defaults; waitingFor and failureCode are independent; '
      'every DownloadStatus and MediaType round-trips', () async {
    await db.into(db.downloadItems).insert(_item('t:p1'));
    final row = await db.select(db.downloadItems).getSingle();
    expect(row.receivedBytes, 0);
    expect(row.attempts, 0);
    expect(row.serverConfirmed, isFalse);
    expect(row.waitingFor, isNull);
    expect(row.failureCode, isNull);

    await db
        .update(db.downloadItems)
        .write(const DownloadItemsCompanion(waitingFor: Value('wifi')));
    var updated = await db.select(db.downloadItems).getSingle();
    expect((updated.waitingFor, updated.failureCode), ('wifi', null));

    await db
        .update(db.downloadItems)
        .write(
          const DownloadItemsCompanion(
            waitingFor: Value(null),
            failureCode: Value('SOURCE_UNAVAILABLE'),
          ),
        );
    updated = await db.select(db.downloadItems).getSingle();
    expect(
      (updated.waitingFor, updated.failureCode),
      (null, 'SOURCE_UNAVAILABLE'),
    );

    var n = 0;
    for (final type in MediaType.values) {
      for (final status in DownloadStatus.values) {
        final key = 'k${n++}';
        await db
            .into(db.downloadItems)
            .insert(_item(key, mediaType: type, status: status));
        final read = await (db.select(
          db.downloadItems,
        )..where((t) => t.itemKey.equals(key))).getSingle();
        expect((read.mediaType, read.status), (type, status));
      }
    }
  });

  test(
    'download_membership: one item in two collections; deleting a collection '
    'removes only its membership; a dangling membership is rejected',
    () async {
      await db.into(db.downloadItems).insert(_item('t:p1'));
      await db.into(db.downloadCollections).insert(_collection('album', 'a1'));
      await db
          .into(db.downloadCollections)
          .insert(_collection('playlist', 'l1'));
      await db
          .into(db.downloadMembership)
          .insert(_member('album', 'a1', 't:p1'));
      await db
          .into(db.downloadMembership)
          .insert(_member('playlist', 'l1', 't:p1'));

      await (db.delete(
        db.downloadCollections,
      )..where((t) => t.kind.equals('album'))).go();

      final members = await db.select(db.downloadMembership).get();
      expect(members.map((m) => (m.kind, m.refId, m.itemKey)), [
        ('playlist', 'l1', 't:p1'),
      ]);
      expect(await db.select(db.downloadItems).get(), hasLength(1));

      await expectLater(
        db
            .into(db.downloadMembership)
            .insert(_member('playlist', 'l1', 't:missing')),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        db
            .into(db.downloadMembership)
            .insert(_member('album', 'missing', 't:p1')),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test('outbox: seq increases in insertion order and is not reused after a '
      'delete', () async {
    OutboxCompanion op(String key) => OutboxCompanion.insert(
      opType: 'pref.set',
      entityKey: key,
      payloadJson: '{}',
      createdAt: _at,
    );

    final first = await db.into(db.outbox).insert(op('a'));
    final second = await db.into(db.outbox).insert(op('b'));
    expect(second, greaterThan(first));

    await (db.delete(db.outbox)..where((t) => t.seq.equals(second))).go();
    final third = await db.into(db.outbox).insert(op('c'));
    expect(third, greaterThan(second));

    final row = await (db.select(
      db.outbox,
    )..where((t) => t.seq.equals(third))).getSingle();
    expect(row.attempts, 0);
    expect(row.nextAttemptAt, isNull);
    expect(row.lastError, isNull);
  });

  test(
    'play_sessions: playedAt round-trips to the millisecond in UTC',
    () async {
      final playedAt = DateTime.utc(2025, 6, 7, 8, 9, 10, 123);
      await db
          .into(db.playSessions)
          .insert(
            PlaySessionsCompanion.insert(
              sessionId: 's1',
              queueItemId: 'q1',
              playbackId: 'tidal:123',
              metaJson: '{}',
              playedAt: playedAt,
              updatedAt: _at,
            ),
          );

      final row = await db.select(db.playSessions).getSingle();
      expect(row.playedAt.isUtc, isTrue);
      expect(row.playedAt, playedAt);
      expect(row.listenedMs, 0);
      expect(row.playbackId, 'tidal:123');

      final stored = await db
          .customSelect('SELECT played_at FROM play_sessions')
          .getSingle();
      expect(stored.read<String>('played_at'), '2025-06-07T08:09:10.123Z');
    },
  );

  test('search_history: Jazz and jazz are the same row', () async {
    await db
        .into(db.searchHistory)
        .insertOnConflictUpdate(
          SearchHistoryCompanion.insert(query: 'Jazz', lastUsedAt: _at),
        );
    final later = _at.add(const Duration(minutes: 1));
    await db
        .into(db.searchHistory)
        .insertOnConflictUpdate(
          SearchHistoryCompanion.insert(query: 'jazz', lastUsedAt: later),
        );

    final rows = await db.select(db.searchHistory).get();
    expect(rows, hasLength(1));
    expect(rows.single.lastUsedAt, later);
    expect(
      await (db.select(
        db.searchHistory,
      )..where((t) => t.query.equals('JAZZ'))).get(),
      hasLength(1),
    );
  });

  test('foreign keys are enforced', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });
}
