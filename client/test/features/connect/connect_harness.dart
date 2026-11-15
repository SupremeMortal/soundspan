// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/features/connect/connect.dart';
import 'package:soundspan/features/connect/ui/probe_controller.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/url_opener/url_opener.dart';

import '../../helpers/pump_app.dart';

/// A [ProbeController] the test puts into each state.
class FakeProbeController extends ProbeController {
  /// The addresses [start] was called with.
  final List<ServerAddress> started = [];

  /// How often [retry] was called.
  int retries = 0;

  /// How often [cancel] was called.
  int cancels = 0;

  @override
  Future<ProbeState> build() => Completer<ProbeState>().future;

  @override
  void start(ServerAddress address) {
    started.add(address);
    state = const AsyncLoading<ProbeState>();
  }

  @override
  void retry() => retries++;

  @override
  void cancel() => cancels++;

  /// Puts the controller into [next].
  void emit(ProbeState next) => state = AsyncData(next);
}

/// Records the addresses it is asked to open.
class RecordingUrlOpener implements UrlOpener {
  /// The opened addresses.
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

/// Shows the [ProbeResult] the sign-in route received.
class SignInStub extends StatelessWidget {
  /// Creates the stub for [result].
  const new(this.result, {super.key});

  /// The result passed to `/connect/sign-in`.
  final ProbeResult? result;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text('sign-in ${result?.baseUrl}'));
}

/// The connect routes with a stub sign-in screen, starting at [initial].
GoRouter connectRouter({String initial = RoutePaths.connect, Object? extra}) =>
    GoRouter(
      initialLocation: initial,
      initialExtra: extra,
      routes: [
        GoRoute(path: RoutePaths.home, builder: (_, _) => const Text('home')),
        GoRoute(
          path: RoutePaths.connect,
          builder: (_, state) => AddressScreen.fromExtra(state.extra),
          routes: [
            GoRoute(
              path: 'probe',
              builder: (_, state) =>
                  ProbeScreen(request: state.extra! as ProbeRequest),
            ),
            GoRoute(
              path: 'sign-in',
              builder: (_, state) => SignInStub(state.extra as ProbeResult?),
            ),
          ],
        ),
      ],
    );

/// What `pumpConnect` built.
class ConnectHarness {
  new _(this.container, this.router, this.probe, this.opener);

  /// The provider container.
  final ProviderContainer container;

  /// The router.
  final GoRouter router;

  /// The fake probe controller.
  final FakeProbeController probe;

  /// The fake browser opener.
  final RecordingUrlOpener opener;
}

/// Pumps the connect routes with a [FakeProbeController].
extension PumpConnect on WidgetTester {
  /// Pumps the connect routes; [hasProfile] decides whether a profile
  /// exists, [capabilities] the platform.
  Future<ConnectHarness> pumpConnect({
    String initial = RoutePaths.connect,
    Object? extra,
    bool hasProfile = false,
    PlatformCapabilities capabilities = PlatformCapabilities.android,
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
    double textScale = 1.0,
    String origin = 'https://app.example.com',
    List<Override> overrides = const [],
  }) async {
    final probe = FakeProbeController();
    final opener = RecordingUrlOpener();
    final router = connectRouter(initial: initial, extra: extra);
    addTearDown(router.dispose);
    final container = await pumpApp(
      Router.withConfig(config: router),
      size: size,
      theme: theme,
      textScale: textScale,
      overrides: [
        probeControllerProvider.overrideWith(() => probe),
        connectHasProfileProvider.overrideWithValue(hasProfile),
        platformCapabilitiesProvider.overrideWithValue(capabilities),
        urlOpenerProvider.overrideWithValue(opener),
        appOriginProvider.overrideWithValue(origin),
        ...overrides,
      ],
    );
    await settle();
    return ConnectHarness._(container, router, probe, opener);
  }
}

/// Settles route transitions without waiting for an indeterminate progress
/// indicator, which never settles.
extension Settle on WidgetTester {
  /// Pumps a second of frames.
  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await pump(const Duration(milliseconds: 100));
    }
  }
}

/// A probe result at [base], reached from [requested] (defaults to [base]).
ProbeResult probeResult(
  String base, {
  String? requested,
  bool isPrivateHost = false,
}) {
  final url = Uri.parse(base);
  return ProbeResult(
    baseUrl: url,
    requestedBaseUrl: Uri.parse(requested ?? base),
    localLoginEnabled: true,
    oidcEnabled: false,
    isCleartext: url.scheme == 'http',
    isPrivateHost: isPrivateHost,
  );
}
