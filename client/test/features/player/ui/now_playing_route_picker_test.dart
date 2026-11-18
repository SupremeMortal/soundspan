// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/route_picker/route_picker.dart';
import 'package:soundspan/shared/widgets/quality_badge.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

const _placeholderKey = Key('routePicker.placeholder');

void main() {
  /// Pumps `/now-playing` with [capabilities] and the picker seam faked
  /// with a placeholder; returns the rig and the tints it was built with.
  Future<(PlayerRig, List<(Color, Color)>)> pumpNowPlaying(
    WidgetTester tester, {
    required PlatformCapabilities capabilities,
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
  }) async {
    final rig = PlayerRig();
    final tints = <(Color, Color)>[];
    final router = GoRouter(
      initialLocation: RoutePaths.nowPlaying,
      routes: [
        GoRoute(
          path: RoutePaths.nowPlaying,
          builder: (_, _) => const NowPlayingScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = await tester.pumpApp(
      Router.withConfig(config: router),
      size: size,
      theme: theme,
      overrides: [
        ...rig.overrides,
        platformCapabilitiesProvider.overrideWithValue(capabilities),
        routePickerBuilderProvider.overrideWithValue(({
          required tint,
          required activeTint,
        }) {
          tints.add((tint, activeTint));
          return const ColoredBox(
            key: _placeholderKey,
            color: Color(0x00000000),
          );
        }),
      ],
    );
    container.read(playbackControllerProvider);
    await rig.start(tester, play: false);
    await tester.pumpAndSettle();
    return (rig, tints);
  }

  testWidgets('with a system picker the labelled 48 × 48 slot sits in the '
      'quality row', (tester) async {
    final (rig, tints) = await pumpNowPlaying(
      tester,
      capabilities: PlatformCapabilities.iOS,
    );

    final slot = find.byKey(NowPlayingScreen.routePickerKey);
    expect(slot, findsOneWidget);
    expect(tester.getSize(slot), const Size(48, 48));
    expect(
      find.descendant(of: slot, matching: find.byKey(_placeholderKey)),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Audio output'), findsOneWidget);
    // Same row as the quality badge.
    expect(
      tester.getCenter(slot).dy,
      moreOrLessEquals(
        tester.getCenter(find.byType(QualityBadge)).dy,
        epsilon: 24,
      ),
    );
    expect(tints, isNotEmpty);
    await expectMeetsGuidelines(tester);
    await rig.close(tester);
  });

  testWidgets('landscape medium shows the slot too', (tester) async {
    final (rig, _) = await pumpNowPlaying(
      tester,
      capabilities: PlatformCapabilities.iOS,
      size: const Size(1000, 700),
    );

    expect(find.byKey(NowPlayingScreen.routePickerKey), findsOneWidget);
    await expectMeetsGuidelines(tester);
    await rig.close(tester);
  });

  testWidgets('without a system picker there is no slot', (tester) async {
    final (rig, tints) = await pumpNowPlaying(
      tester,
      capabilities: PlatformCapabilities.android,
    );

    expect(find.byKey(NowPlayingScreen.routePickerKey), findsNothing);
    expect(find.byKey(_placeholderKey), findsNothing);
    expect(find.bySemanticsLabel('Audio output'), findsNothing);
    expect(tints, isEmpty);
    await rig.close(tester);
  });

  testWidgets('buildRoutePicker is an empty box off iOS', (tester) async {
    final picker = buildRoutePicker(
      tint: const Color(0xFF000000),
      activeTint: const Color(0xFFFFFFFF),
    );
    expect(picker, isA<SizedBox>());
    expect((picker as SizedBox).width, 0);
    expect(picker.height, 0);
  }, variant: TargetPlatformVariant.all(excluding: {TargetPlatform.iOS}));

  testWidgets('buildRoutePicker embeds the native view on iOS', (tester) async {
    final picker = buildRoutePicker(
      tint: const Color(0xFF102030),
      activeTint: const Color(0xFF405060),
    );
    expect(picker, isA<UiKitView>());
    final view = picker as UiKitView;
    expect(view.viewType, 'io.soundspan.app/route_picker');
    expect(view.creationParams, {'tint': 0xFF102030, 'activeTint': 0xFF405060});
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
