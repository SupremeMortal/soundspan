// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/smtc_controls.dart';
import 'package:soundspan/platform/media_controls/media_controls_factory.dart';

import '../helpers/fake_clock.dart';

void main() {
  test('Android, iOS, macOS and Linux show audio_service controls', () {
    for (final os in ['android', 'ios', 'macos', 'linux']) {
      expect(
        mediaControlsKindFor(operatingSystem: os),
        MediaControlsKind.audioService,
        reason: os,
      );
    }
  });

  test('the web shows audio_service controls', () {
    expect(
      mediaControlsKindFor(operatingSystem: 'web', web: true),
      MediaControlsKind.audioService,
    );
  });

  test('Windows shows the System Media Transport Controls', () {
    expect(
      mediaControlsKindFor(operatingSystem: 'windows'),
      MediaControlsKind.smtc,
    );
  });

  test('an unknown platform shows none', () {
    expect(
      mediaControlsKindFor(operatingSystem: 'fuchsia'),
      MediaControlsKind.none,
    );
  });

  test('the selected kind is the controls built', () {
    MediaControls build(String os, {bool web = false}) => mediaControlsFor(
      operatingSystem: os,
      web: web,
      channelName: () => 'Playback',
      clock: FakeClock(),
    );

    expect(build('android'), isA<AudioServiceControls>());
    expect(build('web', web: true), isA<AudioServiceControls>());
    expect(build('windows'), isA<SmtcControls>());
    expect(build('fuchsia'), isA<NoopMediaControls>());
  });
}
