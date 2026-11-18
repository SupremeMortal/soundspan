// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Consumer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../a11y/screen_registry.dart';
import '../../features/player/ui/player_rig.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

/// A paused track at 1:05 of 3:41, streamed as FLAC 24/96 kHz.
final PlaybackSnapshot _snapshot = () {
  final item = playerItem('a', artistId: 'ar-1');
  return PlaybackSnapshot(
    queue: QueueState(items: [item, playerItem('b')], cursor: 0),
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

/// The player shows [_snapshot]; no profile is active.
final List<Override> _overrides = [
  initialActiveProfileIdProvider.overrideWithValue(null),
  playbackControllerProvider.overrideWith((ref) {
    final controller = PlayerRig().controller;
    ref.onDispose(controller.dispose);
    return controller;
  }),
  playbackStateProvider.overrideWith((ref) => Stream.value(_snapshot)),
  playbackSnapshotProvider.overrideWith((ref) => Stream.value(_snapshot)),
];

/// [child] once the controller exists, as it does after a play action.
Widget _withController(Widget child) => Consumer(
  builder: (context, ref, _) {
    ref.watch(playbackControllerProvider);
    return child;
  },
);

/// The shell around the Home placeholder, with the player showing.
Widget _shell(BuildContext context) => _withController(
  AppShell(
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    onSearch: (_) {},
    onBack: () {},
    child: const PlaceholderScreen('Home', branchRoot: true),
  ),
);

/// A thumbnail row with the album column from 800, and an album row.
Widget _rows(BuildContext context) => Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TrackRow(
        title: 'Come Together',
        artist: 'The Beatles',
        album: 'Abbey Road',
        duration: const Duration(minutes: 4, seconds: 19),
        leading: const TrackRowLeading.thumbnail('album-1'),
        showAlbumColumn: MediaQuery.sizeOf(context).width >= 800,
        liked: true,
        onToggleLike: () {},
        onTap: () {},
        onMenu: (_) {},
      ),
      TrackRow(
        title: 'So What',
        artist: 'Miles Davis',
        duration: const Duration(minutes: 9, seconds: 22),
        leading: const TrackRowLeading.index(2),
        onTap: () {},
        onMenu: (_) {},
      ),
    ],
  ),
);

/// Two cards, one with a title too long for its line.
Widget _cards(BuildContext context) => Padding(
  padding: const EdgeInsets.all(16),
  child: Wrap(
    spacing: 16,
    runSpacing: 16,
    children: [
      SizedBox(
        width: 160,
        child: MediaCard(
          title: 'Abbey Road',
          subtitle: 'The Beatles',
          artworkRef: 'album-1',
          onTap: () {},
        ),
      ),
      SizedBox(
        width: 160,
        child: MediaCard(
          title: 'A title far too long for one line',
          subtitle: 'An artist with a long name',
          artworkRef: 'album-2',
          onTap: () {},
        ),
      ),
    ],
  ),
);

Widget _bottom(Widget player) =>
    Align(alignment: Alignment.bottomCenter, child: player);

/// A button, a row and a card, for the focus ring.
Widget _focusables(BuildContext context) => Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FilledButton(onPressed: () {}, child: const Text('Play')),
      const SizedBox(height: 16),
      TrackRow(
        title: 'Come Together',
        artist: 'The Beatles',
        duration: const Duration(minutes: 4, seconds: 19),
        leading: const TrackRowLeading.index(1),
        onTap: () {},
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: 160,
        child: MediaCard(
          title: 'Abbey Road',
          subtitle: 'The Beatles',
          artworkRef: 'album-1',
          onTap: () {},
        ),
      ),
    ],
  ),
);

/// Presses Tab [count] times: keyboard focus on the [count]th focusable.
Future<void> Function(WidgetTester) _tab(int count) => (tester) async {
  for (var i = 0; i < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
};

const List<Size> _bothEnds = [TestSizes.compact, TestSizes.expanded];

void main() {
  // Text scale 2.0, the largest the app follows (doc 09, Typography).
  goldenMatrix(
    'a11y_shell',
    builder: _shell,
    overrides: _overrides,
    sizes: _bothEnds,
    themes: const [ThemeMode.dark],
    textScales: const [2],
  );
  goldenMatrix(
    'a11y_track_row',
    builder: _rows,
    sizes: _bothEnds,
    themes: const [ThemeMode.dark],
    textScales: const [2],
  );
  goldenMatrix(
    'a11y_media_card',
    builder: _cards,
    sizes: _bothEnds,
    themes: const [ThemeMode.dark],
    textScales: const [2],
  );
  goldenMatrix(
    'a11y_player_bar',
    builder: (_) =>
        _bottom(const Padding(padding: EdgeInsets.all(8), child: PlayerBar())),
    overrides: _overrides,
    sizes: const [TestSizes.expanded],
    themes: const [ThemeMode.dark],
    textScales: const [2],
  );
  goldenMatrix(
    'a11y_mini_player',
    builder: (_) => _bottom(const MiniPlayer()),
    overrides: _overrides,
    sizes: const [TestSizes.compact],
    themes: const [ThemeMode.dark],
    textScales: const [2],
  );
  goldenMatrix(
    'a11y_now_playing',
    builder: (_) => _withController(const NowPlayingScreen()),
    overrides: _overrides,
    sizes: const [TestSizes.compact],
    themes: const [ThemeMode.dark],
    textScales: const [2],
  );
  // Sign-in is a route of the whole app: pumped as its registry case.
  final signIn = registry.firstWhere((c) => c.name == 'Sign in');
  const signInOptions = PumpOptions(
    size: TestSizes.compact,
    theme: ThemeMode.dark,
    textScale: 2,
  );
  final signInFile = goldenFileName(
    'a11y_sign_in',
    size: signInOptions.size,
    theme: signInOptions.theme,
    textScale: signInOptions.textScale,
  );
  testWidgets(signInFile, tags: ['golden'], (tester) async {
    await signIn.pump(tester, signInOptions);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(goldenPath(signInFile)),
    );
  });

  // The high-contrast variant of both themes (doc 09, Theme mode).
  goldenMatrix(
    'a11y_shell',
    builder: _shell,
    overrides: _overrides,
    sizes: const [TestSizes.expanded],
    highContrast: const [true],
  );
  goldenMatrix(
    'a11y_track_row',
    builder: _rows,
    sizes: const [Size(800, 240)],
    highContrast: const [true],
  );

  // The focus ring on a button, a row, a card and a navigation item.
  for (final (name, tabs) in const [
    ('button', 1),
    ('track_row', 2),
    ('media_card', 3),
  ]) {
    goldenMatrix(
      'a11y_focus_$name',
      builder: _focusables,
      sizes: const [Size(390, 480)],
      act: _tab(tabs),
    );
  }
  goldenMatrix(
    'a11y_focus_navigation',
    builder: _shell,
    overrides: _overrides,
    sizes: const [TestSizes.compact],
    act: (tester) async {
      // Keyboard focus on the first navigation bar destination.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final home = find.byType(NavigationDestination).first;
      // The focus node nearest the destination's icon is its ink well's.
      Focus.of(
        tester.element(
          find.descendant(of: home, matching: find.byType(Icon)).first,
        ),
      ).requestFocus();
      await tester.pumpAndSettle();
    },
  );
}
