// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/artist/artist.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../features/detail_fixtures.dart';
import '../../../features/library/library_harness.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/play_rig.dart';
import '../../../helpers/pump_app.dart';
import 'selection_harness.dart';

/// The selection of the track lists beyond the album and playlist pages
/// (doc 09, Desktop Interaction: Selection). The search, mix and Explore
/// lists are covered beside their screens' other tests.
void main() {
  final linux = TargetPlatformVariant.only(TargetPlatform.linux);

  /// Clicks [first], Ctrl+clicks [second] and checks both are selected and
  /// nothing played.
  Future<void> selectTwo(
    WidgetTester tester,
    PlayRig rig,
    String first,
    String second,
  ) async {
    await click(tester, first);
    await rig.settle(tester);
    expect(selectedTitles(tester), [first]);
    expect(rig.queued, isEmpty);
    await click(tester, second, modifier: LogicalKeyboardKey.controlLeft);
    expect(selectedTitles(tester), [second, first]);
  }

  testWidgets('Library Songs: click selects, Ctrl+click adds, Enter plays the '
      'selection and the menu is the selection menu', (tester) async {
    final rig = PlayRig();
    await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: FakeLibraryRepository()..trackList = tracks(5),
      size: TestSizes.expanded,
      overrides: rig.overrides,
      shellShortcuts: true,
    );

    await selectTwo(tester, rig, 'Song 3', 'Song 1');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await rig.settle(tester);

    expect(rig.queued, ['p1', 'p3']);
    expect(rig.current, 'p1');
    expect(rig.context, const QueueContext(kind: QueueContextKind.library));
    await expectSelectionMenu(tester, 'Song 3');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Liked Songs: click selects, Ctrl+click adds, Enter plays the '
      'selection and the menu is the selection menu', (tester) async {
    final rig = PlayRig();
    final repositories = FakeRepositories();
    repositories.library.likedList = [
      fixtureTrack(1),
      fixtureTrack(2),
      fixtureTrack(3),
    ];
    await pumpDetail(
      tester,
      underShellShortcuts(const PlaylistScreen(playlistId: likedPlaylistId)),
      size: TestSizes.expanded,
      repositories: repositories,
      overrides: rig.overrides,
    );

    await selectTwo(tester, rig, 'Song 1.3', 'Song 1.1');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await rig.settle(tester);

    expect(rig.queued, ['p-1-1', 'p-1-3']);
    expect(rig.current, 'p-1-1');
    expect(rig.context?.id, likedPlaylistId);
    await expectSelectionMenu(tester, 'Song 1.3');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Artist Popular: click selects, Ctrl+click adds, Enter plays '
      'the selection and the menu is the selection menu', (tester) async {
    final rig = PlayRig();
    await pumpDetail(
      tester,
      underShellShortcuts(const ArtistScreen(artistId: 'ar-1')),
      size: TestSizes.expanded,
      repositories: artistRepositories(
        fixtureArtistDetail(
          topTracks: [fixtureTrack(1), fixtureTrack(2), fixtureTrack(3)],
        ),
      ),
      overrides: rig.overrides,
    );

    await selectTwo(tester, rig, 'Song 1.3', 'Song 1.1');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await rig.settle(tester);

    expect(rig.queued, ['p-1-1', 'p-1-3']);
    expect(rig.current, 'p-1-1');
    expect(rig.context?.kind, QueueContextKind.artist);
    await expectSelectionMenu(tester, 'Song 1.3');
    await rig.close(tester);
  }, variant: linux);
}
