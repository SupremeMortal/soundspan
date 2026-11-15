// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

/// Reads and writes the `device_settings` rows of a profile's `state.db`
/// (doc 05). Values are stored JSON-encoded.
class DeviceSettingsDao {
  /// Creates the accessor over [_database].
  new(this._database);

  final StateDatabase _database;

  /// The decoded value of [key], or null when it is unset or does not
  /// decode.
  Future<Object?> read(String key) async =>
      _decode(await _query(key).getSingleOrNull());

  /// Stores [value], JSON-encoded, under [key], replacing any earlier value.
  Future<void> write(String key, Object? value) => _database
      .into(_database.deviceSettings)
      .insertOnConflictUpdate(
        DeviceSettingsCompanion.insert(key: key, value: jsonEncode(value)),
      );

  /// The decoded value of [key] now and after every change.
  Stream<Object?> watch(String key) =>
      _query(key).watchSingleOrNull().map(_decode);

  SimpleSelectStatement<$DeviceSettingsTable, DeviceSetting> _query(
    String key,
  ) =>
      _database.select(_database.deviceSettings)
        ..where((t) => t.key.equals(key));

  static Object? _decode(DeviceSetting? row) {
    if (row == null) return null;
    try {
      return jsonDecode(row.value);
    } on FormatException {
      return null;
    }
  }
}
