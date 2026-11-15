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
