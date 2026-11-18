// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Cached ordered lists: one row per endpoint and parameters (doc 05).
///
/// Their entries are in `list_entries`.
@DataClassName('CacheList')
class Lists extends Table {
  /// The endpoint and parameters, for example `playlist:<id>`.
  TextColumn get listKey => text()();

  /// The server's total, when it reported one.
  IntColumn get total => integer().nullable()();

  /// When the list was last fetched, in UTC.
  DateTimeColumn get fetchedAt => dateTime()();

  /// Whether every entry of the list is cached.
  BoolColumn get complete => boolean().withDefault(const Constant(false))();

  /// When the list was last read, in UTC; pruning removes lists not read
  /// for 30 days.
  DateTimeColumn get lastReadAt => dateTime()();

  @override
  Set<Column> get primaryKey => {listKey};
}
