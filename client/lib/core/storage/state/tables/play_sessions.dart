// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// The play in progress, kept so a kill does not lose it (doc 06).
class PlaySessions extends Table {
  /// The session's id, a client-generated UUID.
  TextColumn get sessionId => text()();

  /// The queue entry being played.
  TextColumn get queueItemId => text()();

  /// The played item's `playbackId`, stored verbatim.
  TextColumn get playbackId => text()();

  /// The serialized `TrackMeta`.
  TextColumn get metaJson => text()();

  /// The instant the play started.
  DateTimeColumn get playedAt => dateTime()();

  /// How long the user has listened, in milliseconds.
  IntColumn get listenedMs => integer().withDefault(const Constant(0))();

  /// When the row last changed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sessionId};
}
