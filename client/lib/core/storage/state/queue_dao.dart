// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

/// The persisted queue: its item rows in canonical order and its meta row.
typedef StoredQueue = ({List<QueueSnapshotData> items, QueueMetaData meta});

/// Reads and writes the `queue_snapshot` and `queue_meta` rows of a
/// profile's `state.db` (doc 05, doc 06 Local Queue Persistence).
class QueueDao {
  /// Creates the accessor over [_database].
  new(this._database);

  final StateDatabase _database;

  /// The stored queue, or null when there is no meta row.
  Future<StoredQueue?> read() async {
    final meta = await _database.select(_database.queueMeta).getSingleOrNull();
    if (meta == null) return null;
    final items = await (_database.select(
      _database.queueSnapshot,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    return (items: items, meta: meta);
  }

  /// Replaces every item row with [items] and writes [meta], in one
  /// transaction.
  Future<void> replace(List<QueueSnapshotData> items, QueueMetaData meta) =>
      _database.transaction(() async {
        await _database.batch((batch) {
          batch
            ..deleteAll(_database.queueSnapshot)
            ..insertAll(_database.queueSnapshot, items)
            ..insert(
              _database.queueMeta,
              meta,
              mode: InsertMode.insertOrReplace,
            );
        });
      });

  /// Writes [meta] alone, keeping the item rows.
  Future<void> writeMeta(QueueMetaData meta) => _database
      .into(_database.queueMeta)
      .insert(meta, mode: InsertMode.insertOrReplace);

  /// Deletes every item row and the meta row.
  Future<void> clear() => _database.transaction(() async {
    await _database.delete(_database.queueSnapshot).go();
    await _database.delete(_database.queueMeta).go();
  });
}
