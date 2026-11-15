// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistRecord _$PlaylistRecordFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'createdAt',
      'id',
      'isPublic',
      'mixId',
      'name',
      'spotifyPlaylistId',
      'spotifyPlaylistUrl',
      'updatedAt',
      'userId',
    ],
    disallowNullValues: const [
      'createdAt',
      'id',
      'isPublic',
      'name',
      'updatedAt',
      'userId',
    ],
  );
  return PlaylistRecord(
    createdAt: PlaylistRecord._read_createdAt(json['createdAt']),
    id: json['id'] as String,
    isPublic: json['isPublic'] as bool,
    mixId: json['mixId'] as String?,
    name: json['name'] as String,
    spotifyPlaylistId: json['spotifyPlaylistId'] as String?,
    spotifyPlaylistUrl: json['spotifyPlaylistUrl'] as String?,
    updatedAt: PlaylistRecord._read_updatedAt(json['updatedAt']),
    userId: json['userId'] as String,
    additionalProperties:
        PlaylistRecord._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistRecord._readExtras(
            PlaylistRecord._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistRecordToJson(PlaylistRecord instance) =>
    <String, dynamic>{
      'createdAt': ?PlaylistRecord._write_createdAt(instance.createdAt),
      'id': instance.id,
      'isPublic': instance.isPublic,
      'mixId': instance.mixId,
      'name': instance.name,
      'spotifyPlaylistId': instance.spotifyPlaylistId,
      'spotifyPlaylistUrl': instance.spotifyPlaylistUrl,
      'updatedAt': ?PlaylistRecord._write_updatedAt(instance.updatedAt),
      'userId': instance.userId,
    };
