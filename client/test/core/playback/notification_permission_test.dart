// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/notification_permission.dart';

import '../../helpers/fake_local_notifications.dart';
import '../../helpers/memory_device_settings.dart';
import 'controller/controller_harness.dart';
import 'queue/queue_test_items.dart';

/// A controller harness with a [NotificationPermissionPrompt] on an
/// Android device of [sdk].
class _Prompt {
  new({required this.sdk, MemoryDeviceSettings? settings, bool granted = true})
    : settings = settings ?? MemoryDeviceSettings(),
      notifications = FakeLocalNotifications(granted: granted) {
    prompt = NotificationPermissionPrompt(
      snapshots: h.controller.snapshots,
      settings: this.settings,
      notifications: notifications,
      androidSdkVersion: () async => sdk,
    );
  }

  final int? sdk;
  final MemoryDeviceSettings settings;
  final FakeLocalNotifications notifications;
  final ControllerHarness h = ControllerHarness(ids: const ['a', 'b']);
  late final NotificationPermissionPrompt prompt;

  Future<void> playAndPausePlay() async {
    await h.controller.playItems(trackItems(['a', 'b']));
    await h.play(const Duration(seconds: 1));
    await h.controller.pause();
    await h.controller.play();
    await h.settle();
  }

  Future<void> dispose() async {
    await prompt.dispose();
    await h.controller.dispose();
  }
}

void main() {
  test('Android 13 asks once, on the first play of the session, and '
      'remembers that it asked', () async {
    final p = _Prompt(sdk: 33);

    await p.h.settle();
    expect(p.notifications.permissionRequests, 0);

    await p.playAndPausePlay();

    expect(p.notifications.permissionRequests, 1);
    expect(p.settings.values[notificationsAskedKey], isTrue);
    expect(p.h.controller.snapshot.playing, isTrue);
    await p.dispose();
  });

  test('a refusal is not asked again in a later session', () async {
    final settings = MemoryDeviceSettings();
    final first = _Prompt(sdk: 34, settings: settings, granted: false);
    await first.playAndPausePlay();
    await first.dispose();

    final second = _Prompt(sdk: 34, settings: settings, granted: false);
    await second.playAndPausePlay();

    expect(first.notifications.permissionRequests, 1);
    expect(second.notifications.permissionRequests, 0);
    expect(second.h.controller.snapshot.playing, isTrue);
    await second.dispose();
  });

  test('below Android 13 and off Android nothing is asked', () async {
    for (final sdk in [26, 32, null]) {
      final p = _Prompt(sdk: sdk);

      await p.playAndPausePlay();

      expect(p.notifications.permissionRequests, 0, reason: '$sdk');
      expect(p.settings.values, isNot(contains(notificationsAskedKey)));
      expect(p.h.controller.snapshot.playing, isTrue, reason: '$sdk');
      await p.dispose();
    }
  });

  test('a failing request is logged and playback goes on', () async {
    final h = ControllerHarness(ids: const ['a']);
    final prompt = NotificationPermissionPrompt(
      snapshots: h.controller.snapshots,
      settings: MemoryDeviceSettings(),
      notifications: _ThrowingNotifications(),
      androidSdkVersion: () async => 35,
    );

    await h.controller.playItems(trackItems(['a']));
    await h.play(const Duration(seconds: 1));

    expect(h.controller.snapshot.playing, isTrue);
    await prompt.dispose();
    await h.controller.dispose();
  });
}

class _ThrowingNotifications extends FakeLocalNotifications {
  @override
  Future<bool> requestPermission() async => throw StateError('no activity');
}
