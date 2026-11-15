// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/player_slots.dart';
import 'package:soundspan/app/shell/sidebar_playlists.dart';
import 'package:soundspan/app/shell/top_bar.dart';

/// The [AdaptiveShell] with its slots filled: the [TopBar] on expanded
/// windows, the [AvatarButton] at the bottom of the rail on medium ones,
/// the [SidebarPlaylists] under the expanded sidebar's destinations, and the
/// player slots.
///
/// On compact windows the avatar sits in each branch root's app bar, which
/// the branch screens build.
class AppShell extends StatelessWidget {
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

  /// The selected destination's content.
  final Widget child;

  @override
  Widget build(BuildContext context) => AdaptiveShell(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    topBar: TopBar(
      onBack: onBack,
      onForward: onForward,
      onSearch: onSearch,
      onSearchChanged: onSearchChanged,
      avatar: const AvatarButton(),
    ),
    railTrailing: const AvatarButton(),
    miniPlayer: const MiniPlayerSlot(),
    playerBar: const PlayerBarSlot(),
    sidebarPlaylists: SidebarPlaylists(selectedPlaylistId: openPlaylistId),
    onExplore: onExplore,
    child: child,
  );
}
