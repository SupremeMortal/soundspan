// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Keeps the active profile's [ServerCapabilities] current (doc 04,
/// Capability Discovery and Version Gate).
///
/// A refresh reads the server version, then `GET /api/system/features`,
/// stores both on the profile row with the time they were fetched, and
/// hands the result to the profile's [serverCapabilitiesProvider]. It runs
/// when the profile container is created ([start]), on resume after more
/// than [resumeAfter] in the background, and on [refreshNow].
class CapabilityRefresher {
  /// Creates the refresher of profile `profileId`.
  new({
    required this._api,
    required this._profiles,
    required this._profileId,
    required this._clock,
    required this._minServer,
    required this._onRefreshed,
    required this._logger,
  });

  /// How long the app must have been in the background for a resume to
  /// refresh.
  static const Duration resumeAfter = Duration(hours: 1);

  final SoundspanApi _api;
  final ProfileRepository _profiles;
  final String _profileId;
  final Clock _clock;
  final Version _minServer;
  final void Function(ServerCapabilities) _onRefreshed;
  final AppLogger _logger;

  Future<bool>? _running;
  DateTime? _backgroundSince;
  AppLifecycleListener? _lifecycle;
  bool _started = false;
  bool _disposed = false;

  /// Refreshes once and follows the app lifecycle from then on. Later calls
  /// do nothing.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _lifecycle = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onStateChange: handleLifecycle,
    );
    await refresh();
  }

  /// Fetches the version and the features and stores them; true when it
  /// succeeded. A failure is logged and keeps the cached value. While a run
  /// is in progress, callers share it.
  Future<bool> refresh() =>
      _running ??= _run().whenComplete(() => _running = null);

  /// Refreshes now, for a caller that received `FeatureDisabled`.
  Future<bool> refreshNow() => refresh();

  /// Follows the app's lifecycle: a resume after more than [resumeAfter]
  /// hidden or paused refreshes.
  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _backgroundSince ??= _clock.now();
      case AppLifecycleState.resumed:
        final since = _backgroundSince;
        _backgroundSince = null;
        if (since != null && _clock.now().difference(since) > resumeAfter) {
          unawaited(refresh());
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// Stops following the lifecycle; a refresh in progress no longer stores
  /// its result.
  void dispose() {
    _disposed = true;
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  Future<bool> _run() async {
    if (_disposed) return false;
    try {
      final version = await _api.fetchServerVersion();
      final features = await _api.send(
        (rest) => rest.session.getSystemFeatures(),
      );
      if (_disposed) return false;
      final fetchedAt = _clock.now();
      final capabilities = ServerCapabilities.fromFeatures(
        serverVersion: Version.tryParse(version ?? ''),
        features: features.toJson(),
        minServer: _minServer,
        fetchedAt: fetchedAt,
      );
      await _profiles.updateServerInfo(
        _profileId,
        serverVersion: version,
        features: capabilities.toFeaturesJson(),
        featuresFetchedAt: fetchedAt,
      );
      if (_disposed) return false;
      _onRefreshed(capabilities);
      _logger.info('Capabilities refreshed', {
        'profileId': _profileId,
        'serverVersion': version ?? 'unknown',
      });
      return true;
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Capability refresh failed',
        {'profileId': _profileId},
        error,
        stackTrace,
      );
      return false;
    }
  }
}

/// The [CapabilityRefresher] of the profile scope.
final Provider<CapabilityRefresher> capabilityRefresherProvider =
    Provider<CapabilityRefresher>(
      (ref) {
        final refresher = CapabilityRefresher(
          api: ref.watch(soundspanApiProvider),
          profiles: ref.watch(profileRepositoryProvider),
          profileId: ref.watch(profileContextProvider).profile.id,
          clock: ref.watch(clockProvider),
          minServer: ref.watch(versionGateProvider).min,
          onRefreshed: (capabilities) =>
              ref.read(serverCapabilitiesProvider.notifier).current =
                  capabilities,
          logger: ref.read(appLoggerProvider('Capabilities')),
        );
        ref.onDispose(refresher.dispose);
        return refresher;
      },
      dependencies: [
        soundspanApiProvider,
        serverCapabilitiesProvider,
        profileContextProvider,
      ],
    );

/// The post-first-frame task of the capability refresh (doc 02, Bootstrap
/// Sequence, step 8): starts the [CapabilityRefresher] of every profile
/// container the [ProfileRuntime] under [root] activates, now and later.
Future<void> startCapabilityRefresh(ProviderContainer root) async {
  final runtime = root.read(profileRuntimeProvider);
  void onState() {
    final container = runtime.container;
    if (runtime.state.value is ProfileRuntimeActive && container != null) {
      unawaited(container.read(capabilityRefresherProvider).start());
    }
  }

  runtime.state.addListener(onState);
  onState();
}
