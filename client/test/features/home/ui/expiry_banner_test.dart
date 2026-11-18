// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/auth/key_expiry_monitor.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/key_expiry_binding.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/features/home/ui/expiry_banner.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';

final _profile = Profile(
  id: 'p1',
  baseUrl: Uri.parse('https://music.example.com'),
  displayName: 'music.example.com',
  userId: 'user-1',
  username: 'ada',
  role: 'user',
  authKind: AuthKind.deviceLink,
  deviceId: 'd1',
  credentialCreatedAt: DateTime.utc(2026),
  credentialExpiresAt: DateTime.utc(2026, 4),
  state: ProfileState.active,
  lastUsedAt: DateTime.utc(2026),
);

void main() {
  Future<GoRouter> pump(WidgetTester tester, KeyExpiryState state) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: ExpiryBanner()),
        ),
        GoRoute(
          path: '/connect/sign-in',
          builder: (_, state) => Text(
            'sign-in ${state.uri.queryParameters['profile']} '
            'relink=${state.uri.queryParameters['relink']}',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpApp(
      Router.withConfig(config: router),
      overrides: <Override>[
        profileContextProvider.overrideWithValue(
          ProfileContext(profile: _profile),
        ),
        keyExpiryStateProvider.overrideWith((ref) => Stream.value(state)),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('says how many days are left', (tester) async {
    await pump(tester, const KeyExpiryState.expiring(5));

    expect(find.text('This device’s link expires in 5 days'), findsOneWidget);
    expect(find.text('Link again'), findsOneWidget);
    expect(find.byTooltip('Dismiss'), findsNothing);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('says today for the last day', (tester) async {
    await pump(tester, const KeyExpiryState.expiring(1));

    expect(find.text('This device’s link expires today'), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('says the link has expired', (tester) async {
    await pump(tester, KeyExpiryState.expired);

    expect(find.text('This device’s link has expired'), findsOneWidget);
    expect(find.text('Link again'), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('is absent with nothing to warn about', (tester) async {
    await pump(tester, KeyExpiryState.none);

    expect(find.textContaining('link'), findsNothing);
    expect(find.text('Link again'), findsNothing);
  });

  testWidgets('Link again opens the re-link flow of the profile', (
    tester,
  ) async {
    await pump(tester, const KeyExpiryState.expiring(3));

    await tester.tap(find.text('Link again'));
    await tester.pumpAndSettle();

    expect(find.text('sign-in p1 relink=1'), findsOneWidget);
  });
}
