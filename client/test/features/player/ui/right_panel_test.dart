// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

void main() {
  /// Pumps the expanded shell with a paused queue of a, b, c.
  Future<PlayerRig> pumpShell(
    WidgetTester tester, {
    Size size = TestSizes.expanded,
    ThemeMode theme = ThemeMode.dark,
  }) async {
    final rig = PlayerRig();
    final container = await tester.pumpApp(
      AppShell(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        onSearch: (_) {},
        child: const Center(child: Text('content')),
      ),
      size: size,
      theme: theme,
      overrides: [
        ...rig.overrides,
        initialActiveProfileIdProvider.overrideWithValue(null),
      ],
    );
    container.read(playbackControllerProvider);
    await rig.start(tester, play: false);
    await tester.pumpAndSettle();
    return rig;
  }

  double sidebarWidth(WidgetTester tester) =>
      tester.getSize(find.byKey(AdaptiveShell.sidebarKey)).width;

  testWidgets('the queue button toggles the queue panel', (tester) async {
    final rig = await pumpShell(tester);
    expect(find.byKey(AdaptiveShell.rightPanelKey), findsNothing);

    await tester.tap(find.byTooltip('Queue'));
    await tester.pumpAndSettle();

    final panel = find.byKey(AdaptiveShell.rightPanelKey);
    expect(tester.getSize(panel).width, AdaptiveShell.rightPanelWidth);
    expect(
      find.descendant(of: panel, matching: find.byType(QueueView)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.text('Next up')),
      findsOneWidget,
    );
    expect(sidebarWidth(tester), AdaptiveShell.sidebarWidth);

    await tester.tap(find.byTooltip('Queue'));
    await tester.pumpAndSettle();
    expect(find.byKey(AdaptiveShell.rightPanelKey), findsNothing);
    await rig.close(tester);
  });

  testWidgets('the open panel collapses the sidebar below 1200', (
    tester,
  ) async {
    final rig = await pumpShell(tester, size: const Size(1100, 800));
    expect(sidebarWidth(tester), AdaptiveShell.sidebarWidth);

    await tester.tap(find.byTooltip('Queue'));
    await tester.pumpAndSettle();
    expect(sidebarWidth(tester), AdaptiveShell.railWidth);
    expect(find.byTooltip('Home'), findsOneWidget);
    await expectMeetsGuidelines(tester);

    await tester.tap(find.byTooltip('Queue'));
    await tester.pumpAndSettle();
    expect(sidebarWidth(tester), AdaptiveShell.sidebarWidth);
    await rig.close(tester);
  });

  testWidgets('the expand button shows and hides the overlay', (tester) async {
    final rig = await pumpShell(tester);
    expect(find.byType(NowPlayingOverlay), findsNothing);

    await tester.tap(find.byTooltip('Show now playing'));
    await tester.pumpAndSettle();
    final overlay = find.byType(NowPlayingOverlay);
    expect(overlay, findsOneWidget);
    expect(
      find.descendant(of: overlay, matching: find.text('Song a')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: overlay, matching: find.text('The Band a')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Hide now playing'));
    await tester.pumpAndSettle();
    expect(find.byType(NowPlayingOverlay), findsNothing);
    expect(find.text('content'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('Escape closes the overlay', (tester) async {
    final rig = await pumpShell(tester);
    await tester.tap(find.byTooltip('Show now playing'));
    await tester.pumpAndSettle();
    expect(find.byType(NowPlayingOverlay), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(NowPlayingOverlay), findsNothing);
    await rig.close(tester);
  });

  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('panel and overlay meet the guidelines (${theme.name})', (
      tester,
    ) async {
      final rig = await pumpShell(tester, theme: theme);
      await tester.tap(find.byTooltip('Queue'));
      await tester.tap(find.byTooltip('Show now playing'));
      await tester.pumpAndSettle();

      // In light the player bar's artist line is exempt from the contrast
      // sampler only (see player_bar_test.dart and doc 11, Golden Tests).
      await expectMeetsGuidelines(
        tester,
        contrastSamplingExempt: [
          if (theme == ThemeMode.light)
            find.descendant(
              of: find.byType(PlayerBar),
              matching: find.text('The Band a'),
            ),
        ],
      );
      await rig.close(tester);
    });
  }
}
