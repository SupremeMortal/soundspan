// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/paths/paths.dart';

/// Creates the web [DatabaseOpener].
DatabaseOpener createDatabaseOpener(AppPaths paths) =>
    const WebDatabaseOpener();

/// A placeholder web [DatabaseOpener] whose methods throw
/// [UnsupportedError], so the web build compiles until the drift WASM
/// opener exists.
final class WebDatabaseOpener implements DatabaseOpener {
  /// Creates the web opener.
  const new();

  @override
  QueryExecutor open(DatabaseTarget target) =>
      throw UnsupportedError('Databases are not available on web yet');

  @override
  Future<void> delete(DatabaseTarget target) =>
      throw UnsupportedError('Databases are not available on web yet');
}
