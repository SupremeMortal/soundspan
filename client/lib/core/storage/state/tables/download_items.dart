// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/state/enums.dart';

/// One row per downloaded track or episode file (doc 05, doc 07).
@TableIndex(name: 'download_items_status', columns: {#status})
class DownloadItems extends Table {
  /// `t:<playbackId>` or `e:<podcastId>:<episodeId>`.
  TextColumn get itemKey => text()();

  /// Whether the file is a track or an episode.
  TextColumn get mediaType => textEnum<MediaType>()();

  /// Track or episode metadata: enough to render and play offline.
  TextColumn get metaJson => text()();

  /// The quality as resolved by the server.
  TextColumn get quality => text().nullable()();

  /// The item's state.
  TextColumn get status => textEnum<DownloadStatus>()();

  /// Why a queued or paused item is not running, such as `space` or
  /// `wifi`. Never a failure code.
  TextColumn get waitingFor => text().nullable()();

  /// The transfer task's id.
  TextColumn get taskId => text().nullable()();

  /// The URL the file is downloaded from.
  TextColumn get downloadUrl => text().nullable()();

  /// The server's ETag for the file.
  TextColumn get etag => text().nullable()();

  /// The size the server announced, in bytes.
  IntColumn get expectedBytes => integer().nullable()();

  /// Bytes received so far.
  IntColumn get receivedBytes => integer().withDefault(const Constant(0))();

  /// The verified size on disk, in bytes.
  IntColumn get sizeBytes => integer().nullable()();

  /// The file's path under `profiles/<id>/media`.
  TextColumn get relativePath => text().nullable()();

  /// A failure or unavailability code, including the server's `reason`.
  TextColumn get failureCode => text().nullable()();

  /// Transfer attempts since the last reset.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Whether the server acknowledged the completed download.
  BoolColumn get serverConfirmed =>
      boolean().withDefault(const Constant(false))();

  /// When the item was first requested.
  DateTimeColumn get requestedAt => dateTime()();

  /// When the file was verified.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// When the file was last played.
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {itemKey};
}
