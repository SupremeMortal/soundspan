// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The desktop's OS media controls adapter initialises and accepts an update
// (doc 11, Integration (desktop); doc 10): MPRIS on Linux, SmtcControls on
// Windows, audio_service on macOS. Run by the desktop-integration jobs of
// .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/desktop/media_controls_smoke_test.dart -d <os>
//
// With --dart-define=MEDIA_CONTROLS_HOLD_FILE=<path> the test keeps the
// controls up until that file exists (at most two minutes), so the Linux job
// can check from outside that the session bus owns the MPRIS name.

@Tags(['desktop'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/platform/clock/system_clock.dart';
import 'package:soundspan/platform/media_controls/media_controls_factory.dart';

import '../support/session_bus_names.dart';

const String _holdFile = String.fromEnvironment('MEDIA_CONTROLS_HOLD_FILE');

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the desktop media controls initialise and accept an update', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final controls = createMediaControls(
        channelName: () => 'Playback',
        clock: const SystemClock(),
      );
      await controls.init(_Commands());
      controls.update(
        const MediaSessionState(
          queueItemId: 'desktop-smoke-1',
          title: 'Desktop smoke tone',
          artist: 'soundspan',
          album: 'Desktop integration',
          duration: Duration(minutes: 3),
          position: Duration(seconds: 5),
          playing: true,
          buffering: false,
          speed: 1,
          skipInterval: Duration(seconds: 15),
          actions: {
            MediaAction.pause,
            MediaAction.seek,
            MediaAction.stop,
            MediaAction.next,
            MediaAction.previous,
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final names = await sessionBusNames();
      if (names != null) {
        expect(
          names.where((n) => n.startsWith('$mprisBusNamePrefix.instance')),
          hasLength(1),
          reason: 'the MPRIS player is on the session bus',
        );
      }
      if (_holdFile.isNotEmpty) {
        final hold = File(_holdFile);
        final watch = Stopwatch()..start();
        while (!hold.existsSync() && watch.elapsed.inMinutes < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        expect(
          hold.existsSync(),
          isTrue,
          reason: 'the workflow step checked the bus and wrote $_holdFile',
        );
      }

      controls.update(MediaSessionState.empty);
      await controls.dispose();
    });
  });
}
