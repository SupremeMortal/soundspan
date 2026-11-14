// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// What a [SessionController] reports on [SessionController.states].
@immutable
sealed class SessionState {
  const new();

  /// The server rejected the credential permanently for [reason]; the
  /// profile is signed out.
  const factory signedOut(UnauthenticatedReason reason) = SessionSignedOut;
}

/// The profile was signed out because the server rejected its credential.
final class SessionSignedOut extends SessionState {
  /// Creates the event for [reason].
  const new(this.reason);

  /// Why the credential was rejected.
  final UnauthenticatedReason reason;

  @override
  bool operator ==(Object other) =>
      other is SessionSignedOut && other.reason == reason;

  @override
  int get hashCode => Object.hash(SessionSignedOut, reason);

  @override
  String toString() => 'SessionState.signedOut(${reason.name})';
}

/// Holds one profile's credential and owns its signed-in state (doc 04,
/// Session Lifecycle). The transport reads it as its [CredentialProvider].
class SessionController implements CredentialProvider {
  /// Creates the controller of the given profile; call [load] before
  /// reading [current].
  new({required this._profileId, required this._repository});

  final String _profileId;
  final ProfileRepository _repository;
  final StreamController<SessionState> _states =
      StreamController<SessionState>.broadcast();
  Credentials? _current;
  bool _rejected = false;

  /// Session events: a sign-out after the server rejected the credential.
  Stream<SessionState> get states => _states.stream;

  @override
  Credentials? get current => _current;

  /// Reads the stored credential; [current] is synchronous afterwards.
  Future<void> load() async {
    _current = await _repository.readCredentials(_profileId);
  }

  /// Stores [next] (refresh token, then access token) and only then makes
  /// it [current].
  @override
  Future<void> onTokensRotated(JwtCredentials next) async {
    await _repository.writeCredentials(_profileId, next);
    _current = next;
  }

  /// Signs the profile out: forgets the credential, deletes its secrets,
  /// marks the profile signed out and emits [SessionState.signedOut]. The
  /// cache, downloads and outbox are kept. Calls after the first are
  /// ignored.
  @override
  void onUnauthenticated(UnauthenticatedReason reason) {
    if (_rejected) return;
    _rejected = true;
    _current = null;
    unawaited(_signOut(reason));
  }

  Future<void> _signOut(UnauthenticatedReason reason) async {
    await _repository.deleteCredentials(_profileId);
    await _repository.setState(_profileId, ProfileState.signedOut);
    if (!_states.isClosed) _states.add(SessionState.signedOut(reason));
  }

  /// Closes [states].
  void dispose() => unawaited(_states.close());
}
