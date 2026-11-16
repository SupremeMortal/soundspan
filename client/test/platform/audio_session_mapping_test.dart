// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/audio_session/audio_session_gateway.dart';
import 'package:soundspan/platform/audio_session/audio_session_mapping.dart';

void main() {
  group('plugin interruption events map to AudioSessionEvent', () {
    final rows = <(bool, AudioInterruptionType, AudioSessionEvent)>[
      (true, AudioInterruptionType.duck, const DuckBegan()),
      (false, AudioInterruptionType.duck, const DuckEnded()),
      (true, AudioInterruptionType.pause, const InterruptionBegan()),
      (true, AudioInterruptionType.unknown, const InterruptionBegan()),
      (
        false,
        AudioInterruptionType.pause,
        const InterruptionEnded(shouldResume: true),
      ),
      (
        false,
        AudioInterruptionType.unknown,
        const InterruptionEnded(shouldResume: false),
      ),
    ];
    for (final (begin, type, expected) in rows) {
      test('${begin ? 'begin' : 'end'} of ${type.name} is $expected', () {
        expect(
          audioSessionEventOf(AudioInterruptionEvent(begin, type)),
          expected,
        );
      });
    }
  });

  group('profiles map to the plugin configuration', () {
    test('music is music() without pausing when ducked', () {
      final config = audioSessionConfigurationOf(AudioFocusProfile.music);
      const music = AudioSessionConfiguration.music();
      expect(config.avAudioSessionCategory, music.avAudioSessionCategory);
      expect(
        config.androidAudioAttributes?.usage,
        music.androidAudioAttributes?.usage,
      );
      expect(
        config.androidAudioAttributes?.contentType,
        AndroidAudioContentType.music,
      );
      expect(config.androidWillPauseWhenDucked, isFalse);
    });

    test('speech is speech() without pausing when ducked', () {
      final config = audioSessionConfigurationOf(AudioFocusProfile.speech);
      const speech = AudioSessionConfiguration.speech();
      expect(config.avAudioSessionMode, speech.avAudioSessionMode);
      expect(
        config.androidAudioAttributes?.contentType,
        AndroidAudioContentType.speech,
      );
      expect(config.androidWillPauseWhenDucked, isFalse);
    });
  });

  test('the no-op gateway grants focus and has no events', () async {
    const gateway = NoopAudioSessionGateway();
    await gateway.configure(AudioFocusProfile.music);
    expect(await gateway.setActive(true), isTrue);
    expect(await gateway.events.isEmpty, isTrue);
    expect(gateway.osDucksItself, isFalse);
  });
}
