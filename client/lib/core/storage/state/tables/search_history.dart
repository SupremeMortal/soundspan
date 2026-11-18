// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Recent searches; queries differing only in case are one row.
class SearchHistory extends Table {
  /// The search text, compared case-insensitively.
  TextColumn get query => text().customConstraint('NOT NULL COLLATE NOCASE')();

  /// When the query was last used.
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {query};
}
