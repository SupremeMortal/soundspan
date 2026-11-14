// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart';

/// App-wide settings as key/value rows; see `AppSettingsStore`.
class AppSettings extends Table {
  /// The setting's key.
  TextColumn get key => text()();

  /// The setting's value, JSON-encoded.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
