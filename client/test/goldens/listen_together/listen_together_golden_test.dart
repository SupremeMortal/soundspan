// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart' show Consumer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/ui/listen_together_screen.dart';
import 'package:soundspan/features/player/player.dart';

import '../../features/listen_together/ui/listen_together_ui_rig.dart';
import '../../features/player/ui/player_rig.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

/// [child] at the window class of the surface.
Widget _sized(Widget child) => LayoutBuilder(
  builder: (context, constraints) => WindowClassScope(
    windowClass: windowClassOf(constraints.biggest),
    child: child,
  ),
);

/// The screen over a fake controller in [state], with the user's group and
/// one public group in the lobby.
List<Override> _screen(ListenTogetherState Function() state) {
  final controller = FakeListenTogetherController()..emit(state());
  final repository = FakeListenTogetherRepository()
    ..myGroup = sampleGroup()
    ..discovered = [sampleSummary()];
  return [
    ...listenTogetherOverrides(controller, repository),
    profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
    initialActiveProfileIdProvider.overrideWithValue(null),
  ];
}

/// A follower's paused track at 1:05 of 3:41 in a group.
final PlaybackSnapshot _follower = () {
  final item = playerItem('a');
  return PlaybackSnapshot(
    queue: QueueState(items: [item, playerItem('b')], cursor: 0),
    current: item,
    status: EngineStatus.ready,
    playing: false,
    position: const Duration(minutes: 1, seconds: 5),
    buffered: const Duration(minutes: 2),
    duration: const Duration(minutes: 3, seconds: 41),
    remoteAttached: true,
    remoteCanControl: false,
  );
}();

void main() {
  goldenMatrix(
    'listen_together_lobby',
    builder: (_) => _sized(const ListenTogetherScreen()),
    overrides: _screen(() => const ListenTogetherIdle()),
  );

  goldenMatrix(
    'listen_together_group',
    builder: (_) => _sized(const ListenTogetherScreen()),
    overrides: _screen(() => activeOf(sampleGroup(hostUserId: me))),
  );

  goldenMatrix(
    'player_bar_follower',
    sizes: const [TestSizes.expanded],
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        ref.watch(playbackControllerProvider);
        return const Align(
          alignment: Alignment.bottomCenter,
          child: PlayerBar(),
        );
      },
    ),
    overrides: [
      playbackControllerProvider.overrideWith((ref) {
        final controller = PlayerRig().controller;
        ref.onDispose(controller.dispose);
        return controller;
      }),
      playbackStateProvider.overrideWith((ref) => Stream.value(_follower)),
      playbackSnapshotProvider.overrideWith((ref) => Stream.value(_follower)),
      ..._screen(() => activeOf(sampleGroup())),
    ],
  );
}
