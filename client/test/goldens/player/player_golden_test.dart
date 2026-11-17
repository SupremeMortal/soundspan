// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart' show Consumer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/features/player/player.dart';

import '../../features/player/ui/player_rig.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

/// A paused track at 1:05 of 3:41, buffered to 2:00, streamed as FLAC
/// 24/96 kHz with shuffle on and the queue of four repeating.
final PlaybackSnapshot _snapshot = () {
  final item = playerItem('a', artistId: 'ar-1');
  return PlaybackSnapshot(
    queue: QueueState(
      items: [item, playerItem('b'), playerItem('c'), playerItem('d')],
      cursor: 0,
      shuffleOrder: const [0, 1, 2, 3],
      repeat: RepeatMode.all,
    ),
    current: item,
    status: EngineStatus.ready,
    playing: false,
    position: const Duration(minutes: 1, seconds: 5),
    buffered: const Duration(minutes: 2),
    duration: const Duration(minutes: 3, seconds: 41),
    quality: const StreamQualityInfo(
      quality: 'original',
      codec: 'flac',
      bitDepth: 24,
      sampleRate: 96000,
    ),
  );
}();

final List<Override> _overrides = [
  playbackControllerProvider.overrideWith((ref) {
    final controller = PlayerRig().controller;
    ref.onDispose(controller.dispose);
    return controller;
  }),
  playbackStateProvider.overrideWith((ref) => Stream.value(_snapshot)),
  playbackSnapshotProvider.overrideWith((ref) => Stream.value(_snapshot)),
];

Widget _bottom(Widget player) =>
    Align(alignment: Alignment.bottomCenter, child: player);

/// [child] once the controller exists, as it does after a play action.
Widget _withController(Widget child) => Consumer(
  builder: (context, ref, _) {
    ref.watch(playbackControllerProvider);
    return child;
  },
);

/// The right panel showing the queue.
class _QueueOpen extends RightPanelNotifier {
  @override
  RightPanel build() => RightPanel.queue;
}

/// The now-playing overlay shown.
class _OverlayShown extends NowPlayingOverlayNotifier {
  @override
  bool build() => true;
}

/// The expanded shell around an empty content area.
Widget _shell() => _withController(
  AppShell(
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    onSearch: (_) {},
    child: const SizedBox.expand(),
  ),
);

/// A medium window held in landscape.
const Size _mediumLandscape = Size(800, 600);

void main() {
  goldenMatrix(
    'player_bar',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    overrides: _overrides,
  );

  goldenMatrix(
    'player_bar',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    themes: const [ThemeMode.dark],
    textScales: const [2.0],
    overrides: _overrides,
  );

  goldenMatrix(
    'player_bar',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    themes: const [ThemeMode.dark],
    locales: const [pseudoLocale, Locale('ar')],
    overrides: _overrides,
  );

  goldenMatrix(
    'now_playing',
    builder: (_) => _withController(const NowPlayingScreen()),
    sizes: const [TestSizes.compact, TestSizes.medium],
    overrides: _overrides,
  );

  goldenMatrix(
    'now_playing',
    builder: (_) => _withController(const NowPlayingScreen()),
    sizes: const [TestSizes.compact],
    themes: const [ThemeMode.dark],
    locales: const [pseudoLocale, Locale('ar')],
    overrides: _overrides,
  );

  goldenMatrix(
    'now_playing_landscape',
    builder: (_) => _withController(const NowPlayingScreen()),
    sizes: const [_mediumLandscape],
    overrides: _overrides,
  );

  goldenMatrix(
    'queue_panel',
    builder: (_) => _shell(),
    sizes: const [TestSizes.expanded],
    overrides: [
      ..._overrides,
      initialActiveProfileIdProvider.overrideWithValue(null),
      rightPanelProvider.overrideWith(_QueueOpen.new),
    ],
  );

  goldenMatrix(
    'now_playing_overlay',
    builder: (_) => _shell(),
    sizes: const [TestSizes.expanded],
    overrides: [
      ..._overrides,
      initialActiveProfileIdProvider.overrideWithValue(null),
      nowPlayingOverlayProvider.overrideWith(_OverlayShown.new),
    ],
  );

  goldenMatrix(
    'mini_player',
    builder: (_) => _bottom(const MiniPlayer()),
    sizes: const [TestSizes.compact, TestSizes.medium],
    overrides: _overrides,
  );
}
