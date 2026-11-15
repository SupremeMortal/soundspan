// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/discover/domain/discovery_artist.dart';
import 'package:soundspan/features/discover/domain/discovery_playlist.dart';
import 'package:soundspan/features/discover/ui/discovery_artist_card.dart';
import 'package:soundspan/features/discover/ui/discovery_view_model.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/util/uuid.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/media_grid_layout.dart';
import 'package:soundspan/shared/widgets/offline_banner.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// Explore (`/explore`, pushed inside the current branch; doc 09, Shell by
/// Window Class): this week's discovery playlist, then the recommended and
/// the popular artists, each section hidden when it is empty or failed.
///
/// Each section shows skeletons until it has a value; when every section
/// is empty one [EmptyState] takes their place. While the server has
/// `discovery` off the screen says so and requests nothing. Pull to
/// refresh on touch and F5 on desktop fetch every section again.
class ExploreScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  /// The key of the discovery playlist's Play button.
  static const Key playKey = ValueKey('ExploreScreen.play');

  /// The key of the discovery playlist's Shuffle button.
  static const Key shuffleKey = ValueKey('ExploreScreen.shuffle');

  /// How many discovery tracks show before "Show all".
  static const int collapsedTracks = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final enabled = ref.watch(discoveryEnabledProvider);

    final Widget content;
    if (!enabled) {
      content = EmptyState(
        icon: Icons.explore_off_outlined,
        message: l10n.exploreNotAvailable,
      );
    } else {
      content = _ExploreBody(onRefresh: () => refreshDiscovery(ref));
    }

    return RouteTitle(
      screen: l10n.navExplore,
      child: Scaffold(
        appBar: windowClass == WindowClass.compact
            ? AppBar(
                title: Text(l10n.navExplore),
                actions: const [AvatarButton()],
              )
            : null,
        body: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.f5): _RefreshIntent(),
          },
          child: Actions(
            actions: {
              _RefreshIntent: CallbackAction<_RefreshIntent>(
                onInvoke: (_) => enabled ? refreshDiscovery(ref) : null,
              ),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  const OfflineBanner(),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks Explore to fetch its sections again.
class _RefreshIntent extends Intent {
  const new();
}

/// The sections, or the empty state when every one is empty.
class _ExploreBody extends ConsumerWidget {
  const new({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gutter = pageGutter(WindowClass.of(context));
    final playlist = ref.watch(currentDiscoveryProvider);
    final recommended = ref.watch(recommendedForYouProvider);
    final popular = ref.watch(popularArtistsProvider);

    bool shown(AsyncValue<Object?> value) => switch (value.value) {
      null => false,
      final List<Object?> list => list.isNotEmpty,
      _ => true,
    };
    final settled = [
      playlist,
      recommended,
      popular,
    ].every((value) => value.hasValue || value.hasError);
    final allEmpty =
        settled && !shown(playlist) && !shown(recommended) && !shown(popular);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              Spacing.x24,
              gutter,
              Spacing.x8,
            ),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.navExplore,
                  style: context.typography.headline.copyWith(
                    color: context.colors.content,
                  ),
                ),
              ),
            ),
          ),
          if (allEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.explore_outlined,
                message: l10n.exploreEmpty,
              ),
            )
          else ...[
            if (_loading(playlist))
              ..._trackSkeletons(context)
            else if (playlist.value case final value?)
              _DiscoverySection(playlist: value),
            ..._artistSection(
              context,
              l10n.discoverRecommendedForYou,
              recommended,
            ),
            ..._artistSection(context, l10n.discoverPopularArtists, popular),
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.x32)),
          ],
        ],
      ),
    );
  }
}

bool _loading(AsyncValue<Object?> value) => !value.hasValue && !value.hasError;

List<Widget> _trackSkeletons(BuildContext context) => [
  _SectionTitle(AppLocalizations.of(context).exploreThisWeek),
  SliverPadding(
    padding: EdgeInsets.symmetric(
      horizontal: pageGutter(WindowClass.of(context)) - Spacing.x8,
    ),
    sliver: SliverList.builder(
      itemCount: 4,
      itemBuilder: (_, _) => const TrackRowSkeleton(withThumbnail: true),
    ),
  ),
];

/// A titled grid of [value]'s artists: skeleton tiles while it has no
/// value, nothing when it is empty, disabled or failed.
List<Widget> _artistSection(
  BuildContext context,
  String title,
  AsyncValue<List<DiscoveryArtist>?> value,
) {
  if (_loading(value)) {
    return [_SectionTitle(title), const _ArtistGrid(artists: null)];
  }
  final artists = value.value;
  if (artists == null || artists.isEmpty) return const [];
  return [_SectionTitle(title), _ArtistGrid(artists: artists)];
}

/// A section title in the page's gutter.
class _SectionTitle extends StatelessWidget {
  const new(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(WindowClass.of(context));
    final trailing = this.trailing;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, Spacing.x24, gutter, Spacing.x8),
      sliver: SliverToBoxAdapter(
        child: Wrap(
          spacing: Spacing.x16,
          runSpacing: Spacing.x8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: context.typography.title.copyWith(
                  color: context.colors.content,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// The grid of [artists]; skeleton tiles while null.
class _ArtistGrid extends StatelessWidget {
  const new({required this.artists});

  final List<DiscoveryArtist>? artists;

  static const int _skeletonTiles = 4;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(WindowClass.of(context));
    final artists = this.artists;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gutter - MediaCard.padding),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = gridColumnsFor(width);
          final tileWidth = (width - gridSpacing * (columns - 1)) / columns;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: MediaCard.extentFor(context, width: tileWidth),
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridSpacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => artists == null
                  ? const MediaCardSkeleton()
                  : DiscoveryArtistCard(artists[index]),
              childCount: artists?.length ?? _skeletonTiles,
            ),
          );
        },
      ),
    );
  }
}

/// "This week's discoveries": Play and Shuffle, then the first
/// [ExploreScreen.collapsedTracks] tracks with "Show all" for the rest.
class _DiscoverySection extends ConsumerStatefulWidget {
  const new({required this.playlist});

  final DiscoveryPlaylist playlist;

  @override
  ConsumerState<_DiscoverySection> createState() => _DiscoverySectionState();
}

class _DiscoverySectionState extends ConsumerState<_DiscoverySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gutter = pageGutter(WindowClass.of(context));
    final tracks = widget.playlist.tracks;
    final playable = [
      for (final track in tracks)
        if (track.playbackId != null) track,
    ];
    final visible = _expanded || tracks.length <= ExploreScreen.collapsedTracks
        ? tracks
        : tracks.sublist(0, ExploreScreen.collapsedTracks);
    final canPlay = playable.isNotEmpty;

    return SliverMainAxisGroup(
      slivers: [
        _SectionTitle(
          l10n.exploreThisWeek,
          trailing: Wrap(
            spacing: Spacing.x8,
            children: [
              FilledButton.icon(
                key: ExploreScreen.playKey,
                onPressed: canPlay
                    ? () => unawaited(_play(playable, shuffle: false))
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.explorePlay),
              ),
              OutlinedButton.icon(
                key: ExploreScreen.shuffleKey,
                onPressed: canPlay
                    ? () => unawaited(_play(playable, shuffle: true))
                    : null,
                icon: const Icon(Icons.shuffle_rounded),
                label: Text(l10n.exploreShuffle),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter - Spacing.x8),
          sliver: SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final track = visible[index];
              return TrackRow(
                title: track.meta.title,
                artist: track.meta.artist,
                album: track.meta.album,
                duration: Duration(seconds: track.meta.durationSec),
                leading: TrackRowLeading.thumbnail(track.meta.artworkRef),
                enabled: track.playbackId != null,
                disabledReason: l10n.trackNotPlayable,
              );
            },
          ),
        ),
        if (visible.length < tracks.length)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, Spacing.x8, gutter, 0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = true),
                  child: Text(l10n.exploreShowAll),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Replaces the queue with [tracks], in order or shuffled.
  Future<void> _play(List<Track> tracks, {required bool shuffle}) async {
    final context = QueueContext(
      kind: QueueContextKind.playlist,
      title: AppLocalizations.of(this.context).exploreThisWeek,
    );
    final controller = ref.read(playbackControllerProvider);
    await controller.setShuffle(shuffle);
    await controller.playItems(
      [
        for (final track in tracks)
          QueueItem.track(
            queueItemId: Uuid.v4(),
            track: track,
            context: context,
          ),
      ],
      startIndex: shuffle ? Random().nextInt(tracks.length) : 0,
      context: context,
    );
  }
}
