// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
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
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/podcasts/domain/podcast_detail.dart';
import 'package:soundspan/features/podcasts/ui/episode_row.dart';
import 'package:soundspan/features/podcasts/ui/podcasts_view_model.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/detail_page.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

/// The podcast page (`/podcasts/:podcastId`; doc 09, Podcasts).
///
/// A [DetailHeader] with the artwork, "PODCAST", the title, "Author · N
/// episodes" and a Subscribe or Unsubscribe pill; the description
/// collapsed to three lines with "Show more"; then the episodes in server
/// order as [EpisodeRow]s of one fixed height. Unsubscribe asks first and
/// then returns to `/podcasts`. Both buttons are disabled, with a tooltip,
/// while the server is not reachable, and a failure shows a snackbar and
/// changes nothing. Tapping an episode row replaces the queue with that
/// episode and plays it from its saved progress, or, when that is unknown,
/// from the position its download last reached.
///
/// Where the platform downloads, each row shows its download glyph and a
/// menu with Download, Remove download, and Retry download for a failed
/// one; while offline an episode without a file is disabled with "Not
/// available offline", and with nothing cached the page lists the
/// downloaded episodes of the podcast.
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
    // Offline with nothing cached, the downloaded episodes stand in.
    final downloaded =
        detail.value == null && detail.hasError && ref.watch(isOfflineProvider)
        ? _downloadedDetail(ref)
        : null;
    final value = downloaded != null
        ? AsyncValue<PodcastDetail>.data(downloaded)
        : detail.whenData((cached) => cached.value);
    return RouteTitle(
      screen: l10n.screenPodcast,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: DetailPage<PodcastDetail>(
          value: value,
          refreshError: detail.value?.refreshError,
          onRefresh: () =>
              ref.read(podcastDetailProvider(podcastId).notifier).refresh(),
          onRetry: () => ref.invalidate(podcastDetailProvider(podcastId)),
          builder: (context, detail) => _slivers(context, ref, detail),
        ),
      ),
    );
  }

  /// The podcast as its downloaded episodes describe it; null when none of
  /// its episodes is downloaded.
  PodcastDetail? _downloadedDetail(WidgetRef ref) {
    final episodes = [
      for (final meta
          in ref.watch(downloadedEpisodesProvider).value ??
              const <EpisodeDownloadMeta>[])
        if (meta.podcastId == podcastId) meta,
    ];
    if (episodes.isEmpty) return null;
    episodes.sort(
      (a, b) => (b.publishedAt ?? DateTime(0)).compareTo(
        a.publishedAt ?? DateTime(0),
      ),
    );
    return PodcastDetail(
      podcast: episodes.first.toPodcast(),
      episodes: [for (final meta in episodes) meta.toEpisode()],
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    WidgetRef ref,
    PodcastDetail detail,
  ) {
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
              itemBuilder: (context, index) =>
                  _EpisodeTile(podcast: podcast, episode: episodes[index]),
            ),
          ),
        ],
      ),
    ];
  }
}

/// One [EpisodeRow] of the page with its download glyph, menu and offline
/// state.
class _EpisodeTile extends ConsumerWidget {
  const new({required this.podcast, required this.episode});

  final Podcast podcast;
  final Episode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final downloads = ref.watch(downloadsAvailableProvider);
    final glyph = downloads
        ? watchEpisodeGlyph(ref, podcast.id, episode.id)
        : null;
    final offline = downloads && ref.watch(isOfflineProvider);
    final unavailableOffline = offline && glyph != DownloadGlyphState.completed;
    final key = EpisodeItemKey(podcastId: podcast.id, episodeId: episode.id);
    final played = _withDownloadedProgress(
      ref,
      glyph == DownloadGlyphState.completed,
    );
    final progress = played.progress;
    final durationSec = episode.durationSec;
    void retry() => unawaited(ref.read(downloadControllerProvider).retry(key));
    return EpisodeRow(
      title: episode.title,
      publishedAt: episode.publishedAt,
      duration: durationSec == null ? null : Duration(seconds: durationSec),
      position: progress == null
          ? null
          : Duration(milliseconds: (progress.currentTimeSec * 1000).round()),
      isFinished: progress?.isFinished ?? false,
      download: glyph,
      onDownloadTap: glyph == DownloadGlyphState.failed ? retry : null,
      disabledReason: unavailableOffline ? l10n.trackNotAvailableOffline : null,
      menu: glyph == null
          ? null
          : [
              if (glyph == DownloadGlyphState.failed)
                MenuEntry(
                  id: 'retryDownload',
                  label: l10n.menuRetryDownload,
                  icon: Icons.refresh_rounded,
                  onSelected: retry,
                ),
              if (glyph == DownloadGlyphState.none ||
                  glyph == DownloadGlyphState.unavailable)
                MenuEntry(
                  id: 'download',
                  label: l10n.menuDownload,
                  icon: Icons.download_rounded,
                  onSelected: () => unawaited(
                    ref
                        .read(downloadControllerProvider)
                        .pinEpisode(podcast, episode),
                  ),
                )
              else
                MenuEntry(
                  id: 'removeDownload',
                  label: l10n.menuRemoveDownload,
                  icon: Icons.delete_outline_rounded,
                  destructive: true,
                  onSelected: () => unawaited(
                    confirmAndUnpin(
                      context,
                      ref,
                      CollectionKind.episode,
                      '${podcast.id}:${episode.id}',
                    ),
                  ),
                ),
            ],
      onTap: () =>
          unawaited(ref.read(playActionsProvider).playEpisode(podcast, played)),
    );
  }

  /// The episode, with the position its download last reached as its
  /// progress when the server's progress is unknown.
  Episode _withDownloadedProgress(WidgetRef ref, bool downloaded) {
    if (episode.progress != null || !downloaded) return episode;
    final progress = ref.watch(
      downloadedEpisodesProvider.select((value) {
        for (final meta in value.value ?? const <EpisodeDownloadMeta>[]) {
          if (meta.podcastId == podcast.id && meta.episodeId == episode.id) {
            return meta.toEpisode().progress;
          }
        }
        return null;
      }),
    );
    return progress == null ? episode : episode.copyWith(progress: progress);
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
