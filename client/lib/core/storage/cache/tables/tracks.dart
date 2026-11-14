// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Cached tracks (doc 05).
///
/// `key` is the playback id when the track has one, else a derived key so a
/// track that cannot be played still has an identity.
@DataClassName('CacheTrack')
@TableIndex(name: 'tracks_title', columns: {#title})
@TableIndex(name: 'tracks_album_id', columns: {#albumId})
class Tracks extends Table {
  /// The track's cache key.
  TextColumn get key => text()();

  /// The playback id; null for a track that cannot be played.
  TextColumn get playbackId => text().nullable()();

  /// The domain track, JSON-encoded.
  TextColumn get json => text()();

  /// The album's id, for local queries.
  TextColumn get albumId => text().nullable()();

  /// The artist's id, for local queries.
  TextColumn get artistId => text().nullable()();

  /// The title, for local search.
  TextColumn get title => text()();

  /// When the row was fetched, in UTC.
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
