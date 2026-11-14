// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Cached artists (doc 05).
@DataClassName('CacheArtist')
@TableIndex(name: 'artists_name', columns: {#name})
class Artists extends Table {
  /// The artist's id.
  TextColumn get id => text()();

  /// The domain artist, JSON-encoded.
  TextColumn get json => text()();

  /// The name, for local search and sorting.
  TextColumn get name => text()();

  /// When the row was fetched, in UTC.
  DateTimeColumn get fetchedAt => dateTime()();

  /// When the artist's detail was last fetched, in UTC.
  DateTimeColumn get detailFetchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
