// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// What the user asked to keep offline: a track, album, playlist or episode
/// (doc 07).
class DownloadCollections extends Table {
  /// `track`, `album`, `playlist` or `episode`.
  TextColumn get kind => text()();

  /// The collection's reference: a track's `playbackId`, an album or
  /// playlist id, or `<podcastId>:<episodeId>` for an episode.
  TextColumn get refId => text()();

  /// The title shown in the downloads list.
  TextColumn get title => text()();

  /// Enough metadata (subtitle, artwork ref) to render the row offline.
  TextColumn get metaJson => text()();

  /// A plain state name such as `resolving`, `ready` or `blocked`.
  TextColumn get status => text()();

  /// Why the collection is blocked, such as `serverQuota` or
  /// `disabledByServer`.
  TextColumn get blockedReason => text().nullable()();

  /// Detail of the state as JSON, for example the byte values of a server
  /// quota refusal.
  TextColumn get detailJson => text().nullable()();

  /// The requested download quality, if one was chosen.
  TextColumn get quality => text().nullable()();

  /// When the user asked for the download.
  DateTimeColumn get requestedAt => dateTime()();

  /// When the server last resolved the collection's items.
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {kind, refId};
}
