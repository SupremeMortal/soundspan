// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';

/// Sets the window or tab title to `<screen> · soundspan` while its route is
/// the visible one.
///
/// A route that is covered by another in its navigator, or that sits in a
/// shell branch that is not selected, leaves the title alone.
class RouteTitle extends StatelessWidget {
  /// Titles the window with [screen] around [child].
  const new({required this.screen, required this.child, super.key});

  /// The localized screen name.
  final String screen;

  /// The route's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (!visible) return child;
    return Title(
      title: AppLocalizations.of(context).windowTitle(screen),
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}

/// A screen that only shows its centred, localized name until the issue that
/// builds it lands.
class PlaceholderScreen extends StatelessWidget {
  /// Creates a placeholder titled [name].
  const new(this.name, {super.key});

  /// The localized screen name.
  final String name;

  @override
  Widget build(BuildContext context) => RouteTitle(
    screen: name,
    child: Scaffold(body: Center(child: Text(name))),
  );
}
