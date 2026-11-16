// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// A smoke test of the platform's OS media controls (doc 06, OS Media
// Controls), run by the jobs of .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/media_controls_smoke_test.dart -d <device>
//
// on Linux under dbus-run-session, and on the web with `flutter drive`.

@Tags(['engine'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/platform/clock/system_clock.dart';
import 'package:soundspan/platform/media_controls/media_controls_factory.dart';

import 'support/session_bus_names.dart';

class _Commands implements MediaCommandHandler {
  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> skipForward() async {}

  @override
  Future<void> skipBackward() async {}

  @override
  Future<void> setLiked(bool liked) async {}
}

MediaSessionState _track({required bool playing}) => MediaSessionState(
  queueItemId: 'smoke-1',
  title: 'Smoke tone',
  artist: 'soundspan',
  album: 'Device tests',
  duration: const Duration(minutes: 3),
  position: const Duration(seconds: 12),
  playing: playing,
  buffering: false,
  speed: 1,
  skipInterval: const Duration(seconds: 15),
  actions: {
    if (playing) MediaAction.pause else MediaAction.play,
    MediaAction.seek,
    MediaAction.stop,
    MediaAction.next,
    MediaAction.previous,
  },
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the platform media controls initialise, show a playing, a '
      'paused and the empty state, and are disposed', (tester) async {
    await tester.runAsync(() async {
      final controls = createMediaControls(
        channelName: () => 'Playback',
        clock: const SystemClock(),
      );

      await controls.init(_Commands());
      final names = await sessionBusNames();
      if (names != null) {
        expect(
          names.where((n) => n.startsWith('$mprisBusNamePrefix.instance')),
          hasLength(1),
          reason: 'the MPRIS player is on the session bus',
        );
      }
      controls
        ..update(_track(playing: true))
        ..update(_track(playing: false))
        ..update(MediaSessionState.empty);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await controls.dispose();
    });
  });
}
