// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/pump_app.dart';

/// The album artist of the fixtures.
const String fixtureArtist = 'The Artist';

/// Track [number] of disc [disc] of `al-1`, 3 minutes plus [number]
/// seconds long; [playable] false leaves out the playback id.
Track fixtureTrack(
  int number, {
  int disc = 1,
  String artist = fixtureArtist,
  bool playable = true,
  String? artworkRef,
}) => Track(
  meta: TrackMeta(
    title: 'Song $disc.$number',
    artist: artist,
    album: 'The Album',
    durationSec: 180 + number,
    artworkRef: artworkRef,
  ),
  playbackId: playable ? PlaybackId('p-$disc-$number') : null,
  albumId: 'al-1',
  artistId: 'ar-1',
  discNumber: disc,
  trackNumber: number,
);

/// Album [id] by [fixtureArtist].
Album fixtureAlbum(String id, {int? year = 2020, String? releaseType}) => Album(
  id: id,
  title: 'Album $id',
  artistName: fixtureArtist,
  artistId: 'ar-1',
  year: year,
  artworkRef: 'cover-$id',
  releaseType: releaseType,
);

/// Pumps [screen] inside a [WindowClassScope] for [size], at `/detail` of a
/// router that also has `/album/:albumId` and `/artist/:artistId` stand-ins,
/// and returns the router.
Future<GoRouter> pumpDetail(
  WidgetTester tester,
  Widget screen, {
  FakeRepositories? repositories,
  Size size = TestSizes.compact,
  ThemeMode theme = ThemeMode.dark,
  double textScale = 1.0,
  List<Override> overrides = const [],
}) async {
  Widget scoped(Widget child) => Builder(
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: child,
    ),
  );
  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(path: '/detail', builder: (_, _) => scoped(screen)),
      GoRoute(
        path: '/album/:albumId',
        builder: (_, state) =>
            Text('album page ${state.pathParameters['albumId']}'),
      ),
      GoRoute(
        path: '/artist/:artistId',
        builder: (_, state) =>
            Text('artist page ${state.pathParameters['artistId']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpApp(
    Router.withConfig(config: router),
    size: size,
    theme: theme,
    textScale: textScale,
    overrides: [...?repositories?.overrides, ...overrides],
  );
  await tester.pumpAndSettle();
  return router;
}

/// A [FakeRepositories] seeded with album `al-1` of [tracks] and the
/// artist's [others] albums.
FakeRepositories albumRepositories(
  List<Track> tracks, {
  List<Album> others = const [],
  String? releaseType,
}) {
  final repositories = FakeRepositories();
  final album = fixtureAlbum('al-1', releaseType: releaseType);
  repositories.library
    ..albumDetails['al-1'] = AlbumDetail(
      album: album,
      tracks: tracks,
      owned: true,
    )
    ..albumList = [album, ...others];
  return repositories;
}

/// The biography of the fixture artist: long enough to need more than
/// three lines on every window size.
final String fixtureBiography = List.filled(
  12,
  'The Artist formed in a small town and played every club on the coast '
  'before their first record.',
).join(' ');

/// Artist `ar-1` with [topTracks], [albums], [similar] artists, [genres]
/// and [biography].
ArtistDetail fixtureArtistDetail({
  List<Track> topTracks = const [],
  List<Album> albums = const [],
  List<SimilarArtist> similar = const [],
  List<String> genres = const [],
  String? biography,
}) => ArtistDetail(
  artist: const Artist(
    id: 'ar-1',
    name: fixtureArtist,
    artworkRef: 'face-ar-1',
  ),
  topTracks: topTracks,
  albums: albums,
  similarArtists: similar,
  genres: genres,
  biography: biography,
);

/// A [FakeRepositories] seeded with artist `ar-1` as [detail].
FakeRepositories artistRepositories(ArtistDetail detail) {
  final repositories = FakeRepositories();
  repositories.library.artistDetails['ar-1'] = detail;
  return repositories;
}

/// Artist `ar-1` with all five sections populated.
ArtistDetail fullArtistDetail() => fixtureArtistDetail(
  topTracks: [for (var n = 1; n <= 7; n++) fixtureTrack(n)],
  albums: [
    fixtureAlbum('al-1', releaseType: 'Album'),
    fixtureAlbum('al-2', year: 2018),
    fixtureAlbum('al-3', year: 2021, releaseType: 'Single'),
    fixtureAlbum('al-4', year: 2022, releaseType: 'EP'),
  ],
  similar: const [
    SimilarArtist(name: 'Kindred', artworkRef: 'face-ar-2', libraryId: 'ar-2'),
    SimilarArtist(name: 'Elsewhere', artworkRef: 'face-ar-3'),
    SimilarArtist(name: 'Neighbour', libraryId: 'ar-4'),
  ],
  genres: const ['Jazz', 'Soul', 'Funk', 'Disco'],
  biography: fixtureBiography,
);
