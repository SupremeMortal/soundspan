// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/two_pane.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/features/library/ui/paged_library_view.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/providers/playlist_list.dart';
import 'package:soundspan/shared/widgets/built_range_reporter.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';
import 'package:soundspan/shared/widgets/refresh_target.dart';

/// The Playlists tab: Liked Songs pinned first and "New playlist", which
/// names, creates and opens a playlist, then the user's playlists
/// as rows of one fixed height with a mosaic, the name and the track count
/// (doc 09, Library). Tapping a row opens the playlist in the Library
/// branch.
///
/// With no playlists, Liked Songs is followed by a one-line hint; a failed
/// load with nothing loaded shows an [ErrorView] under Liked Songs.
class PlaylistsTab extends ConsumerStatefulWidget {
  /// Creates the tab.
  const new({super.key});

  /// The height of a row at text scale 1.0.
  static const double rowHeight = 56;

  /// The edge of a row's artwork.
  static const double artworkSize = 40;

  /// The key of the "New playlist" row.
  static const Key newKey = Key('library.playlists.new');

  /// The key of the empty-list hint.
  static const Key hintKey = Key('library.playlists.hint');

  /// The height of a row at the ambient text scale: [rowHeight], or the
  /// two text lines when they need more.
  static double extentFor(BuildContext context) {
    final typography = context.typography;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle style) =>
        scaler.scale(style.fontSize!) * (style.height ?? 1);
    final content =
        line(typography.body) + line(typography.bodySmall) + Spacing.x8;
    return content > rowHeight ? content : rowHeight;
  }

  @override
  ConsumerState<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends ConsumerState<PlaylistsTab> {
  late final BuiltRangeReporter _reporter = BuiltRangeReporter(
    (first, last) =>
        ref.read(playlistListSourceProvider).value?.ensureVisible(first, last),
  );

  @override
  void dispose() {
    _reporter.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(playlistListSourceProvider).value?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gutter = gutterOf(WindowClass.of(context));
    final list = ref.watch(playlistListProvider);
    final snapshot = list.value;
    final total = snapshot?.total;
    final error = list.error ?? snapshot?.refreshError;
    final extent = PlaylistsTab.extentFor(context);

    final Widget body;
    if (total == 0) {
      body = SliverToBoxAdapter(
        child: Padding(
          key: PlaylistsTab.hintKey,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x8,
            vertical: Spacing.x12,
          ),
          child: Text(
            l10n.libraryPlaylistsEmptyHint,
            style: context.typography.bodySmall.copyWith(
              color: context.colors.contentSecondary,
            ),
          ),
        ),
      );
    } else if (error != null && (snapshot?.loadedCount ?? 0) == 0) {
      body = SliverToBoxAdapter(
        child: ErrorView(
          error: error,
          onRetry: () {
            if (list.hasError) {
              ref.invalidate(playlistListSourceProvider);
            } else {
              unawaited(_refresh());
            }
          },
        ),
      );
    } else {
      body = SliverFixedExtentList.builder(
        itemExtent: extent,
        itemCount: total ?? 1,
        itemBuilder: (context, index) {
          _reporter.built(index);
          final playlist = snapshot?.itemAt(index);
          if (playlist == null) return const _PlaylistRowSkeleton();
          return PlaylistRow(
            selected: TwoPaneSelection.isSelected(
              context,
              DetailKind.playlist.name,
              playlist.id,
            ),
            name: playlist.name,
            subtitle: l10n.libraryPlaylistTrackCount(playlist.trackCount),
            artwork: MosaicArtwork(
              refs: playlist.coverRefs,
              size: PlaylistsTab.artworkSize,
            ),
            onTap: () => DetailNavigation.openPlaylist(context, playlist.id),
          );
        },
      );
    }

    return AppRefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter - Spacing.x8,
              Spacing.x8,
              gutter - Spacing.x8,
              Spacing.x32,
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: extent,
                    child: PlaylistRow(
                      selected: TwoPaneSelection.isSelected(
                        context,
                        DetailKind.playlist.name,
                        'liked',
                      ),
                      name: l10n.libraryLikedSongs,
                      artwork: const LikedSongsArtwork(
                        size: PlaylistsTab.artworkSize,
                      ),
                      onTap: () =>
                          DetailNavigation.openPlaylist(context, 'liked'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: extent,
                    child: PlaylistRow(
                      key: PlaylistsTab.newKey,
                      name: l10n.playlistNew,
                      artwork: const _NewPlaylistArtwork(),
                      onTap: () =>
                          unawaited(createPlaylistAndOpen(context, ref)),
                    ),
                  ),
                ),
                body,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The square that stands for Liked Songs where a playlist shows its
/// mosaic: a `brand` heart on `surfaceHighlight`.
class LikedSongsArtwork extends StatelessWidget {
  /// Creates the artwork, [size] logical pixels square.
  const new({required this.size, super.key});

  /// The edge length, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceHighlight,
            borderRadius: BorderRadius.circular(Radii.small),
          ),
          child: Icon(
            Icons.favorite_rounded,
            size: size / 2,
            color: colors.brand,
          ),
        ),
      ),
    );
  }
}

/// The square of the "New playlist" row: a plus on `surfaceHighlight`.
class _NewPlaylistArtwork extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: PlaylistsTab.artworkSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceHighlight,
            borderRadius: BorderRadius.circular(Radii.small),
          ),
          child: Icon(
            Icons.add_rounded,
            size: PlaylistsTab.artworkSize / 2,
            color: colors.content,
          ),
        ),
      ),
    );
  }
}

/// One playlist in the Library's list: [artwork], [name] and an optional
/// [subtitle], opening the playlist on tap. The [selected] row of a
/// two-pane list sits on `surfaceActive`.
class PlaylistRow extends StatelessWidget {
  /// Creates the row of the playlist [name].
  const new({
    required this.name,
    required this.artwork,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    super.key,
  });

  /// Whether the row is the selected item of a two-pane list.
  final bool selected;

  /// The playlist name, in `body`.
  final String name;

  /// The second line, in `bodySmall` and `contentSecondary`.
  final String? subtitle;

  /// The square at the start of the row.
  final Widget artwork;

  /// Opens the playlist.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final subtitle = this.subtitle;
    final radius = BorderRadius.circular(Radii.small);
    return Semantics(
      selected: selected ? true : null,
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? colors.surfaceActive : null,
          borderRadius: radius,
        ),
        child: InkWell(
          onTap: onTap,
          hoverColor: colors.surfaceHover,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.x8,
              vertical: Spacing.x4,
            ),
            child: Row(
              children: [
                artwork,
                const SizedBox(width: Spacing.x12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.body.copyWith(color: colors.content),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodySmall.copyWith(
                            color: colors.contentSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistRowSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final scaler = MediaQuery.textScalerOf(context);
    Widget bar(TextStyle style, double widthFactor) => SizedBox(
      height: scaler.scale(style.fontSize!) * (style.height ?? 1),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: widthFactor,
        heightFactor: 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceHighlight,
            borderRadius: BorderRadius.circular(Spacing.x4),
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x8,
          vertical: Spacing.x4,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: PlaylistsTab.artworkSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(Radii.small),
                ),
              ),
            ),
            const SizedBox(width: Spacing.x12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  bar(typography.body, 0.6),
                  bar(typography.bodySmall, 0.3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
