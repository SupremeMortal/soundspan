// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

import '../../helpers/fake_reachability.dart';

void main() {
  late StateDatabase db;
  late DeviceSettingsDao settings;
  late FakeReachability reachability;
  late StreamQualityPolicy policy;

  setUp(() {
    db = StateDatabase(NativeDatabase.memory());
    settings = DeviceSettingsDao(db);
    reachability = FakeReachability();
    policy = StreamQualityPolicy(settings, reachability);
  });
  tearDown(() => db.close());

  Future<void> store({String wifi = 'high', String cellular = 'low'}) async {
    await settings.write(qualityWifiKey, wifi);
    await settings.write(qualityCellularKey, cellular);
  }

  test('Wi-Fi reads quality.wifi', () async {
    await store();
    reachability.connectionType = ConnectionType.wifi;
    expect(await policy.current(), 'high');
  });

  test('cellular reads quality.cellular', () async {
    await store();
    reachability.connectionType = ConnectionType.cellular;
    expect(await policy.current(), 'low');
  });

  for (final type in [ConnectionType.other, ConnectionType.none]) {
    test('${type.name} reads the Wi-Fi value', () async {
      await store();
      reachability.connectionType = type;
      expect(await policy.current(), 'high');
    });
  }

  test('serverDefault gives null', () async {
    await store(wifi: serverDefaultQuality, cellular: serverDefaultQuality);
    expect(await policy.current(), isNull);
    reachability.connectionType = ConnectionType.cellular;
    expect(await policy.current(), isNull);
  });

  test('an unset value gives null', () async {
    expect(await policy.current(), isNull);
    reachability.connectionType = ConnectionType.cellular;
    expect(await policy.current(), isNull);
  });

  group('DeviceSettingsDao', () {
    test('write replaces the value and read decodes it', () async {
      await settings.write('playback.volume', 0.5);
      await settings.write('playback.volume', 0.8);
      expect(await settings.read('playback.volume'), 0.8);
      expect(await settings.read('missing'), isNull);
    });

    test('a value that is not JSON reads as null', () async {
      await db
          .into(db.deviceSettings)
          .insert(DeviceSettingsCompanion.insert(key: 'k', value: '{oops'));
      expect(await settings.read('k'), isNull);
    });

    test('watch emits the current value and every change', () async {
      final values = settings.watch(qualityWifiKey);
      final seen = expectLater(
        values,
        emitsInOrder(<Object?>[null, 'high', 'low']),
      );
      await pumpEventQueue();
      await settings.write(qualityWifiKey, 'high');
      await pumpEventQueue();
      await settings.write(qualityWifiKey, 'low');
      await seen;
    });
  });
}
