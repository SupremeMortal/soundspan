// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/shortcuts/shell_focus_groups.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The four top-level destinations, in navigation order.
enum ShellDestination {
  /// The home screen.
  home(Icons.home_outlined, Icons.home_rounded),

  /// The search screen.
  search(Icons.search_rounded, Icons.saved_search_rounded),

  /// The library.
  library(Icons.library_music_outlined, Icons.library_music_rounded),

  /// Podcasts.
  podcasts(Icons.podcasts_rounded, Icons.podcasts_rounded);

  new(this.icon, this.selectedIcon);

  /// The icon while not selected.
  final IconData icon;

  /// The icon while selected.
  final IconData selectedIcon;

  /// The localized label.
  String label(AppLocalizations l10n) => switch (this) {
    home => l10n.navHome,
    search => l10n.navSearch,
    library => l10n.navLibrary,
    podcasts => l10n.navPodcasts,
  };
}

/// The app shell: navigation chrome around the selected destination's
/// content, chosen by the [WindowClass] of the available space (doc 09,
/// Shell by Window Class).
///
/// Compact windows put the content above a bottom [NavigationBar], medium
/// windows put a [NavigationRail] beside it, and expanded windows put a
/// [sidebarWidth] sidebar beside it, the panels separated by
/// [Spacing.x8] of `ground`. The top bar is shown only on expanded windows,
/// the rail's trailing slot only on medium ones.
///
/// On expanded windows a [rightPanel] sits after the content, [rightPanelWidth]
/// wide, and a [contentOverlay] covers the content area. While the right
/// panel is open on a window narrower than [wideWidth] the sidebar collapses
/// to a [railWidth] rail of the destinations.
///
/// The navigation, the content (with its overlay), the right panel and the
/// player are each a focus traversal group, put in [focusGroups] when given
/// so F6 can move between them (doc 09, Accessibility).
class AdaptiveShell extends StatefulWidget {
  /// Creates the shell around [child].
  const new({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.topBar,
    this.railTrailing,
    this.miniPlayer,
    this.playerBar,
    this.sidebarPlaylists,
    this.onExplore,
    this.rightPanel,
    this.contentOverlay,
    this.focusGroups,
    super.key,
  });

  /// The width of the expanded sidebar.
  static const double sidebarWidth = 256;

  /// The key of the expanded sidebar.
  static const Key sidebarKey = Key('shell.sidebar');

  /// The width of the sidebar collapsed to a rail.
  static const double railWidth = 72;

  /// The width of the right panel.
  static const double rightPanelWidth = 360;

  /// The window width below which an open right panel collapses the
  /// sidebar.
  static const double wideWidth = 1200;

  /// The key of the right panel.
  static const Key rightPanelKey = Key('shell.rightPanel');

  /// The key of the content overlay.
  static const Key contentOverlayKey = Key('shell.contentOverlay');

  /// The key of [destination] in the compact navigation bar.
  static Key destinationKey(ShellDestination destination) =>
      ValueKey('shell.destination.${destination.name}');

  /// The index of the selected [ShellDestination].
  final int selectedIndex;

  /// Called with the index of the tapped destination, including the
  /// selected one.
  final ValueChanged<int> onDestinationSelected;

  /// The selected destination's content.
  final Widget child;

  /// The top bar slot (expanded).
  final Widget? topBar;

  /// The slot at the bottom of the navigation rail (medium).
  final Widget? railTrailing;

  /// The mini player slot (compact and medium).
  final Widget? miniPlayer;

  /// The player bar slot (expanded).
  final Widget? playerBar;

  /// The playlist list slot under the sidebar destinations (expanded).
  final Widget? sidebarPlaylists;

  /// Opens Explore from an "Explore" item below the sidebar destinations
  /// (expanded); null leaves the item out.
  final VoidCallback? onExplore;

  /// The right panel (expanded); null leaves it out.
  final Widget? rightPanel;

  /// What covers the content area (expanded); null leaves it uncovered.
  final Widget? contentOverlay;

  /// The focus groups the shell's areas join; null leaves them out.
  final ShellFocusGroups? focusGroups;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  // Keeps the content's state when a resize moves it to another layout.
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'shell.content');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = windowClassOf(constraints.biggest);
        final content = KeyedSubtree(key: _contentKey, child: widget.child);
        return WindowClassScope(
          windowClass: windowClass,
          child: switch (windowClass) {
            WindowClass.compact => _compact(context, content),
            WindowClass.medium => _medium(context, content),
            WindowClass.expanded => _expanded(
              context,
              content,
              collapsed:
                  widget.rightPanel != null &&
                  constraints.maxWidth < AdaptiveShell.wideWidth,
            ),
          },
        );
      },
    );
  }

  Widget _navigation(BuildContext context, Widget child) => Semantics(
    container: true,
    label: AppLocalizations.of(context).navMainLabel,
    child: ShellFocusGroup(group: widget.focusGroups?.navigation, child: child),
  );

  Widget _contentGroup(Widget content) =>
      ShellFocusGroup(group: widget.focusGroups?.content, child: content);

  Widget? _player(Widget? player) => player == null
      ? null
      : ShellFocusGroup(group: widget.focusGroups?.player, child: player);

  Widget _compact(BuildContext context, Widget content) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: _contentGroup(content)),
            ?_player(widget.miniPlayer),
          ],
        ),
      ),
      bottomNavigationBar: _navigation(
        context,
        NavigationBar(
          selectedIndex: widget.selectedIndex,
          onDestinationSelected: widget.onDestinationSelected,
          destinations: [
            for (final destination in ShellDestination.values)
              NavigationDestination(
                key: AdaptiveShell.destinationKey(destination),
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label(l10n),
                tooltip: destination.label(l10n),
              ),
          ],
        ),
      ),
    );
  }

  Widget _medium(BuildContext context, Widget content) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _navigation(
                    context,
                    NavigationRail(
                      selectedIndex: widget.selectedIndex,
                      onDestinationSelected: widget.onDestinationSelected,
                      labelType: NavigationRailLabelType.all,
                      trailing: widget.railTrailing == null
                          ? null
                          : Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Spacing.x16,
                                  ),
                                  child: widget.railTrailing,
                                ),
                              ),
                            ),
                      destinations: [
                        for (final destination in ShellDestination.values)
                          NavigationRailDestination(
                            icon: Tooltip(
                              message: destination.label(l10n),
                              excludeFromSemantics: true,
                              child: Icon(destination.icon),
                            ),
                            selectedIcon: Tooltip(
                              message: destination.label(l10n),
                              excludeFromSemantics: true,
                              child: Icon(destination.selectedIcon),
                            ),
                            label: Text(destination.label(l10n)),
                          ),
                      ],
                    ),
                  ),
                  Expanded(child: _contentGroup(content)),
                ],
              ),
            ),
            ?_player(widget.miniPlayer),
          ],
        ),
      ),
    );
  }

  Widget _expanded(
    BuildContext context,
    Widget content, {
    required bool collapsed,
  }) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    const panelRadius = BorderRadius.all(Radius.circular(Radii.large));
    final rightPanel = widget.rightPanel;
    final overlay = widget.contentOverlay;
    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        child: Column(
          children: [
            ?widget.topBar,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.x8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      key: AdaptiveShell.sidebarKey,
                      width: collapsed
                          ? AdaptiveShell.railWidth
                          : AdaptiveShell.sidebarWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceRaised,
                          borderRadius: panelRadius,
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _navigation(
                                context,
                                Padding(
                                  padding: const EdgeInsets.all(Spacing.x8),
                                  child: Column(
                                    children: [
                                      for (final (index, destination)
                                          in ShellDestination.values.indexed)
                                        _SidebarDestination(
                                          label: destination.label(l10n),
                                          icon: index == widget.selectedIndex
                                              ? destination.selectedIcon
                                              : destination.icon,
                                          selected:
                                              index == widget.selectedIndex,
                                          collapsed: collapsed,
                                          onTap: () => widget
                                              .onDestinationSelected(index),
                                        ),
                                      if (widget.onExplore
                                          case final onExplore?)
                                        _SidebarDestination(
                                          label: l10n.navExplore,
                                          icon: Icons.explore_outlined,
                                          selected: false,
                                          collapsed: collapsed,
                                          onTap: onExplore,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: collapsed
                                    ? const SizedBox.shrink()
                                    : widget.sidebarPlaylists ??
                                          const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.x8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: panelRadius,
                        child: _contentGroup(
                          Stack(
                            fit: StackFit.expand,
                            children: [
                              content,
                              if (overlay != null)
                                FocusTraversalGroup(
                                  key: AdaptiveShell.contentOverlayKey,
                                  child: overlay,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (rightPanel != null) ...[
                      const SizedBox(width: Spacing.x8),
                      SizedBox(
                        key: AdaptiveShell.rightPanelKey,
                        width: AdaptiveShell.rightPanelWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised,
                            borderRadius: panelRadius,
                          ),
                          child: ClipRRect(
                            borderRadius: panelRadius,
                            child: Material(
                              type: MaterialType.transparency,
                              child: ShellFocusGroup(
                                group: widget.focusGroups?.rightPanel,
                                child: rightPanel,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ?_player(widget.playerBar),
          ],
        ),
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.x4),
        child: IconButton(
          tooltip: label,
          isSelected: selected,
          onPressed: onTap,
          color: colors.contentSecondary,
          selectedIcon: Icon(icon, color: colors.content),
          style: IconButton.styleFrom(
            backgroundColor: selected ? colors.surfaceActive : null,
          ),
          icon: Icon(icon),
        ),
      );
    }
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: ListTile(
        selected: selected,
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
        minTileHeight: Sizes.touchTarget,
        iconColor: colors.contentSecondary,
        textColor: colors.contentSecondary,
        selectedColor: colors.content,
        selectedTileColor: colors.surfaceActive,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.small)),
        ),
      ),
    );
  }
}
