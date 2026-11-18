// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' show LazyDatabase, QueryExecutor;
import 'package:drift/wasm.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:sqlite3/wasm.dart' show InMemoryFileSystem, WasmSqlite3;

/// Creates the web [DatabaseOpener].
DatabaseOpener createDatabaseOpener(AppPaths paths) => WebDatabaseOpener();

/// Opens the drift WASM database named [name].
typedef WasmOpen = Future<WasmDatabaseResult> Function(String name);

/// The web [DatabaseOpener]: drift WASM databases named by
/// [databaseNameOf], run through `web/sqlite3.wasm` and
/// `web/drift_worker.js`.
///
/// drift chooses the best storage the browser offers without cross-origin
/// isolation (doc 05, Web Storage). When the open throws, or drift can only
/// offer in-memory storage (private browsing), the database lives in memory
/// and [isVolatile] becomes true.
final class WebDatabaseOpener implements DatabaseOpener {
  /// Creates the opener. [openWasm] opens a persistent database; it defaults
  /// to `WasmDatabase.open` and a test passes one that fails.
  new({WasmOpen? openWasm}) : _openWasm = openWasm ?? _defaultOpen;

  static final Uri _sqlite3Uri = Uri.parse('sqlite3.wasm');
  static final Uri _driftWorkerUri = Uri.parse('drift_worker.js');

  final WasmOpen _openWasm;
  Future<WasmSqlite3>? _memorySqlite3;
  bool _volatile = false;

  static Future<WasmDatabaseResult> _defaultOpen(String name) =>
      WasmDatabase.open(
        databaseName: name,
        sqlite3Uri: _sqlite3Uri,
        driftWorkerUri: _driftWorkerUri,
      );

  @override
  bool get isVolatile => _volatile;

  @override
  QueryExecutor open(DatabaseTarget target) =>
      LazyDatabase(() => _open(databaseNameOf(target)));

  Future<QueryExecutor> _open(String name) async {
    try {
      final result = await _openWasm(name);
      if (result.chosenImplementation == WasmStorageImplementation.inMemory) {
        _volatile = true;
      }
      return result.resolvedExecutor;
    } on Object {
      _volatile = true;
      return WasmDatabase.inMemory(await _loadMemorySqlite3());
    }
  }

  Future<WasmSqlite3> _loadMemorySqlite3() =>
      _memorySqlite3 ??= WasmSqlite3.loadFromUrl(_sqlite3Uri).then(
        (sqlite3) => sqlite3
          ..registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true),
      );

  @override
  Future<void> delete(DatabaseTarget target) async {
    final name = databaseNameOf(target);
    final probe = await WasmDatabase.probe(
      sqlite3Uri: _sqlite3Uri,
      driftWorkerUri: _driftWorkerUri,
      databaseName: name,
    );
    for (final existing in probe.existingDatabases) {
      if (existing.$2 == name) await probe.deleteDatabase(existing);
    }
  }
}
