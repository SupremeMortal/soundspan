// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart'
    show GeneratedDatabase, LazyDatabase, QueryExecutor, Table, TableInfo;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/cache/open_cache_database.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/database_opener/database_opener_io.dart';
import 'package:soundspan/platform/paths/paths_io.dart';

/// A database without tables that claims [schemaVersion].
class _VersionedDatabase extends GeneratedDatabase {
  new(super.executor, this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
}

/// An opener whose every database fails on first use.
class _FailingOpener implements DatabaseOpener {
  final List<DatabaseTarget> deleted = [];
  int opens = 0;

  @override
  bool get isVolatile => false;

  @override
  QueryExecutor open(DatabaseTarget target) {
    opens++;
    return LazyDatabase(() => throw StateError('cannot open'));
  }

  @override
  Future<void> delete(DatabaseTarget target) async => deleted.add(target);
}

/// Records deletes, then delegates to the native opener.
class _RecordingOpener implements DatabaseOpener {
  new(this.inner);

  final DatabaseOpener inner;
  final List<DatabaseTarget> deleted = [];

  @override
  bool get isVolatile => inner.isVolatile;

  @override
  QueryExecutor open(DatabaseTarget target) => inner.open(target);

  @override
  Future<void> delete(DatabaseTarget target) {
    deleted.add(target);
    return inner.delete(target);
  }
}

final _at = DateTime.utc(2025, 1, 2);

void main() {
  late Directory root;
  late IoAppPaths paths;
  late _RecordingOpener opener;
  late File file;

  setUp(() {
    root = Directory.systemTemp.createTempSync('open_cache_database_test');
    paths = IoAppPaths(
      appSupport: p.join(root.path, 'support'),
      appCache: p.join(root.path, 'cache'),
    );
    opener = _RecordingOpener(IoDatabaseOpener(paths));
    file = File(paths.profile('p1').cacheDb);
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('a healthy file opens and keeps its rows', () async {
    final first = await openCacheDatabase(opener, 'p1');
    await first
        .into(first.blobs)
        .insert(BlobsCompanion.insert(key: 'home', json: '{}', fetchedAt: _at));
    await first.close();

    final second = await openCacheDatabase(opener, 'p1');
    addTearDown(second.close);

    final blobs = await second.select(second.blobs).get();
    expect(blobs.map((b) => b.key), ['home']);
    expect(opener.deleted, isEmpty);
  });

  test('a file with a different schema version is emptied and recreated, '
      'not migrated', () async {
    file.parent.createSync(recursive: true);
    final newer = _VersionedDatabase(NativeDatabase(file), 2);
    await newer.customStatement(
      'CREATE TABLE blobs (key TEXT PRIMARY KEY, json TEXT, extra TEXT)',
    );
    await newer.customStatement("INSERT INTO blobs VALUES ('home', '{}', 'x')");
    await newer.customStatement('CREATE TABLE future (x TEXT)');
    await newer.close();

    final db = await openCacheDatabase(opener, 'p1');
    addTearDown(db.close);

    expect(await db.select(db.blobs).get(), isEmpty);
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((row) => row.read<String>('name'))
        .get();
    expect(tables, unorderedEquals(db.allTables.map((t) => t.actualTableName)));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 1);
    // The blobs table has the current columns, so an insert works.
    await db
        .into(db.blobs)
        .insert(BlobsCompanion.insert(key: 'k', json: '{}', fetchedAt: _at));
    expect(opener.deleted, isEmpty);
  });

  test('a corrupt file is deleted and recreated once', () async {
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(List<int>.generate(8192, (i) => (i * 31) % 256));

    final db = await openCacheDatabase(opener, 'p1');
    addTearDown(db.close);

    expect(opener.deleted, [const CacheDatabaseTarget('p1')]);
    await db
        .into(db.blobs)
        .insert(BlobsCompanion.insert(key: 'k', json: '{}', fetchedAt: _at));
    expect(await db.select(db.blobs).get(), hasLength(1));
  });

  test('a second failure propagates', () async {
    final failing = _FailingOpener();

    await expectLater(openCacheDatabase(failing, 'p1'), throwsStateError);

    expect(failing.deleted, [const CacheDatabaseTarget('p1')]);
    expect(failing.opens, 2);
  });
}
