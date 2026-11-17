// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/session/sign_out_participant.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Step 4 of sign-out (doc 04, Sign-Out): tells the server that the
/// profile's credential is no longer used.
abstract interface class SessionRevoker {
  /// Revokes [credentials] of [profile]: `POST /api/auth/logout` for a
  /// password profile, `DELETE /api/api-keys/current` for a device-linked
  /// or pasted API key.
  Future<void> revoke(Profile profile, Credentials credentials);
}

/// The [SessionRevoker] over a one-off client built from the stored
/// credential, with connect and receive timeouts of 5 s.
final class ApiSessionRevoker implements SessionRevoker {
  /// Creates the revoker; `apis` builds the one-off client.
  const new({
    required this._userAgent,
    this._apis = _defaultApi,
    this._timeout = const Duration(seconds: 5),
  });

  final String _userAgent;
  final SoundspanApiFactory _apis;
  final Duration _timeout;

  static SoundspanApi _defaultApi(
    ApiConfig config,
    CredentialProvider credentials,
  ) => SoundspanApi(config, credentials: credentials);

  @override
  Future<void> revoke(Profile profile, Credentials credentials) async {
    final api = _apis(
      ApiConfig(
        baseUrl: profile.baseUrl,
        userAgent: _userAgent,
        playbackDeviceId: profile.deviceId,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
      ),
      _StoredCredential(credentials),
    );
    try {
      switch (profile.authKind) {
        case AuthKind.password:
          await api.send((rest) => rest.session.logout());
        case AuthKind.deviceLink || AuthKind.apiKey:
          await api.send((rest) => rest.session.revokeCurrentApiKey());
      }
    } finally {
      api.close();
    }
  }
}

/// A [CredentialProvider] that sends one stored credential and never
/// stores a rotation: the credential is about to be deleted.
final class _StoredCredential implements CredentialProvider {
  new(this.current);

  @override
  final Credentials current;

  @override
  Future<void> onTokensRotated(JwtCredentials next) async {}

  @override
  void onUnauthenticated(UnauthenticatedReason reason) {}
}

/// What sign-out uses of the active profile's scope.
abstract interface class SignOutScope {
  /// The registered [SignOutParticipant]s, in execution order.
  List<SignOutParticipant> get participants;

  /// Runs one outbox pass.
  Future<void> flushOutbox();

  /// The number of operations the outbox has not sent.
  Future<int> pendingChanges();
}

/// The [SignOutScope] of a profile container.
final class ContainerSignOutScope implements SignOutScope {
  /// Reads from [_container].
  const new(this._container);

  final ProviderContainer _container;

  @override
  List<SignOutParticipant> get participants =>
      _container.read(signOutParticipantsProvider);

  @override
  Future<void> flushOutbox() => _container.read(outboxProvider).flush();

  @override
  Future<int> pendingChanges() =>
      _container.read(outboxProvider).watchCount().first;
}

/// Signs a profile out of its server, or removes the server (doc 04,
/// Sign-Out).
///
/// Signing out stops what uses the credential (the participants of the
/// active profile), tries the outbox once, revokes the credential, deletes
/// the profile's secrets and marks it signed out. The outbox pass and the
/// revoke are best-effort with a budget of 5 s each; a failure of either,
/// or of a participant, is logged without the credential and ignored, so
/// sign-out always completes locally. The cache, downloads and outbox are
/// kept. A failure to delete the secrets propagates and leaves the profile
/// signed in.
class SignOutSequence {
  /// Creates the sequence. `scopeOf` reads the active profile's container;
  /// `opener` and `clock` count the pending changes of an inactive profile;
  /// `timer` (default [Timer.new]) ends the wait for a step after [budget].
  new({
    required this._runtime,
    required this._profiles,
    required this._revoker,
    required this._opener,
    required this._clock,
    this._scopeOf = ContainerSignOutScope.new,
    this._timer = Timer.new,
  });

  /// How long the outbox pass and the revoke may take each.
  static const Duration budget = Duration(seconds: 5);

  static final AppLogger _log = AppLogger.scope('SignOut');

  final ProfileRuntime _runtime;
  final ProfileRepository _profiles;
  final SessionRevoker _revoker;
  final DatabaseOpener _opener;
  final Clock _clock;
  final SignOutScope Function(ProviderContainer container) _scopeOf;
  final Timer Function(Duration duration, void Function() callback) _timer;

  /// Signs [profileId] out. When it is the active profile, its container is
  /// created again afterwards, so the app shows sign-in for it with its
  /// server and username. [removeDownloads] is passed to the participants.
  Future<void> signOut(String profileId, {bool removeDownloads = false}) async {
    final scope = _activeScope(profileId);
    await _stop(scope, removeDownloads: removeDownloads, remove: false);
    await _forget(profileId);
    if (scope != null) await _runtime.reload(profileId);
    _log.info('Signed out', {'profileId': profileId});
  }

  /// Signs [profileId] out with each participant's
  /// [SignOutParticipant.beforeRemove] run before the outbox pass, then
  /// deletes the profile: its directory trees, databases and row. When it
  /// was the active profile, the most recently used remaining profile that
  /// is signed in becomes active, or none.
  Future<void> removeServer(String profileId) async {
    final scope = _activeScope(profileId);
    await _stop(scope, removeDownloads: false, remove: true);
    await _forget(profileId);
    if (_holds(profileId)) {
      final remaining = await _profiles.watchAll().first;
      final next = remaining
          .where((p) => p.id != profileId && p.state == ProfileState.active)
          .firstOrNull;
      await _runtime.switchTo(next?.id);
    }
    await _profiles.delete(profileId);
    _log.info('Server removed', {'profileId': profileId});
  }

  /// The number of operations of [profileId] that have not reached the
  /// server; 0 when its `state.db` cannot be read.
  Future<int> pendingChanges(String profileId) async {
    final scope = _activeScope(profileId);
    if (scope != null) return await scope.pendingChanges();
    final database = StateDatabase(
      _opener.open(StateDatabaseTarget(profileId)),
    );
    try {
      return await OutboxStore(database, _clock).watchCount().first;
    } on Object catch (error) {
      _log.warning('Pending changes not counted', {
        'profileId': profileId,
        'error': error.runtimeType.toString(),
      });
      return 0;
    } finally {
      await database.close();
    }
  }

  /// Whether sign-out of [profileId] offers "Also remove downloads": a
  /// participant of the active profile reports downloads.
  Future<bool> offersDownloadRemoval(String profileId) async {
    final scope = _activeScope(profileId);
    if (scope == null) return false;
    for (final participant in _participants(scope)) {
      if (participant is DownloadsSignOutParticipant &&
          await participant.hasDownloads()) {
        return true;
      }
    }
    return false;
  }

  SignOutScope? _activeScope(String profileId) {
    final container = _runtime.container;
    if (_runtime.state.value != ProfileRuntimeActive(profileId) ||
        container == null) {
      return null;
    }
    return _scopeOf(container);
  }

  /// Whether [profileId] is the profile the runtime holds, with or without
  /// a container.
  bool _holds(String profileId) => switch (_runtime.state.value) {
    ProfileRuntimeActive(profileId: final id) ||
    ProfileRuntimeLocalDataTooNew(profileId: final id) => id == profileId,
    _ => false,
  };

  List<SignOutParticipant> _participants(SignOutScope scope) {
    try {
      return scope.participants;
    } on Object catch (error) {
      _log.warning('Sign-out participants unavailable', {
        'error': error.runtimeType.toString(),
      });
      return const [];
    }
  }

  /// Steps 1 to 3: the participants, then one outbox pass.
  Future<void> _stop(
    SignOutScope? scope, {
    required bool removeDownloads,
    required bool remove,
  }) async {
    if (scope == null) return;
    final participants = _participants(scope);
    for (final participant in participants) {
      await _guard(
        'Sign-out participant failed',
        () => participant.onSignOut(removeDownloads: removeDownloads),
      );
    }
    if (remove) {
      for (final participant in participants) {
        await _guard('Remove participant failed', participant.beforeRemove);
      }
    }
    await _bestEffort('Outbox flush', scope.flushOutbox);
  }

  /// Steps 4 and 5: revoke, then delete the secrets and mark the profile
  /// signed out.
  Future<void> _forget(String profileId) async {
    final profile = await _profiles.byId(profileId);
    if (profile == null) throw StateError('No profile $profileId');
    final credentials = await _profiles.readCredentials(profileId);
    if (credentials != null) {
      await _bestEffort('Revoke', () => _revoker.revoke(profile, credentials));
    }
    await _profiles.deleteCredentials(profileId);
    await _profiles.setState(profileId, ProfileState.signedOut);
  }

  Future<void> _guard(String message, Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      _log.warning(message, {'error': error.runtimeType.toString()});
    }
  }

  /// Waits for [action] for at most [budget]; a timeout or failure is
  /// logged by its type only, so no credential reaches the log.
  Future<void> _bestEffort(String what, Future<void> Function() action) async {
    final expired = Completer<bool>();
    final timer = _timer(budget, () {
      if (!expired.isCompleted) expired.complete(false);
    });
    try {
      final finished = await Future.any([
        Future.sync(action).then((_) => true),
        expired.future,
      ]);
      if (!finished) _log.warning('$what timed out');
    } on Object catch (error) {
      _log.warning('$what failed', {'error': error.runtimeType.toString()});
    } finally {
      timer.cancel();
    }
  }
}

/// The app's [SignOutSequence], under the root container.
final Provider<SignOutSequence> signOutSequenceProvider =
    Provider<SignOutSequence>(
      (ref) => SignOutSequence(
        runtime: ref.watch(profileRuntimeProvider),
        profiles: ref.watch(profileRepositoryProvider),
        revoker: ApiSessionRevoker(userAgent: ref.watch(userAgentProvider)),
        opener: ref.watch(databaseOpenerProvider),
        clock: ref.watch(clockProvider),
      ),
    );
