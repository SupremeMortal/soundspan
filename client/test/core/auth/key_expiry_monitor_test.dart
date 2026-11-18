// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/key_expiry_monitor.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/notifications/local_notifications.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_local_notifications.dart';

void main() {
  final expiry = DateTime.utc(2026, 6, 1, 12);
  final created = expiry.subtract(const Duration(days: 90));
  late StateDatabase db;
  late DeviceSettingsDao settings;
  late FakeClock clock;
  late FakeLocalNotifications notifications;
  late StreamController<Profile?> profiles;
  final monitors = <KeyExpiryMonitor>[];

  Profile profile({
    AuthKind authKind = AuthKind.deviceLink,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool noExpiry = false,
  }) => Profile(
    id: 'p1',
    baseUrl: Uri.parse('https://music.example.com'),
    displayName: 'music.example.com',
    userId: 'user-1',
    username: 'ada',
    role: 'user',
    authKind: authKind,
    deviceId: 'd1',
    credentialCreatedAt: createdAt ?? created,
    credentialExpiresAt: noExpiry ? null : (expiresAt ?? expiry),
    state: ProfileState.active,
    lastUsedAt: created,
  );

  void daysBefore(int days) => clock.set(
    expiry.subtract(Duration(days: days)).add(const Duration(hours: 1)),
  );

  Future<KeyExpiryMonitor> start(Profile? first) async {
    profiles = StreamController<Profile?>.broadcast();
    final monitor = KeyExpiryMonitor(
      profile: profiles.stream,
      settings: settings,
      notifications: notifications,
      clock: clock,
      text: (days) => (title: 'Link expiring', body: 'in $days days'),
    );
    monitors.add(monitor);
    await monitor.start(first);
    return monitor;
  }

  setUp(() {
    db = StateDatabase(NativeDatabase.memory());
    settings = DeviceSettingsDao(db);
    clock = FakeClock();
    notifications = FakeLocalNotifications();
  });
  tearDown(() async {
    for (final monitor in monitors) {
      monitor.dispose();
    }
    monitors.clear();
    await db.close();
  });

  test('15 days out: none, no notification', () async {
    daysBefore(15);

    final monitor = await start(profile());

    expect(monitor.current, KeyExpiryState.none);
    expect(notifications.shown, isEmpty);
    expect(notifications.permissionRequests, 0);
  });

  test('14 days out: expiring(14) and one notification', () async {
    daysBefore(14);

    final monitor = await start(profile());

    expect(monitor.current, const KeyExpiryState.expiring(14));
    final shown = notifications.shown.single;
    expect(shown.channel, accountNotificationChannel);
    expect(shown.payload, 'relink:p1');
    expect(shown.body, 'in 14 days');
  });

  test('notifies at 14, 3 and 1 day and nowhere else', () async {
    daysBefore(14);
    final monitor = await start(profile());
    expect(notifications.shown, hasLength(1));

    for (var days = 13; days >= 4; days--) {
      daysBefore(days);
      await monitor.evaluate();
      expect(monitor.current, KeyExpiryState.expiring(days));
    }
    expect(notifications.shown, hasLength(1));

    daysBefore(3);
    await monitor.evaluate();
    expect(notifications.shown, hasLength(2));
    daysBefore(2);
    await monitor.evaluate();
    expect(notifications.shown, hasLength(2));
    daysBefore(1);
    await monitor.evaluate();
    expect(monitor.current, const KeyExpiryState.expiring(1));
    expect(notifications.shown, hasLength(3));
  });

  test('0 and -1 days: expired, no notification', () async {
    clock.set(expiry);
    final monitor = await start(profile());
    expect(monitor.current, KeyExpiryState.expired);

    clock.set(expiry.add(const Duration(days: 1)));
    await monitor.evaluate();

    expect(monitor.current, KeyExpiryState.expired);
    expect(notifications.shown, isEmpty);
  });

  test('first opened 2 days out: one notification for threshold 3', () async {
    daysBefore(2);

    final monitor = await start(profile());

    expect(monitor.current, const KeyExpiryState.expiring(2));
    expect(notifications.shown, hasLength(1));
    expect(await settings.read(keyExpiryNotifiedKey), {
      'credentialCreatedAt': created.toIso8601String(),
      'threshold': 3,
    });
  });

  test('a restart on the same day does not notify again', () async {
    daysBefore(14);
    (await start(profile())).dispose();

    await start(profile());

    expect(notifications.shown, hasLength(1));
  });

  test('a new credential resets the thresholds', () async {
    daysBefore(3);
    final monitor = await start(profile());
    expect(notifications.shown, hasLength(1));

    final renewed = profile(
      createdAt: clock.now(),
      expiresAt: clock.now().add(const Duration(days: 2, hours: 1)),
    );
    profiles.add(renewed);
    await pumpEventQueue();

    expect(monitor.current, const KeyExpiryState.expiring(3));
    expect(notifications.shown, hasLength(2));
  });

  test('a re-link to a far expiry returns to none', () async {
    daysBefore(3);
    final monitor = await start(profile());
    final states = <KeyExpiryState>[];
    monitor.states.listen(states.add);

    profiles.add(
      profile(
        createdAt: clock.now(),
        expiresAt: clock.now().add(const Duration(days: 90)),
      ),
    );
    await pumpEventQueue();

    expect(monitor.current, KeyExpiryState.none);
    expect(states, [KeyExpiryState.none]);
  });

  test('a password profile and a null expiry stay none', () async {
    clock.set(expiry);

    final password = await start(profile(authKind: AuthKind.password));
    final unknown = await start(profile(noExpiry: true));

    expect(password.current, KeyExpiryState.none);
    expect(unknown.current, KeyExpiryState.none);
    expect(notifications.shown, isEmpty);
  });

  test('permission refused: no show and the state is unchanged', () async {
    notifications.granted = false;
    daysBefore(14);

    final monitor = await start(profile());

    expect(notifications.permissionRequests, 1);
    expect(notifications.shown, isEmpty);
    expect(monitor.current, const KeyExpiryState.expiring(14));
  });
}
