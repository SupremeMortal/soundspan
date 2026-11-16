// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
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
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/shared/clock.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/idle_outbox.dart';
import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

/// A profile scope whose controller drives [engine] and stores its queue in
/// [database].
ProviderContainer _scope(
  RecordingEngine engine,
  ProfileDisposer disposer,
  StateDatabase database,
) => ProviderContainer(
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
    stateDatabaseProvider.overrideWithValue(database),
    outboxProvider.overrideWithValue(idleOutbox(database)),
  ],
);

RecordingEngine _engine() => RecordingEngine(
  FakeEngine(sources: {uriOf('a'): const FakeSource(duration: trackLength)}),
);

void main() {
  test('disposing the provider stops and disposes the engine', () async {
    final engine = _engine();
    final disposer = ProfileDisposer(AppLogger.scope('Test'));
    final database = StateDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = _scope(engine, disposer, database);
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

  test('the next scope restores the queue the last one stored when it '
      'ended', () async {
    final database = StateDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final firstDisposer = ProfileDisposer(AppLogger.scope('Test'));
    final first = _scope(_engine(), firstDisposer, database);
    await first
        .read(playbackControllerProvider)
        .playItems(trackItems(['a', 'b']));
    await firstDisposer.closeAll();
    first.dispose();

    final engine = _engine();
    final second = _scope(
      engine,
      ProfileDisposer(AppLogger.scope('Test')),
      database,
    );
    addTearDown(second.dispose);
    final controller = second.read(playbackControllerProvider);
    await controller.restore();
    await pumpEventQueue();

    expect(idsOf(controller.snapshot.queue.items), ['a', 'b']);
    expect(controller.snapshot.current?.queueItemId, 'a');
    expect(controller.snapshot.playing, isFalse);
    expect(engine.calls, isEmpty);
  });
}
