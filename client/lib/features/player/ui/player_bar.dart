// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/podcast_settings.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/features/listen_together/listen_together.dart';
import 'package:soundspan/features/player/ui/player_item.dart';
import 'package:soundspan/features/player/ui/right_panel.dart';
import 'package:soundspan/features/player/ui/seek_bar.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/group_controls.dart';
import 'package:soundspan/shared/widgets/quality_badge.dart';

/// The player of expanded windows, at least [minHeight] high on
/// `surfaceRaised` (doc 09, Components).
///
/// Left: the current item's artwork, title, artist and [QualityBadge].
/// Centre: the [PlayerTransport] (for a track shuffle, previous,
/// play/pause, next and repeat; for an episode skip back and forward and
/// the speed), with the [SeekBar] and the elapsed and total times beneath.
/// Right: the lyrics button, which toggles the lyrics in the right panel
/// (hidden for an episode), the queue button, which toggles the queue
/// there, the expand button,
/// which shows and hides the now-playing overlay, and the volume slider.
/// It reads only the playback controller's snapshots and calls its
/// commands; position changes rebuild the seek bar alone. It renders
/// nothing while the queue is empty.
class PlayerBar extends ConsumerWidget {
  /// Creates the player bar.
  const new({super.key});

  /// The height of the bar at text scale 1.0; larger text makes it taller.
  static const double minHeight = 96;

  /// The size of the play/pause circle.
  static const double playButtonSize = 48;

  /// The edge length of the artwork.
  static const double artworkSize = 56;

  /// The width of the volume slider.
  static const double volumeWidth = 128;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playbackStateProvider).value;
    final current = snapshot?.current;
    if (snapshot == null || current == null) return const SizedBox.shrink();
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: colors.surfaceRaised,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.large)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.x16,
            vertical: Spacing.x8,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: typography.body.copyWith(
                              color: colors.content,
                            ),
                          ),
                          Text(
                            current.playerSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: typography.bodySmall.copyWith(
                              color: colors.contentSecondary,
                            ),
                          ),
                          if (snapshot.quality case final quality?) ...[
                            const SizedBox(height: Spacing.x4),
                            QualityBadge(info: quality),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.x16),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayerTransport(snapshot: snapshot),
                    const _PlayerBarProgress(),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.x16),
              const Expanded(
                flex: 3,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [_PanelButtons(), _VolumeControl()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shuffle, previous, play/pause, next and repeat, calling the playback
/// controller; for an episode, skip back, play/pause, skip forward and the
/// speed menu instead (doc 06, Podcasts).
class PlayerTransport extends ConsumerWidget {
  /// Creates the controls for [snapshot], with a play/pause circle
  /// [playButtonSize] across.
  const new({
    required this.snapshot,
    this.playButtonSize = PlayerBar.playButtonSize,
    super.key,
  });

  /// The playback state shown.
  final PlaybackSnapshot snapshot;

  /// The diameter of the play/pause circle.
  final double playButtonSize;

  /// The key of the episode speed menu button.
  static const Key speedKey = Key('player.speed');

  /// The key of the previous button.
  static const Key previousKey = Key('player.previous');

  /// The key of the play/pause button.
  static const Key playPauseKey = Key('player.playPause');

  /// The key of the next button.
  static const Key nextKey = Key('player.next');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(playbackControllerProvider);
    if (snapshot.current is EpisodeQueueItem) {
      final seconds = snapshot.skipInterval.inSeconds;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keeps play/pause centred against the speed button.
          const SizedBox(width: _speedButtonWidth),
          IconButton(
            tooltip: l10n.playerSkipBack(seconds),
            color: colors.content,
            icon: const Icon(Icons.fast_rewind_rounded),
            onPressed: controller.skipBackward,
          ),
          const SizedBox(width: Spacing.x4),
          PlayPauseButton(
            snapshot: snapshot,
            size: playButtonSize,
            onPressed: controller.togglePlayPause,
          ),
          const SizedBox(width: Spacing.x4),
          IconButton(
            tooltip: l10n.playerSkipForward(seconds),
            color: colors.content,
            icon: const Icon(Icons.fast_forward_rounded),
            onPressed: controller.skipForward,
          ),
          SizedBox(
            width: _speedButtonWidth,
            child: _SpeedButton(
              key: speedKey,
              speed: snapshot.speed,
              onSelected: (speed) =>
                  controller.setEpisodeSpeed(speed, remember: true),
            ),
          ),
        ],
      );
    }
    final queue = snapshot.queue;
    final shuffled = queue.isShuffled;
    final repeat = queue.repeat;
    final repeatLabel = switch (repeat) {
      RepeatMode.off => l10n.playerRepeatOff,
      RepeatMode.all => l10n.playerRepeatAll,
      RepeatMode.one => l10n.playerRepeatOne,
    };
    // In a Listen Together group the group has no shuffle or repeat, and a
    // follower cannot use the transport (doc 08, Commands From This Device).
    final attached = snapshot.remoteAttached;
    final locked = attached && !snapshot.remoteCanControl;
    final group = ref.watch(attachedListenTogetherProvider);
    bool pending(bool Function(PlaybackCommand) test) =>
        isGroupCommandPending(group, test);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!attached)
          _ToggleButton(
            on: shuffled,
            label: l10n.playerShuffle,
            icon: Icons.shuffle_rounded,
            onPressed: () => controller.setShuffle(!shuffled),
          ),
        TransportButton(
          key: previousKey,
          label: l10n.playerPrevious,
          icon: Icons.skip_previous_rounded,
          locked: locked,
          pending: pending((command) => command is PreviousCommand),
          onPressed: controller.previous,
        ),
        const SizedBox(width: Spacing.x4),
        HostControlled(
          locked: locked,
          child: PlayPauseButton(
            key: playPauseKey,
            snapshot: snapshot,
            size: playButtonSize,
            pending: pending(isPlayPauseCommand),
            onPressed: locked ? null : controller.togglePlayPause,
          ),
        ),
        const SizedBox(width: Spacing.x4),
        TransportButton(
          key: nextKey,
          label: l10n.playerNext,
          icon: Icons.skip_next_rounded,
          locked: locked,
          pending: pending((command) => command is NextCommand),
          onPressed: controller.next,
        ),
        if (!attached)
          _ToggleButton(
            on: repeat != RepeatMode.off,
            label: repeatLabel,
            icon: repeat == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            onPressed: () => controller.setRepeat(nextRepeatMode(repeat)),
          ),
      ],
    );
  }
}

/// A transport icon button labelled [label]: disabled with the host's
/// tooltip while [locked], its icon replaced by a spinner while [pending]
/// (the button stays focusable).
class TransportButton extends StatelessWidget {
  /// Creates the button.
  const new({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.locked = false,
    this.pending = false,
    this.color,
    super.key,
  });

  /// The button's label and, unless locked, its tooltip.
  final String label;

  /// The icon.
  final IconData icon;

  /// What a press does.
  final VoidCallback onPressed;

  /// Whether only the group's host may use the control.
  final bool locked;

  /// Whether the control's command awaits the group's acknowledgement.
  final bool pending;

  /// The icon colour; `content` by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.content;
    return HostControlled(
      locked: locked,
      child: IconButton(
        tooltip: locked ? null : label,
        color: color,
        icon: pending
            ? Semantics(
                label: label,
                child: GroupCommandSpinner(color: color),
              )
            : Icon(icon, semanticLabel: locked ? label : null),
        onPressed: locked ? null : onPressed,
      ),
    );
  }
}

const double _speedButtonWidth = 56;

/// The episode speed, as a button opening the menu of
/// [episodeSpeedOptions].
class _SpeedButton extends StatelessWidget {
  const new({required this.speed, required this.onSelected, super.key});

  final double speed;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<double>(
      tooltip: l10n.playerSpeed,
      initialValue: speed,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in episodeSpeedOptions)
          CheckedPopupMenuItem<double>(
            value: option,
            checked: option == speed,
            child: Text(l10n.playerSpeedValue(option)),
          ),
      ],
      child: SizedBox(
        height: Sizes.touchTarget,
        child: Center(
          child: Text(
            l10n.playerSpeedValue(speed),
            style: typography.bodySmall.tabular.copyWith(color: colors.content),
          ),
        ),
      ),
    );
  }
}

/// The repeat mode a tap on the repeat button sets: off, all, one, off.
RepeatMode nextRepeatMode(RepeatMode mode) => switch (mode) {
  RepeatMode.off => RepeatMode.all,
  RepeatMode.all => RepeatMode.one,
  RepeatMode.one => RepeatMode.off,
};

/// An icon button in `positive` (or [onColor]) while [on], else
/// `contentSecondary`.
class _ToggleButton extends StatelessWidget {
  const new({
    required this.on,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.onColor,
  });

  final bool on;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? onColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: Semantics(
        toggled: on,
        child: IconButton(
          tooltip: label,
          color: on ? onColor ?? colors.positive : colors.contentSecondary,
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// The play/pause circle: [size] across in `transport` with the icon in
/// `onTransport`, ringed by a progress indicator while the item loads or
/// buffers with the play intent set.
class PlayPauseButton extends StatelessWidget {
  /// Creates the button for [snapshot].
  const new({
    required this.snapshot,
    required this.onPressed,
    this.size = PlayerBar.playButtonSize,
    this.pending = false,
    super.key,
  });

  /// The playback state shown.
  final PlaybackSnapshot snapshot;

  /// The diameter of the circle: [PlayerBar.playButtonSize] on the player
  /// bar, larger on now playing.
  final double size;

  /// Toggles play and pause; null disables the button (a Listen Together
  /// follower).
  final VoidCallback? onPressed;

  /// Whether a play or pause command awaits the group's acknowledgement:
  /// the icon is replaced by a spinner.
  final bool pending;

  /// The key of the progress ring.
  static const Key ringKey = Key('player.playPause.ring');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final label = snapshot.playing ? l10n.playerPause : l10n.playerPlay;
    final waiting =
        snapshot.playing &&
        (snapshot.status == EngineStatus.loading ||
            snapshot.status == EngineStatus.buffering);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: onPressed == null ? null : label,
            style: IconButton.styleFrom(
              backgroundColor: colors.transport,
              foregroundColor: colors.onTransport,
              disabledBackgroundColor: colors.surfaceActive,
              disabledForegroundColor: colors.contentDisabled,
              fixedSize: Size.square(size),
            ),
            iconSize: size / 2,
            icon: pending
                ? Semantics(
                    label: label,
                    child: GroupCommandSpinner(color: colors.onTransport),
                  )
                : Icon(
                    snapshot.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    semanticLabel: onPressed == null ? label : null,
                  ),
            onPressed: onPressed,
          ),
          if (waiting)
            Positioned.fill(
              child: IgnorePointer(
                child: CircularProgressIndicator(
                  key: ringKey,
                  strokeWidth: 2,
                  color: colors.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The seek bar with the times; the only part of the bar that rebuilds as
/// the position moves.
class _PlayerBarProgress extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(playbackSnapshotProvider).value;
    if (snapshot == null) return const SizedBox(height: SeekBar.height);
    final locked = snapshot.remoteAttached && !snapshot.remoteCanControl;
    return HostControlled(
      locked: locked,
      child: SeekBar(
        position: snapshot.position,
        buffered: snapshot.buffered,
        duration: snapshot.duration,
        status: snapshot.status,
        playing: snapshot.playing,
        onSeek: locked ? null : ref.read(playbackControllerProvider).seek,
        showTimes: true,
        speed: snapshot.speed,
      ),
    );
  }
}

/// The lyrics button (not for an episode), the queue button and the
/// expand button.
class _PanelButtons extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final panel = ref.watch(rightPanelProvider);
    final queueOpen = panel == RightPanel.queue;
    final expanded = ref.watch(nowPlayingOverlayProvider);
    final episode = ref.watch(
      playbackStateProvider.select(
        (snapshot) => snapshot.value?.current is EpisodeQueueItem,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!episode)
          _ToggleButton(
            on: panel == RightPanel.lyrics,
            label: l10n.lyricsTitle,
            icon: Icons.lyrics_outlined,
            onColor: colors.brand,
            onPressed: () =>
                ref.read(rightPanelProvider.notifier).toggle(RightPanel.lyrics),
          ),
        _ToggleButton(
          on: queueOpen,
          label: l10n.nowPlayingQueue,
          icon: Icons.queue_music_rounded,
          onColor: colors.brand,
          onPressed: () =>
              ref.read(rightPanelProvider.notifier).toggle(RightPanel.queue),
        ),
        _ToggleButton(
          on: expanded,
          label: expanded ? l10n.nowPlayingCollapse : l10n.nowPlayingExpand,
          icon: expanded
              ? Icons.close_fullscreen_rounded
              : Icons.open_in_full_rounded,
          onColor: colors.brand,
          onPressed: () =>
              ref.read(nowPlayingOverlayProvider.notifier).toggle(),
        ),
      ],
    );
  }
}

/// The volume slider over the controller's user volume.
class _VolumeControl extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final controller = ref.watch(playbackControllerProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.volume_up_rounded, color: colors.contentSecondary),
        SizedBox(
          width: PlayerBar.volumeWidth,
          height: Sizes.touchTarget,
          child: ValueListenableBuilder<double>(
            valueListenable: controller.volumeListenable,
            builder: (context, volume, _) => Semantics(
              label: l10n.playerVolume,
              child: Slider(
                value: volume,
                activeColor: colors.brand,
                inactiveColor: colors.lineStrong,
                onChanged: controller.setVolume,
                semanticFormatterCallback: (value) =>
                    '${(value * 100).round()}%',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
