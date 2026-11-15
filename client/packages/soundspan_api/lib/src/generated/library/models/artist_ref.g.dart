// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistRef _$ArtistRefFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name'],
    disallowNullValues: const ['id', 'name'],
  );
  return ArtistRef(
    id: json['id'] as String,
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    additionalProperties:
        ArtistRef._extras(json, 'additionalProperties') == null
        ? const {}
        : ArtistRef._readExtras(
            ArtistRef._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ArtistRefToJson(ArtistRef instance) => <String, dynamic>{
  'id': instance.id,
  'mbid': ?instance.mbid,
  'name': instance.name,
};
