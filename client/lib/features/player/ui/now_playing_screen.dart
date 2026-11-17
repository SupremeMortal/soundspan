// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/features/player/ui/lyrics_view.dart';
import 'package:soundspan/features/player/ui/player_bar.dart';
import 'package:soundspan/features/player/ui/player_item.dart';
import 'package:soundspan/features/player/ui/queue_sheet.dart';
import 'package:soundspan/features/player/ui/queue_view.dart';
import 'package:soundspan/features/player/ui/seek_bar.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/backdrop.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/quality_badge.dart';

/// The full-screen now playing of compact and medium windows, the
/// `/now-playing` route (doc 09, Now Playing, Queue, Lyrics).
///
/// A close button and the "NOW PLAYING" overline; the current item's
/// artwork (at most [maxArtworkSize], radius 12), title and artist (a link
/// to the artist page when the track has one); the [SeekBar] with the
/// elapsed and remaining time; shuffle, previous, a [playButtonSize]
/// play/pause circle, next and repeat; and a row with the [QualityBadge]
/// and the lyrics and queue buttons, which open the lyrics and the queue
/// as sheets. A landscape window wider than compact shows the [QueueView]
/// beside the controls instead, with the [LyricsView] in a second tab. The
/// lyrics are not offered for an episode. The background is the artwork's
/// [Backdrop].
class NowPlayingScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  /// The largest edge of the artwork.
  static const double maxArtworkSize = 360;

  /// The diameter of the play/pause circle.
  static const double playButtonSize = 64;

  /// The key of the artist line.
  static const Key artistKey = Key('nowPlaying.artist');

  /// The key of the queue shown beside the controls.
  static const Key sideQueueKey = Key('nowPlaying.sideQueue');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final snapshot = ref.watch(playbackControllerProvider.exists)
        ? ref.watch(playbackStateProvider).value
        : null;
    final current = snapshot?.current;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Backdrop(
        artworkRef: current?.playerArtworkRef,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final windowClass = windowClassOf(constraints.biggest);
              final sideBySide =
                  windowClass != WindowClass.compact &&
                  constraints.maxWidth > constraints.maxHeight;
              final gutter = windowClass == WindowClass.compact
                  ? Spacing.x16
                  : Spacing.x24;
              final Widget body;
              if (snapshot == null || current == null) {
                body = EmptyState(
                  icon: Icons.queue_music_rounded,
                  message: l10n.queueEmpty,
                );
              } else if (sideBySide) {
                body = Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Controls(
                        snapshot: snapshot,
                        current: current,
                        showQueueButton: false,
                      ),
                    ),
                    const SizedBox(width: Spacing.x24),
                    Expanded(
                      child: current is EpisodeQueueItem
                          ? const QueueView(key: sideQueueKey)
                          : const _QueueAndLyricsTabs(),
                    ),
                  ],
                );
              } else {
                body = _Controls(
                  snapshot: snapshot,
                  current: current,
                  showQueueButton: true,
                );
              }
              return WindowClassScope(
                windowClass: windowClass,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      Expanded(child: body),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The close button and the overline.
class _Header extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: l10n.nowPlayingClose,
          color: colors.content,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Text(
            l10n.nowPlayingOverline.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typography.overline.copyWith(
              color: colors.contentSecondary,
            ),
          ),
        ),
        const SizedBox(width: Sizes.touchTarget),
      ],
    );
  }
}

/// Artwork, title and artist, the seek bar, the transport and the bottom
/// row.
class _Controls extends ConsumerWidget {
  const new({
    required this.snapshot,
    required this.current,
    required this.showQueueButton,
  });

  final PlaybackSnapshot snapshot;
  final QueueItem current;
  final bool showQueueButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final quality = snapshot.quality;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.x16),
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: Artwork(
                  ref: current.playerArtworkRef,
                  size: math.min(
                    NowPlayingScreen.maxArtworkSize,
                    math.min(constraints.maxWidth, constraints.maxHeight),
                  ),
                  radius: Radii.large,
                ),
              ),
            ),
          ),
        ),
        NowPlayingTitle(item: current),
        const SizedBox(height: Spacing.x16),
        const _Progress(),
        const SizedBox(height: Spacing.x8),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: PlayerTransport(
              snapshot: snapshot,
              playButtonSize: NowPlayingScreen.playButtonSize,
            ),
          ),
        ),
        const SizedBox(height: Spacing.x8),
        Row(
          children: [
            if (quality != null) QualityBadge(info: quality),
            const Spacer(),
            if (showQueueButton && current is! EpisodeQueueItem)
              IconButton(
                tooltip: l10n.lyricsTitle,
                color: colors.contentSecondary,
                icon: const Icon(Icons.lyrics_outlined),
                onPressed: () => unawaited(showLyricsSheet(context)),
              ),
            if (showQueueButton)
              IconButton(
                tooltip: l10n.nowPlayingQueue,
                color: colors.contentSecondary,
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: () => unawaited(showQueueSheet(context)),
              ),
          ],
        ),
      ],
    );
  }
}

/// The queue and the lyrics as two tabs, beside the controls of a
/// landscape window wider than compact.
class _QueueAndLyricsTabs extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            labelColor: colors.content,
            unselectedLabelColor: colors.contentSecondary,
            indicatorColor: colors.brand,
            dividerColor: colors.line,
            tabs: [
              Tab(text: l10n.queueTitle),
              Tab(text: l10n.lyricsTitle),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                QueueView(key: NowPlayingScreen.sideQueueKey),
                LyricsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The title of [item] in `title` and its artist below; the artist is a
/// link that closes the route and opens the artist page when the track has
/// an artist id, and plain text otherwise.
class NowPlayingTitle extends StatelessWidget {
  /// Creates the title and artist of [item].
  const new({
    required this.item,
    this.large = false,
    this.linkArtist = true,
    super.key,
  });

  /// The item shown.
  final QueueItem item;

  /// Whether the title is in `headline` rather than `title`, for the
  /// overlay.
  final bool large;

  /// Whether the artist line may link to the artist page.
  final bool linkArtist;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final artistId = linkArtist ? item.playerArtistId : null;
    final artistStyle = typography.body.copyWith(
      color: colors.contentSecondary,
    );
    final artist = Text(
      item.playerSubtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: artistStyle,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.playerTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (large ? typography.headline : typography.title).copyWith(
            color: colors.content,
          ),
        ),
        if (artistId == null)
          Padding(
            key: NowPlayingScreen.artistKey,
            padding: const EdgeInsets.symmetric(vertical: Spacing.x4),
            child: artist,
          )
        else
          Semantics(
            link: true,
            child: TextButton(
              key: NowPlayingScreen.artistKey,
              style: TextButton.styleFrom(
                foregroundColor: colors.contentSecondary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, Sizes.touchTarget),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: AlignmentDirectional.centerStart,
              ),
              onPressed: () => _openArtist(context, artistId),
              child: artist,
            ),
          ),
      ],
    );
  }

  void _openArtist(BuildContext context, String artistId) {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
    DetailNavigation.openArtistIn(router, artistId);
  }
}

/// The seek bar with the elapsed and remaining time; the only part that
/// rebuilds as the position moves.
class _Progress extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playbackSnapshotProvider).value;
    if (snapshot == null) return const SizedBox(height: SeekBar.height);
    return SeekBar(
      position: snapshot.position,
      buffered: snapshot.buffered,
      duration: snapshot.duration,
      status: snapshot.status,
      playing: snapshot.playing,
      onSeek: ref.read(playbackControllerProvider).seek,
      showTimes: true,
      showRemaining: true,
    );
  }
}
