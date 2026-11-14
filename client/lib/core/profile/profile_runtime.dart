// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/database_too_new_exception.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';

/// What [ProfileRuntime.state] reports.
@immutable
sealed class ProfileRuntimeState {
  const new();

  /// No profile is active.
  static const ProfileRuntimeState none = ProfileRuntimeNone();

  /// A switch is running; nothing of the old profile may be built.
  static const ProfileRuntimeState switching = ProfileRuntimeSwitching();
}

/// No profile is active and there is no profile container.
final class ProfileRuntimeNone extends ProfileRuntimeState {
  /// The state without a profile.
  const new();

  @override
  String toString() => 'ProfileRuntimeState.none';
}

/// A profile switch is in progress.
final class ProfileRuntimeSwitching extends ProfileRuntimeState {
  /// The state during a switch.
  const new();

  @override
  String toString() => 'ProfileRuntimeState.switching';
}

/// Profile [profileId] is active; its container is
/// [ProfileRuntime.container].
final class ProfileRuntimeActive extends ProfileRuntimeState {
  /// The state with [profileId] active.
  const new(this.profileId);

  /// The active profile.
  final String profileId;

  @override
  bool operator ==(Object other) =>
      other is ProfileRuntimeActive && other.profileId == profileId;

  @override
  int get hashCode => Object.hash(ProfileRuntimeActive, profileId);

  @override
  String toString() => 'ProfileRuntimeState.active($profileId)';
}

/// The `state.db` of profile [profileId] was written by a newer version of
/// the app. Nothing was opened or deleted; the user may reset the profile's
/// local state ([ProfileRuntime.resetLocalState]).
final class ProfileRuntimeLocalDataTooNew extends ProfileRuntimeState {
  /// The state for [profileId].
  const new(this.profileId);

  /// The profile whose local data is too new.
  final String profileId;

  @override
  bool operator ==(Object other) =>
      other is ProfileRuntimeLocalDataTooNew && other.profileId == profileId;

  @override
  int get hashCode => Object.hash(ProfileRuntimeLocalDataTooNew, profileId);

  @override
  String toString() => 'ProfileRuntimeState.localDataTooNew($profileId)';
}

/// Owns the active profile's nested [ProviderContainer] (doc 02, Background
/// Entry Points). The widget tree attaches to it through `ProfileScope`;
/// background entry points read [container].
class ProfileRuntime {
  /// Creates the runtime under the given root container.
  new(this._root);

  final ProviderContainer _root;
  final ValueNotifier<ProfileRuntimeState> _state = ValueNotifier(
    ProfileRuntimeState.none,
  );
  ProviderContainer? _container;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

  AppLogger get _logger => _root.read(appLoggerProvider('Profile'));

  /// The active profile's container, or null when no profile is active.
  ProviderContainer? get container => _container;

  /// The runtime's state.
  ValueListenable<ProfileRuntimeState> get state => _state;

  /// Activates the stored active profile, if there is one.
  Future<void> start() {
    final id = _root.read(activeProfileIdProvider);
    return id == null ? Future<void>.value() : switchTo(id);
  }

  /// Makes [profileId] the active profile, or with null leaves no profile
  /// active. Calls run one after another, in call order.
  ///
  /// The old container's closers run and it is disposed before the new one
  /// is created. The new profile's session is loaded and its `state.db`
  /// opened before its id is stored as the active one. A `state.db` written
  /// by a newer app version ends in [ProfileRuntimeLocalDataTooNew]. An id
  /// without a profile record is treated like null. Switching to the active
  /// profile does nothing.
  Future<void> switchTo(String? profileId) => _serial(() => _switch(profileId));

  /// Deletes the `state.db` and the directory trees of [profileId], then
  /// activates it. Only ever called from an explicit user action.
  Future<void> resetLocalState(String profileId) => _serial(() async {
    _state.value = ProfileRuntimeState.switching;
    await _closeCurrent();
    await _root
        .read(databaseOpenerProvider)
        .delete(StateDatabaseTarget(profileId));
    await _root.read(appPathsProvider).deleteProfileTree(profileId);
    await _switch(profileId);
  });

  /// Closes and disposes the active container. The runtime is unusable
  /// afterwards; further calls do nothing.
  Future<void> dispose() => _serial(() async {
    if (_disposed) return;
    _disposed = true;
    await _closeCurrent();
    _state.dispose();
  });

  Future<void> _serial(Future<void> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _switch(String? profileId) async {
    if (profileId != null &&
        _state.value == ProfileRuntimeActive(profileId) &&
        _container != null) {
      return;
    }
    _state.value = ProfileRuntimeState.switching;
    await _closeCurrent();

    final repository = _root.read(profileRepositoryProvider);
    final profile = profileId == null ? null : await repository.byId(profileId);
    if (profile == null) {
      if (profileId != null) {
        _logger.warning('No profile to activate', {'profileId': profileId});
      }
      await _root.read(activeProfileIdProvider.notifier).set(null);
      _state.value = ProfileRuntimeState.none;
      return;
    }

    final container = ProviderContainer(
      parent: _root,
      overrides: [
        profileContextProvider.overrideWithValue(
          ProfileContext(
            profile: profile,
            paths: kIsWeb
                ? null
                : _root.read(appPathsProvider).profile(profile.id),
          ),
        ),
      ],
    );
    try {
      await container.read(sessionControllerProvider).load();
      await container
          .read(stateDatabaseProvider)
          .customSelect('SELECT 1')
          .get();
    } on DatabaseTooNewException catch (error) {
      _logger.warning('Local data is too new', {
        'profileId': profile.id,
        'found': error.found,
        'supported': error.supported,
      });
      await _close(container);
      _state.value = ProfileRuntimeLocalDataTooNew(profile.id);
      return;
    } on Object {
      await _close(container);
      _state.value = ProfileRuntimeState.none;
      rethrow;
    }
    _container = container;
    await _root.read(activeProfileIdProvider.notifier).set(profile.id);
    await repository.touchLastUsed(profile.id);
    _state.value = ProfileRuntimeActive(profile.id);
  }

  Future<void> _closeCurrent() async {
    final container = _container;
    _container = null;
    if (container != null) await _close(container);
  }

  static Future<void> _close(ProviderContainer container) async {
    await container.read(profileDisposerProvider).closeAll();
    container.dispose();
  }
}

/// The process-wide [ProfileRuntime], under the root container.
final Provider<ProfileRuntime> profileRuntimeProvider =
    Provider<ProfileRuntime>((ref) {
      final runtime = ProfileRuntime(ref.container);
      ref.onDispose(() => unawaited(runtime.dispose()));
      return runtime;
    });
