// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/artist/artist.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/shelf.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/play_rig.dart';
import '../../helpers/pump_app.dart';
import '../detail_fixtures.dart';

const _screen = ArtistScreen(artistId: 'ar-1');

/// A window tall enough to lay out every section of a full page at once.
const Size _tall = Size(1440, 4000);

List<TrackRow> _rows(WidgetTester tester) =>
    tester.widgetList<TrackRow>(find.byType(TrackRow)).toList();

List<String> _cardTitles(WidgetTester tester) => tester
    .widgetList<MediaCard>(find.byType(MediaCard))
    .map((card) => card.title)
    .toList();

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('header shows round artwork, the name and up to three genres', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: artistRepositories(
        fixtureArtistDetail(genres: const ['Jazz', 'Soul', 'Funk', 'Disco']),
      ),
    );
    expect(find.text('ARTIST'), findsOneWidget);
    expect(find.text(fixtureArtist), findsOneWidget);
    expect(find.text('Jazz · Soul · Funk'), findsOneWidget);
    final artwork = tester.widget<Artwork>(
      find.descendant(
        of: find.byKey(DetailHeader.artworkKey),
        matching: find.byType(Artwork),
      ),
    );
    expect(artwork.shape, ArtworkShape.circle);
    expect(artwork.ref, 'face-ar-1');
  });

  testWidgets('a header without genres has no metadata text', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: artistRepositories(fixtureArtistDetail()),
    );
    expect(find.textContaining(' · '), findsNothing);
  });

  testWidgets('Popular shows five tracks, Show more expands to ten, Show less '
      'collapses', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(
        fixtureArtistDetail(
          topTracks: [for (var n = 1; n <= 12; n++) fixtureTrack(n)],
        ),
      ),
    );
    expect(find.text('Popular'), findsOneWidget);
    expect(_rows(tester).map((row) => (row.leading as TrackRowIndex).number), [
      1,
      2,
      3,
      4,
      5,
    ]);
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(_rows(tester), hasLength(10));
    expect((_rows(tester).last.leading as TrackRowIndex).number, 10);
    expect(find.text('Song 1.11'), findsNothing);
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(_rows(tester), hasLength(5));
    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('Popular has no expand control with five or fewer tracks', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: artistRepositories(
        fixtureArtistDetail(
          topTracks: [for (var n = 1; n <= 5; n++) fixtureTrack(n)],
        ),
      ),
    );
    expect(_rows(tester), hasLength(5));
    expect(find.text('Show more'), findsNothing);
    expect(find.text('Show less'), findsNothing);
  });

  testWidgets('albums and singles are split by release type, and an untyped '
      'entry is an album', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(
        fixtureArtistDetail(
          albums: [
            fixtureAlbum('al-1', releaseType: 'Album'),
            fixtureAlbum('al-2'),
            fixtureAlbum('al-3', releaseType: 'single'),
            fixtureAlbum('al-4', releaseType: 'EP'),
          ],
        ),
      ),
    );
    Finder cardsUnder(String title) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(Shelf)),
      matching: find.byType(MediaCard),
    );
    List<String> titles(Finder cards) =>
        tester.widgetList<MediaCard>(cards).map((card) => card.title).toList();
    expect(titles(cardsUnder('Albums')), ['Album al-1', 'Album al-2']);
    expect(titles(cardsUnder('Singles and EPs')), ['Album al-3', 'Album al-4']);
    final card = tester.widget<MediaCard>(
      find.widgetWithText(MediaCard, 'Album al-1'),
    );
    expect(card.subtitle, '2020');
    expect(card.shape, ArtworkShape.square);
  });

  testWidgets('tapping an album opens the album route in the current branch', (
    tester,
  ) async {
    final router = await pumpDetail(
      tester,
      _screen,
      repositories: artistRepositories(
        fixtureArtistDetail(albums: [fixtureAlbum('al-2')]),
      ),
    );
    await _scrollTo(tester, find.text('Album al-2'));
    await tester.tap(find.text('Album al-2'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/album/al-2');
    expect(find.text('album page al-2'), findsOneWidget);
  });

  testWidgets('similar artists without a library id are not listed; tapping '
      'one with an id opens its page', (tester) async {
    final router = await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(
        fixtureArtistDetail(
          similar: const [
            SimilarArtist(name: 'Kindred', libraryId: 'ar-2'),
            SimilarArtist(name: 'Elsewhere'),
          ],
        ),
      ),
    );
    expect(find.text('Similar Artists'), findsOneWidget);
    expect(_cardTitles(tester), ['Kindred']);
    expect(
      tester.widget<MediaCard>(find.byType(MediaCard)).shape,
      ArtworkShape.circle,
    );
    await tester.tap(find.text('Kindred'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/artist/ar-2');
  });

  testWidgets('similar artists all without a library id hide the section', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(
        fixtureArtistDetail(similar: const [SimilarArtist(name: 'Elsewhere')]),
      ),
    );
    expect(find.text('Similar Artists'), findsNothing);
  });

  testWidgets('biography collapses to three lines and expands in place', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(
        fixtureArtistDetail(biography: fixtureBiography),
      ),
    );
    expect(find.text('About'), findsOneWidget);
    Text bio() => tester.widget<Text>(find.byKey(ArtistScreen.biographyKey));
    expect(bio().maxLines, 3);
    final collapsed = tester.getSize(find.byKey(ArtistScreen.biographyKey));
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(bio().maxLines, isNull);
    expect(
      tester.getSize(find.byKey(ArtistScreen.biographyKey)).height,
      greaterThan(collapsed.height),
    );
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(bio().maxLines, 3);
  });

  testWidgets('a short biography has no control', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(
        fixtureArtistDetail(biography: 'A short story.'),
      ),
    );
    expect(find.text('A short story.'), findsOneWidget);
    expect(find.text('Read more'), findsNothing);
  });

  testWidgets('markup in the biography is not rendered as tags', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(
        fixtureArtistDetail(
          biography:
              'A <b>bold</b> band &amp; friends. '
              '<a href="https://example.com/x">Read more on the web</a>',
        ),
      ),
    );
    expect(
      find.text('A bold band & friends. Read more on the web'),
      findsOneWidget,
    );
    expect(find.textContaining('<'), findsNothing);
  });

  testWidgets('sections with no content are absent', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(
        fixtureArtistDetail(albums: [fixtureAlbum('al-2')]),
      ),
    );
    expect(find.text('Albums'), findsOneWidget);
    for (final absent in [
      'Popular',
      'Singles and EPs',
      'Similar Artists',
      'About',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
    expect(find.byType(TrackRow), findsNothing);
  });

  testWidgets('an unplayable popular track is disabled', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: artistRepositories(
        fixtureArtistDetail(
          topTracks: [fixtureTrack(1), fixtureTrack(2, playable: false)],
        ),
      ),
    );
    final rows = _rows(tester);
    expect(rows[0].enabled, isTrue);
    expect(rows[1].enabled, isFalse);
    expect(rows[1].disabledReason, 'Not playable');
  });

  testWidgets('a Popular row plays the shown tracks from that row', (
    tester,
  ) async {
    final rig = PlayRig();
    await pumpDetail(
      tester,
      _screen,
      repositories: artistRepositories(
        fixtureArtistDetail(
          topTracks: [
            for (var n = 1; n <= 7; n++) fixtureTrack(n, playable: n != 2),
          ],
        ),
      ),
      overrides: rig.overrides,
    );

    await tester.tap(find.text('Song 1.3'));
    await rig.settle(tester);

    // Five are shown; the second is not playable.
    expect(rig.queued, ['p-1-1', 'p-1-3', 'p-1-4', 'p-1-5']);
    expect(rig.current, 'p-1-3');
    expect(
      rig.context,
      const QueueContext(
        kind: QueueContextKind.artist,
        id: 'ar-1',
        title: fixtureArtist,
      ),
    );
    await rig.close(tester);
  });

  testWidgets('an unplayable Popular row does nothing on tap', (tester) async {
    final rig = PlayRig();
    final router = await pumpDetail(
      tester,
      _screen,
      repositories: artistRepositories(
        fixtureArtistDetail(topTracks: [fixtureTrack(1, playable: false)]),
      ),
      overrides: rig.overrides,
    );

    await tester.tap(find.text('Song 1.1'), warnIfMissed: false);
    await rig.settle(tester);

    expect(rig.queued, isEmpty);
    expect(router.state.uri.path, '/detail');
    await rig.close(tester);
  });

  testWidgets('NotFound shows the unavailable message', (tester) async {
    await pumpDetail(tester, _screen, repositories: FakeRepositories());
    expect(find.text('This item is no longer available'), findsOneWidget);
  });

  testWidgets('a skeleton shows while the artist loads', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: FakeRepositories(library: _SlowLibrary()),
    );
    expect(find.byType(DetailHeaderSkeleton), findsOneWidget);
    expect(find.byType(TrackRowSkeleton), findsWidgets);
  });

  testWidgets('refresh failure keeps cached content', (tester) async {
    final repositories = artistRepositories(
      fixtureArtistDetail(topTracks: [fixtureTrack(1)]),
    );
    repositories.library.errors['refreshArtist'] = const ServerError();
    await pumpDetail(tester, _screen, repositories: repositories);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(repositories.library.refreshCount('refreshArtist'), 1);
    expect(
      find.text('Couldn’t refresh. Showing saved content.'),
      findsOneWidget,
    );
    expect(find.text(fixtureArtist), findsOneWidget);
    expect(find.text('Song 1.1'), findsOneWidget);
  });

  testWidgets('the only controls are the action bar, the Popular rows, '
      'navigation, expand and collapse, and refresh', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      size: _tall,
      repositories: artistRepositories(fullArtistDetail()),
    );
    final handle = tester.ensureSemantics();
    await tester.pump();
    final labels = <String>[];
    void visit(SemanticsNode node) {
      final data = node.getSemanticsData();
      if (!node.isMergedIntoParent && data.hasAction(SemanticsAction.tap)) {
        labels.add(data.label);
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visit(
      tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!,
    );
    handle.dispose();
    final cards = [
      'Album al-1, 2020',
      'Album al-2, 2018',
      'Album al-3, 2021',
      'Album al-4, 2022',
      'Kindred, Artist',
      'Neighbour, Artist',
    ];
    expect(
      labels,
      unorderedEquals([
        ...cards,
        'Play',
        'Shuffle',
        'More options',
        'Show more',
        'Read more',
        for (var n = 1; n <= 5; n++) startsWith('Song 1.$n, '),
      ]),
    );
    // Refresh is the scroll view's pull-to-refresh, not a button.
    expect(find.byType(RefreshIndicator), findsOneWidget);
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
          repositories: artistRepositories(fullArtistDetail()),
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
        repositories: artistRepositories(fullArtistDetail()),
      );
      expect(tester.takeException(), isNull);
      await _scrollTo(tester, find.text('Read more'));
      expect(tester.takeException(), isNull);
    });
  }
}

/// A library whose artist read never emits.
class _SlowLibrary extends FakeLibraryRepository {
  @override
  Stream<Cached<ArtistDetail>> artist(String id) =>
      StreamController<Cached<ArtistDetail>>().stream;
}
