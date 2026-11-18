// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchItem _$SearchItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['kind', 'score', 'source'],
    disallowNullValues: const [
      'album',
      'artist',
      'catalogue',
      'kind',
      'playlist',
      'podcast',
      'remoteAlbum',
      'remoteTrack',
      'score',
      'source',
      'track',
    ],
  );
  return SearchItem(
    album: json['album'] == null
        ? null
        : SearchAlbum.fromJson(json['album'] as Map<String, dynamic>),
    artist: json['artist'] == null
        ? null
        : SearchArtist.fromJson(json['artist'] as Map<String, dynamic>),
    catalogue: json['catalogue'] == null
        ? null
        : DiscoverResult.fromJson(json['catalogue'] as Map<String, dynamic>),
    kind: SearchItem._read_kind(json['kind']),
    playlist: json['playlist'] == null
        ? null
        : PlaylistSummary.fromJson(json['playlist'] as Map<String, dynamic>),
    podcast: json['podcast'] == null
        ? null
        : SearchPodcast.fromJson(json['podcast'] as Map<String, dynamic>),
    remoteAlbum: json['remoteAlbum'] == null
        ? null
        : SearchRemoteAlbum.fromJson(
            json['remoteAlbum'] as Map<String, dynamic>,
          ),
    remoteTrack: json['remoteTrack'] == null
        ? null
        : SearchRemoteTrack.fromJson(
            json['remoteTrack'] as Map<String, dynamic>,
          ),
    score: json['score'] as num,
    source: SearchItem._read_source(json['source']),
    track: json['track'] == null
        ? null
        : SearchTrack.fromJson(json['track'] as Map<String, dynamic>),
    additionalProperties:
        SearchItem._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchItem._readExtras(
            SearchItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchItemToJson(SearchItem instance) =>
    <String, dynamic>{
      'album': ?instance.album?.toJson(),
      'artist': ?instance.artist?.toJson(),
      'catalogue': ?instance.catalogue?.toJson(),
      'kind': ?SearchItem._write_kind(instance.kind),
      'playlist': ?instance.playlist?.toJson(),
      'podcast': ?instance.podcast?.toJson(),
      'remoteAlbum': ?instance.remoteAlbum?.toJson(),
      'remoteTrack': ?instance.remoteTrack?.toJson(),
      'score': instance.score,
      'source': ?SearchItem._write_source(instance.source),
      'track': ?instance.track?.toJson(),
    };
