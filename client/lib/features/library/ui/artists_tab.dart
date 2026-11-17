// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/two_pane.dart';
import 'package:soundspan/features/library/ui/library_controls.dart';
import 'package:soundspan/features/library/ui/library_queries.dart';
import 'package:soundspan/features/library/ui/paged_media_grid.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

/// The localized name of an artists order.
String artistSortLabel(AppLocalizations l10n, ArtistSort sort) =>
    switch (sort) {
      ArtistSort.name => l10n.librarySortNameAsc,
      ArtistSort.nameDesc => l10n.librarySortNameDesc,
      ArtistSort.tracks => l10n.librarySortMostTracks,
    };

/// The Artists tab: the library's artists as a paged grid of round cards
/// that open the artist (doc 09, Library).
class ArtistsTab extends ConsumerWidget {
  /// Creates the tab.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(artistQueryProvider);
    final notifier = ref.read(artistQueryProvider.notifier);
    return PagedMediaGrid<Artist>(
      sourceKey: query,
      open: (repository) => repository.artists(query),
      emptyIcon: Icons.person_outline_rounded,
      emptyMessage: l10n.libraryArtistsEmpty,
      controls: [
        LibrarySortMenu<ArtistSort>(
          values: ArtistSort.values,
          selected: query.sortBy,
          label: artistSortLabel,
          onSelected: (sort) => notifier.query = query.copyWith(sortBy: sort),
        ),
        LibraryOriginChips(
          selected: query.origin,
          onSelected: (origin) =>
              notifier.query = query.copyWith(origin: origin),
        ),
      ],
      bubbleTitle: query.sortBy == ArtistSort.tracks
          ? null
          : (artist) => artist.name,
      itemBuilder: (context, artist) => MediaCard(
        selected: TwoPaneSelection.isSelected(
          context,
          DetailKind.artist.name,
          artist.id,
        ),
        title: artist.name,
        subtitle: l10n.libraryArtistCardSubtitle,
        artworkRef: artist.artworkRef,
        shape: ArtworkShape.circle,
        onTap: () => DetailNavigation.openArtist(context, artist.id),
      ),
    );
  }
}
