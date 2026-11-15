// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/window_class.dart';

/// Sets the window or tab title to `<screen> · soundspan` while its route is
/// the visible one.
///
/// A route that is covered by another in its navigator, or that sits in a
/// shell branch that is not selected, leaves the title alone. The widget
/// tree below keeps its shape either way, so the state of [child] survives a
/// dialog, sheet or popup opening over the route.
class RouteTitle extends StatefulWidget {
  /// Titles the window with [screen] around [child].
  const new({required this.screen, required this.child, super.key});

  /// The localized screen name.
  final String screen;

  /// The route's content.
  final Widget child;

  @override
  State<RouteTitle> createState() => _RouteTitleState();
}

class _RouteTitleState extends State<RouteTitle> {
  /// The description this route last applied while visible, or null while
  /// it is hidden, so the title is set again when it becomes visible.
  ApplicationSwitcherDescription? _applied;

  @override
  Widget build(BuildContext context) {
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (!visible) {
      _applied = null;
      return widget.child;
    }
    final description = ApplicationSwitcherDescription(
      label: AppLocalizations.of(context).windowTitle(widget.screen),
      primaryColor: Theme.of(context).colorScheme.surface.toARGB32(),
    );
    if (_applied?.label != description.label ||
        _applied?.primaryColor != description.primaryColor) {
      _applied = description;
      unawaited(SystemChrome.setApplicationSwitcherDescription(description));
    }
    return widget.child;
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
