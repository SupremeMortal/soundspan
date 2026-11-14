// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';

/// Per-profile, per-device settings as key/value rows (doc 05).
class DeviceSettings extends Table {
  /// The setting's key, for example `playback.volume`.
  TextColumn get key => text()();

  /// The setting's value, JSON-encoded.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
