// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_artist_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackArtistRef _$TrackArtistRefFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['name'],
    disallowNullValues: const ['id', 'name'],
  );
  return TrackArtistRef(
    id: json['id'] as String?,
    name: json['name'] as String,
    additionalProperties:
        TrackArtistRef._extras(json, 'additionalProperties') == null
        ? const {}
        : TrackArtistRef._readExtras(
            TrackArtistRef._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TrackArtistRefToJson(TrackArtistRef instance) =>
    <String, dynamic>{'id': ?instance.id, 'name': instance.name};
