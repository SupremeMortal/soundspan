// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';

import '../../helpers/pump_app.dart';

const _title = 'A Rather Long Album Title';

Widget _page({Widget? actions, VoidCallback? onLink}) => Builder(
  builder: (context) => WindowClassScope(
    windowClass: windowClassOf(MediaQuery.sizeOf(context)),
    child: Scaffold(
      body: CustomScrollView(
        slivers: [
          DetailHeader(
            artworkRef: 'cover',
            overline: 'Album',
            title: _title,
            metadata: DetailMetadataLine(
              link: 'The Artist',
              onLink: onLink,
              parts: const ['2020', '12 songs'],
            ),
            actions: actions,
            slivers: [
              SliverList.builder(
                itemCount: 60,
                itemBuilder: (context, index) =>
                    SizedBox(height: 48, child: Text('Row $index')),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

Finder _appBarTitle() =>
    find.descendant(of: find.byType(AppBar), matching: find.text(_title));

void main() {
  testWidgets('artwork is 140, 192 and 232 at 390, 800 and 1440', (
    tester,
  ) async {
    for (final (size, edge) in [
      (TestSizes.compact, 140.0),
      (TestSizes.medium, 192.0),
      (TestSizes.expanded, 232.0),
    ]) {
      await tester.pumpApp(_page(), size: size);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(DetailHeader.artworkKey)),
        Size(edge, edge),
        reason: '$size',
      );
    }
  });

  testWidgets('the title style follows the window class', (tester) async {
    for (final (size, windowClass) in [
      (TestSizes.compact, WindowClass.compact),
      (TestSizes.medium, WindowClass.medium),
      (TestSizes.expanded, WindowClass.expanded),
    ]) {
      await tester.pumpApp(_page(), size: size);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(CustomScrollView));
      final expected = DetailHeader.titleStyleFor(
        context.typography,
        windowClass,
      );
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(SliverToBoxAdapter),
          matching: find.text(_title),
        ),
      );
      expect(title.style?.fontSize, expected.fontSize, reason: '$size');
      expect(title.style?.height, expected.height, reason: '$size');
      expect(title.maxLines, 2);
    }
    final typography = tester.element(find.byType(CustomScrollView)).typography;
    expect(
      DetailHeader.titleStyleFor(typography, WindowClass.compact).fontSize,
      24,
    );
    expect(
      DetailHeader.titleStyleFor(typography, WindowClass.expanded),
      typography.display,
    );
  });

  testWidgets('scrolling collapses the header and keeps the title in the '
      'app bar', (tester) async {
    await tester.pumpApp(_page());
    await tester.pumpAndSettle();
    expect(_appBarTitle(), findsNothing);
    expect(find.byKey(DetailHeader.artworkKey).hitTestable(), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(_appBarTitle(), findsOneWidget);
    expect(find.byKey(DetailHeader.artworkKey).hitTestable(), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(_appBarTitle(), findsNothing);
  });

  testWidgets('the actions slot is empty by default', (tester) async {
    await tester.pumpApp(_page());
    await tester.pumpAndSettle();
    expect(find.byKey(DetailHeader.actionsKey), findsNothing);

    await tester.pumpApp(_page(actions: const Text('Play')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(DetailHeader.actionsKey),
        matching: find.text('Play'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the overline is upper case and the metadata link is tappable', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpApp(_page(onLink: () => opened++));
    await tester.pumpAndSettle();
    expect(find.text('ALBUM'), findsOneWidget);
    expect(find.text(' · 2020 · 12 songs'), findsOneWidget);
    await tester.tap(find.byKey(DetailMetadataLine.linkKey));
    expect(opened, 1);
  });

  testWidgets('total durations read in minutes, then hours and minutes', (
    tester,
  ) async {
    await tester.pumpApp(const SizedBox());
    final l10n = AppLocalizations.of(tester.element(find.byType(SizedBox)));
    expect(formatTotalDuration(l10n, const Duration(minutes: 45)), '45 min');
    expect(
      formatTotalDuration(l10n, const Duration(hours: 1, minutes: 5)),
      '1 hr 5 min',
    );
    expect(formatTotalDuration(l10n, const Duration(seconds: -3)), '0 min');
  });
}
