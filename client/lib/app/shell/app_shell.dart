// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/player_slots.dart';
import 'package:soundspan/app/shell/shortcuts/search_focus.dart';
import 'package:soundspan/app/shell/shortcuts/shell_focus_groups.dart';
import 'package:soundspan/app/shell/shortcuts/shell_shortcuts.dart';
import 'package:soundspan/app/shell/sidebar_playlists.dart';
import 'package:soundspan/app/shell/top_bar.dart';
import 'package:soundspan/app/shell/update_banner.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/shell/window_controls.dart';
import 'package:soundspan/app/shell/window_title_bar.dart';
import 'package:soundspan/features/listen_together/listen_together.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/features/social/social.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

/// The [AdaptiveShell] with its slots filled: the [TopBar] on expanded
/// windows, the [AvatarButton] at the bottom of the rail on medium ones,
/// the [SidebarPlaylists] under the expanded sidebar's destinations, the
/// player slots, the [QueuePanel], [LyricsPanel] or [ActivityPanel] in the
/// right panel as [rightPanelProvider] says, and the [NowPlayingOverlay]
/// over the content while [nowPlayingOverlayProvider] is set. The
/// [UpdateBanner] sits at the top of the content on every window class.
///
/// On compact windows the avatar sits in each branch root's app bar, which
/// the branch screens build.
///
/// The [ShellShortcuts] wrap it on desktop and the web, with focus groups
/// for F6.
class AppShell extends ConsumerStatefulWidget {
  /// Creates the shell around [child].
  const new({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onSearch,
    required this.child,
    this.onSearchChanged,
    this.onBack,
    this.onForward,
    this.openPlaylistId,
    this.onExplore,
    this.onVibe,
    this.onListenTogether,
    super.key,
  });

  /// The index of the selected [ShellDestination].
  final int selectedIndex;

  /// Called with the index of the tapped destination.
  final ValueChanged<int> onDestinationSelected;

  /// Called with the query submitted in the top bar.
  final ValueChanged<String> onSearch;

  /// Called with the top bar's text as it is typed, after a pause, while
  /// the Search destination is selected; null otherwise.
  final ValueChanged<String>? onSearchChanged;

  /// Goes back in the current branch; null disables Back.
  final VoidCallback? onBack;

  /// Re-opens the location last left with Back; null disables Forward.
  final VoidCallback? onForward;

  /// The id of the playlist the window shows, marked in the sidebar; null
  /// when none is open.
  final String? openPlaylistId;

  /// Opens Explore; null leaves the sidebar item out.
  final VoidCallback? onExplore;

  /// Opens Vibe; null leaves the sidebar item out.
  final VoidCallback? onVibe;

  /// Opens Listen Together; null leaves the sidebar item out.
  final VoidCallback? onListenTogether;

  /// The selected destination's content.
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final ShellFocusGroups _focusGroups = ShellFocusGroups();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'shell.search');

  @override
  void dispose() {
    _focusGroups.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _focusSearch() {
    if (windowClassOf(MediaQuery.sizeOf(context)) == WindowClass.expanded) {
      _searchFocus.requestFocus();
      return;
    }
    ref.read(searchFocusRequestProvider.notifier).request();
    if (widget.selectedIndex != ShellDestination.search.index) {
      widget.onDestinationSelected(ShellDestination.search.index);
    }
  }

  /// The top bar, which is also the window's title bar when the app draws
  /// its own: the window buttons at its ends, and on macOS room for the
  /// traffic lights.
  Widget _topBar(BuildContext context) {
    final chrome = watchWindowChrome(ref);
    final layout = chrome.shownLayout;
    WindowControls? controls(
      List<WindowButton> buttons,
      WindowControlsSide side,
    ) => buttons.isEmpty
        ? null
        : WindowControls(
            buttons: buttons,
            state: chrome.state,
            side: side,
            height: TopBar.titleBarHeight,
          );
    final bar = TopBar(
      onBack: widget.onBack,
      onForward: widget.onForward,
      onSearch: widget.onSearch,
      onSearchChanged: widget.onSearchChanged,
      searchFocusNode: _searchFocus,
      avatar: const AvatarButton(),
      activityOpen: ref.watch(rightPanelProvider) == RightPanel.activity,
      onToggleActivity: () =>
          ref.read(rightPanelProvider.notifier).toggle(RightPanel.activity),
      titleBarMode: chrome.integrated,
      leadingControls: controls(layout.leading, WindowControlsSide.leading),
      trailingControls: controls(layout.trailing, WindowControlsSide.trailing),
      leadingInset:
          chrome.integrated && defaultTargetPlatform == TargetPlatform.macOS
          ? macOSTrafficLightsInset
          : 0,
    );
    return chrome.integrated ? WindowTitleBarClaim(child: bar) : bar;
  }

  @override
  Widget build(BuildContext context) => ShellShortcuts(
    focusGroups: _focusGroups,
    onDestinationSelected: widget.onDestinationSelected,
    onFocusSearch: _focusSearch,
    onOpenSettings: () =>
        unawaited(GoRouter.of(context).push<void>(RoutePaths.settings)),
    onBack: widget.onBack,
    onForward: widget.onForward,
    child: AdaptiveShell(
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      focusGroups: _focusGroups,
      topBar: _topBar(context),
      railTrailing: const AvatarButton(),
      miniPlayer: const MiniPlayerSlot(),
      playerBar: const PlayerBarSlot(),
      sidebarPlaylists: SidebarPlaylists(
        selectedPlaylistId: widget.openPlaylistId,
      ),
      onExplore: widget.onExplore,
      onVibe: widget.onVibe,
      onListenTogether: widget.onListenTogether,
      inListenTogetherGroup: ref.watch(inListenTogetherGroupProvider),
      rightPanel: switch (ref.watch(rightPanelProvider)) {
        RightPanel.queue => const QueuePanel(),
        RightPanel.lyrics => const LyricsPanel(),
        RightPanel.activity => const ActivityPanel(),
        RightPanel.none => null,
      },
      contentOverlay: ref.watch(nowPlayingOverlayProvider)
          ? const NowPlayingOverlay()
          : null,
      child: Column(
        children: [
          const UpdateBanner(),
          Expanded(child: widget.child),
        ],
      ),
    ),
  );
}
