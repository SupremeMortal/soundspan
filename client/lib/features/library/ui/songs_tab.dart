// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/library/ui/library_controls.dart';
import 'package:soundspan/features/library/ui/library_queries.dart';
import 'package:soundspan/features/library/ui/paged_library_view.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/dnd/drag_payload.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
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
/// Unloaded indexes are [TrackRowSkeleton]s. Tapping a row plays the rows
/// loaded so far, in list order, from that row (context `library`); a
/// track without a playback id is disabled as not playable. "Shuffle all",
/// beside the sort and filter controls, plays the library in the server's
/// random order ([PlayActions.shuffleLibrary]). A long list has the
/// alphabetical fast-scroll thumb on touch input.
class SongsTab extends ConsumerWidget {
  /// Creates the tab.
  const new({super.key});

  /// The space after the last row.
  static const double bottomPadding = Spacing.x32;

  /// The key of the "Shuffle all" button.
  static const Key shuffleAllKey = ValueKey('SongsTab.shuffleAll');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(trackQueryProvider);
    final notifier = ref.read(trackQueryProvider.notifier);
    final downloadedOnly = ref.watch(showDownloadedOnlyProvider);
    return PagedLibraryView<Track>(
      sourceKey: (query, downloadedOnly),
      open: (repository) => downloadedOnly
          ? downloadedSource<Track>(ref, DownloadedList.tracks)
          : repository.tracks(query),
      emptyIcon: Icons.music_note_outlined,
      emptyMessage: l10n.librarySongsEmpty,
      controls: [
        TextButton.icon(
          key: shuffleAllKey,
          onPressed: () =>
              unawaited(ref.read(playActionsProvider).shuffleLibrary()),
          icon: const Icon(Icons.shuffle_rounded),
          label: Text(l10n.librarySongsShuffleAll),
        ),
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
        const DownloadedOnlyChip(),
      ],
      fastScroll: true,
      // Every order of the list is by name.
      bubbleTitle: (track) => track.meta.title,
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
          return Consumer(
            builder: (context, ref, _) => TrackRow(
              title: track.meta.title,
              artist: track.meta.artist,
              album: track.meta.album,
              showAlbumColumn: windowClass == WindowClass.expanded,
              duration: Duration(seconds: track.meta.durationSec),
              leading: TrackRowLeading.thumbnail(track.meta.artworkRef),
              enabled: track.playbackId != null,
              disabledReason: l10n.trackNotPlayable,
              liked: track.isLiked,
              onToggleLike: toggleLikeOf(ref, track),
              playbackId: track.playbackId,
              dragPayload: TracksPayload([track]),
              onTap: () => _play(ref, snapshot!, index),
              onAddToQueue: addToQueueOf(ref, track),
              onMenu: (position) => unawaited(
                openTrackMenu(
                  context,
                  ref,
                  _scope(snapshot!, index, track),
                  position: position,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The menu scope of row [index]: Play now plays the loaded rows in list
  /// order from it.
  TrackActionScope _scope(
    PagedSnapshot<Track> snapshot,
    int index,
    Track track,
  ) {
    final loaded = snapshot.loaded.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return TrackActionScope(
      track: track,
      tracks: [for (final entry in loaded) entry.value],
      index: loaded.indexWhere((entry) => entry.key == index),
      context: const QueueContext(kind: QueueContextKind.library),
    );
  }

  /// Plays the rows loaded so far, in list order, from row [index].
  void _play(WidgetRef ref, PagedSnapshot<Track> snapshot, int index) {
    final loaded = snapshot.loaded.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    unawaited(
      ref
          .read(playActionsProvider)
          .playTracks(
            [for (final entry in loaded) entry.value],
            startIndex: loaded.indexWhere((entry) => entry.key == index),
            context: const QueueContext(kind: QueueContextKind.library),
          ),
    );
  }
}
