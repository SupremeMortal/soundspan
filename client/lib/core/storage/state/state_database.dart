// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/database_too_new_exception.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.steps.g.dart';
import 'package:soundspan/core/storage/state/tables/device_settings.dart';
import 'package:soundspan/core/storage/state/tables/download_collections.dart';
import 'package:soundspan/core/storage/state/tables/download_items.dart';
import 'package:soundspan/core/storage/state/tables/download_membership.dart';
import 'package:soundspan/core/storage/state/tables/outbox.dart';
import 'package:soundspan/core/storage/state/tables/play_sessions.dart';
import 'package:soundspan/core/storage/state/tables/queue_meta.dart';
import 'package:soundspan/core/storage/state/tables/queue_snapshot.dart';
import 'package:soundspan/core/storage/state/tables/search_history.dart';

part 'state_database.g.dart';

/// `state.db`: one profile's durable on-device state (doc 05).
///
/// It is migrated step by step and never recreated.
@DriftDatabase(
  tables: [
    DeviceSettings,
    QueueSnapshot,
    QueueMeta,
    DownloadCollections,
    DownloadItems,
    DownloadMembership,
    Outbox,
    PlaySessions,
    SearchHistory,
  ],
)
class StateDatabase extends _$StateDatabase {
  /// Creates the database over [e], usually from a `DatabaseOpener`.
  new(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from > to) throw DatabaseTooNewException('state.db', from, to);
      // Generated from drift_schemas/state/; a new version adds a step here.
      await stepByStep()(m, from, to);
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
