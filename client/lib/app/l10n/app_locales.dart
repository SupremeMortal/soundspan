// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/build_config.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';

/// The generated pseudo-locale (`en_XA`), a development aid for layout
/// checks with longer, accented text.
const Locale pseudoLocale = Locale('en', 'XA');

/// The release channel the app runs on, [BuildConfig.channel] unless
/// overridden.
final Provider<String> buildChannelProvider = Provider<String>(
  (ref) => BuildConfig.channel,
);

/// The locales the app offers on [channel]: every generated locale, with
/// [pseudoLocale] only on the `dev` channel.
List<Locale> appLocalesFor(String channel) => [
  for (final locale in AppLocalizations.supportedLocales)
    if (channel == 'dev' || locale != pseudoLocale) locale,
];

/// The locales the app offers on the current [buildChannelProvider]: the
/// `MaterialApp` supported locales and the Appearance language list.
final Provider<List<Locale>> appLocalesProvider = Provider<List<Locale>>(
  (ref) => appLocalesFor(ref.watch(buildChannelProvider)),
);

/// The app's localization delegates: the generated [AppLocalizations]
/// messages followed by `material_ui`'s Material, Cupertino and Widgets
/// localizations, whose `MaterialLocalizations` type is the one
/// `material_ui` widgets look up.
///
/// The generated `AppLocalizations.localizationsDelegates` holds the
/// `flutter_localizations` delegates instead, which `material_ui` widgets do
/// not find for a language other than English.
const List<LocalizationsDelegate<Object?>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
