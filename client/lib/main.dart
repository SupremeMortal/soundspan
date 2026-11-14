// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/theme.dart';

void main() {
  runApp(const SoundspanApp());
}

/// The soundspan application.
class SoundspanApp extends StatelessWidget {
  /// Creates the application.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: SoundspanTheme.light,
      darkTheme: SoundspanTheme.dark,
      highContrastTheme: SoundspanTheme.lightHighContrast,
      highContrastDarkTheme: SoundspanTheme.darkHighContrast,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: Text(AppLocalizations.of(context).appTitle)),
        ),
      ),
    );
  }
}
