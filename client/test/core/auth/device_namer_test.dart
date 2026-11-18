// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/device_namer.dart';
import 'package:soundspan/platform/device_info/device_info.dart';

void main() {
  test('desktop uses the host name and the OS', () {
    const namer = DeviceNamer(
      DeviceInfo(hostName: 'studio-pc', osLabel: 'Linux', isMobile: false),
    );

    expect(namer.defaultName(), 'studio-pc (soundspan Linux)');
  });

  test('Android is "Android phone"', () {
    const namer = DeviceNamer(
      DeviceInfo(hostName: 'localhost', osLabel: 'Android', isMobile: true),
    );

    expect(namer.defaultName(), 'Android phone (soundspan Android)');
  });

  test('iOS is "iPhone"', () {
    const namer = DeviceNamer(
      DeviceInfo(hostName: 'iPhone-7', osLabel: 'iOS', isMobile: true),
    );

    expect(namer.defaultName(), 'iPhone (soundspan iOS)');
  });

  test('a 200-character host name is cut to 64 characters and keeps the '
      'suffix', () {
    final namer = DeviceNamer(
      DeviceInfo(hostName: 'h' * 200, osLabel: 'Windows', isMobile: false),
    );

    final name = namer.defaultName();

    expect(name.length, DeviceNamer.maxLength);
    expect(name, endsWith(' (soundspan Windows)'));
    expect(name, startsWith('hhhh'));
  });

  test('a desktop without a host name uses the OS as its label', () {
    const namer = DeviceNamer(DeviceInfo(osLabel: 'macOS', isMobile: false));

    expect(namer.defaultName(), 'macOS (soundspan macOS)');
  });

  group('normalize', () {
    const namer = DeviceNamer(
      DeviceInfo(hostName: 'studio-pc', osLabel: 'Linux', isMobile: false),
    );

    test('trims and collapses whitespace runs', () {
      expect(
        namer.normalize('  Living \t room\n  speaker  '),
        'Living room speaker',
      );
    });

    test('cuts to 64 characters', () {
      expect(namer.normalize('x' * 100), 'x' * 64);
    });

    test('whitespace only falls back to the default name', () {
      expect(namer.normalize(' \t\n '), 'studio-pc (soundspan Linux)');
    });

    test('does not split a character outside the basic plane', () {
      final name = namer.normalize('${'x' * 63}🎵');

      expect(name, 'x' * 63);
    });
  });
}
