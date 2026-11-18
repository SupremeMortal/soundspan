// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Cached playlists (doc 05).
@DataClassName('CachePlaylist')
@TableIndex(name: 'playlists_name', columns: {#name})
class Playlists extends Table {
  /// The playlist's id.
  TextColumn get id => text()();

  /// The domain playlist, JSON-encoded.
  TextColumn get json => text()();

  /// The name, for local search and sorting.
  TextColumn get name => text()();

  /// When the row was fetched, in UTC.
  DateTimeColumn get fetchedAt => dateTime()();

  /// When the playlist's detail was last fetched, in UTC.
  DateTimeColumn get detailFetchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
