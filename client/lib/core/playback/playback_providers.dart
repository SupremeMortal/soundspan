// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/playback/engines/player_engine_provider.dart';
import 'package:soundspan/core/playback/persistence.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/state/queue_dao.dart';
import 'package:soundspan/platform/stream_auth/stream_auth.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

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
/// scope, with the scope's stream-info repository and session controller.
///
/// It restores the queue this device stored before taking any command, and
/// writes it at once when the app goes to the background. Ending the scope
/// writes the queue, stops playback and disposes the engine.
final Provider<PlaybackController> playbackControllerProvider =
    Provider<PlaybackController>(
      (ref) {
        final persistence = ref.watch(queuePersistenceProvider);
        final controller = PlaybackController(
          engine: ref.watch(playerEngineBuilderProvider)(),
          resolver: ref.watch(sourceResolverProvider),
          info: ref.watch(playbackInfoRepositoryProvider),
          session: ref.watch(sessionControllerProvider),
          clock: ref.watch(clockProvider),
          persistence: persistence,
        );
        unawaited(controller.restore());
        final lifecycle = AppLifecycleListener(
          binding: WidgetsBinding.instance,
          onStateChange: persistence.handleLifecycle,
        );
        ref.watch(profileDisposerProvider).register(controller.dispose);
        ref.onDispose(() {
          lifecycle.dispose();
          unawaited(controller.dispose());
        });
        return controller;
      },
      dependencies: [
        sourceResolverProvider,
        playbackInfoRepositoryProvider,
        sessionControllerProvider,
        profileDisposerProvider,
        queuePersistenceProvider,
      ],
    );
