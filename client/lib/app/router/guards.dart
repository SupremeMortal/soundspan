// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/version_gate.dart';

/// Where the router sends a request for [location] (doc 02, Routing), or
/// null to let it through.
///
/// `/connect/**` is always reachable, so a second server can be added. With
/// no active profile everything else goes to `/connect`; with a profile
/// that is signed out it goes to `/connect/sign-in?profile=<id>`. When the
/// active profile's server is older than `minServer` ([belowMin]), every
/// shell location goes to `/connect/probe?profile=<id>`, which says so.
String? guardRedirect(
  Uri location,
  ProfileRuntimeState state, {
  required bool signedOut,
  bool belowMin = false,
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
    ProfileRuntimeActive(:final profileId)
        when belowMin && _isShellLocation(location) =>
      Uri(
        path: RoutePaths.probe,
        queryParameters: {'profile': profileId},
      ).toString(),
    _ => null,
  };
}

/// Whether [location] is a destination of the shell or a detail opened in
/// one, including the root, which leads to the home branch.
bool _isShellLocation(Uri location) =>
    location.path == '/' ||
    branchBaseOf(location) != null ||
    DetailKind.values.any(
      (kind) => location.pathSegments.firstOrNull == kind.name,
    );

/// What the guards read: the [ProfileRuntime]'s state, whether the active
/// profile is signed out and whether its server is below the [VersionGate]'s
/// minimum. Notifies when any of them changes, so the router re-runs its
/// redirect.
class AuthGateState extends ChangeNotifier {
  /// Follows the given runtime, placing server versions with `gate`.
  new(this._runtime, this._gate) {
    _runtime.state.addListener(_onRuntime);
    _onRuntime();
  }

  final ProfileRuntime _runtime;
  final VersionGate _gate;
  StreamSubscription<SessionState>? _session;
  ProviderSubscription<ServerCapabilities>? _capabilities;
  bool _signedOut = false;
  bool _belowMin = false;

  /// Whether the active profile's server, as last refreshed, is older than
  /// the oldest supported version.
  bool get belowMin => _belowMin;

  /// The runtime's state.
  ProfileRuntimeState get state => _runtime.state.value;

  /// Whether the active profile is signed out: it was stored signed out, or
  /// its session signed out since it became active.
  bool get signedOut => _signedOut;

  void _onRuntime() {
    unawaited(_session?.cancel());
    _session = null;
    _capabilities?.close();
    _capabilities = null;
    _signedOut = false;
    _belowMin = false;
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
      _capabilities = container.listen(serverCapabilitiesProvider, (_, next) {
        final belowMin = _gate.evaluate(next.serverVersion).blocks;
        if (belowMin != _belowMin) {
          _belowMin = belowMin;
          notifyListeners();
        }
      });
      _belowMin = _gate
          .evaluate(container.read(serverCapabilitiesProvider).serverVersion)
          .blocks;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _runtime.state.removeListener(_onRuntime);
    unawaited(_session?.cancel());
    _capabilities?.close();
    super.dispose();
  }
}
