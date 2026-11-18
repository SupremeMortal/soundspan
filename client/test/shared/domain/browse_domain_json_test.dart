// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// Encodes the JSON of a value to a JSON string and back, as the cache does.
Map<String, Object?> _roundTrip(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  const track = Track(
    meta: TrackMeta(
      title: 'Song',
      artist: 'Band',
      album: 'Record',
      durationSec: 9,
    ),
    playbackId: PlaybackId('pb-1'),
  );
  const album = Album(
    id: 'al-1',
    title: 'Record',
    artistName: 'Band',
    artistId: 'ar-1',
  );
  const artist = Artist(id: 'ar-1', name: 'Band');
  const podcast = PodcastSummary(id: 'p-1', title: 'Show', author: 'Host');
  const summary = PlaylistSummary(
    id: 'pl-1',
    name: 'Mix',
    trackCount: 1,
    isOwner: true,
    isPublic: false,
    coverRefs: ['c-1'],
  );

  test('playlist types survive a JSON round trip', () {
    const detail = PlaylistDetail(
      summary: summary,
      items: [
        PlaylistItem(
          id: 'i-1',
          sort: 0,
          track: track,
          isPlayable: false,
          message: 'Unavailable',
        ),
      ],
    );

    expect(PlaylistDetail.fromJson(_roundTrip(detail.toJson())), detail);
  });

  test('mix, recent items and podcast summaries survive a JSON round trip', () {
    const mix = MixSummary(
      id: 'm-1',
      name: 'Mix',
      description: 'About',
      coverRefs: ['c'],
    );
    const recent = [
      RecentItem.artist(artist: artist),
      RecentItem.podcast(
        podcast: Podcast(id: 'p-1', title: 'Show'),
      ),
    ];

    expect(MixSummary.fromJson(_roundTrip(mix.toJson())), mix);
    for (final item in recent) {
      expect(RecentItem.fromJson(_roundTrip(item.toJson())), item);
    }
    expect(PodcastSummary.fromJson(_roundTrip(podcast.toJson())), podcast);
  });

  test('a search page survives a JSON round trip', () {
    const page = SearchPage(
      items: [
        SearchResult(hit: SearchHit.track(track: track), score: 4.2),
        SearchResult(hit: SearchHit.album(album: album), score: 3.5),
        SearchResult(hit: SearchHit.artist(artist: artist), score: 3.1),
        SearchResult(hit: SearchHit.playlist(playlist: summary), score: 2),
        SearchResult(
          hit: SearchHit.podcast(podcast: podcast),
          score: 1.5,
          source: SearchResultSource.catalogue,
        ),
      ],
      hasMore: true,
    );

    expect(SearchPage.fromJson(_roundTrip(page.toJson())), page);
  });

  test('search filters carry the server type values', () {
    expect(
      [for (final filter in SearchFilter.values) filter.value],
      ['all', 'tracks', 'artists', 'albums', 'playlists', 'podcasts'],
    );
  });
}
