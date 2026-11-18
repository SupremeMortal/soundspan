// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// A smoke test of the platform's OS media controls (doc 06, OS Media
// Controls), run by the jobs of .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/media_controls_smoke_test.dart -d <device>
//
// on Linux under dbus-run-session, on Windows (SmtcControls over the
// soundspan_smtc plugin), and on the web with `flutter drive`.

@Tags(['engine'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/smtc_gateway.dart';
import 'package:soundspan/core/playback/media_controls/smtc_gateway_windows.dart';
import 'package:soundspan/platform/clock/system_clock.dart';
import 'package:soundspan/platform/media_controls/media_controls_factory.dart';

import 'support/session_bus_names.dart';
import 'support/smoke_thumbnail.dart';

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

  @override
  Future<void> setVolume(double volume) async {}

  @override
  MediaBrowseSource? get browseSource => null;

  @override
  DownloadsBrowse? get browseDownloads => null;

  @override
  Future<void> playRequest(PlayRequest request) async {}
}

MediaSessionState _track({required bool playing, Uri? artwork}) =>
    MediaSessionState(
      queueItemId: 'smoke-1',
      title: 'Smoke tone',
      artist: 'soundspan',
      album: 'Device tests',
      duration: const Duration(minutes: 3),
      artworkUri: artwork,
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
      final thumbnail = await smokeThumbnail();
      controls
        ..update(_track(playing: true, artwork: thumbnail))
        ..update(_track(playing: false, artwork: thumbnail))
        ..update(MediaSessionState.empty);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await controls.dispose();
    });
  });

  // SmtcControls sends without waiting, so its gateway's calls are also
  // awaited one by one: a failing plugin method fails this test.
  testWidgets('the Windows SMTC plugin accepts every call', (tester) async {
    await tester.runAsync(() async {
      final gateway = WindowsSmtcGateway();
      await gateway.init();
      final thumbnail = await smokeThumbnail();
      await gateway.setEnabledButtons(SmtcButton.values.toSet());
      await gateway.setMetadata(
        title: 'Smoke tone',
        artist: 'soundspan',
        album: 'Device tests',
        thumbnail: thumbnail,
      );
      for (final status in SmtcStatus.values) {
        await gateway.setStatus(status);
      }
      await gateway.setTimeline(
        position: const Duration(seconds: 42),
        duration: const Duration(seconds: 215),
      );
      await gateway.setTimeline(position: Duration.zero, duration: null);
      await gateway.clear();
      await gateway.dispose();
    });
  }, skip: kIsWeb || defaultTargetPlatform != TargetPlatform.windows);
}
