// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'popular_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PopularArtist _$PopularArtistFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'image', 'listeners', 'name', 'playCount'],
    disallowNullValues: const [
      'id',
      'listeners',
      'mbid',
      'name',
      'playCount',
      'url',
    ],
  );
  return PopularArtist(
    id: json['id'] as String,
    image: json['image'] as String?,
    listeners: PopularArtist._read_listeners(json['listeners']),
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    playCount: PopularArtist._read_playCount(json['playCount']),
    url: json['url'] as String?,
    additionalProperties:
        PopularArtist._extras(json, 'additionalProperties') == null
        ? const {}
        : PopularArtist._readExtras(
            PopularArtist._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PopularArtistToJson(PopularArtist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image': instance.image,
      'listeners': ?PopularArtist._write_listeners(instance.listeners),
      'mbid': ?instance.mbid,
      'name': instance.name,
      'playCount': ?PopularArtist._write_playCount(instance.playCount),
      'url': ?instance.url,
    };
