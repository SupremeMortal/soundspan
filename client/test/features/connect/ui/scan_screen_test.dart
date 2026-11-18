// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/deep_link_router.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/features/connect/connect.dart';
import 'package:soundspan/features/connect/ui/device_link_panel.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_qr_scanner.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'device_link_fakes.dart';

const _scanQr = 'Scan QR code';
const _rejected = 'That is not a soundspan code';
const _enterCode = 'Enter the code instead';

/// The link panel's location in the test router.
const _panel = '/connect/link';

/// The scanner's location.
const _scan = '/connect/scan';

class _NoProfiles implements DeepLinkProfiles {
  @override
  bool get hasActive => false;

  @override
  Future<String?> idForBaseUrl(List<Uri> candidates) async => null;

  @override
  Future<void> switchTo(String profileId) async {}
}

/// What [_pump] built.
class _Harness {
  new(this.router, this.scanner);

  final GoRouter router;
  final FakeQrScanner scanner;

  String get location => router.state.uri.path;

  ProbeRequest get request => router.state.extra! as ProbeRequest;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  PlatformCapabilities capabilities = PlatformCapabilities.android,
  String initial = _scan,
}) async {
  final scanner = FakeQrScanner();
  final router = GoRouter(
    initialLocation: _panel,
    routes: [
      GoRoute(
        path: RoutePaths.connect,
        builder: (_, _) => const AddressScreen(),
        routes: [
          GoRoute(
            path: 'link',
            builder: (_, _) => Scaffold(
              body: SingleChildScrollView(
                child: DeviceLinkPanel(
                  baseUrl: Uri.parse(linkBase),
                  onLinked: (_) async {},
                ),
              ),
            ),
          ),
          GoRoute(
            path: 'scan',
            redirect: ScanScreen.redirect,
            builder: (_, _) => const ScanScreen(),
          ),
          GoRoute(
            path: 'probe',
            builder: (_, state) => Text(
              'probe ${(state.extra! as ProbeRequest).address.candidates.first}',
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  final clock = FakeClock();
  await tester.pumpApp(
    Router.withConfig(config: router),
    clock: clock,
    overrides: [
      platformCapabilitiesProvider.overrideWithValue(capabilities),
      qrScannerFactoryProvider.overrideWithValue(() => scanner),
      deepLinkRouterProvider.overrideWithValue(
        DeepLinkRouter(router: router, profiles: _NoProfiles(), clock: clock),
      ),
      deviceLinkSignInProvider.overrideWithValue(FakeDeviceLinkSignIn()),
      deviceInfoProvider.overrideWithValue(
        const DeviceInfo(osLabel: 'Linux', isMobile: false, hostName: 'studio'),
      ),
    ],
  );
  await tester.pumpAndSettle();
  if (initial == _scan) {
    unawaited(router.push<void>(_scan));
    await tester.pumpAndSettle();
  }
  return _Harness(router, scanner);
}

void main() {
  testWidgets('the scanner starts when the screen opens', (tester) async {
    final harness = await _pump(tester);
    expect(harness.location, _scan);
    expect(harness.scanner.starts, 1);
    expect(harness.scanner.running, isTrue);
  });

  testWidgets('a device-page link probes its server with its code and stops '
      'the scanner', (tester) async {
    final harness = await _pump(tester);
    harness.scanner.scan(
      'soundspan://link?code=ABC234&server=https%3A%2F%2Fmusic.example.com',
    );
    await tester.pumpAndSettle();
    expect(harness.location, RoutePaths.probe);
    expect(harness.request.address.linkCode, 'ABC234');
    expect(
      harness.request.address.candidates.first,
      Uri.parse('https://music.example.com'),
    );
    expect(harness.scanner.running, isFalse);
    expect(harness.scanner.stops, greaterThanOrEqualTo(1));
  });

  testWidgets('a server address probes it with no code', (tester) async {
    final harness = await _pump(tester);
    harness.scanner.scan('https://music.example.com/soundspan');
    await tester.pumpAndSettle();
    expect(harness.location, RoutePaths.probe);
    expect(harness.request.address.linkCode, isNull);
    expect(
      harness.request.address.candidates.first,
      Uri.parse('https://music.example.com/soundspan'),
    );
    expect(harness.scanner.running, isFalse);
  });

  testWidgets('another value is rejected for three seconds, scanning goes on '
      'and a repeat does not re-trigger it', (tester) async {
    final harness = await _pump(tester);
    harness.scanner.scan('hello');
    await tester.pump();
    expect(find.text(_rejected), findsOneWidget);
    expect(harness.location, _scan);
    expect(harness.scanner.running, isTrue);

    await tester.pump(const Duration(seconds: 2));
    harness.scanner.scan('hello');
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text(_rejected), findsNothing);
    harness.scanner.scan('hello');
    await tester.pump();
    expect(find.text(_rejected), findsNothing);
    expect(harness.location, _scan);
    expect(harness.scanner.running, isTrue);
  });

  testWidgets('a link with an invalid code is not a soundspan code', (
    tester,
  ) async {
    final harness = await _pump(tester);
    harness.scanner.scan(
      'soundspan://link?code=ABC10O&server=https%3A%2F%2Fmusic.example.com',
    );
    await tester.pump();
    expect(find.text(_rejected), findsOneWidget);
    expect(harness.location, _scan);
    expect(harness.scanner.running, isTrue);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a denied permission shows the fallback; Enter the code '
      'instead returns to the panel', (tester) async {
    final harness = await _pump(tester);
    harness.scanner.fail(QrScannerError.permissionDenied);
    await tester.pump();
    expect(
      find.text('soundspan cannot use the camera to scan the code.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'To scan, allow camera access for soundspan in your system settings.',
      ),
      findsOneWidget,
    );
    await expectMeetsGuidelines(tester);
    await tester.tap(find.text(_enterCode));
    await tester.pumpAndSettle();
    expect(harness.location, _panel);
    expect(find.byType(DeviceLinkPanel), findsOneWidget);
  });

  for (final error in [QrScannerError.noCamera, QrScannerError.unsupported]) {
    testWidgets('$error shows No camera available', (tester) async {
      final harness = await _pump(tester);
      harness.scanner.fail(error);
      await tester.pump();
      expect(find.text('No camera available'), findsOneWidget);
      expect(find.text(_enterCode), findsOneWidget);
      await expectMeetsGuidelines(tester);
    });
  }

  testWidgets('leaving the screen stops the scanner', (tester) async {
    final harness = await _pump(tester);
    harness.router.pop();
    await tester.pumpAndSettle();
    expect(harness.location, _panel);
    expect(harness.scanner.stops, 1);
    expect(harness.scanner.running, isFalse);
  });

  testWidgets('backgrounding the app stops the scanner and resuming starts '
      'it again', (tester) async {
    final harness = await _pump(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(harness.scanner.running, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(harness.scanner.running, isTrue);
  });

  group('entry points', () {
    testWidgets('the panel and the address screen open the scanner', (
      tester,
    ) async {
      final harness = await _pump(tester, initial: _panel);
      await tester.ensureVisible(find.text(_scanQr));
      await tester.tap(find.text(_scanQr));
      await tester.pumpAndSettle();
      expect(harness.location, _scan);
      harness.router.go(RoutePaths.connect);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_scanQr));
      await tester.pumpAndSettle();
      expect(harness.location, _scan);
    });

    testWidgets('without canScanQr neither is built and the route '
        'redirects', (tester) async {
      final harness = await _pump(
        tester,
        capabilities: PlatformCapabilities.windowsAndLinux,
        initial: _panel,
      );
      expect(find.byType(DeviceLinkPanel), findsOneWidget);
      expect(find.text(_scanQr), findsNothing);
      harness.router.go(RoutePaths.connect);
      await tester.pumpAndSettle();
      expect(find.byType(AddressScreen), findsOneWidget);
      expect(find.text(_scanQr), findsNothing);
      harness.router.go(_scan);
      await tester.pumpAndSettle();
      expect(harness.location, RoutePaths.connect);
      expect(harness.scanner.starts, 0);
    });
  });
}
