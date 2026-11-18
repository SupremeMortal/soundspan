// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/shared/clock.dart';

/// The recent searches of a profile, over the `search_history` table of its
/// `state.db` (doc 05, StateDatabase).
///
/// Queries are trimmed and compared without case; at most [limit] are kept.
class SearchHistoryStore {
  /// A store over [_db] stamping queries with [_clock].
  new(this._db, this._clock);

  /// The most queries kept.
  static const int limit = 20;

  final StateDatabase _db;
  final Clock _clock;

  /// The recent queries, newest first, at most [limit].
  Stream<List<String>> watchRecent() {
    final table = _db.searchHistory;
    return (_db.select(table)
          ..orderBy([(row) => OrderingTerm.desc(row.lastUsedAt)])
          ..limit(limit))
        .map((row) => row.query)
        .watch();
  }

  /// Records [query] as used now. A query already recorded in any case
  /// keeps its first spelling and moves to the top; a blank one is ignored.
  /// The oldest queries beyond [limit] are deleted.
  Future<void> record(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;
    final table = _db.searchHistory;
    final now = _clock.now();
    await _db.transaction(() async {
      final updated =
          await (_db.update(table)..where((row) => row.query.equals(text)))
              .write(SearchHistoryCompanion(lastUsedAt: Value(now)));
      if (updated == 0) {
        await _db
            .into(table)
            .insert(
              SearchHistoryCompanion.insert(query: text, lastUsedAt: now),
            );
      }
      final kept = _db.selectOnly(table)
        ..addColumns([table.query])
        ..orderBy([OrderingTerm.desc(table.lastUsedAt)])
        ..limit(limit);
      await (_db.delete(
        table,
      )..where((row) => row.query.isNotInQuery(kept))).go();
    });
  }

  /// Removes [query], compared without case.
  Future<void> remove(String query) => (_db.delete(
    _db.searchHistory,
  )..where((row) => row.query.equals(query.trim()))).go();

  /// Removes every recent query.
  Future<void> clear() => _db.delete(_db.searchHistory).go();
}
