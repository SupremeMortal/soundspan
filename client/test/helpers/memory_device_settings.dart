// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/storage/state/device_settings_dao.dart';

/// [DeviceSettingsDao] over a map, outliving the controllers that use it.
class MemoryDeviceSettings implements DeviceSettingsDao {
  /// The stored values by key.
  final Map<String, Object?> values = {};

  @override
  Future<Object?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Object? value) async => values[key] = value;

  @override
  Stream<Object?> watch(String key) => Stream.value(values[key]);
}
