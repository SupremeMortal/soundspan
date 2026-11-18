// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/two_pane.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/library/ui/library_controls.dart';
import 'package:soundspan/features/library/ui/library_queries.dart';
import 'package:soundspan/features/library/ui/paged_media_grid.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/dnd/drag_payload.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

/// The localized name of an albums order.
String albumSortLabel(AppLocalizations l10n, AlbumSort sort) => switch (sort) {
  AlbumSort.name => l10n.librarySortNameAsc,
  AlbumSort.nameDesc => l10n.librarySortNameDesc,
  AlbumSort.recent => l10n.librarySortYearNewest,
};

/// The Albums tab: the library's albums as a paged grid of square cards
/// that open the album, and play it from their play button (doc 09,
/// Library).
class AlbumsTab extends ConsumerWidget {
  /// Creates the tab.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(albumQueryProvider);
    final notifier = ref.read(albumQueryProvider.notifier);
    final downloadedOnly = ref.watch(showDownloadedOnlyProvider);
    return PagedMediaGrid<Album>(
      sourceKey: (query, downloadedOnly),
      open: (repository) => downloadedOnly
          ? downloadedSource<Album>(ref, DownloadedList.albums)
          : repository.albums(query),
      emptyIcon: Icons.album_outlined,
      emptyMessage: l10n.libraryAlbumsEmpty,
      controls: [
        LibrarySortMenu<AlbumSort>(
          values: AlbumSort.values,
          selected: query.sortBy,
          label: albumSortLabel,
          onSelected: (sort) => notifier.query = query.copyWith(sortBy: sort),
        ),
        LibraryOriginChips(
          selected: query.origin,
          onSelected: (origin) =>
              notifier.query = query.copyWith(origin: origin),
        ),
        const DownloadedOnlyChip(),
      ],
      bubbleTitle: query.sortBy == AlbumSort.recent
          ? null
          : (album) => album.title,
      itemBuilder: (context, album) => MediaCard(
        selected: TwoPaneSelection.isSelected(
          context,
          DetailKind.album.name,
          album.id,
        ),
        title: album.title,
        subtitle: album.artistName,
        artworkRef: album.artworkRef,
        onTap: () => DetailNavigation.openAlbum(context, album.id),
        dragPayload: AlbumPayload(album.id, album.title, album.trackCount),
        onPlay: () =>
            unawaited(ref.read(playActionsProvider).playAlbum(album.id)),
        onMenu: (position) =>
            unawaited(openAlbumMenu(context, ref, album, position: position)),
      ),
    );
  }
}
