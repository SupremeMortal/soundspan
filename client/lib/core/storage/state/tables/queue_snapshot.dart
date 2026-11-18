// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// The persisted queue, one row per item in canonical order (doc 06).
class QueueSnapshot extends Table {
  /// The item's index in canonical order, from 0.
  IntColumn get position => integer()();

  /// The queue entry's id, unique within the queue.
  TextColumn get queueItemId => text().unique()();

  /// `track` or `episode`.
  TextColumn get kind => text()();

  /// The serialized `QueueItem`: everything needed to show and play it,
  /// including its queue context.
  TextColumn get itemJson => text()();

  @override
  Set<Column> get primaryKey => {position};
}
