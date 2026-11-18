// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/shortcuts/shell_focus_groups.dart';
import 'package:soundspan/app/shell/shortcuts/shell_shortcuts.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/widgets/refresh_target.dart';

import '../../../features/player/ui/player_rig.dart';
import '../../../helpers/pump_app.dart';

/// Records what the [ShellShortcuts] callbacks and the likes received.
class ShortcutRecorder implements TrackLikes {
  /// The destination indexes opened.
  final List<int> destinations = [];

  /// How often the search field was asked for.
  int searches = 0;

  /// How often Settings was opened.
  int settings = 0;

  /// How often Back was used.
  int backs = 0;

  /// How often Forward was used.
  int forwards = 0;

  /// How often the screen was refreshed.
  int refreshes = 0;

  /// The tracks whose like was toggled.
  final List<Track> liked = [];

  @override
  Future<void> toggleLike(Track track) async => liked.add(track);
}

/// The key of the harness's text field.
const Key textFieldKey = Key('harness.text');

/// The key of the harness's button in the top bar.
const Key topBarButtonKey = Key('harness.topBar');

/// The keys of the harness's two buttons under the sidebar's destinations.
const List<Key> sidebarPlaylistKeys = [
  Key('harness.playlist.1'),
  Key('harness.playlist.2'),
];

/// The key of the harness's button in the content.
const Key contentButtonKey = Key('harness.button');

/// Pumps [ShellShortcuts] at [size] around an [AdaptiveShell] whose content
/// has a text field, a button and a refreshable list, with [rig]'s
/// controller; [back] and [forward] decide whether Back and Forward have
/// somewhere to go. The controller is created, as at profile activation.
/// With [rightPanel] the shell has a right panel and with
/// [playerBar] a player bar, each holding one button; with [topBar] a top
/// bar holding one button and with [sidebarPlaylists] two buttons under the
/// sidebar's destinations.
Future<ProviderContainer> pumpShortcuts(
  WidgetTester tester, {
  required PlayerRig rig,
  required ShortcutRecorder recorder,
  Size size = TestSizes.expanded,
  bool back = true,
  bool forward = true,
  bool rightPanel = false,
  bool playerBar = true,
  bool refreshable = true,
  bool topBar = false,
  bool sidebarPlaylists = false,
  List<Override> overrides = const [],
}) async {
  final groups = ShellFocusGroups();
  addTearDown(groups.dispose);
  final content = Column(
    children: [
      const SizedBox(width: 200, child: TextField(key: textFieldKey)),
      TextButton(
        key: contentButtonKey,
        onPressed: () {},
        child: const Text('Content'),
      ),
      Expanded(
        child: refreshable
            ? AppRefreshIndicator(
                onRefresh: () async => recorder.refreshes++,
                child: ListView(children: const [SizedBox(height: 2000)]),
              )
            : ListView(children: const [SizedBox(height: 2000)]),
      ),
    ],
  );
  final container = await tester.pumpApp(
    ShellShortcuts(
      focusGroups: groups,
      onDestinationSelected: recorder.destinations.add,
      onFocusSearch: () => recorder.searches++,
      onOpenSettings: () => recorder.settings++,
      onBack: back ? () => recorder.backs++ : null,
      onForward: forward ? () => recorder.forwards++ : null,
      child: AdaptiveShell(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        focusGroups: groups,
        topBar: topBar
            ? TextButton(
                key: topBarButtonKey,
                onPressed: () {},
                child: const Text('Top bar'),
              )
            : null,
        sidebarPlaylists: sidebarPlaylists
            ? Column(
                children: [
                  for (final key in sidebarPlaylistKeys)
                    TextButton(
                      key: key,
                      onPressed: () {},
                      child: const Text('Playlist'),
                    ),
                ],
              )
            : null,
        rightPanel: rightPanel
            ? Center(
                child: TextButton(
                  key: const Key('harness.panel'),
                  onPressed: () {},
                  child: const Text('Panel'),
                ),
              )
            : null,
        playerBar: playerBar
            ? TextButton(
                key: const Key('harness.player'),
                onPressed: () {},
                child: const Text('Player'),
              )
            : null,
        miniPlayer: playerBar
            ? TextButton(
                key: const Key('harness.player'),
                onPressed: () {},
                child: const Text('Player'),
              )
            : null,
        child: content,
      ),
    ),
    size: size,
    overrides: [
      ...rig.overrides,
      trackLikesProvider.overrideWithValue(recorder),
      ...overrides,
    ],
  );
  // The profile creates its controller when it activates.
  container.read(playbackControllerProvider);
  return container;
}
