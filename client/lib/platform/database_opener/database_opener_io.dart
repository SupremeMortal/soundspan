// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/paths/paths.dart';

/// Creates the native [DatabaseOpener] over [paths].
DatabaseOpener createDatabaseOpener(AppPaths paths) => IoDatabaseOpener(paths);

/// The native [DatabaseOpener]: SQLite files at the [AppPaths] locations,
/// each run on a background isolate by `drift_flutter`, in WAL mode with
/// `synchronous = NORMAL`.
///
/// `app.db` is in `appSupport`; `state.db` and `cache.db` are at their
/// [ProfilePaths] locations. Missing directories are created on open.
final class IoDatabaseOpener implements DatabaseOpener {
  /// Creates an opener for the files under [paths].
  const new(this.paths);

  /// Where the database files live.
  final AppPaths paths;

  /// The file of [target].
  String fileOf(DatabaseTarget target) => switch (target) {
    AppDatabaseTarget() => p.join(paths.appSupport, 'app.db'),
    StateDatabaseTarget(:final profileId) => paths.profile(profileId).stateDb,
    CacheDatabaseTarget(:final profileId) => paths.profile(profileId).cacheDb,
  };

  @override
  bool get isVolatile => false;

  @override
  QueryExecutor open(DatabaseTarget target) {
    final file = fileOf(target);
    final cache = paths.appCache;
    return driftDatabase(
      name: databaseNameOf(target),
      native: DriftNativeOptions(
        databasePath: () async {
          await Directory(p.dirname(file)).create(recursive: true);
          return file;
        },
        tempDirectoryPath: () async {
          await Directory(cache).create(recursive: true);
          return cache;
        },
        // Runs on the database isolate whenever a connection opens.
        setup: (database) => database
          ..execute('PRAGMA journal_mode = WAL')
          ..execute('PRAGMA synchronous = NORMAL'),
      ),
    );
  }

  @override
  Future<void> delete(DatabaseTarget target) async {
    final file = fileOf(target);
    for (final path in [file, '$file-wal', '$file-shm']) {
      try {
        await File(path).delete();
      } on PathNotFoundException {
        // Already gone.
      }
    }
  }
}
