// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/main.dart';

void main() {
  testWidgets('shows the localized app title', (tester) async {
    await tester.pumpWidget(const SoundspanApp());
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(
      AppLocalizations.supportedLocales.first,
    );
    expect(l10n.appTitle, 'soundspan');
    expect(find.text(l10n.appTitle), findsOneWidget);
  });
}
