// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// A soundspan:// link given to a second launch reaches the running app
// (doc 10, Deep Links Summary). Run by the client-desktop-linux job under
// Xvfb with a window manager and a D-Bus session bus:
//
//   flutter test integration_test/desktop/deep_link_test.dart -d linux

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/deep_link_router.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/platform/clock/system_clock.dart';
import 'package:soundspan/platform/deep_links/deep_links.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

class _ActiveProfile implements DeepLinkProfiles {
  @override
  bool get hasActive => true;

  @override
  Future<String?> idForBaseUrl(List<Uri> candidates) async => null;

  @override
  Future<void> switchTo(String profileId) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a second launch with soundspan://album/test-id exits and the '
      'first instance opens /album/test-id', (tester) async {
    final shell = createDesktopShell();
    await tester.runAsync(shell.init);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Text('home')),
        for (final kind in DetailKind.values)
          GoRoute(
            path: '/${kind.name}/:id',
            builder: (_, state) =>
                Text('${kind.name} ${state.pathParameters['id']}'),
          ),
      ],
    );
    addTearDown(router.dispose);
    final deepLinks = DeepLinkRouter(
      router: router,
      profiles: _ActiveProfile(),
      clock: const SystemClock(),
    );
    addTearDown(deepLinks.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.runAsync(
      () => deepLinks.listen(
        createDeepLinks(launchArguments: const [], desktopShell: shell),
      ),
    );

    final second = (await tester.runAsync(
      () => Process.run(Platform.resolvedExecutable, [
        'soundspan://album/test-id',
      ]).timeout(const Duration(seconds: 10)),
    ))!;
    expect(second.exitCode, 0, reason: '${second.stdout}${second.stderr}');

    String location() =>
        router.routerDelegate.currentConfiguration.uri.toString();
    for (var i = 0; i < 50 && location() != '/album/test-id'; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(location(), '/album/test-id');
    await tester.pumpAndSettle();
    expect(find.text('album test-id'), findsOneWidget);
  });
}
