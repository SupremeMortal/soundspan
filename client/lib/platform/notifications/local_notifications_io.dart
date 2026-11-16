// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:soundspan/platform/notifications/local_notifications.dart';

/// The native [LocalNotifications], over `flutter_local_notifications`.
LocalNotifications createLocalNotifications() => PluginLocalNotifications();

/// [LocalNotifications] over `flutter_local_notifications`. The plugin is
/// initialized on first use, without asking for permission.
class PluginLocalNotifications implements LocalNotifications {
  /// Creates the notifications over [plugin].
  new({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// The Windows toast activator GUID of the app (doc 10, Windows).
  static const windowsGuid = '4bf43cb4-9830-433a-b7be-8872cc40d022';

  static const _channelNames = <String, String>{
    accountNotificationChannel: 'Account',
  };

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  Future<void>? _ready;
  String? _launchPayload;

  Future<void> _init() => _ready ??= () async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_soundspan'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'soundspan',
          appUserModelId: 'io.soundspan.app',
          guid: windowsGuid,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchPayload = launch?.notificationResponse?.payload;
    }
  }();

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    if (Platform.isMacOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return true;
  }

  @override
  Future<void> show({
    required int id,
    required String channel,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          _channelNames[channel] ?? channel,
          icon: 'ic_stat_soundspan',
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
        linux: const LinuxNotificationDetails(),
      ),
    );
  }

  @override
  Stream<String> get taps async* {
    await _init();
    final launch = _launchPayload;
    _launchPayload = null;
    if (launch != null) yield launch;
    yield* _taps.stream;
  }
}
