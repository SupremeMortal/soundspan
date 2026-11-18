// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/capability_refresher.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/features/connect/connect.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_server_adapter.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/test_root.dart';
import 'connect_harness.dart';

final VersionGate _gate = VersionGate(
  Version.tryParse('1.4.0')!,
  Version.tryParse('1.6.0')!,
);

const _tooOld =
    'This app needs soundspan 1.4.0 or newer. This server runs 1.3.0.';

ProbeRequest _request() => ProbeRequest(
  input: 'music.example.com',
  address: ServerAddress.parse('music.example.com'),
);

ProbeResult _result({String? healthVersion}) => ProbeResult(
  baseUrl: Uri.parse('https://music.example.com'),
  requestedBaseUrl: Uri.parse('https://music.example.com'),
  localLoginEnabled: true,
  oidcEnabled: false,
  isCleartext: false,
  isPrivateHost: false,
  healthVersion: healthVersion,
);

/// Lets a refresh started by a tap finish: real time for the database and
/// the fake server, frames for the widgets.
Future<void> _drain(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  Future<ConnectHarness> pumpProbe(WidgetTester tester) => tester.pumpConnect(
    initial: RoutePaths.probe,
    extra: _request(),
    overrides: [versionGateProvider.overrideWithValue(_gate)],
  );

  testWidgets('a probed server below minServer shows both versions and '
      'cannot continue', (tester) async {
    final harness = await pumpProbe(tester);
    harness.probe.emit(ProbeReady(_result(healthVersion: '1.3.0')));
    await tester.settle();

    expect(find.text(_tooOld), findsOne);
    expect(harness.router.state.uri.path, RoutePaths.probe);
    expect(find.text('Continue'), findsNothing);
    await expectMeetsGuidelines(tester);

    await tester.tap(find.text('Try again'));
    await tester.settle();
    expect(harness.probe.retries, 1);
    expect(harness.router.state.uri.path, RoutePaths.probe);

    await tester.tap(find.text('Edit address'));
    await tester.settle();
    expect(harness.router.state.uri.path, RoutePaths.connect);
  });

  testWidgets('an unknown health version continues to sign-in', (tester) async {
    final harness = await pumpProbe(tester);
    harness.probe.emit(ProbeReady(_result()));
    await tester.settle();
    expect(harness.router.state.uri.path, RoutePaths.signIn);
  });

  testWidgets('a probed server in range continues to sign-in', (tester) async {
    final harness = await pumpProbe(tester);
    harness.probe.emit(ProbeReady(_result(healthVersion: '1.7.0')));
    await tester.settle();
    expect(harness.router.state.uri.path, RoutePaths.signIn);
  });

  testWidgets('an active profile below minServer is redirected to the '
      'message, and Check again returns to the shell once the version is in '
      'range', (tester) async {
    final server = FakeServerAdapter(version: '1.3.0');
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      overrides: [
        versionGateProvider.overrideWithValue(_gate),
        soundspanApiFactoryProvider.overrideWithValue(
          (config, credentials) =>
              SoundspanApi(config, credentials: credentials, adapter: server),
        ),
      ],
    );
    expect(locationOf(root), RoutePaths.home);

    final container = root.container.read(profileRuntimeProvider).container!;
    await tester.runAsync(
      () => container.read(capabilityRefresherProvider).refresh(),
    );
    await tester.pumpAndSettle();

    expect(
      locationOf(root),
      '${RoutePaths.probe}?profile=${Uri.encodeQueryComponent(root.profileId!)}',
    );
    expect(find.text(_tooOld), findsOne);
    expect(find.text('Check again'), findsOne);
    expect(find.text('Switch server'), findsOne);
    await expectMeetsGuidelines(tester);

    // Every shell location leads back to the message.
    root.container.read(routerProvider).go('${RoutePaths.library}/albums');
    await tester.pumpAndSettle();
    expect(find.text(_tooOld), findsOne);

    // Still too old: Check again stays.
    await tester.tap(find.text('Check again'));
    await _drain(tester);
    expect(find.text(_tooOld), findsOne);

    server.version = '1.5.0';
    await tester.tap(find.text('Check again'));
    await _drain(tester);
    expect(locationOf(root), RoutePaths.home);
    expect(find.text(_tooOld), findsNothing);
    expect(server.count('/api/docs.json'), 3);
  });

  testWidgets('Switch server opens the Servers settings', (tester) async {
    final server = FakeServerAdapter(version: '1.3.0');
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      overrides: [
        versionGateProvider.overrideWithValue(_gate),
        soundspanApiFactoryProvider.overrideWithValue(
          (config, credentials) =>
              SoundspanApi(config, credentials: credentials, adapter: server),
        ),
      ],
    );
    final container = root.container.read(profileRuntimeProvider).container!;
    await tester.runAsync(
      () => container.read(capabilityRefresherProvider).refresh(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Switch server'));
    await tester.pumpAndSettle();
    expect(locationOf(root), RoutePaths.settingsServers);
  });
}
