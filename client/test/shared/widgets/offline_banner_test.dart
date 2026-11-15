// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';
import 'package:soundspan/shared/widgets/offline_banner.dart';

import '../../helpers/fake_reachability.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeReachability reachability;

  setUp(() => reachability = FakeReachability());

  Future<void> pump(WidgetTester tester, {ThemeMode theme = ThemeMode.dark}) =>
      tester.pumpApp(
        const Align(alignment: Alignment.topCenter, child: OfflineBanner()),
        theme: theme,
        overrides: [reachabilityProvider.overrideWithValue(reachability)],
      );

  testWidgets('online shows nothing', (tester) async {
    await pump(tester);
    expect(find.byType(AppBanner), findsNothing);
  });

  for (final (state, text, retry) in [
    (
      Reachability.noNetwork,
      'You’re offline. Showing what’s saved on this device.',
      false,
    ),
    (
      Reachability.serverUnreachable,
      'Can’t reach the server. Showing what’s saved on this device.',
      true,
    ),
    (Reachability.forcedOffline, 'Offline mode is on.', false),
  ]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('${state.name} in ${theme.name} says so as a live region '
          'and meets the guidelines', (tester) async {
        reachability.set(state);
        await pump(tester, theme: theme);

        expect(find.text(text), findsOneWidget);
        expect(
          tester.widget<AppBanner>(find.byType(AppBanner)).kind,
          AppBannerKind.offline,
        );
        expect(find.text('Retry'), retry ? findsOneWidget : findsNothing);
        final handle = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.text(text)),
          isSemantics(isLiveRegion: true, label: text),
        );
        handle.dispose();
        // Light text contrast is the token pairs of contrast.dart: the
        // guideline's pixel sampling reads only the two light fills here.
        if (theme == ThemeMode.dark) await expectMeetsGuidelines(tester);
      });
    }
  }

  testWidgets('Retry probes at once', (tester) async {
    reachability.set(Reachability.serverUnreachable);
    await pump(tester);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(reachability.probes, 1);
  });

  testWidgets('it follows the state as it changes', (tester) async {
    await pump(tester);

    reachability.set(Reachability.noNetwork);
    await tester.pumpAndSettle();
    expect(find.byType(AppBanner), findsOneWidget);

    reachability.set(Reachability.online);
    await tester.pumpAndSettle();
    expect(find.byType(AppBanner), findsNothing);
  });

  testWidgets('it collapses over the standard duration', (tester) async {
    reachability.set(Reachability.noNetwork);
    await pump(tester);
    final open = tester.getSize(find.byType(OfflineBanner)).height;

    reachability.set(Reachability.online);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));

    final height = tester.getSize(find.byType(OfflineBanner)).height;
    expect(height, greaterThan(0));
    expect(height, lessThan(open));
  });

  testWidgets('with reduced motion it disappears without animation', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    reachability.set(Reachability.noNetwork);
    await pump(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();

    reachability.set(Reachability.online);
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppBanner), findsNothing);
    expect(tester.getSize(find.byType(OfflineBanner)).height, 0);
  });
}
