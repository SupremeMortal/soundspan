// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine_provider.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/data/playback_state_repository.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/sync_providers.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';
import '../../../helpers/idle_outbox.dart';
import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

/// A profile scope whose controller drives [engine] and stores its queue in
/// [database].
ProviderContainer _scope(
  RecordingEngine engine,
  ProfileDisposer disposer,
  StateDatabase database, {
  PlaybackStateRepository? states,
}) => ProviderContainer(
  overrides: [
    playerEngineBuilderProvider.overrideWithValue(() => engine),
    sourceResolverProvider.overrideWithValue(FakeResolver()),
    playbackInfoRepositoryProvider.overrideWithValue(
      PlaybackInfoRepository(MockPlaybackClient()),
    ),
    playbackStateRepositoryProvider.overrideWithValue(
      states ?? idlePlaybackStateRepository(),
    ),
    reachabilityProvider.overrideWithValue(FakeReachability()),
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

  test('a scope with no stored queue restores the state the server '
      'stored for this device and keeps it current', () async {
    final database = StateDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final client = MockPlaybackClient();
    registerFallbackValue(
      const api.SavePlaybackStateRequest(
        playbackType: api.SavePlaybackStateRequestPlaybackType.track,
      ),
    );
    when(client.getPlaybackState).thenAnswer(
      (_) async => api.PlaybackState.fromJson({
        'userId': 'u-1',
        'deviceId': 'device-1',
        'playbackType': 'track',
        'trackId': null,
        'audiobookId': null,
        'podcastId': null,
        'queue': [
          for (final id in ['pb-a', 'pb-b'])
            {
              'itemType': 'track',
              'id': 'library-$id',
              'playbackId': id,
              'title': 'Song $id',
              'duration': 10,
              'artist': {'id': 'ar-1', 'name': 'Band'},
              'album': {'id': 'al-1', 'title': 'Record', 'coverArt': null},
            },
        ],
        'currentIndex': 1,
        'isShuffle': false,
        'isPlaying': true,
        'currentTime': 4.0,
        'updatedAt': '2025-01-01T12:00:00.000Z',
        'createdAt': '2025-01-01T11:00:00.000Z',
      }),
    );
    when(() => client.savePlaybackState(body: any(named: 'body')))
        .thenAnswer((_) async => null);
    final container = _scope(
      _engine(),
      ProfileDisposer(AppLogger.scope('Test')),
      database,
      states: PlaybackStateRepository(client),
    );
    addTearDown(container.dispose);
    final controller = container.read(playbackControllerProvider);
    await pumpEventQueue();

    final snapshot = controller.snapshot;
    expect(
      [
        for (final item in snapshot.queue.items)
          (item as TrackQueueItem).track.playbackId?.value,
      ],
      ['pb-a', 'pb-b'],
    );
    expect(snapshot.queue.cursor, 1);
    expect(snapshot.position, const Duration(seconds: 4));
    expect(snapshot.playing, isFalse);
    verifyNever(() => client.savePlaybackState(body: any(named: 'body')));

    await controller.jumpTo(snapshot.queue.items.first.queueItemId);
    await pumpEventQueue();
    final body =
        verify(() => client.savePlaybackState(body: captureAny(named: 'body')))
                .captured
                .first
            as api.SavePlaybackStateRequest;
    expect(body.playbackId, 'pb-a');
  });
}
