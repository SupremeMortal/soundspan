// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/util/uuid.dart';

final AppLogger _log = AppLogger.scope('Outbox');

/// One pending row of the outbox.
@immutable
final class OutboxEntry {
  /// Creates the entry.
  const new({
    required this.seq,
    required this.op,
    required this.createdAt,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
  });

  /// Its position in the queue; never reused.
  final int seq;

  /// The operation.
  final OutboxOp op;

  /// When it was enqueued, in UTC.
  final DateTime createdAt;

  /// Failed delivery attempts so far.
  final int attempts;

  /// When the next attempt may run, in UTC, if it is delayed.
  final DateTime? nextAttemptAt;

  /// The last delivery error.
  final String? lastError;

  @override
  String toString() => 'OutboxEntry($seq, $op, attempts: $attempts)';
}

/// The durable, ordered queue of writes in `state.db` (doc 07, Outbox).
///
/// [enqueue] applies the coalescing rule of the op's row in the Operations
/// table. Nothing here talks to the network.
class OutboxStore {
  /// Creates the store over [_db], stamping rows with [_clock].
  new(this._db, this._clock);

  final StateDatabase _db;
  final Clock _clock;

  static const Set<String> _playlistOps = {
    PlaylistRenameOp.type,
    PlaylistAddOp.type,
    PlaylistRemoveOp.type,
    PlaylistReorderOp.type,
    PlaylistDeleteOp.type,
  };

  /// Coalesces [op] with the pending ops and stores it, in one transaction.
  ///
  /// Returns the stored row's `seq`, or null when [op] cancelled a pending
  /// op instead of being stored. Inside a caller's transaction on the same
  /// database it joins that transaction.
  Future<int?> enqueue(OutboxOp op) => _db.transaction(() async {
    switch (op) {
      case PlayOp() || PlaylistCreateOp() || PlaylistAddOp():
        return await _insert(op);
      case PlaylistDeleteOp(:final playlistId):
        final created = await _deleteKey(PlaylistCreateOp.type, op.entityKey);
        await _deletePlaylistOps(playlistId);
        return created > 0 ? null : await _insert(op);
      case PlaylistRemoveOp():
        final cancelled = await _deleteKey(PlaylistAddOp.type, op.entityKey);
        return cancelled > 0 ? null : await _insert(op);
      case OfflineDeleteOp():
        return await _enqueueOfflineDelete(op);
      // Last write wins.
      case PreferenceOp() ||
          AlbumPreferenceOp() ||
          PlaylistRenameOp() ||
          PlaylistReorderOp() ||
          EpisodeProgressOp() ||
          OfflineCompleteOp():
        await _deleteKey(op.opType, op.entityKey);
        return await _insert(op);
    }
  });

  /// The pending ops in `seq` order.
  Future<List<OutboxEntry>> pending() async =>
      await _decode(await _query().get());

  /// The pending ops in `seq` order, limited to [opTypes] when given, again
  /// on every change.
  Stream<List<OutboxEntry>> watchPending({Set<String>? opTypes}) =>
      _query(opTypes: opTypes).watch().asyncMap(_decode);

  /// The number of pending ops, again on every change.
  Stream<int> watchCount() {
    final count = countAll();
    return (_db.selectOnly(
      _db.outbox,
    )..addColumns([count])).map((row) => row.read(count)!).watchSingle();
  }

  /// The oldest pending op, or null when there is none.
  Future<OutboxEntry?> head() async {
    while (true) {
      final row = await (_query()..limit(1)).getSingleOrNull();
      if (row == null) return null;
      final entries = await _decode([row]);
      if (entries.isNotEmpty) return entries.single;
    }
  }

  /// Removes the op at [seq]; nothing happens when it is gone.
  Future<void> delete(int seq) =>
      (_db.delete(_db.outbox)..where((t) => t.seq.equals(seq))).go();

  /// Records a failed attempt of the op at [seq]: one more attempt, the
  /// earliest next attempt and the error. Nothing happens when it is gone.
  Future<void> recordFailure(
    int seq, {
    required DateTime nextAttemptAt,
    String? lastError,
  }) async {
    await (_db.update(_db.outbox)..where((t) => t.seq.equals(seq))).write(
      OutboxCompanion.custom(
        attempts: _db.outbox.attempts + const Constant(1),
        nextAttemptAt: Variable(nextAttemptAt.toUtc()),
        lastError: Variable(lastError),
      ),
    );
  }

  SimpleSelectStatement<$OutboxTable, OutboxData> _query({
    Set<String>? opTypes,
  }) {
    final query = _db.select(_db.outbox)
      ..orderBy([(t) => OrderingTerm.asc(t.seq)]);
    if (opTypes != null) query.where((t) => t.opType.isIn(opTypes));
    return query;
  }

  Future<int> _insert(OutboxOp op) => _db
      .into(_db.outbox)
      .insert(
        OutboxCompanion.insert(
          opType: op.opType,
          entityKey: op.entityKey,
          payloadJson: jsonEncode(op.toPayload()),
          createdAt: _clock.now().toUtc(),
        ),
      );

  /// Deletes the pending ops of [opType] with [entityKey]; returns how many.
  Future<int> _deleteKey(String opType, String entityKey) =>
      (_db.delete(_db.outbox)..where(
            (t) => t.opType.equals(opType) & t.entityKey.equals(entityKey),
          ))
          .go();

  /// Decodes [rows]; a row that does not decode is logged and deleted.
  Future<List<OutboxEntry>> _decode(List<OutboxData> rows) async {
    final entries = <OutboxEntry>[];
    for (final row in rows) {
      final OutboxOp op;
      try {
        op = OutboxOp.decode(row.opType, row.payloadJson);
      } on FormatException catch (error, stackTrace) {
        _log.severe(
          'undecodable outbox row dropped',
          {'seq': row.seq, 'opType': row.opType},
          error,
          stackTrace,
        );
        await delete(row.seq);
        continue;
      }
      entries.add(
        OutboxEntry(
          seq: row.seq,
          op: op,
          createdAt: row.createdAt.toUtc(),
          attempts: row.attempts,
          nextAttemptAt: row.nextAttemptAt?.toUtc(),
          lastError: row.lastError,
        ),
      );
    }
    return entries;
  }

  /// Deletes every pending rename, add, remove, reorder and delete of
  /// [playlistId].
  Future<void> _deletePlaylistOps(String playlistId) async {
    final rows = await _query(opTypes: _playlistOps).get();
    final seqs = [
      for (final row in rows)
        if (_payloadField(row, 'playlistId') == playlistId) row.seq,
    ];
    if (seqs.isEmpty) return;
    await (_db.delete(_db.outbox)..where((t) => t.seq.isIn(seqs))).go();
  }

  /// Merges [op] into the newest pending batch of its device while that
  /// batch has room and no `offlineComplete` of the device follows it, so
  /// a removal never moves ahead of a completion. The merged batch takes a
  /// new `seq` at the tail; ids beyond [OfflineDeleteOp.maxIds] go into new
  /// batches.
  Future<int?> _enqueueOfflineDelete(OfflineDeleteOp op) async {
    final rows = await _query(
      opTypes: {OfflineDeleteOp.type, OfflineCompleteOp.type},
    ).get();
    var batchUuid = op.batchUuid;
    final ids = <String>{};
    for (final row in rows.reversed) {
      if (_payloadField(row, 'deviceId') != op.deviceId) continue;
      if (row.opType == OfflineCompleteOp.type) break;
      final previous = _payloadField(row, 'playbackIds');
      if (previous is List && previous.length < OfflineDeleteOp.maxIds) {
        ids.addAll(previous.whereType<String>());
        batchUuid = _payloadField(row, 'batchUuid')! as String;
        await delete(row.seq);
      }
      break;
    }
    ids.addAll(op.playbackIds);
    final all = ids.toList();
    int? seq;
    for (var i = 0; i < all.length; i += OfflineDeleteOp.maxIds) {
      seq = await _insert(
        OfflineDeleteOp(
          batchUuid: i == 0 ? batchUuid : Uuid.v4(),
          deviceId: op.deviceId,
          playbackIds: all.sublist(
            i,
            (i + OfflineDeleteOp.maxIds).clamp(0, all.length),
          ),
        ),
      );
    }
    return seq;
  }

  static Object? _payloadField(OutboxData row, String key) {
    try {
      final json = jsonDecode(row.payloadJson);
      return json is Map<String, Object?> ? json[key] : null;
    } on FormatException {
      return null;
    }
  }
}

/// The [OutboxStore] of the profile's `state.db`.
final Provider<OutboxStore> outboxStoreProvider = Provider<OutboxStore>(
  (ref) =>
      OutboxStore(ref.watch(stateDatabaseProvider), ref.watch(clockProvider)),
  dependencies: [stateDatabaseProvider],
);
