// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Cached podcasts (doc 05).
@DataClassName('CachePodcast')
class Podcasts extends Table {
  /// The podcast's id.
  TextColumn get id => text()();

  /// The domain podcast, JSON-encoded.
  TextColumn get json => text()();

  /// When the row was fetched, in UTC.
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
