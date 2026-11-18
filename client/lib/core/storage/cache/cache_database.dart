// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/cache/entity_kind.dart';
import 'package:soundspan/core/storage/cache/tables/albums.dart';
import 'package:soundspan/core/storage/cache/tables/artists.dart';
import 'package:soundspan/core/storage/cache/tables/blobs.dart';
import 'package:soundspan/core/storage/cache/tables/episodes.dart';
import 'package:soundspan/core/storage/cache/tables/list_entries.dart';
import 'package:soundspan/core/storage/cache/tables/lists.dart';
import 'package:soundspan/core/storage/cache/tables/playlists.dart';
import 'package:soundspan/core/storage/cache/tables/podcasts.dart';
import 'package:soundspan/core/storage/cache/tables/tracks.dart';

export 'package:soundspan/core/storage/cache/entity_kind.dart';

part 'cache_database.g.dart';

/// `cache.db`: one profile's disposable copy of server data (doc 05).
///
/// It is never migrated: any schema version difference, up or down, drops
/// every table and recreates them. `openCacheDatabase` also deletes and
/// recreates a file that fails to open.
@DriftDatabase(
  tables: [
    Tracks,
    Albums,
    Artists,
    Playlists,
    Podcasts,
    Episodes,
    Lists,
    ListEntries,
    Blobs,
  ],
)
class CacheDatabase extends _$CacheDatabase {
  /// Creates the database over [e], usually from a `DatabaseOpener`.
  new(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      final tables = await customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      ).map((row) => row.read<String>('name')).get();
      for (final table in tables) {
        await customStatement('DROP TABLE IF EXISTS "$table"');
      }
      await m.createAll();
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
