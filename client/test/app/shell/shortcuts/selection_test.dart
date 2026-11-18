// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../features/detail_fixtures.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/play_rig.dart';
import '../../../helpers/pump_app.dart';
import 'selection_harness.dart';

const _album = AlbumScreen(albumId: 'al-1');

Future<void> _pumpAlbum(WidgetTester tester, PlayRig rig) => pumpDetail(
  tester,
  underShellShortcuts(_album),
  size: TestSizes.expanded,
  repositories: albumRepositories([
    fixtureTrack(1),
    fixtureTrack(2),
    fixtureTrack(3),
  ]),
  overrides: rig.overrides,
);

FakeRepositories _playlist({required bool owner}) {
  final repositories = FakeRepositories();
  final items = [
    for (final n in [1, 2, 3])
      PlaylistItem(
        id: 'item-$n',
        sort: n * 10,
        track: fixtureTrack(n),
        isPlayable: true,
      ),
  ];
  repositories.playlists.playlistDetails['pl-1'] = PlaylistDetail(
    summary: PlaylistSummary(
      id: 'pl-1',
      name: 'Road Trip',
      trackCount: items.length,
      isOwner: owner,
      isPublic: true,
    ),
    items: items,
  );
  return repositories;
}

void main() {
  final linux = TargetPlatformVariant.only(TargetPlatform.linux);

  testWidgets('a click selects one row and does not play', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.1');
    await click(tester, 'Song 1.2');
    await rig.settle(tester);

    expect(selectedTitles(tester), ['Song 1.2']);
    expect(rig.queued, isEmpty);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+click toggles a row', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.1');
    await click(tester, 'Song 1.3', modifier: LogicalKeyboardKey.controlLeft);
    expect(selectedTitles(tester), ['Song 1.1', 'Song 1.3']);
    await click(tester, 'Song 1.1', modifier: LogicalKeyboardKey.controlLeft);
    expect(selectedTitles(tester), ['Song 1.3']);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Shift+click extends from the anchor', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.3');
    await click(tester, 'Song 1.1', modifier: LogicalKeyboardKey.shiftLeft);

    expect(selectedTitles(tester), ['Song 1.1', 'Song 1.2', 'Song 1.3']);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Ctrl+A selects every row and Escape clears', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.2');
    await pressWith(
      tester,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyA,
    );
    expect(selectedTitles(tester), ['Song 1.1', 'Song 1.2', 'Song 1.3']);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(selectedTitles(tester), isEmpty);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Down moves the focused row and Shift+Down and Shift+Up '
      'extend', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.1');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selectedTitles(tester), ['Song 1.1']);

    await pressWith(
      tester,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.arrowDown,
    );
    expect(selectedTitles(tester), ['Song 1.1', 'Song 1.2', 'Song 1.3']);

    await pressWith(
      tester,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.arrowUp,
    );
    expect(selectedTitles(tester), ['Song 1.1', 'Song 1.2']);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('a double click plays from that row', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await doubleClick(tester, 'Song 1.2');
    await rig.settle(tester);

    expect(rig.queued, ['p-1-1', 'p-1-2', 'p-1-3']);
    expect(rig.current, 'p-1-2');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Enter plays the selection in list order', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.3');
    await click(tester, 'Song 1.1', modifier: LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await rig.settle(tester);

    expect(rig.queued, ['p-1-1', 'p-1-3']);
    expect(rig.current, 'p-1-1');
    expect(rig.context?.kind, QueueContextKind.album);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Enter on a row outside the selection plays from that row', (
    tester,
  ) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.1');
    await click(tester, 'Song 1.2', modifier: LogicalKeyboardKey.controlLeft);
    await click(tester, 'Song 1.2', modifier: LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await rig.settle(tester);

    expect(rig.queued, ['p-1-1', 'p-1-2', 'p-1-3']);
    expect(rig.current, 'p-1-2');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Shift+Enter queues the selection next', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.1');
    await click(tester, 'Song 1.3', modifier: LogicalKeyboardKey.controlLeft);
    await pressWith(
      tester,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.enter,
    );
    await rig.settle(tester);

    expect(rig.queued, ['p-1-1', 'p-1-3']);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('the menu of a selected row lists the multi-track entries and '
      'acts on all of them', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.2');
    await click(tester, 'Song 1.3', modifier: LogicalKeyboardKey.shiftLeft);
    await tester.tap(rowOf('Song 1.3'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    for (final entry in [
      'Play now',
      'Play next',
      'Add to queue',
      'Add to playlist…',
    ]) {
      expect(find.text(entry), findsOneWidget, reason: entry);
    }
    expect(find.text('Like'), findsNothing);
    expect(find.text('Share link'), findsNothing);

    await tester.tap(find.text('Play now'));
    await rig.settle(tester);
    expect(rig.queued, ['p-1-2', 'p-1-3']);
    expect(rig.current, 'p-1-2');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('the menu of a row outside the selection acts on that row', (
    tester,
  ) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.1');
    await click(tester, 'Song 1.2', modifier: LogicalKeyboardKey.shiftLeft);
    await tester.tap(rowOf('Song 1.3'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    expect(find.text('Share link'), findsOneWidget);
    await tester.tap(find.text('Play now'));
    await rig.settle(tester);
    expect(rig.queued, ['p-1-1', 'p-1-2', 'p-1-3']);
    expect(rig.current, 'p-1-3');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('a touch tap still plays', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await tester.tap(rowOf('Song 1.2'));
    await rig.settle(tester);

    expect(rig.current, 'p-1-2');
    expect(selectedTitles(tester), isEmpty);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Delete removes the selected rows from an owned playlist', (
    tester,
  ) async {
    final repositories = _playlist(owner: true);
    await pumpDetail(
      tester,
      underShellShortcuts(const PlaylistScreen(playlistId: 'pl-1')),
      size: TestSizes.expanded,
      repositories: repositories,
    );

    await click(tester, 'Song 1.1');
    await click(tester, 'Song 1.3', modifier: LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    expect(repositories.playlists.edits, [
      'remove pl-1 item-1',
      'remove pl-1 item-3',
    ]);
  }, variant: linux);

  testWidgets('Delete does nothing in a playlist of another user', (
    tester,
  ) async {
    final repositories = _playlist(owner: false);
    await pumpDetail(
      tester,
      underShellShortcuts(const PlaylistScreen(playlistId: 'pl-1')),
      size: TestSizes.expanded,
      repositories: repositories,
    );

    await click(tester, 'Song 1.1');
    final handled = await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    expect(handled, isFalse);
    expect(repositories.playlists.edits, isEmpty);
  }, variant: linux);
}
