// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// The single row describing the persisted queue's state (doc 06).
class QueueMeta extends Table {
  /// Always 1: the table holds one row.
  IntColumn get id => integer()();

  /// The current item's `queueItemId`, if any.
  TextColumn get currentQueueItemId => text().nullable()();

  /// The playback position in the current item, in milliseconds.
  IntColumn get positionMs => integer().withDefault(const Constant(0))();

  /// The shuffle permutation as a JSON array of canonical indices; null
  /// means shuffle is off.
  TextColumn get shuffleOrderJson => text().nullable()();

  /// `off`, `all` or `one`.
  TextColumn get repeatMode => text().withDefault(const Constant('off'))();

  /// The serialized `QueueContext`, if any.
  TextColumn get contextJson => text().nullable()();

  /// Increases with every change to the queue.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  /// When the queue last changed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}
