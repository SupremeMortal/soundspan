// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/widgets/group_controls.dart';
import 'package:soundspan/shared/widgets/like_button.dart';

/// The actions of an album, artist or playlist page (doc 09, Components:
/// `ActionBar`), for the actions slot of `DetailHeader`.
///
/// Play is an `accent` pill; Shuffle, Like, Add to playlist, Save as
/// playlist and the overflow ("More options") are icon buttons with
/// tooltips. A button whose callback is null is left out, except Save as
/// playlist, which [saveAsPlaylist] shows and a null callback disables. The buttons wrap onto a second line rather
/// than overflow, and are centred on compact windows like the header text.
///
/// In a Listen Together group Play and Shuffle replace the group's queue:
/// they ask first, and are disabled with "The host controls playback"
/// where only the host may.
class ActionBar extends ConsumerWidget {
  /// Creates the bar.
  const new({
    this.onPlay,
    this.onShuffle,
    this.download,
    this.liked = false,
    this.onToggleLike,
    this.onAddToPlaylist,
    this.saveAsPlaylist = false,
    this.onSaveAsPlaylist,
    this.onMenu,
    super.key,
  });

  /// Plays the page's collection from its start.
  final VoidCallback? onPlay;

  /// Plays it shuffled.
  final VoidCallback? onShuffle;

  /// The Download button (the downloads feature's), after Shuffle; left out
  /// when null, such as where the platform does not download.
  final Widget? download;

  /// Whether the heart is filled.
  final bool liked;

  /// Likes or removes the like (albums).
  final VoidCallback? onToggleLike;

  /// Adds every playable track to a playlist.
  final VoidCallback? onAddToPlaylist;

  /// Whether the Save as playlist button shows (mixes).
  final bool saveAsPlaylist;

  /// Saves the collection as a new playlist; while null a shown Save as
  /// playlist button is disabled.
  final VoidCallback? onSaveAsPlaylist;

  /// Opens the page's entity menu at the given global position.
  final void Function(Offset position)? onMenu;

  /// The key of the Play pill.
  static const Key playKey = ValueKey('ActionBar.play');

  /// The key of the Shuffle button.
  static const Key shuffleKey = ValueKey('ActionBar.shuffle');

  /// The key of the Like button.
  static const Key likeKey = ValueKey('ActionBar.like');

  /// The key of the Add to playlist button.
  static const Key addToPlaylistKey = ValueKey('ActionBar.addToPlaylist');

  /// The key of the Save as playlist button.
  static const Key saveAsPlaylistKey = ValueKey('ActionBar.saveAsPlaylist');

  /// The key of the overflow button.
  static const Key menuKey = ValueKey('ActionBar.menu');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final compact = WindowClass.of(context) == WindowClass.compact;
    final locked = hostControlsPlayback(ref);
    final attached = remotePlaybackAttached(ref);
    VoidCallback? replacing(VoidCallback? play) => switch (play) {
      null => null,
      _ when locked => () {},
      _ when attached => () => unawaited(() async {
        if (await confirmReplaceGroupQueue(context, ref)) play();
      }()),
      _ => play,
    };
    final onPlay = replacing(this.onPlay);
    final onShuffle = replacing(this.onShuffle);
    final download = this.download;
    final onToggleLike = this.onToggleLike;
    final onAddToPlaylist = this.onAddToPlaylist;
    final onMenu = this.onMenu;
    Widget icon({
      required Key key,
      required IconData glyph,
      required String tooltip,
      required VoidCallback? onPressed,
    }) => MergeSemantics(
      child: Semantics(
        label: tooltip,
        child: IconButton(
          key: key,
          tooltip: tooltip,
          color: colors.contentSecondary,
          icon: Icon(glyph),
          onPressed: onPressed,
        ),
      ),
    );
    return Wrap(
      alignment: compact ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.x8,
      runSpacing: Spacing.x8,
      children: [
        if (onPlay != null)
          HostControlled(
            locked: locked,
            child: FilledButton.icon(
              key: playKey,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                shape: Radii.pill,
                minimumSize: const Size(0, Sizes.touchTarget),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.x24),
                textStyle: context.typography.subtitle,
              ),
              onPressed: locked ? null : onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.actionPlay),
            ),
          ),
        if (onShuffle != null)
          HostControlled(
            locked: locked,
            child: icon(
              key: shuffleKey,
              glyph: Icons.shuffle_rounded,
              tooltip: l10n.actionShuffle,
              onPressed: locked ? null : onShuffle,
            ),
          ),
        ?download,
        if (onToggleLike != null)
          KeyedSubtree(
            key: likeKey,
            child: LikeButton(liked: liked, onToggle: onToggleLike),
          ),
        if (onAddToPlaylist != null)
          icon(
            key: addToPlaylistKey,
            glyph: Icons.playlist_add_rounded,
            tooltip: l10n.actionAddToPlaylist,
            onPressed: onAddToPlaylist,
          ),
        if (saveAsPlaylist)
          icon(
            key: saveAsPlaylistKey,
            glyph: Icons.library_add_rounded,
            tooltip: l10n.actionSaveAsPlaylist,
            onPressed: onSaveAsPlaylist,
          ),
        if (onMenu != null)
          Builder(
            builder: (context) => icon(
              key: menuKey,
              glyph: Icons.more_horiz_rounded,
              tooltip: l10n.menuMoreOptions,
              onPressed: () {
                final box = context.findRenderObject()! as RenderBox;
                onMenu(box.localToGlobal(box.size.bottomCenter(Offset.zero)));
              },
            ),
          ),
      ],
    );
  }
}
