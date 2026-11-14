// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/shared/clock.dart';

/// The size above which `cache.db` is pruned: 64 MB (doc 05, Pruning).
const int cacheSizeLimitBytes = 64 * 1024 * 1024;

/// How long a list may go unread, and a blob unfetched, before pruning
/// removes it: 30 days (doc 05, Pruning).
const Duration cacheMaxAge = Duration(days: 30);

/// How many of the least recently read lists are removed at a time while
/// `cache.db` stays above its size limit.
const int cacheEvictionBatchSize = 50;

/// What one pruning removed.
@immutable
class PruneReport {
  /// A report of [lists], [blobs] and [entities] removed.
  const new({this.lists = 0, this.blobs = 0, this.entities = 0});

  /// Nothing removed.
  static const PruneReport none = PruneReport();

  /// Lists removed, with their entries.
  final int lists;

  /// Blobs removed.
  final int blobs;

  /// Entity rows removed because no list referenced them any more.
  final int entities;

  /// Whether nothing was removed.
  bool get isEmpty => lists == 0 && blobs == 0 && entities == 0;

  /// The sum of this report and [other].
  PruneReport operator +(PruneReport other) => PruneReport(
    lists: lists + other.lists,
    blobs: blobs + other.blobs,
    entities: entities + other.entities,
  );

  @override
  bool operator ==(Object other) =>
      other is PruneReport &&
      other.lists == lists &&
      other.blobs == blobs &&
      other.entities == entities;

  @override
  int get hashCode => Object.hash(lists, blobs, entities);

  @override
  String toString() =>
      'PruneReport(lists: $lists, blobs: $blobs, entities: $entities)';
}

/// Keeps `cache.db` bounded (doc 05, Pruning).
///
/// Lists not read for [cacheMaxAge] go with their entries, blobs not fetched
/// for [cacheMaxAge] go, and then every entity no list entry references. A
/// blob never keeps an entity alive by itself.
class CachePruner {
  /// A pruner of `db` that reads the time from `clock`.
  ///
  /// `sizeLimitBytes` defaults to [cacheSizeLimitBytes].
  new(this._db, this._clock, {this._sizeLimitBytes = cacheSizeLimitBytes});

  final CacheDatabase _db;
  final Clock _clock;
  final int _sizeLimitBytes;

  static const _entityTables = <(CacheEntityKind, String, String)>[
    (CacheEntityKind.track, 'tracks', 'key'),
    (CacheEntityKind.album, 'albums', 'id'),
    (CacheEntityKind.artist, 'artists', 'id'),
    (CacheEntityKind.playlist, 'playlists', 'id'),
    (CacheEntityKind.podcast, 'podcasts', 'id'),
    (CacheEntityKind.episode, 'episodes', 'id'),
  ];

  /// Removes old lists and blobs and the entities no list references, in
  /// one transaction.
  Future<PruneReport> prune() => _db.transaction(() async {
    final cutoff = _clock.now().subtract(cacheMaxAge);
    final lists = await (_db.delete(
      _db.lists,
    )..where((l) => l.lastReadAt.isSmallerThanValue(cutoff))).go();
    final blobs = await (_db.delete(
      _db.blobs,
    )..where((b) => b.fetchedAt.isSmallerThanValue(cutoff))).go();
    final entities = await _deleteOrphans();
    return PruneReport(lists: lists, blobs: blobs, entities: entities);
  });

  /// The bytes `cache.db` uses: `(page_count - freelist_count) * page_size`.
  Future<int> sizeBytes() async {
    final row = await _db
        .customSelect(
          'SELECT (SELECT page_count FROM pragma_page_count()) '
          '- (SELECT freelist_count FROM pragma_freelist_count()) AS pages, '
          '(SELECT page_size FROM pragma_page_size()) AS page_size',
        )
        .getSingle();
    return row.read<int>('pages') * row.read<int>('page_size');
  }

  /// Prunes at start-up, or when `cache.db` is above its size limit.
  ///
  /// If it is still above the limit afterwards, the least recently read
  /// lists are removed [cacheEvictionBatchSize] at a time, with the entities
  /// that become unreferenced, until it is under the limit or no list is
  /// left.
  Future<PruneReport> pruneIfNeeded({bool atStartup = false}) async {
    if (!atStartup && await sizeBytes() <= _sizeLimitBytes) {
      return PruneReport.none;
    }
    var report = await prune();
    while (await sizeBytes() > _sizeLimitBytes) {
      final batch = await _evictLeastRecentlyRead();
      if (batch.lists == 0) break;
      report += batch;
    }
    return report;
  }

  /// Marks [listKey] as read now, which keeps it from being pruned for
  /// [cacheMaxAge].
  Future<void> touchList(String listKey) async {
    await (_db.update(_db.lists)..where((l) => l.listKey.equals(listKey)))
        .write(ListsCompanion(lastReadAt: Value(_clock.now())));
  }

  Future<PruneReport> _evictLeastRecentlyRead() => _db.transaction(() async {
    final keys =
        await (_db.selectOnly(_db.lists)
              ..addColumns([_db.lists.listKey])
              ..orderBy([OrderingTerm.asc(_db.lists.lastReadAt)])
              ..limit(cacheEvictionBatchSize))
            .map((row) => row.read(_db.lists.listKey)!)
            .get();
    if (keys.isEmpty) return PruneReport.none;
    final lists = await (_db.delete(
      _db.lists,
    )..where((l) => l.listKey.isIn(keys))).go();
    final entities = await _deleteOrphans();
    return PruneReport(lists: lists, entities: entities);
  });

  Future<int> _deleteOrphans() async {
    var removed = 0;
    for (final (kind, table, key) in _entityTables) {
      removed += await _db.customUpdate(
        'DELETE FROM $table WHERE NOT EXISTS (SELECT 1 FROM list_entries e '
        'WHERE e.entity_kind = ? AND e.entity_key = $table.$key)',
        variables: [Variable.withString(kind.name)],
        updates: {_db.allTables.firstWhere((t) => t.actualTableName == table)},
        updateKind: UpdateKind.delete,
      );
    }
    return removed;
  }
}
