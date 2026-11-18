// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/sidebar_playlists.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../../features/detail_fixtures.dart';
import '../../../features/player/ui/player_rig.dart' show playerItem;
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/play_rig.dart';
import '../../../helpers/pump_app.dart';
import '../shortcuts/selection_harness.dart';

/// The playlist the user owns.
const ownedPlaylist = 'Road Trip';

/// A playlist of another user.
const otherPlaylist = 'Their Mix';

/// The expanded shell showing album `al-1` with the album `al-2` in More by
/// this artist, the sidebar playlists [ownedPlaylist] and [otherPlaylist],
/// and the queue panel.
class DndRig {
  new _(this.play, this.repositories);

  /// The playback controller.
  final PlayRig play;

  /// The fake repositories; `playlists.edits` records the adds.
  final FakeRepositories repositories;

  /// Pumps the shell: album `al-1` has tracks 1.1–1.3, and 1.4 not
  /// playable when [unplayable]; `al-2` has tracks 2.1 and 2.2. When
  /// [queued] is not empty the queue is [queued], paused, shuffled with
  /// [shuffle]; [queuePanel] opens the queue panel.
  static Future<DndRig> pump(
    WidgetTester tester, {
    List<String> queued = const ['a', 'b', 'c', 'd'],
    bool unplayable = false,
    bool shuffle = false,
    bool queuePanel = true,
    ThemeMode theme = ThemeMode.dark,
  }) async {
    final repositories = albumRepositories(
      [
        fixtureTrack(1),
        fixtureTrack(2),
        fixtureTrack(3),
        if (unplayable) fixtureTrack(4, playable: false),
      ],
      others: [fixtureAlbum('al-2')],
    );
    repositories.library.albumDetails['al-2'] = AlbumDetail(
      album: fixtureAlbum('al-2'),
      tracks: [fixtureTrack(1, disc: 2), fixtureTrack(2, disc: 2)],
      owned: true,
    );
    repositories.playlists.playlistList = const [
      PlaylistSummary(
        id: 'pl-own',
        name: ownedPlaylist,
        trackCount: 3,
        isOwner: true,
        isPublic: false,
      ),
      PlaylistSummary(
        id: 'pl-other',
        name: otherPlaylist,
        trackCount: 3,
        isOwner: false,
        isPublic: true,
      ),
    ];
    final play = PlayRig();
    await pumpDetail(
      tester,
      underShellShortcuts(
        AppShell(
          selectedIndex: 2,
          onDestinationSelected: (_) {},
          onSearch: (_) {},
          child: const AlbumScreen(albumId: 'al-1'),
        ),
      ),
      size: TestSizes.expanded,
      theme: theme,
      repositories: repositories,
      overrides: [
        ...play.overrides,
        profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
        initialActiveProfileIdProvider.overrideWithValue(null),
      ],
    );
    final rig = DndRig._(play, repositories);
    if (queued.isNotEmpty) {
      unawaited(
        play.controller.playItems([for (final id in queued) playerItem(id)]),
      );
      await play.settle(tester);
      unawaited(play.controller.pause());
      if (shuffle) unawaited(play.controller.setShuffle(true));
    }
    if (queuePanel) {
      ProviderScope.containerOf(tester.element(find.byType(AppShell)))
          .read(rightPanelProvider.notifier)
          .toggle(RightPanel.queue);
    }
    await play.settle(tester);
    return rig;
  }

  /// The adds to playlists, as `add <id> <playback ids>`.
  List<String> get edits => repositories.playlists.edits;

  /// Removes the widgets and disposes the controller.
  Future<void> close(WidgetTester tester) => play.close(tester);
}

/// The titles of the selected rows of the album's track list, in order.
List<String> albumSelection(WidgetTester tester) => [
  for (final row in tester.widgetList<TrackRow>(
    find.descendant(
      of: find.byType(AlbumScreen),
      matching: find.byType(TrackRow),
    ),
  ))
    if (row.selected) row.title,
];

/// The sidebar row of the playlist [name].
Finder sidebarRow(String name) => find.descendant(
  of: find.byType(SidebarPlaylists),
  matching: find.text(name),
);

/// The queue row of the entry [id].
Finder queueRow(String id) => find.byKey(QueueView.rowKey(id));

/// Starts a mouse drag on [from] and moves it past the drag slop.
Future<TestGesture> startDrag(
  WidgetTester tester,
  Finder from, {
  PointerDeviceKind kind = PointerDeviceKind.mouse,
}) async {
  final start = tester.getCenter(from);
  final gesture = await tester.startGesture(start, kind: kind);
  await tester.pump();
  await gesture.moveTo(start + const Offset(24, 8));
  await tester.pump();
  return gesture;
}

/// Moves [gesture] to [to] and pumps.
Future<void> hover(WidgetTester tester, TestGesture gesture, Offset to) async {
  await gesture.moveTo(to);
  await tester.pump();
}

/// Drags [from] with the mouse to [to] and releases there.
Future<void> dragTo(WidgetTester tester, Finder from, Offset to) async {
  final gesture = await startDrag(tester, from);
  await hover(tester, gesture, to);
  await gesture.up();
  await tester.pump();
}

/// The point between the bottom of queue row [id] and the next row.
Offset belowQueueRow(WidgetTester tester, String id) =>
    tester.getRect(queueRow(id)).bottomCenter;
