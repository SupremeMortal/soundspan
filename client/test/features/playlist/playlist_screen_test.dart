// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/like_button.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/play_rig.dart';
import '../../helpers/pump_app.dart';
import '../detail_fixtures.dart';

const _screen = PlaylistScreen(playlistId: 'pl-1');

PlaylistItem _item(int n, {bool playable = true, String? message}) =>
    PlaylistItem(
      id: 'item-$n',
      sort: n * 10,
      track: fixtureTrack(n, artworkRef: 'cover-$n'),
      isPlayable: playable,
      message: message,
    );

FakeRepositories _playlist(
  List<PlaylistItem> items, {
  bool isPublic = true,
  bool isOwner = true,
}) {
  final repositories = FakeRepositories();
  repositories.playlists.playlistDetails['pl-1'] = PlaylistDetail(
    summary: PlaylistSummary(
      id: 'pl-1',
      name: 'Road Trip',
      trackCount: items.length,
      isOwner: isOwner,
      isPublic: isPublic,
      coverRefs: const ['a', 'b', 'c', 'd'],
    ),
    items: items,
  );
  return repositories;
}

List<TrackRow> _rows(WidgetTester tester) =>
    tester.widgetList<TrackRow>(find.byType(TrackRow)).toList();

void main() {
  testWidgets('rows have thumbnails, and the album column only on expanded', (
    tester,
  ) async {
    for (final (size, column) in [
      (TestSizes.compact, false),
      (TestSizes.medium, false),
      (TestSizes.expanded, true),
    ]) {
      await pumpDetail(
        tester,
        _screen,
        size: size,
        repositories: _playlist([_item(1), _item(2)]),
      );
      final rows = _rows(tester);
      expect(rows, hasLength(2));
      expect(rows.map((row) => (row.leading as TrackRowThumbnail).artworkRef), [
        'cover-1',
        'cover-2',
      ]);
      expect(rows.every((row) => row.showAlbumColumn == column), isTrue);
      expect(rows.first.album, 'The Album');
    }
  });

  testWidgets("an unplayable item is disabled with the server's message", (
    tester,
  ) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: _playlist([
        _item(1),
        _item(2, playable: false, message: 'Removed by the label, sorry.'),
        _item(3, playable: false),
      ]),
    );
    final rows = _rows(tester);
    expect(rows.map((row) => row.enabled), [true, false, false]);
    expect(rows[1].disabledReason, 'Removed by the label, sorry.');
    expect(rows[2].disabledReason, 'Not playable');
  });

  testWidgets('items follow the server order', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: _playlist([_item(3), _item(1), _item(2)]),
    );
    expect(_rows(tester).map((row) => row.title), [
      'Song 1.3',
      'Song 1.1',
      'Song 1.2',
    ]);
  });

  testWidgets('the header shows the mosaic, the name, and the count, '
      'duration and visibility', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: _playlist([_item(1), _item(2)]),
    );
    expect(find.byType(MosaicArtwork), findsOneWidget);
    expect(find.text('PLAYLIST'), findsOneWidget);
    expect(find.text('Road Trip'), findsOneWidget);
    expect(find.text('2 songs · 6 min · Public'), findsOneWidget);

    await pumpDetail(
      tester,
      _screen,
      repositories: _playlist([_item(1)], isPublic: false),
    );
    expect(find.text('1 song · 3 min'), findsOneWidget);
  });

  testWidgets('liked uses the paged source and shows skeletons for unloaded '
      'rows', (tester) async {
    final repositories = FakeRepositories();
    repositories.library
      ..likedList = [for (var n = 1; n <= 250; n++) fixtureTrack(n)]
      ..pageDelay = const Duration(seconds: 1);
    await pumpDetail(
      tester,
      const PlaylistScreen(playlistId: likedPlaylistId),
      repositories: repositories,
    );
    expect(repositories.library.queries, ['liked']);
    final source = repositories.library.sources.single;
    expect(source.pageSize, 100);
    expect(find.text('Liked Songs'), findsOneWidget);
    expect(find.text('250 songs'), findsOneWidget);
    expect(find.byType(TrackRowSkeleton), findsWidgets);
    expect(find.byType(TrackRow), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Song 1.1'), findsOneWidget);
    expect(find.byType(TrackRowSkeleton), findsNothing);

    // Pages 0 and 1 load first; page 2 (from row 200) only once in view.
    expect(source.requestedPages, [0, 1]);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pump();
    expect(find.text('Song 1.250'), findsNothing);
    expect(find.byType(TrackRowSkeleton), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(source.requestedPages, [0, 1, 2]);
    expect(find.text('Song 1.250'), findsOneWidget);
  });

  testWidgets('a non-owner sees no edit controls', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      size: TestSizes.expanded,
      repositories: _playlist([_item(1), _item(2)], isOwner: false),
    );
    expect(find.byType(ReorderableListView), findsNothing);
    expect(find.byType(ReorderableDragStartListener), findsNothing);
    // The only buttons in the rows are the tracks' hearts and menus.
    expect(
      find.descendant(
        of: find.byType(TrackRow),
        matching: find.byType(IconButton),
      ),
      findsNWidgets(
        find.byType(LikeButton).evaluate().length +
            find.byKey(TrackRow.overflowKey).evaluate().length,
      ),
    );
    expect(find.byKey(TrackRow.overflowKey), findsNWidgets(2));
    expect(find.byType(TextField), findsNothing);
  });

  for (final owner in [false, true]) {
    testWidgets('tapping a row plays the playable items from it '
        '(owner: $owner)', (tester) async {
      final rig = PlayRig();
      await pumpDetail(
        tester,
        _screen,
        repositories: _playlist([
          _item(1),
          _item(2, playable: false, message: 'Gone'),
          _item(3),
          _item(4),
        ], isOwner: owner),
        overrides: rig.overrides,
      );

      await tester.tap(find.text('Song 1.3'));
      await rig.settle(tester);

      expect(rig.queued, ['p-1-1', 'p-1-3', 'p-1-4']);
      expect(rig.current, 'p-1-3');
      expect(
        rig.context,
        const QueueContext(
          kind: QueueContextKind.playlist,
          id: 'pl-1',
          title: 'Road Trip',
        ),
      );
      await rig.close(tester);
    });
  }

  testWidgets('an unplayable item does nothing on tap', (tester) async {
    final rig = PlayRig();
    await pumpDetail(
      tester,
      _screen,
      repositories: _playlist([_item(1), _item(2, playable: false)]),
      overrides: rig.overrides,
    );

    await tester.tap(find.text('Song 1.2'), warnIfMissed: false);
    await rig.settle(tester);

    expect(rig.queued, isEmpty);
    await rig.close(tester);
  });

  testWidgets('a Liked Songs row plays the loaded liked tracks from it', (
    tester,
  ) async {
    final rig = PlayRig();
    final repositories = FakeRepositories();
    repositories.library.likedList = [
      for (var n = 1; n <= 3; n++) fixtureTrack(n),
    ];
    await pumpDetail(
      tester,
      const PlaylistScreen(playlistId: likedPlaylistId),
      repositories: repositories,
      overrides: rig.overrides,
    );

    await tester.tap(find.text('Song 1.2'));
    await rig.settle(tester);

    expect(rig.queued, ['p-1-1', 'p-1-2', 'p-1-3']);
    expect(rig.current, 'p-1-2');
    expect(rig.context?.kind, QueueContextKind.playlist);
    expect(rig.context?.id, likedPlaylistId);
    await rig.close(tester);
  });

  testWidgets('an empty playlist shows an empty state', (tester) async {
    await pumpDetail(tester, _screen, repositories: _playlist(const []));
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('This playlist has no songs yet'), findsOneWidget);
    expect(find.text('0 songs · 0 min · Public'), findsOneWidget);
  });

  testWidgets('NotFound shows the unavailable message', (tester) async {
    await pumpDetail(tester, _screen, repositories: FakeRepositories());
    expect(find.text('This item is no longer available'), findsOneWidget);
  });

  testWidgets('refresh failure keeps cached content', (tester) async {
    final repositories = _playlist([_item(1)]);
    repositories.playlists.errors['refreshPlaylist'] = const ServerError();
    await pumpDetail(tester, _screen, repositories: repositories);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(repositories.playlists.refreshCount('refreshPlaylist'), 1);
    expect(
      find.text('Couldn’t refresh. Showing saved content.'),
      findsOneWidget,
    );
    expect(find.text('Road Trip'), findsOneWidget);
  });

  testWidgets('pull-to-refresh on liked refreshes the paged source', (
    tester,
  ) async {
    final repositories = FakeRepositories();
    repositories.library.likedList = [fixtureTrack(1)];
    await pumpDetail(
      tester,
      const PlaylistScreen(playlistId: likedPlaylistId),
      repositories: repositories,
    );
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(repositories.library.sources.single.refreshCount, 1);
  });

  testWidgets('no liked songs shows the empty state', (tester) async {
    await pumpDetail(
      tester,
      const PlaylistScreen(playlistId: likedPlaylistId),
      repositories: FakeRepositories(),
    );
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('0 songs'), findsOneWidget);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('meets the screen guidelines at ${size.width.toInt()} in '
          '${theme.name}', (tester) async {
        await pumpDetail(
          tester,
          _screen,
          size: size,
          theme: theme,
          repositories: _playlist([
            _item(1),
            _item(2, playable: false, message: 'Unavailable'),
          ]),
        );
        await expectMeetsGuidelines(tester);
      });
    }
    testWidgets('lays out without overflow at text scale 2.0 at '
        '${size.width.toInt()}', (tester) async {
      await pumpDetail(
        tester,
        _screen,
        size: size,
        textScale: 2,
        repositories: _playlist([_item(1), _item(2)]),
      );
      expect(tester.takeException(), isNull);
      final repositories = FakeRepositories();
      repositories.library.likedList = [fixtureTrack(1), fixtureTrack(2)];
      await pumpDetail(
        tester,
        const PlaylistScreen(playlistId: likedPlaylistId),
        size: size,
        textScale: 2,
        repositories: repositories,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
