// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';

/// The place of the [PlayerBar] on expanded windows: across the bottom,
/// separated from the panels above by [Spacing.x8] of `ground`.
///
/// It takes no space while the queue is empty, outside a profile, and until
/// the profile's playback controller exists: the slot does not create it.
class PlayerBarSlot extends ConsumerWidget {
  /// Creates the slot.
  const new({super.key});

  /// The height of the player bar at text scale 1.0.
  static const double height = PlayerBar.minHeight;

  /// The key of the player bar.
  static const Key panelKey = Key('shell.playerBar');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(playbackControllerProvider.exists)) {
      return const SizedBox.shrink();
    }
    final hasQueue = ref.watch(
      playbackStateProvider.select((state) => state.value?.current != null),
    );
    if (!hasQueue) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.fromLTRB(Spacing.x8, 0, Spacing.x8, Spacing.x8),
      child: PlayerBar(key: panelKey),
    );
  }
}

/// The place of the [MiniPlayer] on compact and medium windows; a tap on
/// the player pushes `/now-playing`.
///
/// It takes no space while the queue is empty, outside a profile, and until
/// the profile's playback controller exists: the slot does not create it.
class MiniPlayerSlot extends ConsumerWidget {
  /// Creates the slot.
  const new({super.key});

  /// The key of the mini player.
  static const Key slotKey = Key('shell.miniPlayer');

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(playbackControllerProvider.exists)
      ? MiniPlayer(
          key: slotKey,
          onOpen: () =>
              unawaited(GoRouter.of(context).push<void>(RoutePaths.nowPlaying)),
        )
      : const SizedBox(key: slotKey, height: 0, width: double.infinity);
}
