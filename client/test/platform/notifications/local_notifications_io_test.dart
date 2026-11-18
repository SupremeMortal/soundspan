// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/platform/notifications/local_notifications_io.dart';

import '../../core/logging/recording_sink.dart';

/// A plugin without launch details, as `flutter_local_notifications` is on
/// Linux.
class _NoLaunchDetailsPlugin implements FlutterLocalNotificationsPlugin {
  DidReceiveNotificationResponseCallback? onResponse;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    onResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() =>
      throw UnimplementedError(
        'getNotificationAppLaunchDetails() has not been implemented',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('without launch details the taps start without them, logged once, '
      'and later taps arrive', () async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: true);
    addTearDown(AppLogging.reset);
    final plugin = _NoLaunchDetailsPlugin();
    final notifications = PluginLocalNotifications(plugin: plugin);
    final taps = <String>[];
    final errors = <Object>[];
    final subscription = notifications.taps.listen(
      taps.add,
      onError: errors.add,
    );
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    plugin.onResponse!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'relink:p1',
      ),
    );
    await pumpEventQueue();

    expect(errors, isEmpty);
    expect(taps, ['relink:p1']);
    expect(sink.entries.where((e) => e.scope == 'Notifications').length, 1);
  });
}
