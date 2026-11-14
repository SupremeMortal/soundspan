// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/platform/clock/system_clock.dart';
import 'package:soundspan/shared/clock.dart';

import '../helpers/fake_clock.dart';
import '../helpers/pump_app.dart';

void main() {
  group('FakeClock', () {
    test('now() returns the default start, in UTC', () {
      final clock = FakeClock();
      expect(clock.now(), DateTime.utc(2025));
      expect(clock.now().isUtc, isTrue);
    });

    test('now() returns a given start, converted to UTC', () {
      final start = DateTime.utc(2030, 6, 15, 12);
      final clock = FakeClock(start: start.toLocal());
      expect(clock.now(), start);
      expect(clock.now().isUtc, isTrue);
    });

    test('advance moves the time forward', () {
      final clock = FakeClock()..advance(const Duration(minutes: 90));
      expect(clock.now(), DateTime.utc(2025, 1, 1, 1, 30));
      clock.advance(const Duration(days: 1));
      expect(clock.now(), DateTime.utc(2025, 1, 2, 1, 30));
    });

    test('set jumps to a given time, kept in UTC', () {
      final target = DateTime.utc(2026, 3, 4, 5, 6, 7);
      final clock = FakeClock()..set(target.toLocal());
      expect(clock.now(), target);
      expect(clock.now().isUtc, isTrue);
    });
  });

  group('SystemClock', () {
    test('returns the current time in UTC', () {
      final before = DateTime.timestamp();
      final now = const SystemClock().now();
      final after = DateTime.timestamp();
      expect(now.isUtc, isTrue);
      expect(now.isBefore(before), isFalse);
      expect(now.isAfter(after), isFalse);
    });
  });

  group('clockProvider', () {
    test('yields a SystemClock by default', () {
      final container = ProviderContainer.test();
      expect(container.read(clockProvider), isA<SystemClock>());
    });

    testWidgets('yields a FakeClock under pumpApp', (tester) async {
      final container = await tester.pumpApp(const SizedBox());
      final clock = container.read(clockProvider);
      expect(clock, isA<FakeClock>());
      expect(clock.now(), DateTime.utc(2025));
    });

    testWidgets('yields the FakeClock passed to pumpApp', (tester) async {
      final fake = FakeClock(start: DateTime.utc(2027));
      final container = await tester.pumpApp(const SizedBox(), clock: fake);
      expect(container.read(clockProvider), same(fake));
    });
  });
}
