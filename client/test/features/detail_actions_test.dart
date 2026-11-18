// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart' show PointerDeviceKind, kSecondaryButton;
import 'package:flutter/semantics.dart'
    show CustomSemanticsAction, SemanticsAction;
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/features/artist/artist.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/guidelines.dart';
import '../helpers/play_rig.dart';
import '../helpers/pump_app.dart';
import 'detail_fixtures.dart';
import 'library/library_harness.dart';

const _album = AlbumScreen(albumId: 'al-1');
const _artist = ArtistScreen(artistId: 'ar-1');

PlaylistDetail _playlist({bool owner = true}) => PlaylistDetail(
  summary: PlaylistSummary(
    id: 'pl-1',
    name: 'Road Trip',
    trackCount: 3,
    isOwner: owner,
    isPublic: false,
  ),
  items: [
    for (var n = 1; n <= 3; n++)
      PlaylistItem(
        id: 'item-$n',
        sort: n,
        track: fixtureTrack(n),
        isPlayable: true,
      ),
  ],
);

FakeRepositories _playlistRepositories({bool owner = true}) {
  final repositories = FakeRepositories(
    playlists: FakePlaylistRepository()..playlistList = playlists(2),
  );
  repositories.playlists.playlistDetails['pl-1'] = _playlist(owner: owner);
  return repositories;
}

/// The menu entry ids shown, in order.
List<String> _entries(WidgetTester tester) => [
  for (final element
      in find
          .byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith('menu.'),
          )
          .evaluate())
    (element.widget.key! as ValueKey<String>).value.substring(5),
];

Future<void> _choose(WidgetTester tester, String id, [PlayRig? rig]) async {
  await tester.tap(find.byKey(ValueKey('menu.$id')));
  if (rig != null) {
    await rig.settle(tester);
  } else {
    await tester.pumpAndSettle();
  }
}

/// Opens the menu of the row [title]; with a [rig], whose playing row
/// animates, it settles by pumping.
Future<void> _openRowMenu(
  WidgetTester tester,
  String title, [
  PlayRig? rig,
]) async {
  await tester.tap(
    find.descendant(
      of: find.widgetWithText(TrackRow, title),
      matching: find.byKey(TrackRow.overflowKey),
    ),
  );
  if (rig != null) {
    await rig.settle(tester);
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
}

/// Records the text written to the clipboard.
List<String> _clipboard(WidgetTester tester) {
  final written = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        written.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return written;
}

void main() {
  group('album page', () {
    testWidgets('Play and Shuffle play the album', (tester) async {
      final rig = PlayRig();
      await pumpDetail(
        tester,
        _album,
        repositories: albumRepositories([fixtureTrack(1), fixtureTrack(2)]),
        overrides: rig.overrides,
      );
      await tester.tap(find.byKey(ActionBar.playKey));
      await rig.settle(tester);
      expect(rig.queued, ['p-1-1', 'p-1-2']);
      expect(rig.current, 'p-1-1');
      expect(rig.context?.kind, QueueContextKind.album);
      expect(rig.controller.snapshot.queue.isShuffled, isFalse);

      await tester.tap(find.byKey(ActionBar.shuffleKey));
      await rig.settle(tester);
      expect(rig.controller.snapshot.queue.isShuffled, isTrue);
      expect(rig.queued.toSet(), {'p-1-1', 'p-1-2'});
      await rig.close(tester);
    });

    testWidgets('Like toggles the album like through the like command', (
      tester,
    ) async {
      final repositories = albumRepositories([fixtureTrack(1)]);
      await pumpDetail(tester, _album, repositories: repositories);
      await tester.tap(find.byKey(ActionBar.likeKey));
      await tester.pump();
      expect(repositories.albumLikes.changes, ['al-1 true']);
    });

    testWidgets('Add to playlist adds every playable track', (tester) async {
      final repositories = albumRepositories([
        fixtureTrack(1),
        fixtureTrack(2, playable: false),
        fixtureTrack(3),
      ]);
      repositories.playlists.playlistList = playlists(2);
      await pumpDetail(tester, _album, repositories: repositories);
      await tester.tap(find.byKey(ActionBar.addToPlaylistKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Playlist 1'));
      await tester.pumpAndSettle();
      expect(repositories.playlists.edits, ['add pl1 p-1-1,p-1-3']);
      expect(find.text('Added 2 songs to Playlist 1'), findsOneWidget);
    });

    testWidgets('an album with no playable track has only Like and the '
        'overflow', (tester) async {
      await pumpDetail(
        tester,
        _album,
        repositories: albumRepositories([fixtureTrack(1, playable: false)]),
      );
      expect(find.byKey(ActionBar.playKey), findsNothing);
      expect(find.byKey(ActionBar.shuffleKey), findsNothing);
      expect(find.byKey(ActionBar.addToPlaylistKey), findsNothing);
      expect(find.byKey(ActionBar.likeKey), findsOneWidget);
      expect(find.byKey(ActionBar.menuKey), findsOneWidget);
    });

    testWidgets('the overflow opens the album menu', (tester) async {
      await pumpDetail(
        tester,
        _album,
        repositories: albumRepositories([fixtureTrack(1)]),
      );
      await tester.tap(find.byKey(ActionBar.menuKey));
      await tester.pumpAndSettle();
      expect(_entries(tester), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.addToPlaylist,
        MenuIds.like,
        MenuIds.goToArtist,
        MenuIds.share,
      ]);
    });

    testWidgets('the overflow button, a long press and a secondary click '
        'open the same track menu', (tester) async {
      await pumpDetail(
        tester,
        _album,
        repositories: albumRepositories([fixtureTrack(1), fixtureTrack(2)]),
      );
      const expected = [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.addToPlaylist,
        MenuIds.like,
        MenuIds.download,
        MenuIds.goToArtist,
        MenuIds.share,
      ];
      await _openRowMenu(tester, 'Song 1.1');
      expect(_entries(tester), expected);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Song 1.1'));
      await tester.pumpAndSettle();
      expect(_entries(tester), expected);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      addTearDown(mouse.removePointer);
      await mouse.down(tester.getCenter(find.text('Song 1.1')));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(
        find.byType(PopupMenuItem<String>),
        findsNWidgets(expected.length),
      );
      expect(_entries(tester), expected);
    });

    testWidgets('Play next and Add to queue change the queue', (tester) async {
      final rig = PlayRig();
      await pumpDetail(
        tester,
        _album,
        repositories: albumRepositories([
          fixtureTrack(1),
          fixtureTrack(2),
          fixtureTrack(3),
        ]),
        overrides: rig.overrides,
      );
      await tester.tap(find.text('Song 1.1'));
      await rig.settle(tester);
      expect(rig.queued, ['p-1-1', 'p-1-2', 'p-1-3']);

      await _openRowMenu(tester, 'Song 1.3', rig);
      await _choose(tester, MenuIds.playNext, rig);
      expect(rig.queued, ['p-1-1', 'p-1-3', 'p-1-2', 'p-1-3']);

      await _openRowMenu(tester, 'Song 1.2', rig);
      await _choose(tester, MenuIds.addToQueue, rig);
      expect(rig.queued, ['p-1-1', 'p-1-3', 'p-1-2', 'p-1-3', 'p-1-2']);

      await _openRowMenu(tester, 'Song 1.2', rig);
      await _choose(tester, MenuIds.playNow, rig);
      expect(rig.current, 'p-1-2');
      expect(rig.queued, ['p-1-1', 'p-1-2', 'p-1-3']);
      await rig.close(tester);
    });

    testWidgets('Add to playlist, Like and Go to artist from a track menu', (
      tester,
    ) async {
      final repositories = albumRepositories([fixtureTrack(1)]);
      repositories.playlists.playlistList = playlists(1);
      await pumpDetail(tester, _album, repositories: repositories);

      await _openRowMenu(tester, 'Song 1.1');
      await _choose(tester, MenuIds.addToPlaylist);
      await tester.tap(find.text('Playlist 0'));
      await tester.pumpAndSettle();
      expect(repositories.playlists.edits, ['add pl0 p-1-1']);

      await _openRowMenu(tester, 'Song 1.1');
      await _choose(tester, MenuIds.like);
      expect(repositories.likes.toggled.map((track) => track.meta.title), [
        'Song 1.1',
      ]);

      await _openRowMenu(tester, 'Song 1.1');
      await _choose(tester, MenuIds.goToArtist);
      expect(find.text('artist page ar-1'), findsOneWidget);
    });

    testWidgets('Share link copies the album link', (tester) async {
      final written = _clipboard(tester);
      await pumpDetail(
        tester,
        _album,
        repositories: albumRepositories([fixtureTrack(1)]),
      );
      await _openRowMenu(tester, 'Song 1.1');
      await _choose(tester, MenuIds.share);
      expect(written, ['soundspan://album/al-1']);
      expect(find.text('Link copied'), findsOneWidget);
    });

    testWidgets('a long press on a card opens the album menu', (tester) async {
      await pumpDetail(
        tester,
        _album,
        size: TestSizes.expanded,
        repositories: albumRepositories(
          [fixtureTrack(1)],
          others: [fixtureAlbum('al-2')],
        ),
      );
      await tester.longPress(find.widgetWithText(MediaCard, 'Album al-2'));
      await tester.pumpAndSettle();
      expect(_entries(tester), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.addToPlaylist,
        MenuIds.like,
        MenuIds.goToArtist,
        MenuIds.share,
      ]);
    });

    testWidgets('the row offers "Add to queue" and "More options" to screen '
        'readers', (tester) async {
      final rig = PlayRig();
      final handle = tester.ensureSemantics();
      await pumpDetail(
        tester,
        _album,
        repositories: albumRepositories([fixtureTrack(1), fixtureTrack(2)]),
        overrides: rig.overrides,
      );
      final node = tester.getSemantics(
        find.widgetWithText(TrackRow, 'Song 1.2'),
      );
      final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
      int action(String label) => CustomSemanticsAction.getIdentifier(
        CustomSemanticsAction(label: label),
      );
      expect(node.getSemanticsData().customSemanticsActionIds, [
        action('Like'),
        action('Add to queue'),
        action('More options'),
      ]);

      owner.performAction(
        node.id,
        SemanticsAction.customAction,
        action('Add to queue'),
      );
      await rig.settle(tester);
      expect(rig.queued, ['p-1-2']);

      owner.performAction(
        node.id,
        SemanticsAction.customAction,
        action('More options'),
      );
      await tester.pumpAndSettle();
      expect(_entries(tester), contains(MenuIds.playNow));
      handle.dispose();
      await rig.close(tester);
    });

    testWidgets('meets the guidelines with the menu open', (tester) async {
      await pumpDetail(
        tester,
        _album,
        repositories: albumRepositories([fixtureTrack(1)]),
      );
      await expectMeetsGuidelines(tester);
      await _openRowMenu(tester, 'Song 1.1');
      await expectMeetsGuidelines(tester);
    });
  });

  group('playlist page', () {
    const screen = PlaylistScreen(playlistId: 'pl-1');

    testWidgets('Play and Shuffle play the playlist', (tester) async {
      final rig = PlayRig();
      await pumpDetail(
        tester,
        screen,
        repositories: _playlistRepositories(),
        overrides: rig.overrides,
      );
      await tester.tap(find.byKey(ActionBar.playKey));
      await rig.settle(tester);
      expect(rig.queued, ['p-1-1', 'p-1-2', 'p-1-3']);
      expect(rig.context?.id, 'pl-1');

      await tester.tap(find.byKey(ActionBar.shuffleKey));
      await rig.settle(tester);
      expect(rig.controller.snapshot.queue.isShuffled, isTrue);
      await rig.close(tester);
    });

    testWidgets('the owner renames and deletes from the overflow', (
      tester,
    ) async {
      final repositories = _playlistRepositories();
      await pumpDetail(tester, screen, repositories: repositories);

      await tester.tap(find.byKey(ActionBar.menuKey));
      await tester.pumpAndSettle();
      expect(_entries(tester), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.share,
        MenuIds.rename,
        MenuIds.delete,
      ]);
      await _choose(tester, MenuIds.rename);
      await tester.enterText(
        find.byKey(PlaylistNameDialog.fieldKey),
        'Night Drive',
      );
      await tester.pump();
      await tester.tap(find.byKey(PlaylistNameDialog.confirmKey));
      await tester.pumpAndSettle();
      expect(repositories.playlists.edits, ['rename pl-1 Night Drive']);

      await tester.tap(find.byKey(ActionBar.menuKey));
      await tester.pumpAndSettle();
      await _choose(tester, MenuIds.delete);
      await tester.tap(find.byKey(DeletePlaylistDialog.confirmKey));
      await tester.pumpAndSettle();
      expect(repositories.playlists.edits, [
        'rename pl-1 Night Drive',
        'delete pl-1',
      ]);
    });

    testWidgets('someone else sees neither Rename nor Delete', (tester) async {
      await pumpDetail(
        tester,
        screen,
        repositories: _playlistRepositories(owner: false),
      );
      await tester.tap(find.byKey(ActionBar.menuKey));
      await tester.pumpAndSettle();
      expect(_entries(tester), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.share,
      ]);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await _openRowMenu(tester, 'Song 1.1');
      expect(_entries(tester), isNot(contains(MenuIds.removeFromPlaylist)));
    });

    testWidgets('Remove from this playlist removes the item', (tester) async {
      final repositories = _playlistRepositories();
      await pumpDetail(tester, screen, repositories: repositories);
      await _openRowMenu(tester, 'Song 1.2');
      expect(_entries(tester), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.addToPlaylist,
        MenuIds.like,
        MenuIds.download,
        MenuIds.removeFromPlaylist,
        MenuIds.goToAlbum,
        MenuIds.goToArtist,
        MenuIds.share,
      ]);
      await _choose(tester, MenuIds.removeFromPlaylist);
      expect(repositories.playlists.edits, ['remove pl-1 item-2']);
    });

    testWidgets('Go to album navigates', (tester) async {
      await pumpDetail(tester, screen, repositories: _playlistRepositories());
      await _openRowMenu(tester, 'Song 1.1');
      await _choose(tester, MenuIds.goToAlbum);
      expect(find.text('album page al-1'), findsOneWidget);
    });

    testWidgets('Share link copies the playlist link', (tester) async {
      final written = _clipboard(tester);
      await pumpDetail(tester, screen, repositories: _playlistRepositories());
      await tester.tap(find.byKey(ActionBar.menuKey));
      await tester.pumpAndSettle();
      await _choose(tester, MenuIds.share);
      expect(written, ['soundspan://playlist/pl-1']);
    });
  });

  group('artist page', () {
    testWidgets('Play and Shuffle play the Popular tracks; the overflow '
        'shares the artist', (tester) async {
      final rig = PlayRig();
      final written = _clipboard(tester);
      await pumpDetail(
        tester,
        _artist,
        repositories: artistRepositories(
          fixtureArtistDetail(topTracks: [fixtureTrack(1), fixtureTrack(2)]),
        ),
        overrides: rig.overrides,
      );
      expect(find.byKey(ActionBar.likeKey), findsNothing);
      expect(find.byKey(ActionBar.addToPlaylistKey), findsNothing);
      await tester.tap(find.byKey(ActionBar.playKey));
      await rig.settle(tester);
      expect(rig.queued, ['p-1-1', 'p-1-2']);
      expect(rig.context?.kind, QueueContextKind.artist);

      await tester.tap(find.byKey(ActionBar.shuffleKey));
      await rig.settle(tester);
      expect(rig.controller.snapshot.queue.isShuffled, isTrue);

      await tester.tap(find.byKey(ActionBar.menuKey));
      await rig.settle(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_entries(tester), [MenuIds.share]);
      await _choose(tester, MenuIds.share, rig);
      expect(written, ['soundspan://artist/ar-1']);
      await rig.close(tester);
    });

    testWidgets('a Popular track menu has no Go to artist', (tester) async {
      await pumpDetail(
        tester,
        _artist,
        repositories: artistRepositories(
          fixtureArtistDetail(topTracks: [fixtureTrack(1)]),
        ),
      );
      await _openRowMenu(tester, 'Song 1.1');
      expect(_entries(tester), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.addToPlaylist,
        MenuIds.like,
        MenuIds.download,
        MenuIds.goToAlbum,
        MenuIds.share,
      ]);
    });
  });
}
