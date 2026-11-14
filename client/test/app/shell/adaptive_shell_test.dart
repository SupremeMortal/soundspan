// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/window_class.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

/// A shell whose selection is local state, with a probe in the content.
class _Harness extends StatefulWidget {
  const new({this.seen});

  final List<WindowClass>? seen;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => AdaptiveShell(
    selectedIndex: selected,
    onDestinationSelected: (index) => setState(() => selected = index),
    child: Builder(
      builder: (context) {
        widget.seen?.add(WindowClass.of(context));
        return const SizedBox.expand();
      },
    ),
  );
}

void main() {
  testWidgets('compact shows a bottom bar with four destinations', (
    tester,
  ) async {
    await tester.pumpApp(const _Harness());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(AdaptiveShell.sidebarKey), findsNothing);
  });

  testWidgets('medium shows a navigation rail', (tester) async {
    await tester.pumpApp(const _Harness(), size: TestSizes.medium);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(AdaptiveShell.sidebarKey), findsNothing);
  });

  testWidgets('expanded shows the 256 px sidebar', (tester) async {
    await tester.pumpApp(const _Harness(), size: TestSizes.expanded);
    expect(find.byKey(AdaptiveShell.sidebarKey), findsOneWidget);
    expect(tester.getSize(find.byKey(AdaptiveShell.sidebarKey)).width, 256);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    for (final label in ['Home', 'Search', 'Library', 'Podcasts']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('resizing to compact keeps the selected destination', (
    tester,
  ) async {
    await tester.pumpApp(const _Harness(), size: TestSizes.expanded);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(500, 900);
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, ShellDestination.library.index);
  });

  testWidgets('WindowClass.of reports the class to a descendant', (
    tester,
  ) async {
    final seen = <WindowClass>[];
    await tester.pumpApp(_Harness(seen: seen), size: TestSizes.medium);
    expect(seen.last, WindowClass.medium);

    tester.view.physicalSize = TestSizes.expanded;
    await tester.pumpAndSettle();
    expect(seen.last, WindowClass.expanded);
  });

  for (final size in [
    TestSizes.compact,
    TestSizes.medium,
    TestSizes.expanded,
  ]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
        'meets the guidelines at ${size.width.toInt()} in ${theme.name}',
        (tester) async {
          await tester.pumpApp(const _Harness(), size: size, theme: theme);
          await tester.pumpAndSettle();
          await expectMeetsGuidelines(tester);
        },
      );
    }
  }
}
