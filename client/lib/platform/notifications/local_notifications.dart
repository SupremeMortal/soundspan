// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The local-notification seam (doc 02, Platform Seams).
///
/// `createLocalNotifications` returns, on native targets, notifications
/// through `flutter_local_notifications`; on web, a no-op that never gets
/// permission.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/notifications/local_notifications_web.dart'
    if (dart.library.io) 'package:soundspan/platform/notifications/local_notifications_io.dart';

export 'local_notifications_web.dart'
    if (dart.library.io) 'local_notifications_io.dart'
    show createLocalNotifications;

/// The Android channel of account notifications, such as an expiring
/// device link.
const String accountNotificationChannel = 'io.soundspan.app.account';

/// Shows notifications from the app itself, outside any server push.
abstract interface class LocalNotifications {
  /// Asks the user for permission to show notifications; true when they
  /// may be shown. Where the platform needs no permission it is true.
  Future<bool> requestPermission();

  /// Shows a notification [id] on [channel] with [title] and [body];
  /// [payload] comes back on [taps] when the user taps it. A second call
  /// with the same [id] replaces the first.
  Future<void> show({
    required int id,
    required String channel,
    required String title,
    required String body,
    String? payload,
  });

  /// The payloads of the notifications the user tapped, including the one
  /// that launched the app.
  Stream<String> get taps;
}

/// The app's [LocalNotifications]; tests override it.
final Provider<LocalNotifications> localNotificationsProvider =
    Provider<LocalNotifications>((ref) => createLocalNotifications());
