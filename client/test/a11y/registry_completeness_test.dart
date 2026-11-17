// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/guidelines.dart';
import '../helpers/pump_app.dart';
import 'screen_registry.dart';

ScreenCase _case(String? routePath) => ScreenCase(
  name: routePath ?? 'sheet',
  routePath: routePath,
  pump: (_, _) async {},
);

Widget _screen(BuildContext context, GoRouterState state) =>
    const SizedBox.shrink();

/// An unlabelled 20 x 20 button: it fails the tap-target size and the
/// tap-target label guidelines.
Widget _smallUnlabelledButton() => Center(
  child: Semantics(
    button: true,
    child: GestureDetector(
      onTap: () {},
      child: const SizedBox.square(dimension: 20),
    ),
  ),
);

void main() {
  final routes = <RouteBase>[
    GoRoute(path: '/', redirect: (_, _) => '/home'),
    GoRoute(
      path: '/home',
      builder: _screen,
      routes: [GoRoute(path: 'album/:albumId', builder: _screen)],
    ),
    ShellRoute(
      builder: (_, _, child) => child,
      routes: [GoRoute(path: '/settings', builder: _screen)],
    ),
  ];

  test('the patterns are the routes that show a screen, joined to their '
      'parents', () {
    expect(screenRoutePatterns(routes), [
      '/home',
      '/home/album/:albumId',
      '/settings',
    ]);
  });

  test('a router whose every screen route has a case is complete', () {
    expect(
      uncoveredRoutePatterns(routes, [
        _case('/home'),
        _case('/home/album/:albumId'),
        _case('/settings'),
        _case(null),
      ]),
      isEmpty,
    );
  });

  test('one extra route without a case fails the completeness check', () {
    final withExtra = [...routes, GoRoute(path: '/extra', builder: _screen)];
    expect(
      uncoveredRoutePatterns(withExtra, [
        _case('/home'),
        _case('/home/album/:albumId'),
        _case('/settings'),
      ]),
      ['/extra'],
    );
  });

  testWidgets('an exemption skips only its named guideline', (tester) async {
    final exempt = ScreenCase(
      name: 'exempt',
      exemption: 'a platform view draws its own unlabelled control',
      exemptGuideline: labeledTapTargetGuideline,
      pump: (tester, options) => tester.pumpApp(_smallUnlabelledButton()),
    );
    await exempt.pump(
      tester,
      const PumpOptions(size: TestSizes.compact, theme: ThemeMode.dark),
    );

    final reasons = (await failedGuidelines(
      tester,
      skip: {exempt.exemptGuideline!},
    )).map((evaluation) => evaluation.reason).join();
    expect(reasons, contains('expected tap target size of at least'));
    expect(reasons, isNot(contains('label')));

    final unexempted = await failedGuidelines(tester);
    expect(unexempted, hasLength(2));
  });
}
