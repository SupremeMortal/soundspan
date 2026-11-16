// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/app/l10n/app_locales.dart';
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
/// 24/96 kHz with shuffle on and the queue repeating.
final PlaybackSnapshot _snapshot = () {
  final item = playerItem('a');
  return PlaybackSnapshot(
    queue: QueueState(
      items: [item, playerItem('b')],
      cursor: 0,
      shuffleOrder: const [0, 1],
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
    'mini_player',
    builder: (_) => _bottom(const MiniPlayer()),
    sizes: const [TestSizes.compact, TestSizes.medium],
    overrides: _overrides,
  );
}
