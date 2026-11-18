// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan/platform/notifications/local_notifications.dart';

/// The `device_settings` key set to true once the notification permission
/// was requested on this device.
const String notificationsAskedKey = 'notifications.asked';

/// The first Android API level with a runtime notification permission
/// (Android 13).
const int notificationPermissionSdk = 33;

final AppLogger _log = AppLogger.scope('NotificationPermission');

/// Asks for the notification permission at the first playback of a
/// session on Android 13 or later, unless it was asked before on this
/// device (doc 10, `POST_NOTIFICATIONS`).
///
/// It only watches the snapshots: playback starts whatever the answer, and
/// the request is never repeated automatically.
class NotificationPermissionPrompt {
  /// Watches [snapshots] for the first one playing; the request goes
  /// through [_notifications] and is remembered in [_settings].
  new({
    required Stream<PlaybackSnapshot> snapshots,
    required this._settings,
    required this._notifications,
    required this._androidSdkVersion,
  }) {
    _subscription = snapshots.listen(_onSnapshot);
  }

  final DeviceSettingsDao? _settings;
  final LocalNotifications _notifications;
  final AndroidSdkVersion _androidSdkVersion;
  late final StreamSubscription<PlaybackSnapshot> _subscription;
  bool _done = false;

  void _onSnapshot(PlaybackSnapshot snapshot) {
    if (_done || !snapshot.playing) return;
    _done = true;
    unawaited(_subscription.cancel());
    unawaited(_ask());
  }

  Future<void> _ask() async {
    try {
      final settings = _settings;
      final sdk = await _androidSdkVersion();
      if (settings == null || sdk == null || sdk < notificationPermissionSdk) {
        return;
      }
      if (await settings.read(notificationsAskedKey) == true) return;
      await settings.write(notificationsAskedKey, true);
      await _notifications.requestPermission();
    } on Object catch (error, stackTrace) {
      _log.warning(
        'The notification permission was not requested',
        const {},
        error,
        stackTrace,
      );
    }
  }

  /// Stops watching.
  Future<void> dispose() {
    _done = true;
    return _subscription.cancel();
  }
}
