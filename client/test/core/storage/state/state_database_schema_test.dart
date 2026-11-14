// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Migration tests for StateDatabase (state.db).
//
// state.db must migrate and is never recreated. Every released schema version
// is dumped to drift_schemas/state/ and turned into test helpers under
// generated_migrations/state/ by tool/gen.sh. To add version N + 1, follow the
// steps in app/app_database_migration_test.dart, with StateDatabase in place
// of AppDatabase.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/storage/database_too_new_exception.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

import '../generated_migrations/state/schema.dart';

/// A database without tables that claims [schemaVersion].
class _VersionedDatabase extends GeneratedDatabase {
  new(super.executor, this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
}

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'a database created at version 1 matches drift_schema_v1.json',
    () async {
      final schema = await verifier.schemaAt(1);
      final db = StateDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 1);
    },
  );

  test(
    'a database from a newer app fails to open and is left untouched',
    () async {
      final dir = Directory.systemTemp.createTempSync('state_db_migration');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'state.db'));

      final newer = _VersionedDatabase(NativeDatabase(file), 2);
      await newer.customStatement('CREATE TABLE future (x TEXT)');
      await newer.close();
      final before = file.readAsBytesSync();

      final db = StateDatabase(NativeDatabase(file));
      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<DatabaseTooNewException>()
              .having((e) => e.database, 'database', 'state.db')
              .having((e) => e.found, 'found', 2)
              .having((e) => e.supported, 'supported', 1),
        ),
      );
      await db.close();

      expect(file.readAsBytesSync(), before);
    },
  );
}
