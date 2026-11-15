// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoverResult _$DiscoverResultFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name', 'type'],
    disallowNullValues: const [
      'artist',
      'coverUrl',
      'description',
      'feedUrl',
      'genres',
      'listeners',
      'mbid',
      'name',
      'playbackId',
      'tags',
      'trackCount',
      'type',
    ],
  );
  return DiscoverResult(
    album: json['album'] as String?,
    artist: json['artist'] as String?,
    bio: json['bio'] as String?,
    coverUrl: json['coverUrl'] as String?,
    description: json['description'] as String?,
    durationSec: json['durationSec'] as num?,
    feedUrl: json['feedUrl'] as String?,
    genres: (json['genres'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    id: DiscoverResult._read_id(json['id']),
    image: json['image'] as String?,
    listeners: DiscoverResult._read_listeners(json['listeners']),
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    playbackId: json['playbackId'] as String?,
    previewUrl: json['previewUrl'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    trackCount: DiscoverResult._read_trackCount(json['trackCount']),
    type: DiscoverResult._read_type(json['type']),
    url: json['url'] as String?,
    additionalProperties:
        DiscoverResult._extras(json, 'additionalProperties') == null
        ? const {}
        : DiscoverResult._readExtras(
            DiscoverResult._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DiscoverResultToJson(DiscoverResult instance) =>
    <String, dynamic>{
      'album': ?instance.album,
      'artist': ?instance.artist,
      'bio': ?instance.bio,
      'coverUrl': ?instance.coverUrl,
      'description': ?instance.description,
      'durationSec': ?instance.durationSec,
      'feedUrl': ?instance.feedUrl,
      'genres': ?instance.genres,
      'id': DiscoverResult._write_id(instance.id),
      'image': ?instance.image,
      'listeners': ?DiscoverResult._write_listeners(instance.listeners),
      'mbid': ?instance.mbid,
      'name': instance.name,
      'playbackId': ?instance.playbackId,
      'previewUrl': ?instance.previewUrl,
      'tags': ?instance.tags,
      'trackCount': ?DiscoverResult._write_trackCount(instance.trackCount),
      'type': ?DiscoverResult._write_type(instance.type),
      'url': ?instance.url,
    };
