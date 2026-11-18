// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/features/search/data/search_history_store.dart';
import 'package:soundspan/features/search/search.dart';
import 'package:soundspan/features/search/search_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/golden.dart';

SearchResult _result(SearchHit hit, {bool catalogue = false}) => SearchResult(
  hit: hit,
  source: catalogue ? SearchResultSource.catalogue : SearchResultSource.library,
);

Track _track(String title, String id, {String? artworkRef}) => Track(
  meta: TrackMeta(
    title: title,
    artist: 'Radiohead',
    album: 'OK Computer',
    durationSec: 263,
    artworkRef: artworkRef,
  ),
  playbackId: PlaybackId(id),
);

/// The online Search screen (doc 09, Search): the filter chips and one
/// relevance-ordered list mixing an artist, albums, songs, a playlist and
/// a podcast, each row labelled with its kind.
void main() {
  final stateDb = StateDatabase(NativeDatabase.memory());
  tearDownAll(stateDb.close);
  final repositories = FakeRepositories();
  repositories.search.results['radiohead'] = [
    _result(
      const SearchHit.artist(
        artist: Artist(id: 'ar1', name: 'Radiohead', artworkRef: 'hero-1'),
      ),
    ),
    _result(
      const SearchHit.album(
        album: Album(
          id: 'al1',
          title: 'OK Computer',
          artistName: 'Radiohead',
          artistId: 'ar1',
          artworkRef: 'cover-1',
        ),
      ),
    ),
    _result(
      SearchHit.track(
        track: _track('Paranoid Android', 'pb1', artworkRef: 'cover-1'),
      ),
    ),
    _result(
      const SearchHit.playlist(
        playlist: PlaylistSummary(
          id: 'pl1',
          name: 'Radiohead deep cuts',
          trackCount: 42,
          isOwner: true,
          isPublic: false,
          coverRefs: ['cover-1', 'cover-2', 'cover-3', 'cover-4'],
        ),
      ),
    ),
    _result(
      const SearchHit.album(
        album: Album(
          id: 'remote-al',
          title: 'Kid A',
          artistName: 'Radiohead',
          artistId: 'ar1',
          artworkRef: 'cover-2',
        ),
      ),
      catalogue: true,
    ),
    _result(
      SearchHit.track(
        track: _track('Karma Police', 'pb2', artworkRef: 'cover-1'),
      ),
      catalogue: true,
    ),
    _result(
      const SearchHit.podcast(
        podcast: PodcastSummary(
          id: 'pc1',
          title: 'Radiohead Revisited',
          author: 'Music Talk',
        ),
      ),
      catalogue: true,
    ),
  ];
  goldenMatrix(
    'search',
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: const SearchScreen(query: 'radiohead'),
    ),
    overrides: [
      ...repositories.overrides,
      searchHistoryStoreProvider.overrideWithValue(
        SearchHistoryStore(stateDb, FakeClock()),
      ),
      profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
    ],
  );
}
