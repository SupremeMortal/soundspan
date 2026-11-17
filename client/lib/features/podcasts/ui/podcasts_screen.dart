// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

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
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/features/podcasts/domain/podcast_ref.dart';
import 'package:soundspan/features/podcasts/ui/podcasts_view_model.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/media_grid_layout.dart';
import 'package:soundspan/shared/widgets/refresh_target.dart';
import 'package:soundspan/shared/widgets/shelf.dart';

/// The Podcasts destination (`/podcasts`; doc 09, Podcasts).
///
/// The page title, a "Your podcasts" grid of the subscribed podcasts and a
/// "Top podcasts" shelf. A subscribed card opens its podcast page; a top
/// podcast that is not subscribed opens a dialog offering to subscribe,
/// and a successful subscribe opens the new podcast's page. Skeleton tiles
/// stand for the grid while it first loads; with nothing cached a failed
/// load shows an [ErrorView], and an empty list an [EmptyState] above the
/// shelf. The shelf is hidden when it is empty or fails. Pull to refresh
/// fetches both again.
class PodcastsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  /// The key of the grid card of subscribed podcast [id].
  static Key cardKey(String id) => ValueKey('PodcastsScreen.card.$id');

  /// The key of the Top Podcasts shelf.
  static const Key shelfKey = ValueKey('PodcastsScreen.shelf');

  /// How many skeleton tiles stand for the grid while it loads.
  static const int skeletonTiles = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final gutter = pageGutter(windowClass);
    final subscribed = ref.watch(subscribedPodcastsProvider);
    final podcasts = subscribed.value?.value;

    final List<Widget> body;
    if (podcasts == null && subscribed.hasError) {
      body = [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            error: subscribed.error!,
            onRetry: () => ref.invalidate(subscribedPodcastsProvider),
          ),
        ),
      ];
    } else {
      body = [
        _SectionTitle(l10n.podcastsYourPodcasts),
        if (podcasts != null && podcasts.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.podcasts_rounded,
              message: l10n.podcastsEmpty,
            ),
          )
        else
          _PodcastGrid(podcasts: podcasts),
        const SliverToBoxAdapter(child: _TopPodcastsShelf()),
      ];
    }

    return RouteTitle(
      screen: l10n.navPodcasts,
      child: Scaffold(
        appBar: windowClass == WindowClass.compact
            ? AppBar(actions: const [AvatarButton()])
            : null,
        body: AppRefreshIndicator(
          onRefresh: () => _refresh(ref),
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
                      l10n.navPodcasts,
                      style: context.typography.headline.copyWith(
                        color: context.colors.content,
                      ),
                    ),
                  ),
                ),
              ),
              ...body,
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.x32)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) => refreshPodcasts(ref);
}

void _open(BuildContext context, String podcastId) =>
    GoRouter.of(context).go(podcastLocation(podcastId));

/// A section title in the page's gutter.
class _SectionTitle extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(WindowClass.of(context));
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, Spacing.x16, gutter, Spacing.x8),
      sliver: SliverToBoxAdapter(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: context.typography.title.copyWith(
              color: context.colors.content,
            ),
          ),
        ),
      ),
    );
  }
}

/// The grid of the subscribed [podcasts]; skeleton tiles while null.
class _PodcastGrid extends StatelessWidget {
  const new({required this.podcasts});

  final List<Podcast>? podcasts;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(WindowClass.of(context));
    final podcasts = this.podcasts;
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
            delegate: SliverChildBuilderDelegate((context, index) {
              if (podcasts == null) return const MediaCardSkeleton();
              final podcast = podcasts[index];
              return MediaCard(
                key: PodcastsScreen.cardKey(podcast.id),
                title: podcast.title,
                subtitle: podcast.author ?? '',
                artworkRef: podcast.artworkRef,
                onTap: () => _open(context, podcast.id),
              );
            }, childCount: podcasts?.length ?? PodcastsScreen.skeletonTiles),
          );
        },
      ),
    );
  }
}

/// The Top Podcasts shelf; nothing while it loads, when it is empty and
/// when it fails.
class _TopPodcastsShelf extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final top = ref.watch(topPodcastsProvider).value;
    if (top == null || top.isEmpty) return const SizedBox.shrink();
    final subscribed = {
      for (final podcast
          in ref.watch(subscribedPodcastsProvider).value?.value ??
              const <Podcast>[])
        podcast.id,
    };
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.x24),
      child: Shelf(
        key: PodcastsScreen.shelfKey,
        title: l10n.podcastsTopPodcasts,
        itemCount: top.length,
        itemBuilder: (context, index) {
          final podcast = top[index];
          return MediaCard(
            title: podcast.title,
            subtitle: podcast.author ?? '',
            artworkRef: podcast.artworkRef,
            onTap: subscribed.contains(podcast.id)
                ? () => _open(context, podcast.id)
                : () => _offerSubscribe(context, ref, podcast),
          );
        },
      ),
    );
  }

  Future<void> _offerSubscribe(
    BuildContext context,
    WidgetRef ref,
    PodcastSummary podcast,
  ) async {
    final l10n = AppLocalizations.of(context);
    final podcastRef = PodcastRef.fromSummary(podcast);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final controller = ref.read(subscribedPodcastsProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _TopPodcastDialog(podcast: podcast, canSubscribe: podcastRef != null),
    );
    if (confirmed != true || podcastRef == null) return;
    try {
      final id = await controller.subscribe(podcastRef);
      router.go(podcastLocation(id));
    } on Exception {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.podcastsSubscribeFailed)),
      );
    }
  }
}

/// The dialog of a top podcast the user is not subscribed to: its artwork,
/// title and author, and Subscribe. It pops with true on Subscribe.
class _TopPodcastDialog extends ConsumerWidget {
  const new({required this.podcast, required this.canSubscribe});

  final PodcastSummary podcast;
  final bool canSubscribe;

  static const double _artwork = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final online =
        (ref.watch(reachabilityStateProvider).value ??
            ref.read(reachabilityProvider).current) ==
        Reachability.online;
    final author = podcast.author;
    final subscribe = FilledButton(
      onPressed: canSubscribe && online
          ? () => Navigator.of(context).pop(true)
          : null,
      child: Text(l10n.podcastsSubscribe),
    );
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Artwork(ref: podcast.artworkRef, size: _artwork),
          const SizedBox(height: Spacing.x16),
          Text(
            podcast.title,
            textAlign: TextAlign.center,
            style: typography.title.copyWith(color: colors.content),
          ),
          if (author != null) ...[
            const SizedBox(height: Spacing.x4),
            Text(
              author,
              textAlign: TextAlign.center,
              style: typography.body.copyWith(color: colors.contentSecondary),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.podcastsCancel),
        ),
        if (online)
          subscribe
        else
          Tooltip(message: l10n.podcastsOfflineTooltip, child: subscribe),
      ],
    );
  }
}
