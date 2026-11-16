// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/platform/notifications/local_notifications.dart';

/// One notification a [FakeLocalNotifications] was asked to show.
typedef ShownNotification = ({
  int id,
  String channel,
  String title,
  String body,
  String? payload,
});

/// [LocalNotifications] that records what it is asked to show.
class FakeLocalNotifications implements LocalNotifications {
  /// Creates the fake; [granted] is what [requestPermission] answers.
  new({this.granted = true});

  /// What [requestPermission] answers.
  bool granted;

  /// How many times permission was asked for.
  int permissionRequests = 0;

  /// The notifications shown, oldest first.
  final List<ShownNotification> shown = [];

  final StreamController<String> _taps = StreamController<String>.broadcast();

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<void> show({
    required int id,
    required String channel,
    required String title,
    required String body,
    String? payload,
  }) async => shown.add((
    id: id,
    channel: channel,
    title: title,
    body: body,
    payload: payload,
  ));

  @override
  Stream<String> get taps => _taps.stream;

  /// Delivers a tap on a notification with [payload].
  void tap(String payload) => _taps.add(payload);
}
