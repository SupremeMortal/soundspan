// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The database opener seam: how a drift database is opened and deleted.
///
/// `createDatabaseOpener(paths)` returns the native opener, which keeps the
/// files at the `AppPaths` locations of doc 05, or the web opener.
library;

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter/foundation.dart' show immutable;

export 'database_opener_web.dart'
    if (dart.library.io) 'database_opener_io.dart'
    show createDatabaseOpener;

/// One of the app's databases.
@immutable
sealed class DatabaseTarget {
  const new();
}

/// `app.db`: profiles and app settings.
final class AppDatabaseTarget extends DatabaseTarget {
  /// The app database.
  const new();

  @override
  bool operator ==(Object other) => other is AppDatabaseTarget;

  @override
  int get hashCode => (AppDatabaseTarget).hashCode;

  @override
  String toString() => 'AppDatabaseTarget()';
}

/// `state.db` of profile [profileId]: durable user state.
final class StateDatabaseTarget extends DatabaseTarget {
  /// The state database of [profileId].
  const new(this.profileId);

  /// The profile the database belongs to.
  final String profileId;

  @override
  bool operator ==(Object other) =>
      other is StateDatabaseTarget && other.profileId == profileId;

  @override
  int get hashCode => Object.hash(StateDatabaseTarget, profileId);

  @override
  String toString() => 'StateDatabaseTarget($profileId)';
}

/// `cache.db` of profile [profileId]: disposable server data.
final class CacheDatabaseTarget extends DatabaseTarget {
  /// The cache database of [profileId].
  const new(this.profileId);

  /// The profile the database belongs to.
  final String profileId;

  @override
  bool operator ==(Object other) =>
      other is CacheDatabaseTarget && other.profileId == profileId;

  @override
  int get hashCode => Object.hash(CacheDatabaseTarget, profileId);

  @override
  String toString() => 'CacheDatabaseTarget($profileId)';
}

/// Opens and deletes the app's databases.
abstract interface class DatabaseOpener {
  /// The executor of [target]; the database opens on first use.
  QueryExecutor open(DatabaseTarget target);

  /// Deletes [target] and its companion files. The database must be closed;
  /// a database that does not exist is not an error.
  Future<void> delete(DatabaseTarget target);
}
