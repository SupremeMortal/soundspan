// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The iOS audio output picker on the simulator (doc 10, iOS: Route
// picker), run by the engine-conformance-ios job of
// .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/ios/route_picker_test.dart -d <udid>
//
// Pumps the now-playing screen over a fake controller and checks that the
// `AVRoutePickerView` platform view registered by AppDelegate.swift is
// created without a PlatformException.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/route_picker/route_picker.dart';

import '../../test/features/player/ui/player_rig.dart';
import '../../test/helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the now-playing screen creates the AVRoutePickerView', (
    tester,
  ) async {
    final errors = <Object>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exception);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    final rig = PlayerRig();
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
      overrides: rig.overrides,
    );
    expect(
      container.read(platformCapabilitiesProvider).hasSystemRoutePicker,
      isTrue,
    );
    container.read(playbackControllerProvider);
    await rig.start(tester, play: false);
    // Platform view creation is asynchronous; give the engine time.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final view = find.byType(UiKitView);
    expect(view, findsOneWidget);
    expect(tester.widget<UiKitView>(view).viewType, routePickerViewType);
    expect(
      find.descendant(
        of: find.byKey(NowPlayingScreen.routePickerKey),
        matching: view,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    expect(errors.whereType<PlatformException>(), isEmpty);
    expect(errors, isEmpty);
    await rig.close(tester);
  });
}
