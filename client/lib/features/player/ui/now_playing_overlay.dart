// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/ui/lyrics_view.dart';
import 'package:soundspan/features/player/ui/now_playing_screen.dart';
import 'package:soundspan/features/player/ui/player_item.dart';
import 'package:soundspan/features/player/ui/queue_context_label.dart';
import 'package:soundspan/features/player/ui/queue_view.dart';
import 'package:soundspan/features/player/ui/right_panel.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/backdrop.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';

/// Now playing on expanded windows: the current item's large artwork,
/// title and artist over the content area, on the artwork's [Backdrop]
/// (doc 09, Now Playing, Queue, Lyrics). For a track the artwork, title
/// and artist take the left half and the [LyricsView], in its larger type,
/// the right half.
///
/// The player bar's expand button shows and hides it through
/// [nowPlayingOverlayProvider]; Escape hides it too.
class NowPlayingOverlay extends ConsumerWidget {
  /// Creates the overlay.
  const new({super.key});

  /// The largest edge of the artwork.
  static const double maxArtworkSize = 480;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(playbackControllerProvider.exists)
        ? ref.watch(playbackStateProvider).value
        : null;
    final current = state?.current;
    final overline =
        queueContextLabel(l10n, state?.queue.context) ??
        l10n.nowPlayingOverline;
    void close() => ref.read(nowPlayingOverlayProvider.notifier).close();
    Widget details(QueueItem item) => _Details(item: item, overline: overline);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        // Holds focus for the screen's keys; never a Tab stop or ringed.
        skipTraversal: true,
        child: Material(
          color: context.colors.surface,
          child: Backdrop(
            artworkRef: current?.playerArtworkRef,
            child: current == null
                ? EmptyState(
                    icon: Icons.queue_music_rounded,
                    message: l10n.queueEmpty,
                    actionLabel: l10n.nowPlayingCollapse,
                    onAction: close,
                  )
                : Padding(
                    padding: const EdgeInsets.all(Spacing.x32),
                    child: current is TrackQueueItem
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: details(current)),
                              const SizedBox(width: Spacing.x32),
                              const Expanded(child: LyricsView(large: true)),
                            ],
                          )
                        : details(current),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The overline, the large artwork and the title and artist of [item].
class _Details extends StatelessWidget {
  const new({required this.item, required this.overline});

  final QueueItem item;
  final String overline;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        overline.toUpperCase(),
        style: context.typography.overline.copyWith(
          color: context.colors.contentSecondary,
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.x24),
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Artwork(
                ref: item.playerArtworkRef,
                size: math.min(
                  NowPlayingOverlay.maxArtworkSize,
                  math.min(constraints.maxWidth, constraints.maxHeight),
                ),
                radius: Radii.large,
              ),
            ),
          ),
        ),
      ),
      NowPlayingTitle(item: item, large: true, linkArtist: false),
    ],
  );
}

/// The queue in the right-hand panel of expanded windows: a "Queue" title
/// above the [QueueView].
class QueuePanel extends StatelessWidget {
  /// Creates the panel content.
  const new({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Spacing.x16,
          Spacing.x16,
          Spacing.x16,
          0,
        ),
        child: Semantics(
          header: true,
          child: Text(
            AppLocalizations.of(context).queueTitle,
            style: context.typography.title.copyWith(
              color: context.colors.content,
            ),
          ),
        ),
      ),
      const Expanded(child: QueueView()),
    ],
  );
}
