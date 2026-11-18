// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/widgets/like_button.dart';

/// The heart of the playing item in the players (doc 09, Components): a
/// [LikeButton] over the item's current preference, wherever the track
/// comes from. Nothing for an episode or a track without a `playbackId`.
class PlayerLikeButton extends ConsumerWidget {
  /// Creates the heart of [item].
  const new({required this.item, super.key});

  /// The key of the heart.
  static const Key likeKey = Key('player.like');

  /// The playing item.
  final QueueItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queued = switch (item) {
      TrackQueueItem(:final track) when track.playbackId != null => track,
      _ => null,
    };
    if (queued == null) return const SizedBox.shrink();
    final track = ref.watch(currentTrackProvider(queued)).value ?? queued;
    return LikeButton(
      key: likeKey,
      liked: track.isLiked,
      onToggle: toggleLikeOf(ref, track),
    );
  }
}
