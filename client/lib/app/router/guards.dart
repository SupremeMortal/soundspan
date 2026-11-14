// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';

/// Where the router sends a request for [location] (doc 02, Routing), or
/// null to let it through.
///
/// `/connect/**` is always reachable, so a second server can be added. With
/// no active profile everything else goes to `/connect`; with a profile
/// that is signed out it goes to `/connect/sign-in?profile=<id>`.
String? guardRedirect(
  Uri location,
  ProfileRuntimeState state, {
  required bool signedOut,
}) {
  final path = location.path;
  if (path == RoutePaths.connect || path.startsWith('${RoutePaths.connect}/')) {
    return null;
  }
  return switch (state) {
    ProfileRuntimeNone() => RoutePaths.connect,
    ProfileRuntimeActive(:final profileId) when signedOut => Uri(
      path: RoutePaths.signIn,
      queryParameters: {'profile': profileId},
    ).toString(),
    _ => null,
  };
}

/// What the guards read: the [ProfileRuntime]'s state and whether the active
/// profile is signed out. Notifies when either changes, so the router
/// re-runs its redirect.
class AuthGateState extends ChangeNotifier {
  /// Follows the given runtime.
  new(this._runtime) {
    _runtime.state.addListener(_onRuntime);
    _onRuntime();
  }

  final ProfileRuntime _runtime;
  StreamSubscription<SessionState>? _session;
  bool _signedOut = false;

  /// The runtime's state.
  ProfileRuntimeState get state => _runtime.state.value;

  /// Whether the active profile is signed out: it was stored signed out, or
  /// its session signed out since it became active.
  bool get signedOut => _signedOut;

  void _onRuntime() {
    unawaited(_session?.cancel());
    _session = null;
    _signedOut = false;
    final container = _runtime.container;
    if (_runtime.state.value is ProfileRuntimeActive && container != null) {
      _signedOut =
          container.read(profileContextProvider).profile.state ==
          ProfileState.signedOut;
      _session = container.read(sessionControllerProvider).states.listen((
        event,
      ) {
        if (event is SessionSignedOut && !_signedOut) {
          _signedOut = true;
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _runtime.state.removeListener(_onRuntime);
    unawaited(_session?.cancel());
    super.dispose();
  }
}
