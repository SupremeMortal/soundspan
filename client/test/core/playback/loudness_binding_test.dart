// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

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
import 'package:soundspan/core/playback/loudness.dart';
import 'package:soundspan/core/playback/loudness_binding.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/settings/settings_providers.dart';
import 'package:soundspan/core/profile/settings/settings_repository.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/sync_providers.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/idle_outbox.dart';
import 'controller/controller_harness.dart';

/// How far into the next item playback runs.
const Duration _past = FakeEngine.positionInterval;

/// -10 LUFS: -8 dB at the default target.
const _loud = Loudness(loudnessLufs: -10, truePeakDb: -1);

/// -24 LUFS with 6 dB of headroom: +3 dB at the default target.
const _quiet = Loudness(loudnessLufs: -24, truePeakDb: -6);

/// -20 LUFS, -1 dBTP: +1 dB at the default target.
const _soft = Loudness(loudnessLufs: -20, truePeakDb: -1);

/// A track entry [id] with [loudness], queued from [kind].
QueueItem _track(
  String id,
  Loudness? loudness, {
  QueueContextKind kind = QueueContextKind.playlist,
}) => QueueItem.track(
  queueItemId: id,
  track: Track(
    meta: TrackMeta(
      title: 'Song $id',
      artist: 'Band',
      album: 'Record',
      durationSec: 180,
    ),
    playbackId: PlaybackId('pb-$id'),
    loudness: loudness,
  ),
  context: QueueContext(kind: kind),
);

/// An episode entry [id].
QueueItem _episode(String id) => QueueItem.episode(
  queueItemId: id,
  episode: const Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'Episode',
    durationSec: 600,
  ),
  podcast: const Podcast(id: 'pod1', title: 'Podcast'),
);

class _MockSessionClient extends Mock implements api.SessionClient;

api.UserSettings _wire(String loudnessMode) => api.UserSettings.fromJson({
  'userId': 'u-1',
  'displayName': null,
  'playbackQuality': 'high',
  'loudnessMode': loudnessMode,
  'maxCacheSizeMb': 2048,
  'offlineEnabled': false,
  'shareListeningStatus': true,
  'shareOnlinePresence': true,
  'showTidalExplore': false,
  'showYtMusicExplore': false,
  'tidalStreamingQuality': 'HIGH',
  'wifiOnly': false,
  'ytMusicQuality': 'HIGH',
});

void main() {
  late ControllerHarness h;
  late LoudnessBinding binding;
  var mode = LoudnessMode.track;
  var target = -18.0;

  setUp(() {
    mode = LoudnessMode.track;
    target = -18.0;
    h = ControllerHarness(ids: ['a', 'b', 'c', 'e']);
    binding = LoudnessBinding(
      controller: h.controller,
      mode: () => mode,
      targetLufs: () => target,
    );
  });
  tearDown(() => binding.dispose());

  test('the engine volume after a track becomes current is the user volume '
      'times the linear gain', () async {
    await h.controller.setVolume(0.8);
    await h.controller.playItems([_track('a', _loud)]);
    await h.settle();

    expect(h.fake.volume, closeTo(0.8 * gainToLinear(-8), 1e-9));
  });

  test('a +3 dB gain stays at 1.0 at full user volume and is about 0.706 '
      'at half', () async {
    await h.controller.playItems([_track('a', _quiet)]);
    await h.settle();
    expect(h.fake.volume, 1.0);

    await h.controller.setVolume(0.5);
    expect(h.fake.volume, closeTo(0.706, 0.001));
  });

  test('a gapless advance to a track with another gain changes the volume '
      'on AdvancedToNext', () async {
    await h.controller.setVolume(0.5);
    await h.controller.playItems([_track('a', _loud), _track('b', _soft)]);
    await h.settle();
    expect(h.fake.volume, closeTo(0.5 * gainToLinear(-8), 1e-9));

    await h.play(trackLength + _past);

    expect(h.controller.snapshot.current?.queueItemId, 'b');
    expect(h.calls.where((c) => c.startsWith('load')), hasLength(1));
    expect(h.fake.volume, closeTo(0.5 * gainToLinear(1), 1e-9));
  });

  test('a jump and a skip apply the gain of the new item', () async {
    await h.controller.setVolume(0.5);
    await h.controller.playItems([
      _track('a', _loud),
      _track('b', _soft),
      _track('c', null),
    ]);
    await h.controller.next();
    await h.settle();
    expect(h.fake.volume, closeTo(0.5 * gainToLinear(1), 1e-9));

    await h.controller.jumpTo('c');
    await h.settle();
    expect(h.fake.volume, closeTo(0.5, 1e-9));
  });

  test('an episode resets the factor to 1.0', () async {
    await h.controller.setVolume(0.5);
    await h.controller.playItems([_track('a', _loud), _episode('e')]);
    await h.settle();
    expect(h.fake.volume, closeTo(0.5 * gainToLinear(-8), 1e-9));

    await h.controller.next();
    await h.settle();

    expect(h.fake.volume, closeTo(0.5, 1e-9));
  });

  test('a mode change mid-item takes effect from the next item', () async {
    mode = LoudnessMode.off;
    await h.controller.setVolume(0.5);
    await h.controller.playItems([_track('a', _loud), _track('b', _loud)]);
    await h.settle();
    expect(h.fake.volume, closeTo(0.5, 1e-9));

    mode = LoudnessMode.track;
    await h.play(const Duration(seconds: 2));
    expect(h.fake.volume, closeTo(0.5, 1e-9));

    await h.controller.next();
    await h.settle();
    expect(h.fake.volume, closeTo(0.5 * gainToLinear(-8), 1e-9));
  });

  test('auto uses album values in an album context', () async {
    mode = LoudnessMode.auto;
    const both = Loudness(
      loudnessLufs: -20,
      truePeakDb: -1,
      albumLoudnessLufs: -10,
      albumTruePeakDb: -1,
    );
    await h.controller.setVolume(0.5);
    await h.controller.playItems([
      _track('a', both, kind: QueueContextKind.album),
    ]);
    await h.settle();

    expect(h.fake.volume, closeTo(0.5 * gainToLinear(-8), 1e-9));
  });

  group('user volume', () {
    late StateDatabase db;
    late DeviceSettingsDao settings;

    setUp(() {
      db = StateDatabase(NativeDatabase.memory());
      settings = DeviceSettingsDao(db);
    });
    tearDown(() => db.close());

    test('setVolume writes playback.volume and a new controller reads it '
        'back', () async {
      final first = ControllerHarness(deviceSettings: settings);
      await first.controller.setVolume(0.25);
      expect(await settings.read(playbackVolumeKey), '0.25');
      await first.controller.dispose();

      final second = ControllerHarness(deviceSettings: settings);
      await second.settle();

      expect(second.controller.volume, 0.25);
      expect(second.fake.volume, 0.25);
      await second.controller.dispose();
    });

    test('the volume is 1.0 when nothing is stored', () async {
      final fresh = ControllerHarness(deviceSettings: settings);
      await fresh.settle();

      expect(fresh.controller.volume, 1.0);
      await fresh.controller.dispose();
    });
  });

  group('loudnessModeProvider', () {
    late _MockSessionClient client;
    late ProviderContainer container;

    setUp(() {
      client = _MockSessionClient();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            SettingsRepository(client),
          ),
        ],
      );
    });
    tearDown(() => container.dispose());

    test(
      'is off until the settings have loaded, then the stored mode',
      () async {
        final answer = Completer<api.UserSettings>();
        when(() => client.getSettings()).thenAnswer((_) => answer.future);

        expect(container.read(loudnessModeProvider), LoudnessMode.off);
        answer.complete(_wire('album'));
        await pumpEventQueue();

        expect(container.read(loudnessModeProvider), LoudnessMode.album);
        verify(() => client.getSettings()).called(1);
      },
    );

    test('stays off when loading fails', () async {
      when(() => client.getSettings())
          .thenThrow(const api.ServerError(status: 500));

      expect(container.read(loudnessModeProvider), LoudnessMode.off);
      await pumpEventQueue();

      expect(container.read(loudnessModeProvider), LoudnessMode.off);
    });

    test('setLoudnessMode replaces the known mode', () async {
      when(() => client.getSettings()).thenAnswer((_) async => _wire('album'));
      container.read(loudnessModeProvider);
      await pumpEventQueue();

      container
          .read(loudnessModeProvider.notifier)
          .setLoudnessMode(LoudnessMode.track);

      expect(container.read(loudnessModeProvider), LoudnessMode.track);
    });
  });

  test(
    'the controller provider applies the mode and the server target',
    () async {
      final client = _MockSessionClient();
      final answer = Completer<api.UserSettings>();
      when(client.getSettings).thenAnswer((_) => answer.future);
      final db = StateDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final fake = FakeEngine(
        sources: {
          for (final id in ['a', 'b'])
            uriOf(id): const FakeSource(duration: trackLength),
        },
      );
      final disposer = ProfileDisposer(AppLogger.scope('Test'));
      final container = ProviderContainer(
        overrides: [
          playerEngineBuilderProvider.overrideWithValue(() => fake),
          sourceResolverProvider.overrideWithValue(FakeResolver()),
          playbackInfoRepositoryProvider.overrideWithValue(
            PlaybackInfoRepository(MockPlaybackClient()),
          ),
          playbackStateRepositoryProvider.overrideWithValue(
            idlePlaybackStateRepository(),
          ),
          reachabilityProvider.overrideWithValue(FakeReachability()),
          sessionControllerProvider.overrideWithValue(
            SessionController(
              profileId: 'p1',
              repository: MockProfileRepository(),
              clock: FakeClock(),
            ),
          ),
          stateDatabaseProvider.overrideWithValue(db),
          outboxProvider.overrideWithValue(idleOutbox(db)),
          settingsRepositoryProvider.overrideWithValue(
            SettingsRepository(client),
          ),
          serverCapabilitiesProvider.overrideWithBuild(
            (ref, notifier) => const ServerCapabilities(
              serverVersion: null,
              hasP6SelfRevoke: true,
              hasP7PlayMarker: true,
              hasP8PlayedAt: true,
              loudnessTargetLufs: -14,
            ),
          ),
          profileDisposerProvider.overrideWithValue(disposer),
          clockProvider.overrideWithValue(FakeClock()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(playbackControllerProvider);
      await controller.setVolume(0.5);

      await controller.playItems([_track('a', _loud), _track('b', _loud)]);
      await pumpEventQueue();
      expect(fake.volume, closeTo(0.5, 1e-9));

      answer.complete(_wire('track'));
      await pumpEventQueue();
      await controller.next();
      await pumpEventQueue();

      expect(fake.volume, closeTo(0.5 * gainToLinear(-4), 1e-9));
      await disposer.closeAll();
    },
  );
}
