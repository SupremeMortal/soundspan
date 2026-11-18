// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Where the refresh shortcut (F5, Ctrl+Shift+R) finds the screen to
/// refresh (doc 09, Desktop Interaction): every [RefreshTarget] below
/// registers with it.
class RefreshRegistry {
  final List<_RefreshTargetState> _targets = [];

  /// Whether a target on screen can refresh.
  bool get canRefresh => _shown() != null;

  /// Refreshes the target on screen; false when there is none.
  bool refresh() {
    final target = _shown();
    if (target == null) return false;
    target.widget.onRefresh();
    return true;
  }

  // The last registered target whose route is current and whose branch is
  // not hidden by the shell's indexed stack.
  _RefreshTargetState? _shown() {
    for (final target in _targets.reversed) {
      if (!target.mounted) continue;
      final context = target.context;
      if (!TickerMode.valuesOf(context).enabled) continue;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) continue;
      return target;
    }
    return null;
  }
}

/// Provides a [RefreshRegistry] to the [RefreshTarget]s below.
class RefreshRegistryScope extends InheritedWidget {
  /// Provides [registry] to [child].
  const new({required this.registry, required super.child, super.key});

  /// The registry.
  final RefreshRegistry registry;

  @override
  bool updateShouldNotify(RefreshRegistryScope oldWidget) =>
      registry != oldWidget.registry;
}

/// Marks a screen that the refresh shortcut refreshes by calling
/// [onRefresh], the same refresh as its pull to refresh.
class RefreshTarget extends StatefulWidget {
  /// Registers [onRefresh] while [child] is shown.
  const new({required this.onRefresh, required this.child, super.key});

  /// Refreshes the screen, by invalidating its view model.
  final VoidCallback onRefresh;

  /// The screen.
  final Widget child;

  @override
  State<RefreshTarget> createState() => _RefreshTargetState();
}

class _RefreshTargetState extends State<RefreshTarget> {
  RefreshRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = context
        .dependOnInheritedWidgetOfExactType<RefreshRegistryScope>()
        ?.registry;
    if (registry == _registry) return;
    _registry?._targets.remove(this);
    _registry = registry?.._targets.add(this);
  }

  @override
  void dispose() {
    _registry?._targets.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A [RefreshIndicator] that the refresh shortcut triggers too: pull to
/// refresh on touch, F5 or Ctrl+Shift+R on desktop (doc 09, Home).
class AppRefreshIndicator extends StatelessWidget {
  /// Refreshes [child] with [onRefresh].
  const new({required this.onRefresh, required this.child, super.key});

  /// Refreshes the screen; the indicator shows until it completes.
  final RefreshCallback onRefresh;

  /// The scrollable screen content.
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshTarget(
    onRefresh: () => unawaited(onRefresh()),
    child: RefreshIndicator(onRefresh: onRefresh, child: child),
  );
}
