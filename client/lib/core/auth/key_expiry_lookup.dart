// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/auth/api_key_repository.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// When a device-link key was issued and when it expires.
@immutable
final class KeyDates {
  /// Creates the pair.
  const new({required this.createdAt, required this.expiresAt});

  /// When the key was issued, in UTC.
  final DateTime createdAt;

  /// When the key stops working, in UTC.
  final DateTime expiresAt;
}

/// Finds the dates of the key this device was just given (doc 04, Device
/// Link): the newest key named after the device, or now and now + 90 days
/// when there is none or the list cannot be read.
class KeyExpiryLookup {
  /// Creates the lookup over [_keys], reading time from [_clock].
  const new(this._keys, this._clock);

  /// How long a key lives when its dates cannot be read.
  static const fallbackLifetime = Duration(days: 90);

  final ApiKeyRepository _keys;
  final Clock _clock;

  /// The dates of the newest key named [deviceName].
  Future<KeyDates> lookup({required String deviceName}) async {
    final List<ApiKeyInfo> keys;
    try {
      keys = await _keys.list();
    } on ApiException {
      return _fallback();
    }
    ApiKeyInfo? newest;
    for (final key in keys) {
      if (key.name != deviceName) continue;
      if (newest == null || key.createdAt.isAfter(newest.createdAt)) {
        newest = key;
      }
    }
    if (newest == null) return _fallback();
    return KeyDates(createdAt: newest.createdAt, expiresAt: newest.expiresAt);
  }

  KeyDates _fallback() {
    final now = _clock.now().toUtc();
    return KeyDates(createdAt: now, expiresAt: now.add(fallbackLifetime));
  }
}
