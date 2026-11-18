// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked_playlist_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LikedPlaylistInfo _$LikedPlaylistInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['description', 'id', 'name'],
    disallowNullValues: const ['description', 'id', 'name'],
  );
  return LikedPlaylistInfo(
    description: json['description'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    additionalProperties:
        LikedPlaylistInfo._extras(json, 'additionalProperties') == null
        ? const {}
        : LikedPlaylistInfo._readExtras(
            LikedPlaylistInfo._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LikedPlaylistInfoToJson(LikedPlaylistInfo instance) =>
    <String, dynamic>{
      'description': instance.description,
      'id': instance.id,
      'name': instance.name,
    };
