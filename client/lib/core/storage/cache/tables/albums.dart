// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Cached albums (doc 05).
@DataClassName('CacheAlbum')
@TableIndex(name: 'albums_title', columns: {#title})
class Albums extends Table {
  /// The album's id.
  TextColumn get id => text()();

  /// The domain album, JSON-encoded.
  TextColumn get json => text()();

  /// The title, for local search and sorting.
  TextColumn get title => text()();

  /// The album artist's name, for local sorting.
  TextColumn get artistName => text()();

  /// The release year, when known.
  IntColumn get year => integer().nullable()();

  /// When the row was fetched, in UTC.
  DateTimeColumn get fetchedAt => dateTime()();

  /// When the album's detail was last fetched, in UTC.
  DateTimeColumn get detailFetchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
