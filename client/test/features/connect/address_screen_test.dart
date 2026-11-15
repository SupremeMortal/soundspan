// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import 'connect_harness.dart';

void main() {
  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.text('Connect'));
    await tester.settle();
  }

  String location(ConnectHarness harness) => harness.router.state.uri.path;

  testWidgets('empty input shows the empty message', (tester) async {
    final harness = await tester.pumpConnect();
    await submit(tester, '   ');
    expect(
      find.text('Enter the address of your soundspan server.'),
      findsOneWidget,
    );
    expect(location(harness), RoutePaths.connect);
    expect(harness.probe.started, isEmpty);
  });

  testWidgets('ftp:// shows the unsupported-scheme message', (tester) async {
    final harness = await tester.pumpConnect();
    await submit(tester, 'ftp://music.example.com');
    expect(
      find.text('Use an address that starts with http:// or https://.'),
      findsOneWidget,
    );
    expect(location(harness), RoutePaths.connect);
  });

  testWidgets('an unusable address shows the invalid message', (tester) async {
    await tester.pumpConnect();
    await submit(tester, 'user@music.example.com');
    expect(
      find.text('That is not a server address. Check it and try again.'),
      findsOneWidget,
    );
    await submit(tester, 'soundspan://link?code=ABC');
    expect(
      find.text('That is not a server address. Check it and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('a LAN address goes straight to the probe', (tester) async {
    final harness = await tester.pumpConnect();
    await submit(tester, '192.168.1.20:3030');
    expect(find.byType(AlertDialog), findsNothing);
    expect(location(harness), RoutePaths.probe);
    expect(
      harness.probe.started.single.candidates.first.toString(),
      'http://192.168.1.20:3030',
    );
  });

  testWidgets('public http asks for confirmation; Cancel stays, Connect '
      'anyway probes', (tester) async {
    final harness = await tester.pumpConnect();
    await submit(tester, 'http://music.example.com');
    expect(find.text('Connection not encrypted'), findsOneWidget);
    await expectMeetsGuidelines(tester);
    await tester.tap(find.text('Cancel'));
    await tester.settle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(location(harness), RoutePaths.connect);
    expect(harness.probe.started, isEmpty);

    await tester.tap(find.text('Connect'));
    await tester.settle();
    await tester.tap(find.text('Connect anyway'));
    await tester.settle();
    expect(location(harness), RoutePaths.probe);
    expect(
      harness.probe.started.single.candidates.single.toString(),
      'http://music.example.com',
    );
  });

  testWidgets('public http where cleartext is not allowed offers only '
      'Cancel', (tester) async {
    final harness = await tester.pumpConnect(
      capabilities: PlatformCapabilities.iOS,
    );
    await submit(tester, 'http://music.example.com');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Connect anyway'), findsNothing);
    expect(
      find.textContaining('This device blocks unencrypted connections'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.settle();
    expect(location(harness), RoutePaths.connect);
    expect(harness.probe.started, isEmpty);
  });

  testWidgets('Enter submits', (tester) async {
    final harness = await tester.pumpConnect();
    await tester.enterText(find.byType(TextField), 'music.example.com');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.settle();
    expect(location(harness), RoutePaths.probe);
    expect(
      harness.probe.started.single.candidates.single.toString(),
      'https://music.example.com',
    );
  });

  testWidgets('back is hidden without a profile', (tester) async {
    await tester.pumpConnect();
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('back is shown with a profile and leaves', (tester) async {
    final harness = await tester.pumpConnect(hasProfile: true);
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.settle();
    expect(location(harness), RoutePaths.home);
  });

  testWidgets('the field asks for a URL keyboard without autocorrect', (
    tester,
  ) async {
    await tester.pumpConnect();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.url);
    expect(field.autocorrect, isFalse);
    expect(field.autofocus, isTrue);
  });

  group('guidelines', () {
    for (final size in [TestSizes.compact, TestSizes.expanded]) {
      for (final theme in [ThemeMode.dark, ThemeMode.light]) {
        testWidgets('${size.width.toInt()} ${theme.name}', (tester) async {
          await tester.pumpConnect(size: size, theme: theme, hasProfile: true);
          await expectMeetsGuidelines(tester);
          await submit(tester, 'ftp://x');
          await expectMeetsGuidelines(tester);
        });
      }
    }

    testWidgets('text scale 2.0 does not overflow', (tester) async {
      await tester.pumpConnect(textScale: 2, hasProfile: true);
      await submit(tester, 'ftp://x');
      expect(tester.takeException(), isNull);
    });
  });
}
