// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The `User-Agent` of API requests: `soundspan-client/<version> (<os>)`.
/// Bootstrap overrides it; it throws until then.
final Provider<String> userAgentProvider = Provider<String>(
  (ref) => throw UnimplementedError('userAgentProvider is set by bootstrap'),
);

/// The [SessionController] of the profile scope. `ProfileRuntime` loads it
/// before the scope becomes active.
final Provider<SessionController> sessionControllerProvider =
    Provider<SessionController>((ref) {
      final controller = SessionController(
        profileId: ref.watch(profileContextProvider).profile.id,
        repository: ref.watch(profileRepositoryProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    }, dependencies: [profileContextProvider]);

/// The [ApiConfig] of the profile's server: its base URL, its device id as
/// the playback device id, and 10 s connect and 30 s receive timeouts.
final Provider<ApiConfig> apiConfigProvider = Provider<ApiConfig>((ref) {
  final profile = ref.watch(profileContextProvider).profile;
  return ApiConfig(
    baseUrl: profile.baseUrl,
    userAgent: ref.watch(userAgentProvider),
    playbackDeviceId: profile.deviceId,
    // ignore: avoid_redundant_argument_values, the timeouts are part of the profile's contract (doc 03).
    connectTimeout: const Duration(seconds: 10),
    // ignore: avoid_redundant_argument_values, see connectTimeout.
    receiveTimeout: const Duration(seconds: 30),
  );
}, dependencies: [profileContextProvider]);

/// The profile's `state.db`. It opens on first use and closes through the
/// [ProfileDisposer] when the profile scope ends.
final Provider<StateDatabase> stateDatabaseProvider = Provider<StateDatabase>((
  ref,
) {
  final profileId = ref.watch(profileContextProvider).profile.id;
  final database = StateDatabase(
    ref.watch(databaseOpenerProvider).open(StateDatabaseTarget(profileId)),
  );
  ref.watch(profileDisposerProvider).register(database.close);
  return database;
}, dependencies: [profileContextProvider, profileDisposerProvider]);
