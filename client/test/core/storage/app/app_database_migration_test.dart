// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Migration tests for AppDatabase (app.db).
//
// Every released schema version is dumped to drift_schemas/app/ and turned
// into test helpers under generated_migrations/app/ by tool/gen.sh. To add
// version N + 1:
//
// 1. Change the tables and raise AppDatabase.schemaVersion to N + 1.
// 2. Run tool/gen.sh. It dumps drift_schema_v<N+1>.json, regenerates the
//    helpers and app_database.steps.g.dart, which gains a `from<N>To<N+1>`
//    parameter on `stepByStep`.
// 3. Implement that step in AppDatabase.migration (the compiler asks for it).
// 4. Add a test here that creates the database at version N from
//    `verifier.schemaAt(N)`, inserts rows with the `v<N>` helper classes,
//    runs `verifier.migrateAndValidate(db, N + 1)` and reads the rows back.
//
// CI runs tool/gen.sh and fails on a diff, so a table change without a new
// version (and its dump) does not merge.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/database_too_new_exception.dart';

import '../generated_migrations/app/schema.dart';

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
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 1);
    },
  );

  test(
    'a database from a newer app fails to open and is left untouched',
    () async {
      final dir = Directory.systemTemp.createTempSync('app_db_migration');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'app.db'));

      final newer = _VersionedDatabase(NativeDatabase(file), 2);
      await newer.customStatement('CREATE TABLE future (x TEXT)');
      await newer.close();
      final before = file.readAsBytesSync();

      final db = AppDatabase(NativeDatabase(file));
      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<DatabaseTooNewException>()
              .having((e) => e.found, 'found', 2)
              .having((e) => e.supported, 'supported', 1),
        ),
      );
      await db.close();

      expect(file.readAsBytesSync(), before);
    },
  );
}
