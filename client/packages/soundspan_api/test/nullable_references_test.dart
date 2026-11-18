// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

void main() {
  test('a discover search without a correction decodes aliasInfo null', () {
    final response = DiscoverSearchResponse.fromJson({
      'aliasInfo': null,
      'results': <Object?>[],
    });

    expect(response.aliasInfo, isNull);
  });

  test('the last liked page decodes nextCursor null', () {
    final pagination = LikedTracksPagination.fromJson({
      'hasMore': false,
      'limit': 2,
      'nextCursor': null,
    });

    expect(pagination.nextCursor, isNull);
  });

  test('a search track decodes peer null', () {
    final track = SearchTrack.fromJson({
      'id': 't-1',
      'title': 'Song',
      'duration': 3,
      'trackNo': 1,
      'albumId': 'al-1',
      'peer': null,
    });

    expect(track.peer, isNull);
  });

  test('a playlist item whose track was removed decodes track null', () {
    final item = PlaylistItem.fromJson({..._playlistItem, 'track': null});

    expect(item.track, isNull);
  });

  test('a playlist item with a track decodes it as a LibraryTrack', () {
    final item = PlaylistItem.fromJson({
      ..._playlistItem,
      'track': _libraryTrack,
    });

    expect(item.track, isA<LibraryTrack>());
    expect(item.track?.id, 't-1');
    expect(item.toJson()['track'], isA<Map<String, Object?>>());
  });

  test('similar tracks without source features decode sourceFeatures '
      'null', () {
    final response = SimilarTracksResponse.fromJson({
      'sourceFeatures': null,
      'sourceTrackId': 't-1',
      'tracks': <Object?>[],
    });

    expect(response.sourceFeatures, isNull);
  });

  test('similar tracks with source features decode them as '
      'VibeAudioFeatures', () {
    final response = SimilarTracksResponse.fromJson({
      'sourceFeatures': _features,
      'sourceTrackId': 't-1',
      'tracks': <Object?>[],
    });

    expect(response.sourceFeatures, isA<VibeAudioFeatures>());
    expect(response.sourceFeatures?.energy, 0.5);
  });

  test('a similar track keeps non-null VibeAudioFeatures', () {
    final track = SimilarTrack.fromJson({
      'audioFeatures': _features,
      'distance': 0.1,
      'duration': 3,
      'id': 't-2',
      'similarity': 0.9,
      'title': 'Other',
    });

    expect(track.audioFeatures, isA<VibeAudioFeatures>());
    expect(track.audioFeatures.valence, 0.25);
  });
}

const _features = <String, Object?>{
  'arousal': null,
  'danceability': 0.75,
  'energy': 0.5,
  'valence': 0.25,
};

const _libraryTrack = <String, Object?>{
  'album': {'coverArt': null, 'id': 'al-1', 'title': 'Album'},
  'duration': 3,
  'id': 't-1',
  'source': 'local',
  'title': 'Song',
  'trackNo': 1,
};

const _playlistItem = <String, Object?>{
  'id': 'pi-1',
  'playback': {'isPlayable': true, 'message': null, 'reason': null},
  'playlistId': 'pl-1',
  'sort': 0,
  'type': 'track',
};
