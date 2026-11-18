// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

/// Reads and writes the `play_sessions` rows of a profile's `state.db`: the
/// plays in progress, kept so a kill does not lose them (doc 05, doc 06
/// Play Reporting).
class PlaySessionStore {
  /// Creates the accessor over [_database].
  new(this._database);

  final StateDatabase _database;

  /// Every stored play.
  Future<List<PlaySession>> all() =>
      _database.select(_database.playSessions).get();

  /// Writes [session], replacing the row with the same `sessionId`.
  Future<void> write(PlaySession session) => _database
      .into(_database.playSessions)
      .insert(session, mode: InsertMode.insertOrReplace);

  /// Deletes the rows of [sessionIds]; answers how many there were.
  Future<int> delete(Iterable<String> sessionIds) {
    final ids = sessionIds.toList();
    if (ids.isEmpty) return Future<int>.value(0);
    return (_database.delete(
      _database.playSessions,
    )..where((t) => t.sessionId.isIn(ids))).go();
  }
}
