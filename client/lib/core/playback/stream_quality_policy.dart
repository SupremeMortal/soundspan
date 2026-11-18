// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';

/// The `device_settings` key of the stream quality on Wi-Fi and every
/// connection that is not cellular.
const qualityWifiKey = 'quality.wifi';

/// The `device_settings` key of the stream quality on a cellular
/// connection.
const qualityCellularKey = 'quality.cellular';

/// The stored quality value that means "let the server decide".
const serverDefaultQuality = 'serverDefault';

/// Chooses the `quality` of a stream URL from the device settings and the
/// current connection (doc 06, Source Resolution).
class StreamQualityPolicy {
  /// Creates the policy over a profile's settings and the reachability
  /// controller that reports the connection type.
  new(this._settings, this._reachability);

  final DeviceSettingsDao _settings;
  final ReachabilityController _reachability;

  /// The quality to request now: `quality.cellular` on a cellular
  /// connection and `quality.wifi` otherwise. Null, meaning the server
  /// default, when the setting is unset, not a string, or `serverDefault`.
  Future<String?> current() async {
    final key = _reachability.connectionType == ConnectionType.cellular
        ? qualityCellularKey
        : qualityWifiKey;
    return switch (await _settings.read(key)) {
      serverDefaultQuality => null,
      final String quality => quality,
      _ => null,
    };
  }
}
