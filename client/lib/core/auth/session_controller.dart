// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/shared/clock.dart';
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
  /// reading [current]. The clock judges how long an access token has left.
  new({
    required this._profileId,
    required this._repository,
    required this._clock,
  });

  final String _profileId;
  final ProfileRepository _repository;
  final Clock _clock;
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

  /// How [ensureFresh] and [refreshNow] renew a JWT session: the
  /// transport's single-flight renewal (`SoundspanApi.refreshSession`), so
  /// a renewal started here and one started by a 401 share one request.
  /// The profile's API sets it when it is built.
  Future<JwtCredentials> Function()? refresher;

  /// The credential to build a long-lived request with, such as a stream
  /// source (doc 06, Credential freshness).
  ///
  /// An API key is returned at once. A JWT whose access token has at least
  /// [minRemaining] left by its `exp` claim (read without a signature
  /// check), or whose expiry cannot be read, is returned as is; otherwise
  /// the session is renewed and the new credential returned. When the
  /// renewal fails with `Offline` or `ServerError` the current token is
  /// returned while it has not expired, and the failure is rethrown once it
  /// has. A rejected renewal signs the profile out and throws
  /// `Unauthenticated`, as does a call with no credential.
  Future<Credentials> ensureFresh({required Duration minRemaining}) async {
    final current = _current;
    switch (current) {
      case null:
        throw const Unauthenticated();
      case ApiKeyCredentials():
        return current;
      case JwtCredentials(:final accessToken):
        final expiry = _expiry(accessToken);
        if (expiry == null || expiry.difference(_clock.now()) >= minRemaining) {
          return current;
        }
        try {
          return await _refresh();
        } on ApiException catch (error) {
          final usable =
              (error is Offline || error is ServerError) &&
              _clock.now().isBefore(expiry);
          if (!usable) rethrow;
          return current;
        }
    }
  }

  /// Renews a JWT session now and returns the new credential; an API key is
  /// returned unchanged. Throws `Unauthenticated` with no credential.
  Future<Credentials> refreshNow() async => switch (_current) {
    null => throw const Unauthenticated(),
    final ApiKeyCredentials key => key,
    JwtCredentials() => await _refresh(),
  };

  Future<JwtCredentials> _refresh() {
    final refresh = refresher;
    if (refresh == null) {
      throw StateError('SessionController has no refresher attached');
    }
    return refresh();
  }

  /// The `exp` claim of [token], or null when it cannot be read.
  static DateTime? _expiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (claims case {'exp': final num exp}) {
        return DateTime.fromMillisecondsSinceEpoch(
          (exp * 1000).round(),
          isUtc: true,
        );
      }
    } on FormatException {
      return null;
    }
    return null;
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
