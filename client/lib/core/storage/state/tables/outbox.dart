// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Writes the server has not received yet, in order (doc 07, Outbox).
@TableIndex(name: 'outbox_entity_key', columns: {#entityKey})
@TableIndex(name: 'outbox_next_attempt_at', columns: {#nextAttemptAt})
class Outbox extends Table {
  /// Insertion order; never reused.
  IntColumn get seq => integer().autoIncrement()();

  /// The operation's type.
  TextColumn get opType => text()();

  /// The coalescing key, for example `pref:<playbackId>`.
  TextColumn get entityKey => text()();

  /// The operation's payload as JSON.
  TextColumn get payloadJson => text()();

  /// When the operation was recorded.
  DateTimeColumn get createdAt => dateTime()();

  /// Delivery attempts so far.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// When the next attempt may run, if it is delayed.
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  /// The last delivery error.
  TextColumn get lastError => text().nullable()();
}
