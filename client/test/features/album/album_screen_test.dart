// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/play_rig.dart';
import '../../helpers/pump_app.dart';
import '../detail_fixtures.dart';

const _screen = AlbumScreen(albumId: 'al-1');

List<TrackRow> _rows(WidgetTester tester) =>
    tester.widgetList<TrackRow>(find.byType(TrackRow)).toList();

void main() {
  testWidgets('single-disc album has no disc headers', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([fixtureTrack(1), fixtureTrack(2)]),
    );
    expect(find.textContaining('Disc'), findsNothing);
    expect(_rows(tester), hasLength(2));
  });

  testWidgets('two discs are grouped under Disc 1 and Disc 2 in track order', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      _screen,
      size: TestSizes.expanded,
      repositories: albumRepositories([
        fixtureTrack(1),
        fixtureTrack(2),
        fixtureTrack(1, disc: 2),
        fixtureTrack(2, disc: 2),
      ]),
    );
    expect(find.text('Disc 1'), findsOneWidget);
    expect(find.text('Disc 2'), findsOneWidget);
    double top(Finder finder) => tester.getTopLeft(finder).dy;
    final disc1 = top(find.byKey(AlbumScreen.discHeaderKey(1)));
    final disc2 = top(find.byKey(AlbumScreen.discHeaderKey(2)));
    final rows = [
      for (final title in ['Song 1.1', 'Song 1.2', 'Song 2.1', 'Song 2.2'])
        top(find.text(title)),
    ];
    expect(disc1, lessThan(rows[0]));
    expect(rows[0], lessThan(rows[1]));
    expect(rows[1], lessThan(disc2));
    expect(disc2, lessThan(rows[2]));
    expect(rows[2], lessThan(rows[3]));
    expect(_rows(tester).map((row) => (row.leading as TrackRowIndex).number), [
      1,
      2,
      1,
      2,
    ]);
  });

  testWidgets('a track artist is shown only when it differs from the album '
      'artist', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([
        fixtureTrack(1),
        fixtureTrack(2, artist: 'A Guest'),
      ]),
    );
    expect(_rows(tester).map((row) => row.artist), ['', 'A Guest']);
    expect(find.text('A Guest'), findsOneWidget);
  });

  testWidgets('metadata line shows artist, year, song count and total '
      'duration', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([
        for (var n = 1; n <= 20; n++) fixtureTrack(n),
      ]),
    );
    // 20 × 180 s + (1 + … + 20) s = 3810 s: 1 hr 3 min.
    expect(find.text(fixtureArtist), findsOneWidget);
    expect(find.text(' · 2020 · 20 songs · 1 hr 3 min'), findsOneWidget);
    expect(find.text('ALBUM'), findsOneWidget);
    expect(find.text('Album al-1'), findsOneWidget);
  });

  testWidgets('the release type is the overline when the server gives one', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([fixtureTrack(1)], releaseType: 'EP'),
    );
    expect(find.text('EP'), findsOneWidget);
    expect(find.text('ALBUM'), findsNothing);
  });

  testWidgets('tapping the artist opens the artist route', (tester) async {
    final router = await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([fixtureTrack(1)]),
    );
    await tester.tap(find.byKey(DetailMetadataLine.linkKey));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/artist/ar-1');
    expect(find.text('artist page ar-1'), findsOneWidget);
  });

  testWidgets('More by this artist excludes the current album and is hidden '
      'when empty', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories(
        [fixtureTrack(1)],
        others: [fixtureAlbum('al-2'), fixtureAlbum('al-3', year: null)],
      ),
    );
    await tester.scrollUntilVisible(
      find.text('More by this artist'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final cards = tester
        .widgetList<MediaCard>(find.byType(MediaCard))
        .map((card) => (card.title, card.subtitle));
    expect(cards, [('Album al-2', '2020'), ('Album al-3', fixtureArtist)]);
    await tester.tap(find.text('Album al-2'));
    await tester.pumpAndSettle();
    expect(find.text('album page al-2'), findsOneWidget);

    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([fixtureTrack(1)]),
    );
    expect(find.text('More by this artist'), findsNothing);
    expect(find.byType(MediaCard), findsNothing);
  });

  testWidgets('an unplayable track is disabled', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([
        fixtureTrack(1),
        fixtureTrack(2, playable: false),
      ]),
    );
    final rows = _rows(tester);
    expect(rows[0].enabled, isTrue);
    expect(rows[1].enabled, isFalse);
    expect(rows[1].disabledReason, 'Not playable');
  });

  testWidgets('tapping a row plays the album from that track', (tester) async {
    final rig = PlayRig();
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([
        fixtureTrack(1),
        fixtureTrack(2),
        fixtureTrack(1, disc: 2),
      ]),
      overrides: rig.overrides,
    );

    await tester.tap(find.text('Song 1.2'));
    await rig.settle(tester);

    expect(rig.queued, ['p-1-1', 'p-1-2', 'p-2-1']);
    expect(rig.current, 'p-1-2');
    expect(rig.controller.snapshot.playing, isTrue);
    expect(
      rig.context,
      const QueueContext(
        kind: QueueContextKind.album,
        id: 'al-1',
        title: 'Album al-1',
      ),
    );
    await rig.close(tester);
  });

  testWidgets('an unplayable row does nothing on tap', (tester) async {
    final rig = PlayRig();
    final router = await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([
        fixtureTrack(1),
        fixtureTrack(2, playable: false),
      ]),
      overrides: rig.overrides,
    );

    await tester.tap(find.text('Song 1.2'), warnIfMissed: false);
    await rig.settle(tester);

    expect(rig.queued, isEmpty);
    expect(router.state.uri.path, '/detail');
    await rig.close(tester);
  });

  testWidgets('a card of More by this artist plays its album', (tester) async {
    final rig = PlayRig();
    final repositories = albumRepositories(
      [fixtureTrack(1)],
      others: [fixtureAlbum('al-2')],
    );
    repositories.library.albumDetails['al-2'] = AlbumDetail(
      album: fixtureAlbum('al-2'),
      tracks: [fixtureTrack(7), fixtureTrack(8)],
      owned: true,
    );
    await pumpDetail(
      tester,
      _screen,
      size: TestSizes.expanded,
      repositories: repositories,
      overrides: rig.overrides,
    );

    final card = find.ancestor(
      of: find.text('Album al-2'),
      matching: find.byType(MediaCard),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: tester.getCenter(card));
    await tester.pump();
    await tester.tap(find.byTooltip('Play'));
    await rig.settle(tester);

    expect(rig.queued, ['p-1-7', 'p-1-8']);
    expect(rig.context?.kind, QueueContextKind.album);
    expect(rig.context?.id, 'al-2');
    await rig.close(tester);
  });

  testWidgets('NotFound shows the unavailable message', (tester) async {
    await pumpDetail(tester, _screen, repositories: FakeRepositories());
    expect(find.text('This item is no longer available'), findsOneWidget);
  });

  testWidgets('a skeleton shows while the album loads', (tester) async {
    await pumpDetail(
      tester,
      const AlbumScreen(albumId: 'slow'),
      repositories: FakeRepositories(library: _SlowLibrary()),
    );
    expect(find.byType(DetailHeaderSkeleton), findsOneWidget);
    expect(find.byType(TrackRowSkeleton), findsWidgets);
  });

  testWidgets('refresh failure keeps cached content', (tester) async {
    final repositories = albumRepositories([fixtureTrack(1)]);
    repositories.library.errors['refreshAlbum'] = const ServerError();
    await pumpDetail(tester, _screen, repositories: repositories);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(repositories.library.refreshCount('refreshAlbum'), 1);
    expect(
      find.text('Couldn’t refresh. Showing saved content.'),
      findsOneWidget,
    );
    expect(find.text('Album al-1'), findsOneWidget);
    expect(find.text('Song 1.1'), findsOneWidget);
  });

  testWidgets('a refresh error on the cached read shows the snackbar', (
    tester,
  ) async {
    final library = _RefreshErrorLibrary();
    await pumpDetail(
      tester,
      _screen,
      repositories: FakeRepositories(library: library),
    );
    expect(find.text('Album al-1'), findsOneWidget);
    expect(
      find.text('Couldn’t refresh. Showing saved content.'),
      findsOneWidget,
    );
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
          repositories: albumRepositories(
            [fixtureTrack(1), fixtureTrack(2, disc: 2, playable: false)],
            others: [fixtureAlbum('al-2')],
          ),
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
        repositories: albumRepositories(
          [
            fixtureTrack(1),
            fixtureTrack(2, artist: 'A Guest With A Long Name'),
          ],
          others: [fixtureAlbum('al-2')],
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

/// A library whose album read never emits.
class _SlowLibrary extends FakeLibraryRepository {
  @override
  Stream<Cached<AlbumDetail>> album(String id) =>
      StreamController<Cached<AlbumDetail>>().stream;
}

/// A library whose album read is cached but could not be refreshed.
class _RefreshErrorLibrary extends FakeLibraryRepository {
  @override
  Stream<Cached<AlbumDetail>> album(String id) async* {
    final album = fixtureAlbum('al-1');
    final detail = AlbumDetail(
      album: album,
      tracks: [fixtureTrack(1)],
      owned: true,
    );
    final fetchedAt = DateTime.utc(2025);
    yield Cached(value: detail, fetchedAt: fetchedAt);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield Cached(
      value: detail,
      fetchedAt: fetchedAt,
      refreshError: const ServerError(),
    );
  }
}
