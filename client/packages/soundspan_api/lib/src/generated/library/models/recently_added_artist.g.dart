// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recently_added_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentlyAddedArtist _$RecentlyAddedArtistFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['albumCount', 'coverArt', 'id', 'mbid', 'name'],
    disallowNullValues: const ['albumCount', 'id', 'name'],
  );
  return RecentlyAddedArtist(
    albumCount: RecentlyAddedArtist._read_albumCount(json['albumCount']),
    coverArt: json['coverArt'] as String?,
    id: json['id'] as String,
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    additionalProperties:
        RecentlyAddedArtist._extras(json, 'additionalProperties') == null
        ? const {}
        : RecentlyAddedArtist._readExtras(
            RecentlyAddedArtist._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RecentlyAddedArtistToJson(
  RecentlyAddedArtist instance,
) => <String, dynamic>{
  'albumCount': ?RecentlyAddedArtist._write_albumCount(instance.albumCount),
  'coverArt': instance.coverArt,
  'id': instance.id,
  'mbid': instance.mbid,
  'name': instance.name,
};
