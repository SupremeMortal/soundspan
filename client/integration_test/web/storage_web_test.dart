// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Web storage in a real browser: drift WASM databases through the web
// DatabaseOpener and the sessionStorage-backed SecretStore. Run by the
// client-web-integration job:
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/web/storage_web_test.dart \
//     -d web-server --browser-name=chrome --headless

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/database_opener/database_opener_web.dart';
import 'package:soundspan/platform/secrets/secrets_web.dart';
import 'package:web/web.dart' as web;

/// A database with one table, `note`, created without code generation; the
/// schema class does not matter to the opener.
class _NoteDatabase extends GeneratedDatabase {
  new(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => customStatement(
      'CREATE TABLE note (id INTEGER PRIMARY KEY, body TEXT NOT NULL)',
    ),
  );

  Future<void> add(String body) =>
      customStatement('INSERT INTO note (body) VALUES (?)', [body]);

  Future<List<String>> bodies() async => [
    for (final row in await customSelect('SELECT body FROM note').get())
      row.read<String>('body'),
  ];
}

const _targets = <DatabaseTarget>[
  AppDatabaseTarget(),
  StateDatabaseTarget('a'),
  CacheDatabaseTarget('a'),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final opener = WebDatabaseOpener();

  Future<void> deleteAll() async {
    for (final target in _targets) {
      await opener.delete(target);
    }
  }

  setUp(deleteAll);
  tearDown(deleteAll);

  testWidgets('three databases open in one tab', (tester) async {
    final first = [for (final t in _targets) _NoteDatabase(opener.open(t))];
    for (final (i, db) in first.indexed) {
      await db.add('row $i');
    }
    for (final db in first) {
      await db.close();
    }

    final second = [for (final t in _targets) _NoteDatabase(opener.open(t))];
    for (final (i, db) in second.indexed) {
      expect(await db.bodies(), ['row $i']);
    }
    for (final db in second) {
      await db.close();
    }
    expect(opener.isVolatile, isFalse);
  });

  testWidgets('delete removes a web database', (tester) async {
    const target = StateDatabaseTarget('a');
    final db = _NoteDatabase(opener.open(target));
    await db.add('kept?');
    await db.close();

    await opener.delete(target);

    final reopened = _NoteDatabase(opener.open(target));
    expect(await reopened.bodies(), isEmpty);
    await reopened.close();
  });

  testWidgets('falls back to memory when storage is unavailable', (
    tester,
  ) async {
    final failing = WebDatabaseOpener(
      openWasm: (name) => throw StateError('storage unavailable'),
    );
    final db = _NoteDatabase(failing.open(const AppDatabaseTarget()));
    await db.add('in memory');
    expect(await db.bodies(), ['in memory']);
    await db.close();
    expect(failing.isVolatile, isTrue);
  });

  group('web secrets', () {
    setUp(() {
      web.window.sessionStorage.clear();
      web.window.localStorage.clear();
    });

    testWidgets('web secrets survive a new store instance', (tester) async {
      await WebSecretStore().write('p/a/refresh', 'r1');

      expect(await WebSecretStore().read('p/a/refresh'), 'r1');
      expect(web.window.localStorage.length, 0);
    });

    testWidgets('web secret delete clears sessionStorage', (tester) async {
      final store = WebSecretStore();
      await store.write('p/a/access', 'a1');
      await store.delete('p/a/access');

      expect(web.window.sessionStorage.getItem('p/a/access'), isNull);
      expect(await WebSecretStore().read('p/a/access'), isNull);
    });
  });
}
