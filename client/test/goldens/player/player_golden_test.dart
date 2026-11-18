// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, Consumer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart' show WidgetTester, find;
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
import '../../helpers/fake_lyrics_repository.dart';
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

/// [_snapshot] playing from a file downloaded at high quality.
final PlaybackSnapshot _downloadedSnapshot = PlaybackSnapshot(
  queue: _snapshot.queue,
  current: _snapshot.current,
  status: _snapshot.status,
  playing: _snapshot.playing,
  position: _snapshot.position,
  buffered: _snapshot.buffered,
  duration: _snapshot.duration,
  quality: StreamQualityInfo.downloaded(quality: 'high'),
  isLocalFile: true,
);

/// A paused episode at 12:30 of 48:00, at 1.5× with a 30-second skip.
final PlaybackSnapshot _episodeSnapshot = () {
  final item = playerEpisode('e');
  return PlaybackSnapshot(
    queue: QueueState(items: [item], cursor: 0),
    current: item,
    status: EngineStatus.ready,
    playing: false,
    position: const Duration(minutes: 12, seconds: 30),
    buffered: const Duration(minutes: 20),
    duration: const Duration(minutes: 48),
    speed: 1.5,
    skipInterval: const Duration(seconds: 30),
  );
}();

/// The overrides of the player goldens, showing [snapshot].
List<Override> _overridesOf(PlaybackSnapshot snapshot) => [
  playbackControllerProvider.overrideWith((ref) {
    final controller = PlayerRig().controller;
    ref.onDispose(controller.dispose);
    return controller;
  }),
  playbackStateProvider.overrideWith((ref) => Stream.value(snapshot)),
  playbackSnapshotProvider.overrideWith((ref) => Stream.value(snapshot)),
];

final List<Override> _overrides = [
  playbackControllerProvider.overrideWith((ref) {
    final controller = PlayerRig().controller;
    ref.onDispose(controller.dispose);
    return controller;
  }),
  playbackStateProvider.overrideWith((ref) => Stream.value(_snapshot)),
  playbackSnapshotProvider.overrideWith((ref) => Stream.value(_snapshot)),
];

/// Synced lyrics of "Song a" around the position of [_snapshot], 1:05.
final List<Override> _lyrics = [
  lyricsRepositoryProvider.overrideWithValue(
    AsyncData(
      FakeLyricsRepository()
        ..byTitle['Song a'] = SyncedLyrics([
          for (final (index, text) in const [
            'The morning light comes through',
            'Across the quiet street',
            '',
            'We walk the long way home',
            'With nothing left to keep',
            'And every song we sang',
            'Is echoing in me',
            'So hold the line tonight',
            'Until the sound is free',
          ].indexed)
            LyricLine(
              time: Duration(seconds: 45 + 5 * index),
              text: text,
            ),
        ]),
    ),
  ),
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

/// The right panel showing the lyrics.
class _LyricsOpen extends RightPanelNotifier {
  @override
  RightPanel build() => RightPanel.lyrics;
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

/// A page with the mini player under a [NowPlayingSheetPage] held open.
Widget _sheetOverPage() => _withController(
  Navigator(
    pages: [
      MaterialPage<void>(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (var i = 1; i <= 12; i++)
                    ListTile(title: Text('Page row $i')),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
      const NowPlayingSheetPage(child: NowPlayingScreen()),
    ],
    onDidRemovePage: (_) {},
  ),
);

/// Holds a drag on the now playing drag handle 30 % of the height down.
Future<void> _holdDragDown(WidgetTester tester) async {
  final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(NowPlayingScreen.dragHandleKey)),
  );
  for (var i = 0; i < 10; i++) {
    await gesture.moveBy(Offset(0, 0.03 * height));
    await tester.pump();
  }
}

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
    'lyrics_panel',
    builder: (_) => _shell(),
    sizes: const [TestSizes.expanded],
    overrides: [
      ..._overrides,
      ..._lyrics,
      initialActiveProfileIdProvider.overrideWithValue(null),
      rightPanelProvider.overrideWith(_LyricsOpen.new),
    ],
  );

  goldenMatrix(
    'lyrics_sheet',
    builder: (_) => _withController(const NowPlayingScreen()),
    sizes: const [TestSizes.compact],
    overrides: [..._overrides, ..._lyrics],
    act: (tester) async {
      await tester.tap(find.byTooltip('Lyrics'));
      await tester.pumpAndSettle();
    },
  );

  goldenMatrix(
    'lyrics_sheet',
    builder: (_) => _withController(const NowPlayingScreen()),
    sizes: const [TestSizes.compact],
    themes: const [ThemeMode.dark],
    textScales: const [2.0],
    overrides: [..._overrides, ..._lyrics],
    act: (tester) async {
      await tester.tap(find.byTooltip('Lyrics'));
      await tester.pumpAndSettle();
    },
  );

  goldenMatrix(
    'now_playing_lyrics_landscape',
    builder: (_) => _withController(const NowPlayingScreen()),
    sizes: const [_mediumLandscape],
    overrides: [..._overrides, ..._lyrics],
    act: (tester) async {
      await tester.tap(find.widgetWithText(Tab, 'Lyrics'));
      await tester.pumpAndSettle();
    },
  );

  goldenMatrix(
    'lyrics_overlay',
    builder: (_) => _shell(),
    sizes: const [TestSizes.expanded],
    overrides: [
      ..._overrides,
      ..._lyrics,
      initialActiveProfileIdProvider.overrideWithValue(null),
      nowPlayingOverlayProvider.overrideWith(_OverlayShown.new),
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
    'player_bar_episode',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    overrides: _overridesOf(_episodeSnapshot),
  );

  goldenMatrix(
    'now_playing_episode',
    builder: (_) => _withController(const NowPlayingScreen()),
    sizes: const [TestSizes.compact],
    overrides: _overridesOf(_episodeSnapshot),
  );

  // The compact bar of desktop pointer input: every transport button,
  // play/pause included, 32 px square.
  goldenMatrix(
    'player_bar_pointer',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    overrides: _overrides,
    platform: TargetPlatform.linux,
  );

  goldenMatrix(
    'player_bar_pointer',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    themes: const [ThemeMode.dark],
    textScales: const [2.0],
    overrides: _overrides,
    platform: TargetPlatform.linux,
  );

  goldenMatrix(
    'player_bar_pointer',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    themes: const [ThemeMode.dark],
    textScales: const [1.0, 2.0],
    locales: const [pseudoLocale, Locale('ar')],
    overrides: _overrides,
    platform: TargetPlatform.linux,
  );

  goldenMatrix(
    'player_bar_episode_pointer',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    themes: const [ThemeMode.dark],
    overrides: _overridesOf(_episodeSnapshot),
    platform: TargetPlatform.linux,
  );

  goldenMatrix(
    'player_bar_downloaded',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    sizes: const [TestSizes.expanded],
    overrides: _overridesOf(_downloadedSnapshot),
  );

  goldenMatrix(
    'now_playing_mid_drag',
    builder: (_) => _sheetOverPage(),
    sizes: const [TestSizes.compact],
    overrides: _overrides,
    act: _holdDragDown,
  );

  goldenMatrix(
    'mini_player',
    builder: (_) => _bottom(const MiniPlayer()),
    sizes: const [TestSizes.compact, TestSizes.medium],
    overrides: _overrides,
  );
}
