// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/two_pane.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/features/library/ui/albums_tab.dart';
import 'package:soundspan/features/library/ui/artists_tab.dart';
import 'package:soundspan/features/library/ui/playlists_tab.dart';
import 'package:soundspan/features/library/ui/songs_tab.dart';
import 'package:soundspan/shared/widgets/offline_banner.dart';

/// The localized name of [tab].
String libraryTabLabel(AppLocalizations l10n, LibraryTab tab) => switch (tab) {
  LibraryTab.playlists => l10n.libraryTabPlaylists,
  LibraryTab.artists => l10n.libraryTabArtists,
  LibraryTab.albums => l10n.libraryTabAlbums,
  LibraryTab.songs => l10n.libraryTabSongs,
};

/// The Library destination (doc 09, Library): the offline notice, then
/// tabs Playlists, Artists, Albums and Songs over the selected tab's list.
///
/// The selected tab is [tab], the route's parameter; selecting another tab
/// goes to its location. Each tab is built when first shown and keeps its
/// state, scroll position included, while the screen is alive.
///
/// In a two-pane window the Playlists, Artists and Albums tabs are a
/// [TwoPaneList]: the screen takes the list pane and the item whose detail
/// is open, [selected], is highlighted.
class LibraryScreen extends StatefulWidget {
  /// Creates the screen showing [tab].
  const new({required this.tab, this.selected = const [], super.key});

  /// The selected tab.
  final LibraryTab tab;

  /// The location segments of the open detail after the tab, such as
  /// `['album', '42']`; empty when none is open.
  final List<String> selected;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: LibraryTab.values.length,
    initialIndex: widget.tab.index,
    vsync: this,
  );
  late final Set<LibraryTab> _built = {widget.tab};

  @override
  void didUpdateWidget(LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != oldWidget.tab) {
      _built.add(widget.tab);
      _tabs.index = widget.tab.index;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _select(int index) {
    final tab = LibraryTab.values[index];
    if (tab == widget.tab) return;
    GoRouter.of(context).go('${RoutePaths.library}/${tab.name}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = WindowClass.of(context) == WindowClass.compact;
    return RouteTitle(
      screen: l10n.navLibrary,
      child: TwoPaneList(
        enabled: widget.tab != LibraryTab.songs,
        selected: widget.selected,
        list: Scaffold(
          appBar: AppBar(
            title: compact ? Text(l10n.navLibrary) : null,
            toolbarHeight: compact ? kToolbarHeight : 0,
            actions: compact ? const [AvatarButton()] : null,
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              onTap: _select,
              tabs: [
                for (final tab in LibraryTab.values)
                  Tab(text: libraryTabLabel(l10n, tab)),
              ],
            ),
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: IndexedStack(
                  index: widget.tab.index,
                  children: [
                    for (final tab in LibraryTab.values)
                      if (!_built.contains(tab))
                        const SizedBox.shrink()
                      else
                        switch (tab) {
                          LibraryTab.playlists => const PlaylistsTab(),
                          LibraryTab.artists => const ArtistsTab(),
                          LibraryTab.albums => const AlbumsTab(),
                          LibraryTab.songs => const SongsTab(),
                        },
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
