// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine_provider.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/shared/clock.dart';

import '../../../helpers/fake_clock.dart';
import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

void main() {
  test('disposing the provider stops and disposes the engine', () async {
    final engine = RecordingEngine(
      FakeEngine(
        sources: {uriOf('a'): const FakeSource(duration: trackLength)},
      ),
    );
    final disposer = ProfileDisposer(AppLogger.scope('Test'));
    final container = ProviderContainer(
      overrides: [
        playerEngineBuilderProvider.overrideWithValue(() => engine),
        sourceResolverProvider.overrideWithValue(FakeResolver()),
        playbackInfoRepositoryProvider.overrideWithValue(
          PlaybackInfoRepository(MockPlaybackClient()),
        ),
        sessionControllerProvider.overrideWithValue(
          SessionController(
            profileId: 'p1',
            repository: MockProfileRepository(),
            clock: FakeClock(),
          ),
        ),
        profileDisposerProvider.overrideWithValue(disposer),
        clockProvider.overrideWithValue(FakeClock()),
      ],
    );
    final controller = container.read(playbackControllerProvider);
    expect(container.read(playbackControllerProvider), same(controller));
    await controller.playItems(trackItems(['a']));
    engine.calls.clear();

    await disposer.closeAll();
    container.dispose();
    await pumpEventQueue();

    expect(engine.calls, ['stop', 'dispose']);
    expect(engine.fake.isDisposed, isTrue);
  });
}
