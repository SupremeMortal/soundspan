// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';

import '../../../../integration_test/support/device_audio_output.dart';

void main() {
  group('deviceAudioOutput', () {
    test("is mpv's null output on Windows", () {
      expect(deviceAudioOutput(operatingSystem: 'windows'), 'null');
    });

    test('is PulseAudio on Linux, so mpv never probes PipeWire', () {
      expect(deviceAudioOutput(operatingSystem: 'linux'), 'pulse');
    });

    test('is the production configuration elsewhere', () {
      for (final os in ['macos', 'android', 'ios']) {
        expect(deviceAudioOutput(operatingSystem: os), isNull, reason: os);
      }
    });
  });
}
