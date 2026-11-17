// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The real app on a desktop window (doc 11, Integration (desktop)): it
// reaches the shell at an expanded size, switches destinations, keeps its
// minimum size and restores its bounds. Run by the desktop-integration jobs
// of .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/desktop/shell_smoke_test.dart -d <os>

@Tags(['desktop'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/window_state_controller.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

import '../support/desktop_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app reaches the shell at an expanded size, switches its '
      'four destinations, keeps the 480 × 600 minimum and a new controller '
      'restores the bounds it saved', (tester) async {
    final server = (await tester.runAsync(DesktopApiServer.start))!;
    addTearDown(server.close);
    final app = await startDesktopApp(tester, server);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final shell = app.container.read(desktopShellProvider);

    // Expanded: the sidebar shows.
    await pumpUntil(
      tester,
      () => find.byKey(AdaptiveShell.sidebarKey).evaluate().isNotEmpty,
      reason: 'the expanded shell shows its sidebar',
    );
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(size.width, greaterThanOrEqualTo(1024));

    // The four destinations.
    final router = app.container.read(routerProvider);
    for (final (label, path) in [
      (l10n.navSearch, RoutePaths.search),
      (l10n.navLibrary, RoutePaths.library),
      (l10n.navPodcasts, RoutePaths.podcasts),
      (l10n.navHome, RoutePaths.home),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byKey(AdaptiveShell.sidebarKey),
          matching: find.text(label),
        ),
      );
      await pumpUntil(
        tester,
        () => router.state.uri.path.startsWith(path),
        reason: 'the $label destination opens $path',
      );
    }

    // The minimum size.
    await tester.runAsync(
      () => shell.setBounds(
        const WindowBounds(left: 40, top: 40, width: 300, height: 300),
      ),
    );
    await _settleWindow(tester);
    final small = (await tester.runAsync(shell.getBounds))!;
    expect(small.width, greaterThanOrEqualTo(480));
    expect(small.height, greaterThanOrEqualTo(600));

    // Bounds saved by this launch are restored by the next start.
    const wanted = WindowBounds(left: 60, top: 50, width: 900, height: 700);
    await tester.runAsync(() => shell.setBounds(wanted));
    await _settleWindow(tester);
    // As on quitting: the app's controller saves the bounds and stops.
    final running = app.container.read(windowStateControllerProvider);
    await tester.runAsync(running.save);
    running.dispose();
    final settings = AppSettingsStore(app.container.read(appDatabaseProvider));
    final saved = (await tester.runAsync(
      () => settings.read(AppSettingKeys.windowBounds),
    ))!;
    // The frame size the window system applied, decorations included.
    expect(saved.width, greaterThan(800));
    expect(saved.height, greaterThan(650));

    await tester.runAsync(
      () => shell.setBounds(
        const WindowBounds(left: 200, top: 150, width: 640, height: 640),
      ),
    );
    await _settleWindow(tester);
    final next = WindowStateController(
      shell: shell,
      settings: settings,
      isDesktop: true,
    );
    addTearDown(next.dispose);
    await tester.runAsync(next.start);
    await _settleWindow(tester);
    final restored = (await tester.runAsync(shell.getBounds))!;
    expect(restored.width, closeTo(saved.width, 2));
    expect(restored.height, closeTo(saved.height, 2));
  });
}

/// Lets the window system apply a geometry request.
Future<void> _settleWindow(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 750)),
  );
  await tester.pump();
}
