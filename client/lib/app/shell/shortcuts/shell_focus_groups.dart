// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';

/// The focus groups of the shell (doc 09, Accessibility). F6 moves focus to
/// the next group that is on screen and has something focusable, Shift+F6
/// to the previous one, wrapping. The order follows the window class: top
/// bar, sidebar, content, right panel, player bar on expanded windows; rail,
/// content, mini player on medium ones; content, mini player, navigation
/// bar on compact ones.
class ShellFocusGroups {
  /// The window class the shell lays out for, which sets the order of
  /// [groups]; the shell keeps it current.
  WindowClass windowClass = WindowClass.expanded;

  /// The top bar group.
  final FocusNode topBar = _groupNode('shell.focus.topBar');

  /// The navigation group: the sidebar, the rail or the navigation bar.
  final FocusNode navigation = _groupNode('shell.focus.navigation');

  /// The content group.
  final FocusNode content = _groupNode('shell.focus.content');

  /// The right panel group.
  final FocusNode rightPanel = _groupNode('shell.focus.rightPanel');

  /// The player bar or mini player group.
  final FocusNode player = _groupNode('shell.focus.player');

  /// The groups in F6 order for [windowClass].
  List<FocusNode> get groups => switch (windowClass) {
    WindowClass.compact => [content, player, navigation],
    WindowClass.medium ||
    WindowClass.expanded => [topBar, navigation, content, rightPanel, player],
  };

  static FocusNode _groupNode(String label) =>
      FocusNode(debugLabel: label, skipTraversal: true, canRequestFocus: false);

  /// Moves focus to the first focusable of the next group on screen after
  /// the one holding focus, or of the previous one when [backward]; false
  /// when no group has a focusable.
  bool cycle({bool backward = false}) {
    final groups = this.groups;
    final focused = FocusManager.instance.primaryFocus;
    final current = focused == null
        ? -1
        : groups.indexWhere(
            (group) => group == focused || focused.ancestors.contains(group),
          );
    for (var step = 1; step <= groups.length; step++) {
      final int index;
      if (current < 0) {
        index = backward ? groups.length - step : step - 1;
      } else {
        index = (current + (backward ? -step : step)) % groups.length;
      }
      final target = _firstFocusable(groups[index]);
      if (target != null) {
        target.requestFocus();
        return true;
      }
    }
    return false;
  }

  /// The focusable of [group] that comes first in reading order, or null
  /// when the group is not on screen or has none.
  static FocusNode? _firstFocusable(FocusNode group) {
    final context = group.context;
    if (context == null || !context.mounted) return null;
    final candidates = [
      for (final node in group.traversalDescendants)
        // A branch the shell's indexed stack hides has its tickers off.
        if (node.context case final nodeContext?
            when nodeContext.mounted &&
                TickerMode.valuesOf(nodeContext).enabled)
          node,
    ];
    if (candidates.isEmpty) return null;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    candidates.sort((a, b) {
      final ra = a.rect;
      final rb = b.rect;
      final byTop = ra.top.round().compareTo(rb.top.round());
      if (byTop != 0) return byTop;
      return rtl ? rb.right.compareTo(ra.right) : ra.left.compareTo(rb.left);
    });
    return candidates.first;
  }

  /// Releases the nodes.
  void dispose() {
    for (final group in [topBar, navigation, content, rightPanel, player]) {
      group.dispose();
    }
  }
}

/// Puts [child] in the focus [group] of the shell, as its own traversal
/// group.
class ShellFocusGroup extends StatelessWidget {
  /// Puts [child] in [group]; a null [group] adds only the traversal group.
  const new({required this.group, required this.child, super.key});

  /// The group's node, from [ShellFocusGroups].
  final FocusNode? group;

  /// The group's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final group = this.group;
    final traversal = FocusTraversalGroup(child: child);
    if (group == null) return traversal;
    return Focus(
      focusNode: group,
      skipTraversal: true,
      canRequestFocus: false,
      child: traversal,
    );
  }
}
