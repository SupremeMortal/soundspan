// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';

/// A playlist created on this device received its server id.
@immutable
final class TempIdResolved {
  /// Records that [tempId] is now [realId].
  const new(this.tempId, this.realId);

  /// The temporary id, `tmp_<uuid>`.
  final String tempId;

  /// The id the server assigned.
  final String realId;

  @override
  bool operator ==(Object other) =>
      other is TempIdResolved &&
      other.tempId == tempId &&
      other.realId == realId;

  @override
  int get hashCode => Object.hash(tempId, realId);

  @override
  String toString() => 'TempIdResolved($tempId -> $realId)';
}

/// Replaces a playlist's temporary id with the server's in the outbox and
/// in `cache.db` (doc 07, Outbox).
///
/// The two databases cannot share a transaction: `state.db` commits first,
/// and `cache.db` rows left with a temporary id are removed by
/// [removeOrphans] at the next start, since the cache is disposable.
class TempIdRewriter {
  /// Creates the rewriter over the profile's [_state] and the `cache.db`
  /// that [_cache] opens.
  new(this._state, this._cache);

  /// The prefix of every temporary playlist id.
  static const String prefix = 'tmp_';

  final StateDatabase _state;
  final Future<CacheDatabase> Function() _cache;

  /// Deletes the create op at [createSeq] and rewrites [tempId] to
  /// [realId] in every pending op, in one `state.db` transaction; then
  /// rewrites the playlist's row, its `playlist:<id>` list and blob, and
  /// the list entries pointing at it, in one `cache.db` transaction.
  Future<void> resolve({
    required int createSeq,
    required String tempId,
    required String realId,
  }) async {
    await _state.transaction(() async {
      await (_state.delete(
        _state.outbox,
      )..where((t) => t.seq.equals(createSeq))).go();
      final rows = await _state.select(_state.outbox).get();
      for (final row in rows) {
        final payload = _replaceIn(jsonDecode(row.payloadJson), tempId, realId);
        final key = row.entityKey
            .split(':')
            .map((part) => part == tempId ? realId : part)
            .join(':');
        final payloadJson = jsonEncode(payload);
        if (payloadJson == row.payloadJson && key == row.entityKey) continue;
        await (_state.update(
          _state.outbox,
        )..where((t) => t.seq.equals(row.seq))).write(
          OutboxCompanion(
            payloadJson: Value(payloadJson),
            entityKey: Value(key),
          ),
        );
      }
    });
    final cache = await _cache();
    await cache.transaction(() => _rewriteCache(cache, tempId, realId));
  }

  /// Deletes every cached playlist with a temporary id that no pending
  /// `playlistCreate` holds, with its list, blob and list entries.
  Future<void> removeOrphans() async {
    final pending = await (_state.select(
      _state.outbox,
    )..where((t) => t.opType.equals(PlaylistCreateOp.type))).get();
    final kept = {
      for (final row in pending)
        if (_tempIdOf(row.payloadJson) case final String id) id,
    };
    final cache = await _cache();
    await cache.transaction(() async {
      final rows = await (cache.select(
        cache.playlists,
      )..where((t) => t.id.like('$prefix%'))).get();
      final entries =
          await (cache.select(cache.listEntries)..where(
                (e) =>
                    e.entityKind.equalsValue(CacheEntityKind.playlist) &
                    e.entityKey.like('$prefix%'),
              ))
              .get();
      final orphans = {
        for (final row in rows) row.id,
        for (final entry in entries) entry.entityKey,
      }.where((id) => id.startsWith(prefix) && !kept.contains(id)).toList();
      if (orphans.isEmpty) return;
      await (cache.delete(
        cache.playlists,
      )..where((t) => t.id.isIn(orphans))).go();
      await (cache.delete(cache.listEntries)..where(
            (e) =>
                e.entityKind.equalsValue(CacheEntityKind.playlist) &
                e.entityKey.isIn(orphans),
          ))
          .go();
      final keys = [for (final id in orphans) 'playlist:$id'];
      await (cache.delete(
        cache.lists,
      )..where((t) => t.listKey.isIn(keys))).go();
      await (cache.delete(cache.blobs)..where((t) => t.key.isIn(keys))).go();
    });
  }

  static Future<void> _rewriteCache(
    CacheDatabase cache,
    String tempId,
    String realId,
  ) async {
    final playlist = await (cache.select(
      cache.playlists,
    )..where((t) => t.id.equals(tempId))).getSingleOrNull();
    if (playlist != null) {
      await (cache.delete(
        cache.playlists,
      )..where((t) => t.id.equals(tempId))).go();
      await cache
          .into(cache.playlists)
          .insertOnConflictUpdate(
            playlist.copyWith(
              id: realId,
              json: _rewriteJson(playlist.json, tempId, realId),
            ),
          );
    }

    final oldKey = 'playlist:$tempId';
    final newKey = 'playlist:$realId';
    final list = await (cache.select(
      cache.lists,
    )..where((t) => t.listKey.equals(oldKey))).getSingleOrNull();
    if (list != null) {
      await (cache.delete(
        cache.lists,
      )..where((t) => t.listKey.equals(newKey))).go();
      await cache.into(cache.lists).insert(list.copyWith(listKey: newKey));
      await (cache.update(cache.listEntries)
            ..where((e) => e.listKey.equals(oldKey)))
          .write(ListEntriesCompanion(listKey: Value(newKey)));
      await (cache.delete(
        cache.lists,
      )..where((t) => t.listKey.equals(oldKey))).go();
    }

    await (cache.update(cache.listEntries)..where(
          (e) =>
              e.entityKind.equalsValue(CacheEntityKind.playlist) &
              e.entityKey.equals(tempId),
        ))
        .write(ListEntriesCompanion(entityKey: Value(realId)));

    final blob = await (cache.select(
      cache.blobs,
    )..where((t) => t.key.equals(oldKey))).getSingleOrNull();
    if (blob != null) {
      await (cache.delete(
        cache.blobs,
      )..where((t) => t.key.equals(oldKey))).go();
      await cache
          .into(cache.blobs)
          .insertOnConflictUpdate(
            blob.copyWith(
              key: newKey,
              json: _rewriteJson(blob.json, tempId, realId),
            ),
          );
    }
  }

  static String _rewriteJson(String json, String tempId, String realId) =>
      jsonEncode(_replaceIn(jsonDecode(json), tempId, realId));

  /// [value] with every string equal to [from] replaced by [to].
  static Object? _replaceIn(Object? value, String from, String to) =>
      switch (value) {
        final String s => s == from ? to : s,
        final List<Object?> list => [
          for (final e in list) _replaceIn(e, from, to),
        ],
        final Map<String, Object?> map => {
          for (final MapEntry(:key, :value) in map.entries)
            key: _replaceIn(value, from, to),
        },
        _ => value,
      };

  static String? _tempIdOf(String payloadJson) {
    try {
      final json = jsonDecode(payloadJson);
      return json is Map<String, Object?> ? json['tempId'] as String? : null;
    } on Object {
      return null;
    }
  }
}
