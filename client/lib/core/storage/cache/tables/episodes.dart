// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Cached podcast episodes (doc 05).
@DataClassName('CacheEpisode')
class Episodes extends Table {
  /// The episode's id.
  TextColumn get id => text()();

  /// The id of the podcast the episode belongs to.
  TextColumn get podcastId => text()();

  /// The domain episode, JSON-encoded.
  TextColumn get json => text()();

  /// When the row was fetched, in UTC.
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
