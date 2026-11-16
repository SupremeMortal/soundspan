// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/notifications/local_notifications.dart';

/// The web [LocalNotifications]: a no-op that never gets permission.
LocalNotifications createLocalNotifications() => const NoLocalNotifications();

/// [LocalNotifications] that shows nothing.
class NoLocalNotifications implements LocalNotifications {
  /// Creates the no-op.
  const new();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> show({
    required int id,
    required String channel,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Stream<String> get taps => const Stream.empty();
}
