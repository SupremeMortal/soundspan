// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'albums',
      'artists',
      'episodes',
      'podcasts',
      'remoteAlbums',
      'remoteTracks',
      'tracks',
    ],
    disallowNullValues: const [
      'albums',
      'artists',
      'episodes',
      'podcasts',
      'remoteAlbums',
      'remoteTracks',
      'tracks',
    ],
  );
  return SearchResponse(
    albums: (json['albums'] as List<dynamic>)
        .map((e) => SearchAlbum.fromJson(e as Map<String, dynamic>))
        .toList(),
    artists: (json['artists'] as List<dynamic>)
        .map((e) => SearchArtist.fromJson(e as Map<String, dynamic>))
        .toList(),
    episodes: (json['episodes'] as List<dynamic>)
        .map((e) => SearchEpisode.fromJson(e as Map<String, dynamic>))
        .toList(),
    podcasts: (json['podcasts'] as List<dynamic>)
        .map((e) => SearchPodcast.fromJson(e as Map<String, dynamic>))
        .toList(),
    remoteAlbums: (json['remoteAlbums'] as List<dynamic>)
        .map((e) => SearchRemoteAlbum.fromJson(e as Map<String, dynamic>))
        .toList(),
    remoteTracks: (json['remoteTracks'] as List<dynamic>)
        .map((e) => SearchRemoteTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => SearchTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        SearchResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchResponse._readExtras(
            SearchResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchResponseToJson(SearchResponse instance) =>
    <String, dynamic>{
      'albums': instance.albums.map((e) => e.toJson()).toList(),
      'artists': instance.artists.map((e) => e.toJson()).toList(),
      'episodes': instance.episodes.map((e) => e.toJson()).toList(),
      'podcasts': instance.podcasts.map((e) => e.toJson()).toList(),
      'remoteAlbums': instance.remoteAlbums.map((e) => e.toJson()).toList(),
      'remoteTracks': instance.remoteTracks.map((e) => e.toJson()).toList(),
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };
