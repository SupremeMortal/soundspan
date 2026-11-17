// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/audio_focus.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/playback/engines/player_engine_provider.dart';
import 'package:soundspan/core/playback/loudness_binding.dart';
import 'package:soundspan/core/playback/notification_permission.dart';
import 'package:soundspan/core/playback/persistence.dart';
import 'package:soundspan/core/playback/play_reporter_input.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/core/playback/state_sync_binding.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/settings/settings_providers.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/core/storage/state/queue_dao.dart';
import 'package:soundspan/core/sync/episode_progress_reporter.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/play_reporter.dart';
import 'package:soundspan/core/sync/play_session_store.dart';
import 'package:soundspan/core/sync/playback_state_sync.dart';
import 'package:soundspan/core/sync/sync_providers.dart';
import 'package:soundspan/platform/audio_session/audio_session_gateway.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan/platform/notifications/local_notifications.dart';
import 'package:soundspan/platform/stream_auth/stream_auth.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart' show StreamUrls;

final AppLogger _log = AppLogger.scope('Playback');

/// The [PlaybackInfoRepository] of the profile scope; its cache lives as
/// long as the scope.
final Provider<PlaybackInfoRepository> playbackInfoRepositoryProvider =
    Provider<PlaybackInfoRepository>(
      (ref) =>
          PlaybackInfoRepository(ref.watch(soundspanApiProvider).rest.playback),
      dependencies: [soundspanApiProvider],
    );

/// The [StreamQualityPolicy] of the profile scope: its device settings and
/// the root [reachabilityProvider].
final Provider<StreamQualityPolicy> streamQualityPolicyProvider =
    Provider<StreamQualityPolicy>(
      (ref) => StreamQualityPolicy(
        ref.watch(deviceSettingsDaoProvider),
        ref.watch(reachabilityProvider),
      ),
      dependencies: [deviceSettingsDaoProvider],
    );

/// The [SourceResolver] of the profile scope: stream URLs on the profile's
/// server, credentials from its session controller, and the platform's
/// [StreamAuth].
final Provider<SourceResolver> sourceResolverProvider =
    Provider<SourceResolver>(
      (ref) {
        final session = ref.watch(sessionControllerProvider);
        // The API attaches the session's refresher; watch it so it exists.
        ref.watch(soundspanApiProvider);
        return SourceResolver(
          ensureFresh: session.ensureFresh,
          urls: StreamUrls(ref.watch(apiConfigProvider).baseUrl),
          quality: ref.watch(streamQualityPolicyProvider),
          auth: ref.watch(streamAuthProvider),
        );
      },
      dependencies: [
        sessionControllerProvider,
        soundspanApiProvider,
        apiConfigProvider,
        streamQualityPolicyProvider,
      ],
    );

/// The [QueuePersistence] of the profile scope, over its `state.db`.
final Provider<QueuePersistence> queuePersistenceProvider =
    Provider<QueuePersistence>(
      (ref) => QueuePersistence(
        dao: QueueDao(ref.watch(stateDatabaseProvider)),
        clock: ref.watch(clockProvider),
      ),
      dependencies: [stateDatabaseProvider],
    );

/// The [PlaybackController] of the profile scope, alive as long as the
/// scope, with the scope's stream-info repository, session controller and
/// device settings.
///
/// It restores the queue this device stored before taking any command, and
/// writes it at once when the app goes to the background. Ending the scope
/// writes the queue, stops playback and disposes the engine.
///
/// Its [PlaybackStateSync] keeps the server's copy of the queue current once
/// the queue is restored, and supplies the queue when none is stored on the
/// device.
///
/// It starts the scope's [LoudnessBinding]: the levelling mode of
/// [loudnessModeProvider] and the target of [serverCapabilitiesProvider]
/// (-18 LUFS while unknown) are read whenever an item becomes current.
///
/// Its [AudioFocusController] applies the audio-focus rules over the root
/// [audioSessionGatewayProvider].
///
/// Its [NotificationPermissionPrompt] asks for the notification permission
/// at the first playback on Android 13 or later.
///
/// Its [PlayReporter] reports every play to the scope's outbox, closing the
/// plays an earlier process left in `play_sessions` first. Ending the scope
/// writes the open play before playback stops.
///
/// Its [EpisodeProgressReporter] saves the progress of the episode playing
/// through the same outbox.
final Provider<PlaybackController> playbackControllerProvider =
    Provider<PlaybackController>(
      (ref) {
        final persistence = ref.watch(queuePersistenceProvider);
        final lifecycleStates = StreamController<AppLifecycleState>.broadcast(
          sync: true,
        );
        final stateSync = PlaybackStateSync(
          repository: ref.watch(playbackStateRepositoryProvider),
          reachability: ref.watch(reachabilityProvider),
          lifecycle: lifecycleStates.stream,
        );
        final controller = PlaybackController(
          engine: ref.watch(playerEngineBuilderProvider)(),
          resolver: ref.watch(sourceResolverProvider),
          info: ref.watch(playbackInfoRepositoryProvider),
          session: ref.watch(sessionControllerProvider),
          clock: ref.watch(clockProvider),
          deviceSettings: ref.watch(deviceSettingsDaoProvider),
          persistence: persistence,
          remoteRestore: () async {
            final remote = await stateSync.restore();
            return remote == null ? null : restoredQueueOf(remote);
          },
        );
        var mode = LoudnessMode.off;
        ref.listen<LoudnessMode>(
          loudnessModeProvider,
          (_, next) => mode = next,
          onError: (_, _) => mode = LoudnessMode.off,
          fireImmediately: true,
        );
        var targetLufs = ServerCapabilities.defaultLoudnessTargetLufs;
        ref.listen<ServerCapabilities>(
          serverCapabilitiesProvider,
          (_, next) => targetLufs = next.loudnessTargetLufs,
          onError: (_, _) =>
              targetLufs = ServerCapabilities.defaultLoudnessTargetLufs,
          fireImmediately: true,
        );
        final loudness = LoudnessBinding(
          controller: controller,
          mode: () => mode,
          targetLufs: () => targetLufs,
        );
        final focus = AudioFocusController(
          controller,
          ref.watch(audioSessionGatewayProvider),
        );
        final permission = NotificationPermissionPrompt(
          snapshots: controller.snapshots,
          settings: ref.watch(deviceSettingsDaoProvider),
          notifications: ref.watch(localNotificationsProvider),
          androidSdkVersion: ref.watch(androidSdkVersionProvider),
        );
        unawaited(
          controller.restore().then(
            (_) => stateSync.follow(controller.snapshots.map(syncedPlaybackOf)),
          ),
        );
        final reporter = PlayReporter(
          ControllerListeningSource(controller),
          PlaySessionStore(ref.watch(stateDatabaseProvider)),
          ref.watch(outboxProvider),
          ref.watch(clockProvider),
          lifecycleStates.stream,
        );
        final episodeProgress = EpisodeProgressReporter(
          ControllerListeningSource(controller),
          ref.watch(outboxProvider).enqueue,
          ref.watch(clockProvider),
        );
        final lifecycle = AppLifecycleListener(
          binding: WidgetsBinding.instance,
          onStateChange: (state) {
            persistence.handleLifecycle(state);
            lifecycleStates.add(state);
          },
        );
        _reporters[controller] = reporter;
        // Closers run in reverse: the open play is written first.
        ref.watch(profileDisposerProvider)
          ..register(controller.dispose)
          ..register(reporter.dispose);
        ref.onDispose(() {
          lifecycle.dispose();
          unawaited(lifecycleStates.close());
          unawaited(reporter.dispose());
          unawaited(episodeProgress.dispose());
          unawaited(stateSync.dispose());
          unawaited(loudness.dispose());
          focus.dispose();
          unawaited(permission.dispose());
          unawaited(controller.dispose());
        });
        return controller;
      },
      dependencies: [
        sourceResolverProvider,
        playbackInfoRepositoryProvider,
        sessionControllerProvider,
        deviceSettingsDaoProvider,
        loudnessModeProvider,
        serverCapabilitiesProvider,
        profileDisposerProvider,
        queuePersistenceProvider,
        stateDatabaseProvider,
        outboxProvider,
        playbackStateRepositoryProvider,
      ],
    );

final Expando<PlayReporter> _reporters = Expando<PlayReporter>();

/// Completes when every play [controller]'s reporter has ended so far is
/// stored, so an outbox pass that follows sends it. Completes at once for a
/// controller that [playbackControllerProvider] did not create.
Future<void> playsWritten(PlaybackController controller) =>
    _reporters[controller]?.flush() ?? Future<void>.value();

/// Every [PlaybackSnapshot] of the profile's [PlaybackController], position
/// changes included (at most four a second). Only widgets that show the
/// position watch it, such as the seek bar; it is not retried on error.
final StreamProvider<PlaybackSnapshot> playbackSnapshotProvider =
    StreamProvider<PlaybackSnapshot>(
      (ref) => ref.watch(playbackControllerProvider).snapshots,
      dependencies: [playbackControllerProvider],
      retry: (_, _) => null,
    );

/// The [PlaybackSnapshot]s of the profile's [PlaybackController] that
/// change more than the position and the buffered range, for widgets that
/// must not rebuild as the position moves; it is not retried on error.
final StreamProvider<PlaybackSnapshot> playbackStateProvider =
    StreamProvider<PlaybackSnapshot>(
      (ref) => ref
          .watch(playbackControllerProvider)
          .snapshots
          .distinct((previous, next) => next.differsOnlyInPosition(previous)),
      dependencies: [playbackControllerProvider],
      retry: (_, _) => null,
    );

/// Creates the [PlaybackController] of every profile that becomes active in
/// [root]'s [ProfileRuntime], as soon as it is active, so the queue it
/// restores from `state.db` shows in the players, paused, on the first
/// frame (doc 02, Bootstrap Sequence; doc 06, Local Queue Persistence).
///
/// Call it before the runtime activates the stored profile. A controller
/// that cannot be created (no engine on the platform) is logged; the next
/// play action reports the failure.
void createPlaybackOnActivation(ProviderContainer root) {
  final runtime = root.read(profileRuntimeProvider);
  final created = Expando<bool>();
  void onState() {
    final container = runtime.container;
    if (runtime.state.value is! ProfileRuntimeActive || container == null) {
      return;
    }
    if (created[container] ?? false) return;
    created[container] = true;
    try {
      container.read(playbackControllerProvider);
    } on Object catch (error, stackTrace) {
      _log.severe(
        'Could not create the playback controller',
        const {},
        error,
        stackTrace,
      );
    }
  }

  runtime.state.addListener(onState);
  onState();
}
