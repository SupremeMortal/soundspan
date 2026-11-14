// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';

import 'in_memory_database_opener.dart';
import 'pump_app.dart';

void main() {
  test('records opened, closed and deleted targets', () async {
    final opener = InMemoryDatabaseOpener();
    final db = AppDatabase(opener.open(const AppDatabaseTarget()));
    await db.customSelect('SELECT 1').get();
    expect(opener.opened, [const AppDatabaseTarget()]);
    expect(opener.closed, isEmpty);

    await db.close();
    expect(opener.closed, [const AppDatabaseTarget()]);

    await opener.delete(const StateDatabaseTarget('p1'));
    expect(opener.deleted, [const StateDatabaseTarget('p1')]);
  });

  test('every open is a new, empty database', () async {
    final opener = InMemoryDatabaseOpener();
    final first = AppDatabase(opener.open(const AppDatabaseTarget()));
    await first.customStatement('CREATE TABLE extra (x TEXT)');
    await first.close();

    final second = AppDatabase(opener.open(const AppDatabaseTarget()));
    addTearDown(second.close);
    final tables = await second
        .customSelect("SELECT name FROM sqlite_master WHERE name = 'extra'")
        .get();
    expect(tables, isEmpty);
  });

  testWidgets('pumpApp provides it as the database opener', (tester) async {
    final container = await tester.pumpApp(const SizedBox());
    expect(
      container.read(databaseOpenerProvider),
      isA<InMemoryDatabaseOpener>(),
    );
  });
}
