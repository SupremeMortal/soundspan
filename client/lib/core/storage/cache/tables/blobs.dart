// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Cached one-off payloads: home shelves, lyrics, artist detail extras
/// (doc 05).
///
/// A blob never keeps an entity from being pruned.
@DataClassName('CacheBlob')
class Blobs extends Table {
  /// The payload's key.
  TextColumn get key => text()();

  /// The payload, JSON-encoded.
  TextColumn get json => text()();

  /// When the payload was fetched, in UTC.
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
