// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/features/podcasts/domain/podcast_detail.dart';
import 'package:soundspan/features/podcasts/ui/episode_row.dart';
import 'package:soundspan/features/podcasts/ui/podcasts_view_model.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/detail_page.dart';

/// The podcast page (`/podcasts/:podcastId`; doc 09, Podcasts).
///
/// A [DetailHeader] with the artwork, "PODCAST", the title, "Author · N
/// episodes" and a Subscribe or Unsubscribe pill; the description
/// collapsed to three lines with "Show more"; then the episodes in server
/// order as [EpisodeRow]s of one fixed height. Unsubscribe asks first and
/// then returns to `/podcasts`. Both buttons are disabled, with a tooltip,
/// while the server is not reachable, and a failure shows a snackbar and
/// changes nothing. Episode rows do nothing on tap.
class PodcastDetailScreen extends ConsumerWidget {
  /// Creates the page of podcast [podcastId].
  const new({required this.podcastId, super.key});

  /// The server's podcast id.
  final String podcastId;

  /// The key of the Subscribe or Unsubscribe button.
  static const Key subscriptionKey = ValueKey(
    'PodcastDetailScreen.subscription',
  );

  /// The key of the description text.
  static const Key descriptionKey = ValueKey('PodcastDetailScreen.description');

  /// How many lines the collapsed description shows.
  static const int descriptionLines = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(podcastDetailProvider(podcastId));
    return RouteTitle(
      screen: l10n.screenPodcast,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: DetailPage<PodcastDetail>(
          value: detail.whenData((cached) => cached.value),
          refreshError: detail.value?.refreshError,
          onRefresh: () =>
              ref.read(podcastDetailProvider(podcastId).notifier).refresh(),
          onRetry: () => ref.invalidate(podcastDetailProvider(podcastId)),
          builder: _slivers,
        ),
      ),
    );
  }

  List<Widget> _slivers(BuildContext context, PodcastDetail detail) {
    final l10n = AppLocalizations.of(context);
    final podcast = detail.podcast;
    final episodes = detail.episodes;
    final gutter = pageGutter(WindowClass.of(context));
    final description = podcast.description?.trim() ?? '';
    return [
      DetailHeader(
        artworkRef: podcast.artworkRef,
        overline: l10n.podcastsOverline,
        title: podcast.title,
        metadata: DetailMetadataLine(
          parts: [
            ?podcast.author,
            l10n.podcastsEpisodeCount(podcast.episodeCount ?? episodes.length),
          ],
        ),
        actions: _SubscriptionButton(podcast: podcast),
        slivers: [
          if (description.isNotEmpty)
            SliverToBoxAdapter(child: _Description(text: description)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter - Spacing.x8,
              Spacing.x8,
              gutter - Spacing.x8,
              Spacing.x32,
            ),
            sliver: SliverFixedExtentList.builder(
              itemExtent: EpisodeRow.extentFor(context),
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                final progress = episode.progress;
                final durationSec = episode.durationSec;
                return EpisodeRow(
                  title: episode.title,
                  publishedAt: episode.publishedAt,
                  duration: durationSec == null
                      ? null
                      : Duration(seconds: durationSec),
                  position: progress == null
                      ? null
                      : Duration(
                          milliseconds: (progress.currentTimeSec * 1000)
                              .round(),
                        ),
                  isFinished: progress?.isFinished ?? false,
                );
              },
            ),
          ),
        ],
      ),
    ];
  }
}

/// Subscribe or Unsubscribe, as a pill. The podcast counts as subscribed
/// unless the loaded subscribed list leaves it out.
class _SubscriptionButton extends ConsumerStatefulWidget {
  const new({required this.podcast});

  final Podcast podcast;

  @override
  ConsumerState<_SubscriptionButton> createState() =>
      _SubscriptionButtonState();
}

class _SubscriptionButtonState extends ConsumerState<_SubscriptionButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final podcast = widget.podcast;
    final list = ref.watch(subscribedPodcastsProvider).value?.value;
    final subscribed = list == null || list.any((p) => p.id == podcast.id);
    final online =
        (ref.watch(reachabilityStateProvider).value ??
            ref.read(reachabilityProvider).current) ==
        Reachability.online;
    final feedUrl = podcast.feedUrl;
    final onPressed = !online || _busy
        ? null
        : subscribed
        ? _unsubscribe
        : feedUrl == null
        ? null
        : () => _subscribe(feedUrl);
    const style = ButtonStyle(
      shape: WidgetStatePropertyAll(Radii.pill),
      minimumSize: WidgetStatePropertyAll(
        Size(Sizes.touchTarget * 2, Sizes.touchTarget),
      ),
    );
    final label = Text(
      subscribed ? l10n.podcastsUnsubscribe : l10n.podcastsSubscribe,
    );
    final Widget button = subscribed
        ? OutlinedButton(
            key: PodcastDetailScreen.subscriptionKey,
            onPressed: onPressed,
            style: style,
            child: label,
          )
        : FilledButton(
            key: PodcastDetailScreen.subscriptionKey,
            onPressed: onPressed,
            style: style,
            child: label,
          );
    if (online) return button;
    return Tooltip(message: l10n.podcastsOfflineTooltip, child: button);
  }

  Future<void> _subscribe(String feedUrl) => _run(
    () => ref
        .read(podcastDetailProvider(widget.podcast.id).notifier)
        .subscribe(feedUrl),
    AppLocalizations.of(context).podcastsSubscribeFailed,
  );

  Future<void> _unsubscribe() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.podcastsUnsubscribeTitle(widget.podcast.title)),
        content: Text(l10n.podcastsUnsubscribeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.podcastsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.podcastsUnsubscribe),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final router = GoRouter.of(context);
    final done = await _run(
      () => ref
          .read(podcastDetailProvider(widget.podcast.id).notifier)
          .unsubscribe(),
      l10n.podcastsUnsubscribeFailed,
    );
    if (done) router.go(RoutePaths.podcasts);
  }

  /// Runs [write]; on failure shows [failure] in a snackbar. Returns whether
  /// it succeeded.
  Future<bool> _run(Future<void> Function() write, String failure) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      await write();
      return true;
    } on Exception {
      messenger?.showSnackBar(SnackBar(content: Text(failure)));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// The podcast description: [text] collapsed to three lines, with "Show
/// more" when it does not fit.
class _Description extends StatefulWidget {
  const new({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final style = context.typography.body.copyWith(
      color: colors.contentSecondary,
    );
    final gutter = pageGutter(WindowClass.of(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max<double>(0, constraints.maxWidth - gutter * 2);
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: PodcastDetailScreen.descriptionLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: width);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Text(
                widget.text,
                key: PodcastDetailScreen.descriptionKey,
                maxLines: _expanded
                    ? null
                    : PodcastDetailScreen.descriptionLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (overflows || _expanded)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter - Spacing.x8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? l10n.podcastsShowLess : l10n.podcastsShowMore,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
