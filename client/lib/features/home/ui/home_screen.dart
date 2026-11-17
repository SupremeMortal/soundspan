// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/profile/version_notice.dart';
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/features/home/ui/expiry_banner.dart';
import 'package:soundspan/features/home/ui/home_view_model.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/offline_banner.dart';
import 'package:soundspan/shared/widgets/refresh_target.dart';
import 'package:soundspan/shared/widgets/shelf.dart';

/// Home (doc 09, Home): the offline, link-expiry and server notices, a greeting and the user's
/// shelves, each read from cache first and built as it scrolls into view.
///
/// A shelf that is empty, disabled, or failed with nothing cached is
/// hidden. When every shelf failed with nothing cached one [ErrorView]
/// takes their place; when every shelf is empty an [EmptyState] does.
/// Pull to refresh on touch and F5 on desktop fetch the shelves again.
/// While the server has `discovery` on, compact and medium windows end with
/// the [ExploreCard].
class HomeScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activated = ref.watch(homeShelfActivationProvider);
    final outcome = homeOutcome({
      for (final shelf in HomeShelf.values)
        if (activated.contains(shelf)) shelf: ref.watch(homeShelfSource(shelf)),
    });
    final compact = WindowClass.of(context) == WindowClass.compact;

    final body = switch (outcome) {
      HomeShelves() => SliverList.builder(
        itemCount: HomeShelf.values.length,
        itemBuilder: (context, index) => _ShelfSlot(HomeShelf.values[index]),
      ),
      HomeAllFailed(:final error) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(error: error, onRetry: () => retryHome(ref)),
      ),
      HomeAllEmpty() => SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.library_music_rounded,
          message: l10n.homeEmptyLibrary,
        ),
      ),
    };

    return RouteTitle(
      screen: l10n.navHome,
      child: Scaffold(
        appBar: compact
            ? AppBar(title: Text(l10n.navHome), actions: const [AvatarButton()])
            : null,
        body: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.f5): _RefreshIntent(),
          },
          child: Actions(
            actions: {
              _RefreshIntent: CallbackAction<_RefreshIntent>(
                onInvoke: (_) => refreshHome(ref),
              ),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  const OfflineBanner(),
                  const ExpiryBanner(),
                  const _VersionNoticeBanner(),
                  Expanded(
                    child: AppRefreshIndicator(
                      onRefresh: () => refreshHome(ref),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          const SliverToBoxAdapter(child: _Greeting()),
                          body,
                          const SliverToBoxAdapter(child: ExploreCard()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks Home to fetch its shelves again.
class _RefreshIntent extends Intent {
  const new();
}

/// The server notice of [versionNoticeProvider], with a dismiss button.
class _VersionNoticeBanner extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notice = ref.watch(versionNoticeProvider).value;
    if (notice == null) return const SizedBox.shrink();
    return AppBanner(
      kind: AppBannerKind.serverNotice,
      message: switch (notice) {
        NewerThanTested() => l10n.homeNoticeNewerThanTested,
        VersionUnknown() => l10n.homeNoticeVersionUnknown,
      },
      onDismiss: () => ref.read(versionNoticeProvider.notifier).dismiss(),
    );
  }
}

/// "Good morning", "Good afternoon" or "Good evening" by the local hour.
class _Greeting extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hour = ref.watch(clockProvider).now().toLocal().hour;
    final text = hour < 12
        ? l10n.homeGreetingMorning
        : hour < 18
        ? l10n.homeGreetingAfternoon
        : l10n.homeGreetingEvening;
    final gutter = _gutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, Spacing.x24, gutter, Spacing.x16),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: context.typography.headline.copyWith(
            color: context.colors.content,
          ),
        ),
      ),
    );
  }
}

double _gutter(BuildContext context) => switch (WindowClass.of(context)) {
  WindowClass.compact => Gutters.compact,
  WindowClass.medium => Gutters.medium,
  WindowClass.expanded => Gutters.expanded,
};

/// One shelf of the list; records that it has been built.
class _ShelfSlot extends ConsumerStatefulWidget {
  const new(this.shelf);

  final HomeShelf shelf;

  @override
  ConsumerState<_ShelfSlot> createState() => _ShelfSlotState();
}

class _ShelfSlotState extends ConsumerState<_ShelfSlot> {
  @override
  void initState() {
    super.initState();
    // Providers may not change while the list builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(homeShelfActivationProvider.notifier).activate(widget.shelf);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (widget.shelf) {
      HomeShelf.continueListening => _shelf(
        l10n.homeShelfContinueListening,
        ref.watch(homeRecentlyListenedProvider),
        (item) => switch (item) {
          RecentArtist(:final artist) => _artistCard(context, artist),
          RecentPodcast(:final podcast) => MediaCard(
            title: podcast.title,
            subtitle: podcast.author ?? l10n.homeCardPodcast,
            artworkRef: podcast.artworkRef,
          ),
        },
      ),
      HomeShelf.recentlyAdded => _shelf(
        l10n.homeShelfRecentlyAdded,
        ref.watch(homeRecentlyAddedProvider),
        (artist) => _artistCard(context, artist),
      ),
      HomeShelf.madeForYou => _madeForYou(context),
      HomeShelf.recommendedForYou => _shelf(
        l10n.discoverRecommendedForYou,
        ref.watch(recommendedForYouProvider),
        DiscoveryArtistCard.new,
        onShowAll: () => DetailNavigation.openExplore(context),
      ),
      HomeShelf.popularArtists => _shelf(
        l10n.discoverPopularArtists,
        ref.watch(popularArtistsProvider),
        DiscoveryArtistCard.new,
        onShowAll: () => DetailNavigation.openExplore(context),
      ),
      HomeShelf.yourPlaylists => _shelf(
        l10n.homeShelfYourPlaylists,
        ref.watch(homePlaylistsProvider),
        (playlist) => MediaCard(
          title: playlist.name,
          subtitle: l10n.homePlaylistSongs(playlist.trackCount),
          artworkRef: null,
          mosaicRefs: playlist.coverRefs,
          onTap: () => DetailNavigation.openPlaylist(context, playlist.id),
          onPlay: () => unawaited(
            ref.read(playActionsProvider).playPlaylist(playlist.id),
          ),
          onMenu: (position) => unawaited(
            openPlaylistMenu(context, ref, playlist, position: position),
          ),
        ),
        onShowAll: () =>
            GoRouter.of(context)
                .go('${RoutePaths.library}/${LibraryTab.playlists.name}'),
      ),
      HomeShelf.popularPodcasts => _shelf(
        l10n.homeShelfPopularPodcasts,
        ref.watch(homeTopPodcastsProvider),
        (podcast) => MediaCard(
          title: podcast.title,
          subtitle: podcast.author ?? l10n.homeCardPodcast,
          artworkRef: podcast.artworkRef,
        ),
      ),
    };
  }

  /// Liked Songs, then the mixes when the server has them.
  Widget _madeForYou(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mixes = ref.watch(homeMixesProvider);
    if (!mixes.hasValue && !mixes.hasError) {
      return _SkeletonShelf(l10n.homeShelfMadeForYou);
    }
    final items = mixes.value ?? const <MixSummary>[];
    return _spaced(
      Shelf(
        title: l10n.homeShelfMadeForYou,
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return MediaCard(
              title: l10n.homeLikedSongs,
              subtitle: l10n.homeLikedSongsSubtitle,
              artworkRef: null,
              onTap: () => DetailNavigation.openPlaylist(
                context,
                PlayActions.likedPlaylistId,
              ),
              onPlay: () => unawaited(
                ref
                    .read(playActionsProvider)
                    .playPlaylist(PlayActions.likedPlaylistId),
              ),
            );
          }
          final mix = items[index - 1];
          return MediaCard(
            title: mix.name,
            subtitle: mix.description,
            artworkRef: null,
            mosaicRefs: mix.coverRefs,
          );
        },
      ),
    );
  }

  Widget _artistCard(BuildContext context, Artist artist) => MediaCard(
    title: artist.name,
    subtitle: AppLocalizations.of(context).homeCardArtist,
    artworkRef: artist.artworkRef,
    shape: ArtworkShape.circle,
    onTap: () => DetailNavigation.openArtist(context, artist.id),
  );

  /// A shelf of [value]: skeletons while it has no value yet, nothing when
  /// it failed with nothing cached, is disabled or is empty.
  Widget _shelf<T>(
    String title,
    AsyncValue<List<T>?> value,
    Widget Function(T item) card, {
    VoidCallback? onShowAll,
  }) {
    if (!value.hasValue && !value.hasError) return _SkeletonShelf(title);
    final items = value.value;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return _spaced(
      Shelf(
        title: title,
        itemCount: items.length,
        itemBuilder: (_, index) => card(items[index]),
        onShowAll: onShowAll,
      ),
    );
  }
}

Widget _spaced(Widget shelf) => Padding(
  padding: const EdgeInsets.only(bottom: Spacing.x24),
  child: shelf,
);

/// A shelf titled [title] of card skeletons, while it has no value yet.
class _SkeletonShelf extends StatelessWidget {
  const new(this.title);

  final String title;

  static const int _cards = 6;

  @override
  Widget build(BuildContext context) => _spaced(
    Shelf(
      title: title,
      itemCount: _cards,
      itemBuilder: (_, _) => const MediaCardSkeleton(),
    ),
  );
}
