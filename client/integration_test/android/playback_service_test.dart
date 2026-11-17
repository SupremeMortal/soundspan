// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The Android playback service (doc 10, Playback service), run on an API 34
// emulator by the engine-conformance-android job of
// .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/android/playback_service_test.dart \
//       -d emulator-5554
//
// A real PlaybackController plays a generated tone on the device's engine
// and is rendered on the real audio_service adapter through the
// MediaControlsBinder, as in the app.

@Tags(['engine'])
library;

import 'dart:io';

import 'package:audio_service/audio_service.dart' as svc;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_plugin.dart';
import 'package:soundspan/core/playback/media_controls/media_controls_binder.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/platform/clock/system_clock.dart';
import 'package:soundspan/platform/player_engine/player_engine_factory.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../test/core/playback/controller/controller_harness.dart'
    show MockPlaybackClient, MockProfileRepository;
import '../support/tone_server.dart';

/// Resolves every entry to the tone file at [_uri].
final class _ToneResolver implements SourceResolver {
  new(this._uri);

  final Uri _uri;

  @override
  Future<EngineSource> resolve(
    QueueItem item, {
    Duration startAt = Duration.zero,
  }) async =>
      EngineSource(queueItemId: item.queueItemId, uri: _uri, startAt: startAt);
}

/// Waits up to [timeout] for [condition], polling.
Future<void> _until(
  bool Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting: $reason');
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a track plays in the playback service with previous, '
      'pause, next and Like, Like reaches the command handler, and pause '
      'leaves the service paused', (tester) async {
    await tester.runAsync(() async {
      final temp = await getTemporaryDirectory();
      await temp.create(recursive: true);
      final tone = File('${temp.path}/playback-service-tone.wav')
        ..writeAsBytesSync(ToneServer.wav(const Duration(seconds: 30)));
      const clock = SystemClock();
      final controller = PlaybackController(
        engine: createPlayerEngine(),
        resolver: _ToneResolver(tone.uri),
        info: PlaybackInfoRepository(MockPlaybackClient()),
        session: SessionController(
          profileId: 'p1',
          repository: MockProfileRepository(),
          clock: clock,
        ),
        clock: clock,
      );
      SoundspanAudioHandler? handler;
      final controls = AudioServiceControls(
        config: () => audioServiceConfigFor(
          operatingSystem: 'android',
          channelName: 'Playback',
        ),
        start: (builder, config) async =>
            handler = await startAudioService(builder, config),
        clock: clock,
        likeLabel: (liked) => liked ? 'Remove like' : 'Like',
      );
      final likes = <bool>[];
      final binder = MediaControlsBinder(
        controller: controller,
        controls: controls,
        pin: (_) async => null,
        clock: clock,
        like: (_, {required liked}) async => likes.add(liked),
      );
      await controls.init(binder);
      final service = handler!;

      await controller.playItems(const [
        QueueItem.track(
          queueItemId: 'tone-1',
          track: Track(
            meta: TrackMeta(
              title: 'Playback service tone',
              artist: 'soundspan',
              album: 'Device tests',
              durationSec: 30,
            ),
            playbackId: PlaybackId('pb-tone-1'),
          ),
          context: QueueContext(
            kind: QueueContextKind.album,
            id: 'device-tests',
            title: 'Device tests',
          ),
        ),
      ]);
      await _until(
        () =>
            controller.snapshot.playing &&
            controller.snapshot.status == EngineStatus.ready &&
            controller.snapshot.position > const Duration(milliseconds: 500),
        reason: 'the engine plays the tone',
      );
      expect(controller.snapshot.error, isNull);
      await _until(
        () =>
            service.playbackState.value.playing &&
            service.playbackState.value.controls.length == 4,
        reason: 'the service shows the playing track',
      );

      final state = service.playbackState.value;
      expect(state.controls.take(3), [
        svc.MediaControl.skipToPrevious,
        svc.MediaControl.pause,
        svc.MediaControl.skipToNext,
      ]);
      expect(state.controls[3].customAction?.name, likeActionName);
      expect(state.controls[3].androidIcon, 'drawable/ic_action_like');
      expect(state.androidCompactActionIndices, [0, 1, 2]);

      await service.customAction(likeActionName);
      expect(likes, [true]);
      await _until(
        () =>
            service.playbackState.value.controls.last.androidIcon ==
            'drawable/ic_action_liked',
        reason: 'the Like action shows the track liked',
      );

      await service.pause();
      await _until(
        () => !service.playbackState.value.playing,
        reason: 'the service shows playback paused',
      );
      expect(controller.snapshot.playing, isFalse);

      await binder.dispose();
      await controls.dispose();
      await controller.dispose();
      if (tone.existsSync()) tone.deleteSync();
    });
  });
}
