// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/settings/settings.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/test_root.dart';

// Its own file: the theme's density follows the first platform a test
// isolate builds it for, and the other Desktop tests run on desktop ones.
void main() {
  testWidgets('Settings → Desktop meets the guidelines', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    root.container.read(routerProvider).go(SettingsSection.desktop.path);
    await tester.pumpAndSettle();

    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });
}
