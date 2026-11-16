// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/ui/player_item.dart';
import 'package:soundspan/shared/widgets/artwork.dart';

/// The player of compact and medium windows (doc 09, Components): a
/// [progressHeight] `brand` progress line on top, then the current item's
/// artwork, title and artist, play/pause and next, on `surfaceRaised`.
///
/// A tap calls [onOpen] when it is set. It renders nothing while the queue
/// is empty.
class MiniPlayer extends ConsumerWidget {
  /// Creates the mini player.
  const new({this.onOpen, super.key});

  /// Opens now playing; null makes the player itself not tappable.
  final VoidCallback? onOpen;

  /// The thickness of the progress line.
  static const double progressHeight = 2;

  /// The edge length of the artwork.
  static const double artworkSize = 44;

  /// The key of the played part of the progress line.
  static const Key progressKey = Key('miniPlayer.progress');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playbackStateProvider).value;
    final current = snapshot?.current;
    if (snapshot == null || current == null) return const SizedBox.shrink();
    final colors = context.colors;
    final typography = context.typography;
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(playbackControllerProvider);
    return Material(
      color: colors.surfaceRaised,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MiniProgress(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Spacing.x8,
                Spacing.x4,
                Spacing.x4,
                Spacing.x4,
              ),
              child: Row(
                children: [
                  Artwork(ref: current.playerArtworkRef, size: artworkSize),
                  const SizedBox(width: Spacing.x12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.playerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.body.copyWith(
                            color: colors.content,
                          ),
                        ),
                        Text(
                          current.playerSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodySmall.copyWith(
                            color: colors.contentSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: snapshot.playing
                        ? l10n.playerPause
                        : l10n.playerPlay,
                    color: colors.content,
                    icon: Icon(
                      snapshot.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: controller.togglePlayPause,
                  ),
                  IconButton(
                    tooltip: l10n.playerNext,
                    color: colors.content,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: controller.next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The progress line; the only part of the mini player that rebuilds as
/// the position moves.
class _MiniProgress extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final snapshot = ref.watch(playbackSnapshotProvider).value;
    final duration = snapshot?.duration;
    final fraction =
        snapshot == null || duration == null || duration <= Duration.zero
        ? 0.0
        : (snapshot.position.inMicroseconds / duration.inMicroseconds).clamp(
            0.0,
            1.0,
          );
    return RepaintBoundary(
      child: SizedBox(
        height: MiniPlayer.progressHeight,
        width: double.infinity,
        child: ColoredBox(
          color: colors.line,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              key: MiniPlayer.progressKey,
              widthFactor: fraction,
              heightFactor: 1,
              child: ColoredBox(color: colors.brand),
            ),
          ),
        ),
      ),
    );
  }
}
