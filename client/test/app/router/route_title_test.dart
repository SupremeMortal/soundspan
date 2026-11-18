// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  List<String> recordTitles(WidgetTester tester) {
    final titles = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
          titles.add(
            (call.arguments as Map<Object?, Object?>)['label']! as String,
          );
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
    return titles;
  }

  State<_Probe> probeState(WidgetTester tester) =>
      tester.state<State<_Probe>>(find.byType(_Probe));

  BuildContext probeContext(WidgetTester tester) =>
      tester.element(find.byType(_Probe));

  Future<void> pumpTitled(WidgetTester tester) => tester.pumpApp(
    const RouteTitle(
      screen: 'Home',
      child: Scaffold(body: _Probe()),
    ),
  );

  testWidgets('keeps the state below it while a dialog covers the route', (
    tester,
  ) async {
    await pumpTitled(tester);
    final before = probeState(tester);

    showDialog<void>(
      context: probeContext(tester),
      builder: (_) => const AlertDialog(content: Text('Dialog')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsOneWidget);
    expect(probeState(tester), same(before));

    Navigator.of(probeContext(tester)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsNothing);
    expect(probeState(tester), same(before));
  });

  testWidgets(
    'keeps the state below it while a bottom sheet covers the route',
    (tester) async {
      await pumpTitled(tester);
      final before = probeState(tester);

      showModalBottomSheet<void>(
        context: probeContext(tester),
        builder: (_) => const Text('Sheet'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sheet'), findsOneWidget);
      expect(probeState(tester), same(before));

      Navigator.of(probeContext(tester)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Sheet'), findsNothing);
      expect(probeState(tester), same(before));
    },
  );

  testWidgets('only the visible route sets the title', (tester) async {
    final titles = recordTitles(tester);
    await pumpTitled(tester);
    expect(titles.last, 'Home · soundspan');

    Navigator.of(probeContext(tester)).push(
      MaterialPageRoute<void>(
        builder: (_) => const RouteTitle(
          screen: 'Album',
          child: Scaffold(body: Text('Album page')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(titles.last, 'Album · soundspan');
    final afterPush = titles.length;

    showDialog<void>(
      context: tester.element(find.text('Album page')),
      builder: (_) => const AlertDialog(content: Text('Dialog')),
    );
    await tester.pumpAndSettle();
    expect(titles.skip(afterPush), isNot(contains('Home · soundspan')));

    Navigator.of(tester.element(find.text('Dialog'))).pop();
    await tester.pumpAndSettle();
    expect(titles.last, 'Album · soundspan');

    Navigator.of(tester.element(find.text('Album page'))).pop();
    await tester.pumpAndSettle();
    expect(titles.last, 'Home · soundspan');
  });
}

/// A stateful leaf whose `State` identity the tests compare.
class _Probe extends StatefulWidget {
  const new();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) => const Text('Probe');
}
