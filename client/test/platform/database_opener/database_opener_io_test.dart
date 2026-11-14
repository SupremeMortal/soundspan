// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/database_opener/database_opener_io.dart';
import 'package:soundspan/platform/paths/paths_io.dart';

/// A database without tables, to drive an executor from the test.
class _RawDatabase extends GeneratedDatabase {
  new(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}

void main() {
  late Directory root;
  late IoAppPaths paths;
  late IoDatabaseOpener opener;

  setUp(() {
    root = Directory.systemTemp.createTempSync('database_opener_test');
    paths = IoAppPaths(
      appSupport: p.join(root.path, 'support'),
      appCache: p.join(root.path, 'cache'),
    );
    opener = IoDatabaseOpener(paths);
  });
  tearDown(() => root.deleteSync(recursive: true));

  final targets = <DatabaseTarget>[
    const AppDatabaseTarget(),
    const StateDatabaseTarget('p1'),
    const CacheDatabaseTarget('p1'),
  ];

  String fileOf(DatabaseTarget target) => switch (target) {
    AppDatabaseTarget() => p.join(paths.appSupport, 'app.db'),
    StateDatabaseTarget(:final profileId) => paths.profile(profileId).stateDb,
    CacheDatabaseTarget(:final profileId) => paths.profile(profileId).cacheDb,
  };

  for (final target in targets) {
    group('$target', () {
      test(
        'opening creates the file at the expected path, in WAL mode',
        () async {
          final db = _RawDatabase(opener.open(target));
          final mode = await db.customSelect('PRAGMA journal_mode').getSingle();
          final sync = await db.customSelect('PRAGMA synchronous').getSingle();
          await db.close();

          expect(File(fileOf(target)).existsSync(), isTrue);
          expect(mode.data.values.single, 'wal');
          expect(sync.data.values.single, 1); // NORMAL
        },
      );

      test('data written, closed and reopened is read back', () async {
        final first = _RawDatabase(opener.open(target));
        await first.customStatement('CREATE TABLE t (x TEXT)');
        await first.customStatement("INSERT INTO t VALUES ('kept')");
        await first.close();

        final second = _RawDatabase(opener.open(target));
        final row = await second.customSelect('SELECT x FROM t').getSingle();
        await second.close();
        expect(row.read<String>('x'), 'kept');
      });

      test('delete removes the database and its companions, twice', () async {
        final db = _RawDatabase(opener.open(target));
        await db.customStatement('CREATE TABLE t (x TEXT)');
        await db.close();
        final file = fileOf(target);
        File('$file-wal').writeAsStringSync('w');
        File('$file-shm').writeAsStringSync('s');

        await opener.delete(target);
        expect(File(file).existsSync(), isFalse);
        expect(File('$file-wal').existsSync(), isFalse);
        expect(File('$file-shm').existsSync(), isFalse);

        await opener.delete(target);
      });
    });
  }

  test('targets are values', () {
    expect(const StateDatabaseTarget('a'), const StateDatabaseTarget('a'));
    expect(
      const StateDatabaseTarget('a'),
      isNot(const CacheDatabaseTarget('a')),
    );
    expect(
      const CacheDatabaseTarget('a'),
      isNot(const CacheDatabaseTarget('b')),
    );
    final id = ['a'].single;
    expect(
      StateDatabaseTarget(id).hashCode,
      const StateDatabaseTarget('a').hashCode,
    );
    expect(CacheDatabaseTarget(id), const CacheDatabaseTarget('a'));
  });
}
