// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommended_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendedArtist _$RecommendedArtistFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'albumCount',
      'coverArt',
      'heroUrl',
      'id',
      'mbid',
      'name',
    ],
    disallowNullValues: const ['albumCount', 'id', 'name'],
  );
  return RecommendedArtist(
    albumCount: RecommendedArtist._read_albumCount(json['albumCount']),
    coverArt: json['coverArt'] as String?,
    heroUrl: json['heroUrl'] as String?,
    id: json['id'] as String,
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    additionalProperties:
        RecommendedArtist._extras(json, 'additionalProperties') == null
        ? const {}
        : RecommendedArtist._readExtras(
            RecommendedArtist._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RecommendedArtistToJson(RecommendedArtist instance) =>
    <String, dynamic>{
      'albumCount': ?RecommendedArtist._write_albumCount(instance.albumCount),
      'coverArt': instance.coverArt,
      'heroUrl': instance.heroUrl,
      'id': instance.id,
      'mbid': instance.mbid,
      'name': instance.name,
    };
