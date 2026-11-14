// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/router/routes.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/test_root.dart';

void main() {
  const notice =
      'This browser is not keeping data, so nothing will be remembered '
      'after this page is closed.';

  testWidgets('shown once when volatile', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      opener: InMemoryDatabaseOpener()..isVolatile = true,
    );
    expect(find.text(notice), findsOneWidget);
    await expectMeetsGuidelines(tester);

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text(notice), findsNothing);

    root.container.read(routerProvider).go('/library/albums');
    await tester.pumpAndSettle();
    root.container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    expect(find.text(notice), findsNothing);
  });

  testWidgets('never shown otherwise', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    expect(find.text(notice), findsNothing);
    root.container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    expect(find.text(notice), findsNothing);
    await expectMeetsGuidelines(tester);
  });
}
