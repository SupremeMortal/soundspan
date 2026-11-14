// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart' show SizedBox, runApp;
import 'package:web/web.dart' as web;

/// The three database names of doc 05 (Files on Disk, web database names).
const databaseNames = ['app', 'p_spike_state', 'p_spike_cache'];

/// Opens the three drift WASM databases, increments a counter in each and
/// publishes the outcome as `S6:<json>` in `document.title`.
Future<void> main() async {
  runApp(const SizedBox.shrink());
  final results = <String, Object?>{};
  for (final name in databaseNames) {
    results[name] = await _measure(name);
  }
  final report = {
    'crossOriginIsolated': web.window.crossOriginIsolated,
    'userAgent': web.window.navigator.userAgent,
    'databases': results,
  };
  web.document.title = 'S6:${jsonEncode(report)}';
}

Future<Map<String, Object?>> _measure(String name) async {
  WasmDatabaseResult? opened;
  final db = SpikeDatabase(
    driftDatabase(
      name: name,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) => opened = result,
      ),
    ),
  );
  try {
    final row = await db
        .customSelect('SELECT value FROM counter WHERE id = 1')
        .getSingleOrNull();
    final next = (row?.read<int>('value') ?? 0) + 1;
    await db.customStatement(
      'INSERT OR REPLACE INTO counter (id, value) VALUES (1, ?)',
      [next],
    );
    return {
      'opened': true,
      'implementation': opened?.chosenImplementation.name,
      'missingFeatures': [
        ...?opened?.missingFeatures.map((feature) => feature.name),
      ],
      'counter': next,
    };
  } on Object catch (error) {
    return {
      'opened': false,
      'implementation': opened?.chosenImplementation.name,
      'error': error.toString(),
    };
  }
  // The databases stay open for the life of the page, as the client's do.
}

/// A drift database with one table, `counter`, created without code
/// generation.
class SpikeDatabase extends GeneratedDatabase {
  /// Wraps [executor].
  SpikeDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => customStatement(
      'CREATE TABLE IF NOT EXISTS counter '
      '(id INTEGER PRIMARY KEY, value INTEGER NOT NULL)',
    ),
  );
}
