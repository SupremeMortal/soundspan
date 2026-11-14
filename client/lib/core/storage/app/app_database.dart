// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/app/app_database.steps.g.dart';
import 'package:soundspan/core/storage/app/profile_enums.dart';
import 'package:soundspan/core/storage/app/tables/app_settings.dart';
import 'package:soundspan/core/storage/app/tables/profiles.dart';
import 'package:soundspan/core/storage/database_too_new_exception.dart';

part 'app_database.g.dart';

/// `app.db`: the server profiles and the app settings (doc 05).
@DriftDatabase(tables: [Profiles, AppSettings])
class AppDatabase extends _$AppDatabase {
  /// Creates the database over [e], usually from a `DatabaseOpener`.
  new(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from > to) throw DatabaseTooNewException('app.db', from, to);
      // Generated from drift_schemas/app/; a new version adds a step here.
      await stepByStep()(m, from, to);
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
