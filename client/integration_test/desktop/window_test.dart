// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Window state on a real desktop window (doc 11, Integration (desktop)).
// Run by the client-desktop-linux job under Xvfb with a window manager:
//
//   flutter test integration_test/desktop/window_test.dart -d linux

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/window_state_controller.dart';
import 'package:soundspan/app/theme/theme.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final shell = createDesktopShell();
  late AppDatabase db;
  late AppSettingsStore settings;
  final controllers = <WindowStateController>[];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = AppSettingsStore(db);
  });

  tearDown(() async {
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    await db.close();
  });

  WindowStateController newController() {
    final controller = WindowStateController(
      shell: shell,
      settings: settings,
      isDesktop: true,
    );
    controllers.add(controller);
    return controller;
  }

  /// Lets the window system apply a geometry request.
  Future<void> settleWindow(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 750)),
    );
    await tester.pump();
  }

  testWidgets(
    'the window never becomes smaller than 480 × 600 when asked to resize '
    'to 300 × 300',
    (tester) async {
      await tester.runAsync(() => newController().start());
      await tester.runAsync(
        () => shell.setBounds(
          const WindowBounds(left: 40, top: 40, width: 300, height: 300),
        ),
      );
      await settleWindow(tester);

      final bounds = (await tester.runAsync(shell.getBounds))!;
      expect(bounds.width, greaterThanOrEqualTo(480));
      expect(bounds.height, greaterThanOrEqualTo(600));
    },
  );

  testWidgets(
    'bounds set through the controller are persisted and applied by a new '
    'controller instance',
    (tester) async {
      const wanted = WindowBounds(left: 60, top: 50, width: 820, height: 640);
      final first = newController();
      await tester.runAsync(first.start);
      await tester.runAsync(() => shell.setBounds(wanted));
      await settleWindow(tester);
      await tester.runAsync(first.save);
      first.dispose();
      final saved = (await tester.runAsync(
        () => settings.read(AppSettingKeys.windowBounds),
      ))!;
      expect(saved.width, closeTo(wanted.width, 2));
      expect(saved.height, closeTo(wanted.height, 2));

      await tester.runAsync(
        () => shell.setBounds(
          const WindowBounds(left: 200, top: 150, width: 600, height: 700),
        ),
      );
      await settleWindow(tester);
      await tester.runAsync(newController().start);
      await settleWindow(tester);

      final restored = (await tester.runAsync(shell.getBounds))!;
      expect(restored.width, closeTo(saved.width, 2));
      expect(restored.height, closeTo(saved.height, 2));
      expect(restored.left, closeTo(saved.left, 64));
      expect(restored.top, closeTo(saved.top, 64));
    },
  );

  testWidgets('the shell renders its navigation at the restored size', (
    tester,
  ) async {
    await tester.runAsync(
      () => settings.write(
        AppSettingKeys.windowBounds,
        const WindowBounds(left: 0, top: 0, width: 1200, height: 800),
      ),
    );
    await tester.runAsync(newController().start);
    await settleWindow(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: SoundspanTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdaptiveShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          child: const SizedBox.expand(),
        ),
      ),
    );
    await settleWindow(tester);

    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(size.width, greaterThanOrEqualTo(1024));
    expect(find.byKey(AdaptiveShell.sidebarKey), findsOneWidget);
  });
}
