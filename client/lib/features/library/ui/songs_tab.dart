// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/features/library/ui/library_controls.dart';
import 'package:soundspan/features/library/ui/library_queries.dart';
import 'package:soundspan/features/library/ui/paged_library_view.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// The localized name of a tracks order.
String trackSortLabel(AppLocalizations l10n, TrackSort sort) => switch (sort) {
  TrackSort.name => l10n.librarySortNameAsc,
  TrackSort.nameDesc => l10n.librarySortNameDesc,
};

/// The Songs tab: every track of the library as a paged list of
/// [TrackRow]s of one fixed height, so the scroll extent is the same
/// before and after any page loads (doc 09, Library).
///
/// Unloaded indexes are [TrackRowSkeleton]s. Rows do nothing on tap; a
/// track without a playback id is disabled as not playable.
class SongsTab extends ConsumerWidget {
  /// Creates the tab.
  const new({super.key});

  /// The space after the last row.
  static const double bottomPadding = Spacing.x32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(trackQueryProvider);
    final notifier = ref.read(trackQueryProvider.notifier);
    return PagedLibraryView<Track>(
      sourceKey: query,
      open: (repository) => repository.tracks(query),
      emptyIcon: Icons.music_note_outlined,
      emptyMessage: l10n.librarySongsEmpty,
      controls: [
        LibrarySortMenu<TrackSort>(
          values: TrackSort.values,
          selected: query.sortBy,
          label: trackSortLabel,
          onSelected: (sort) => notifier.query = query.copyWith(sortBy: sort),
        ),
        LibraryOriginChips(
          selected: query.origin,
          onSelected: (origin) =>
              notifier.query = query.copyWith(origin: origin),
        ),
      ],
      itemsBuilder: _rows,
    );
  }

  Widget _rows(
    BuildContext context,
    SliverConstraints constraints,
    PagedSnapshot<Track>? snapshot,
    void Function(int first, int last) ensureVisible,
  ) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final gutter = gutterOf(windowClass);
    final extent = TrackRow.extentFor(context, withThumbnail: true);
    final screenRows = (constraints.viewportMainAxisExtent / extent).ceil();
    final total = snapshot?.total ?? screenRows;

    final first = math.min(
      (constraints.scrollOffset / extent).floor(),
      math.max(0, total - 1),
    );
    final last = math.max(
      first,
      math.min(
            ((constraints.scrollOffset + constraints.remainingPaintExtent) /
                    extent)
                .ceil(),
            total,
          ) -
          1,
    );
    ensureVisible(first, last);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        gutter - Spacing.x8,
        0,
        gutter - Spacing.x8,
        bottomPadding,
      ),
      sliver: SliverFixedExtentList.builder(
        itemExtent: extent,
        itemCount: total,
        itemBuilder: (context, index) {
          final track = snapshot?.itemAt(index);
          if (track == null) {
            return const TrackRowSkeleton(withThumbnail: true);
          }
          return TrackRow(
            title: track.meta.title,
            artist: track.meta.artist,
            album: track.meta.album,
            showAlbumColumn: windowClass == WindowClass.expanded,
            duration: Duration(seconds: track.meta.durationSec),
            leading: TrackRowLeading.thumbnail(track.meta.artworkRef),
            enabled: track.playbackId != null,
            disabledReason: l10n.trackNotPlayable,
          );
        },
      ),
    );
  }
}
