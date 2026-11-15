// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/probe/probe_failure.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/features/connect/connect.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import 'connect_harness.dart';

const _typed = 'music.example.com';
final Uri _candidate = Uri.parse('https://music.example.com');

ProbeRequest _request([String text = _typed]) =>
    ProbeRequest(input: text, address: ServerAddress.parse(text));

ProbeFailed _failed(ProbeFailureClass failureClass) => ProbeFailed(
  ProbeFailure(failureClass: failureClass, candidate: _candidate),
);

void main() {
  String location(ConnectHarness harness) => harness.router.state.uri.path;

  Future<ConnectHarness> pumpProbe(
    WidgetTester tester, {
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
    double textScale = 1.0,
  }) => tester.pumpConnect(
    initial: RoutePaths.probe,
    extra: _request(),
    size: size,
    theme: theme,
    textScale: textScale,
  );

  Future<void> emit(
    WidgetTester tester,
    ConnectHarness harness,
    ProbeState state,
  ) async {
    harness.probe.emit(state);
    await tester.settle();
  }

  testWidgets('opening the screen starts the probe of the address', (
    tester,
  ) async {
    final harness = await pumpProbe(tester);
    expect(harness.probe.started.single.candidates.single, _candidate);
    expect(find.text('Connecting to https://music.example.com'), findsOne);
  });

  testWidgets('resolving', (tester) async {
    final harness = await pumpProbe(tester);
    harness.probe.emit(ProbeResolving(_candidate));
    await tester.pump();
    expect(find.text('Connecting to https://music.example.com'), findsOne);
    expect(find.byType(CircularProgressIndicator), findsOne);
    await tester.tap(find.text('Cancel'));
    await tester.settle();
    expect(location(harness), RoutePaths.connect);
    expect(harness.probe.cancels, greaterThan(0));
  });

  testWidgets('starting', (tester) async {
    final harness = await pumpProbe(tester);
    harness.probe.emit(ProbeStarting(_candidate, 27));
    await tester.pump();
    expect(find.text('The server is starting'), findsOne);
    expect(find.text('Trying again in 3 seconds'), findsOne);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Trying again in 2 seconds'), findsOne);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Trying again in 1 second'), findsOne);
    harness.probe.emit(ProbeStarting(_candidate, 24));
    await tester.pump();
    expect(find.text('Trying again in 3 seconds'), findsOne);
    expect(find.text('Cancel'), findsOne);
    harness.probe.emit(ProbeResolving(_candidate));
    await tester.settle();
  });

  testWidgets('ready navigates with the result', (tester) async {
    final harness = await pumpProbe(tester);
    await emit(
      tester,
      harness,
      ProbeReady(probeResult('https://music.example.com')),
    );
    expect(location(harness), RoutePaths.signIn);
    expect(find.text('sign-in https://music.example.com'), findsOne);
  });

  testWidgets('ready with changed base shows the final base, Continue '
      'navigates', (tester) async {
    final harness = await pumpProbe(tester);
    await emit(
      tester,
      harness,
      ProbeReady(
        probeResult(
          'https://www.music.example.com/soundspan',
          requested: 'https://music.example.com',
        ),
      ),
    );
    expect(location(harness), RoutePaths.probe);
    expect(
      find.text('Using https://www.music.example.com/soundspan'),
      findsOne,
    );
    expect(find.text('Edit address'), findsOne);
    expect(find.text('Not encrypted'), findsNothing);
    await expectMeetsGuidelines(tester);
    await tester.tap(find.text('Continue'));
    await tester.settle();
    expect(location(harness), RoutePaths.signIn);
    expect(
      find.text('sign-in https://www.music.example.com/soundspan'),
      findsOne,
    );
  });

  testWidgets('private cleartext chip', (tester) async {
    final harness = await pumpProbe(tester);
    await emit(
      tester,
      harness,
      ProbeReady(probeResult('http://192.168.1.20:3030', isPrivateHost: true)),
    );
    expect(location(harness), RoutePaths.probe);
    expect(find.text('Connected to http://192.168.1.20:3030'), findsOne);
    expect(find.text('Not encrypted'), findsOne);
    await expectMeetsGuidelines(tester);
    await tester.tap(find.text('Continue'));
    await tester.settle();
    expect(location(harness), RoutePaths.signIn);
  });

  testWidgets('needsSetup', (tester) async {
    final harness = await pumpProbe(tester);
    await emit(
      tester,
      harness,
      ProbeNeedsSetup(probeResult('https://music.example.com/soundspan')),
    );
    expect(find.textContaining('has not been set up yet'), findsOne);
    await expectMeetsGuidelines(tester);
    await tester.tap(find.text('Open in browser'));
    await tester.settle();
    expect(harness.opener.opened, [
      Uri.parse('https://music.example.com/soundspan'),
    ]);
    await tester.tap(find.text('Try again'));
    expect(harness.probe.retries, 1);
  });

  const messages = {
    ProbeFailureClass.dns: 'Address not found',
    ProbeFailureClass.refused: 'Nothing is listening at that address and port',
    ProbeFailureClass.timeout: 'The server did not answer',
    ProbeFailureClass.tls:
        'The server’s certificate is not trusted by this device',
    ProbeFailureClass.blockedByProxy:
        'Something in front of the server requires its own login',
    ProbeFailureClass.notSoundspan:
        'That address is not a soundspan server (check the path)',
    ProbeFailureClass.serverError: 'The server reported an error',
    ProbeFailureClass.redirectRefused:
        'The server redirected to an address this app will not follow',
  };

  test('every failure class has a test', () {
    expect({
      ...messages.keys,
      ProbeFailureClass.corsOrNetwork,
    }, ProbeFailureClass.values.toSet());
  });

  for (final MapEntry(key: failureClass, value: message) in messages.entries) {
    testWidgets(failureClass.name, (tester) async {
      final harness = await pumpProbe(tester);
      await emit(tester, harness, _failed(failureClass));
      expect(find.text(message), findsOne);
      expect(find.text('Address tried: https://music.example.com'), findsOne);
      expect(find.text('Try again'), findsOne);
      expect(find.text('Edit address'), findsOne);
      expect(find.text('https://app.example.com'), findsNothing);
    });
  }

  testWidgets('corsOrNetwork', (tester) async {
    final harness = await pumpProbe(tester);
    await emit(tester, harness, _failed(ProbeFailureClass.corsOrNetwork));
    expect(find.textContaining('ALLOWED_ORIGINS'), findsOne);
    expect(find.text('Address tried: https://music.example.com'), findsOne);
    final origin = find.widgetWithText(TextField, 'https://app.example.com');
    expect(origin, findsOne);
    expect(tester.widget<TextField>(origin).readOnly, isTrue);
    await expectMeetsGuidelines(tester);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.text('Copy'));
    await tester.settle();
    expect(copied, 'https://app.example.com');
  });

  testWidgets('Try again calls retry', (tester) async {
    final harness = await pumpProbe(tester);
    await emit(tester, harness, _failed(ProbeFailureClass.timeout));
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(harness.probe.retries, 1);
  });

  testWidgets('Edit address returns with the text preserved', (tester) async {
    final harness = await tester.pumpConnect();
    await tester.enterText(find.byType(TextField), 'music.example.com/sub');
    await tester.tap(find.text('Connect'));
    await tester.settle();
    expect(location(harness), RoutePaths.probe);
    await emit(tester, harness, _failed(ProbeFailureClass.notSoundspan));
    await tester.tap(find.text('Edit address'));
    await tester.settle();
    expect(location(harness), RoutePaths.connect);
    expect(find.widgetWithText(TextField, 'music.example.com/sub'), findsOne);
  });

  testWidgets('Edit address keeps the text without an address screen below', (
    tester,
  ) async {
    final harness = await pumpProbe(tester);
    await emit(tester, harness, _failed(ProbeFailureClass.dns));
    await tester.tap(find.text('Edit address'));
    await tester.settle();
    expect(location(harness), RoutePaths.connect);
    expect(find.widgetWithText(TextField, _typed), findsOne);
  });

  testWidgets('leaving cancels the probe', (tester) async {
    final harness = await tester.pumpConnect();
    await tester.enterText(find.byType(TextField), _typed);
    await tester.tap(find.text('Connect'));
    await tester.settle();
    final before = harness.probe.cancels;
    harness.router.pop();
    await tester.settle();
    expect(location(harness), RoutePaths.connect);
    expect(harness.probe.cancels, greaterThan(before));
  });

  testWidgets('the message is a live region', (tester) async {
    final harness = await pumpProbe(tester);
    await emit(tester, harness, _failed(ProbeFailureClass.dns));
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text('Address not found')),
      matchesSemantics(label: 'Address not found', isLiveRegion: true),
    );
    handle.dispose();
  });

  group('guidelines', () {
    final states = <String, ProbeState>{
      'resolving': ProbeResolving(_candidate),
      'starting': ProbeStarting(_candidate, 30),
      'failed': _failed(ProbeFailureClass.corsOrNetwork),
      'needsSetup': ProbeNeedsSetup(probeResult('https://music.example.com')),
    };
    for (final size in [TestSizes.compact, TestSizes.expanded]) {
      for (final theme in [ThemeMode.dark, ThemeMode.light]) {
        testWidgets('${size.width.toInt()} ${theme.name}', (tester) async {
          final harness = await pumpProbe(tester, size: size, theme: theme);
          for (final state in states.values) {
            harness.probe.emit(state);
            await tester.pump();
            await expectMeetsGuidelines(tester);
          }
          harness.probe.emit(ProbeResolving(_candidate));
          await tester.settle();
        });
      }
    }

    testWidgets('text scale 2.0 does not overflow', (tester) async {
      final harness = await pumpProbe(tester, textScale: 2);
      for (final state in states.values) {
        harness.probe.emit(state);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      harness.probe.emit(ProbeResolving(_candidate));
      await tester.settle();
    });
  });
}
