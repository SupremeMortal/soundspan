// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/window_class.dart';

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
///
/// A [branchRoot] screen on a compact window has an app bar with the
/// [AvatarButton], as every branch root does there.
class PlaceholderScreen extends StatelessWidget {
  /// Creates a placeholder titled [name].
  const new(this.name, {this.branchRoot = false, super.key});

  /// The localized screen name.
  final String name;

  /// Whether the screen is the root of a shell branch.
  final bool branchRoot;

  @override
  Widget build(BuildContext context) {
    final compactRoot =
        branchRoot && WindowClass.of(context) == WindowClass.compact;
    return RouteTitle(
      screen: name,
      child: Scaffold(
        appBar: compactRoot
            ? AppBar(title: Text(name), actions: const [AvatarButton()])
            : null,
        body: Center(child: Text(name)),
      ),
    );
  }
}
