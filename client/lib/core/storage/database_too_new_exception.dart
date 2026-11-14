// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Thrown when a database was written by a newer version of the app: its
/// stored schema version is higher than the one this build supports.
///
/// The database is not changed.
class DatabaseTooNewException implements Exception {
  /// Creates the exception for [database], stored at [found], when this build
  /// supports up to [supported].
  const new(this.database, this.found, this.supported);

  /// Which database, for example `app.db`.
  final String database;

  /// The schema version stored in the database.
  final int found;

  /// The highest schema version this build supports.
  final int supported;

  @override
  String toString() =>
      'DatabaseTooNewException: $database is at schema version $found; '
      'this build supports up to $supported';
}
