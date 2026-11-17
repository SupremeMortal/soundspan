// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/listen_together/listen_together.dart';
import 'package:soundspan/features/player/ui/player_bar.dart';
import 'package:soundspan/features/player/ui/player_item.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/widgets/artwork.dart';

/// The player of compact and medium windows (doc 09, Components): a
/// [progressHeight] `brand` progress line on top, then the current item's
/// artwork, title and artist, play/pause and next (skip forward for an
/// episode), on `surfaceRaised`.
///
/// A tap calls [onOpen] when it is set, and so does a swipe up: a vertical
/// drag upward of more than [openDragDistance], or one released upward
/// faster than [openFlingVelocity], wherever it starts, its buttons
/// included. Horizontal swipes do nothing. It renders nothing while the
/// queue is empty.
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

  /// The key of the play/pause button.
  static const Key playPauseKey = Key('miniPlayer.playPause');

  /// The key of the next button (skip forward for an episode).
  static const Key nextKey = Key('miniPlayer.next');

  /// How far up, in logical pixels, a drag must go to open now playing.
  static const double openDragDistance = 24;

  /// How fast upward, in logical pixels per second, a released drag must
  /// move to open now playing.
  static const double openFlingVelocity = 300;

  /// How far a pointer moves before it is a drag rather than a tap: less
  /// than [openDragDistance], so a short drag neither taps nor opens.
  static const double dragSlop = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playbackStateProvider).value;
    final current = snapshot?.current;
    if (snapshot == null || current == null) return const SizedBox.shrink();
    final colors = context.colors;
    final typography = context.typography;
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(playbackControllerProvider);
    final locked = snapshot.remoteAttached && !snapshot.remoteCanControl;
    final group = ref.watch(attachedListenTogetherProvider);
    return _SwipeUp(
      onOpen: onOpen,
      child: Material(
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
                    TransportButton(
                      key: playPauseKey,
                      label: snapshot.playing
                          ? l10n.playerPause
                          : l10n.playerPlay,
                      icon: snapshot.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      locked: locked,
                      pending: isGroupCommandPending(group, isPlayPauseCommand),
                      onPressed: controller.togglePlayPause,
                    ),
                    if (current is EpisodeQueueItem)
                      IconButton(
                        key: nextKey,
                        tooltip: l10n.playerSkipForward(
                          snapshot.skipInterval.inSeconds,
                        ),
                        color: colors.content,
                        icon: const Icon(Icons.fast_forward_rounded),
                        onPressed: controller.skipForward,
                      )
                    else
                      TransportButton(
                        key: nextKey,
                        label: l10n.playerNext,
                        icon: Icons.skip_next_rounded,
                        locked: locked,
                        pending: isGroupCommandPending(
                          group,
                          (command) => command is NextCommand,
                        ),
                        onPressed: controller.next,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calls [onOpen] when a vertical drag over [child] goes up far or fast
/// enough (see [MiniPlayer]).
class _SwipeUp extends StatefulWidget {
  const new({required this.onOpen, required this.child});

  final VoidCallback? onOpen;
  final Widget child;

  @override
  State<_SwipeUp> createState() => _SwipeUpState();
}

class _SwipeUpState extends State<_SwipeUp> {
  double _dy = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.onOpen == null) return widget.child;
    return RawGestureDetector(
      gestures: {
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              VerticalDragGestureRecognizer.new,
              (recognizer) {
                recognizer
                  // The distance counts from where the pointer went down.
                  ..dragStartBehavior = DragStartBehavior.down
                  ..gestureSettings = const DeviceGestureSettings(
                    touchSlop: MiniPlayer.dragSlop,
                  )
                  ..onStart = _start
                  ..onUpdate = _update
                  ..onEnd = _end;
              },
            ),
      },
      child: widget.child,
    );
  }

  void _start(DragStartDetails details) => _dy = 0;

  void _update(DragUpdateDetails details) => _dy += details.delta.dy;

  void _end(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dy < -MiniPlayer.openDragDistance ||
        velocity < -MiniPlayer.openFlingVelocity) {
      widget.onOpen?.call();
    }
    _dy = 0;
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
