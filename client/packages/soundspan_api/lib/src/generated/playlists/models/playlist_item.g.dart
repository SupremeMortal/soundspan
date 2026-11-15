// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistItem _$PlaylistItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'playback',
      'playlistId',
      'sort',
      'track',
      'type',
    ],
    disallowNullValues: const ['id', 'playback', 'playlistId', 'sort', 'type'],
  );
  return PlaylistItem(
    id: json['id'] as String,
    playback: PlaylistItemPlayback.fromJson(
      json['playback'] as Map<String, dynamic>,
    ),
    playlistId: json['playlistId'] as String,
    sort: PlaylistItem._read_sort(json['sort']),
    track: PlaylistItem._read_track(json['track']),
    type: PlaylistItem._read_type(json['type']),
    additionalProperties:
        PlaylistItem._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistItem._readExtras(
            PlaylistItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistItemToJson(PlaylistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'playback': instance.playback.toJson(),
      'playlistId': instance.playlistId,
      'sort': ?PlaylistItem._write_sort(instance.sort),
      'track': PlaylistItem._write_track(instance.track),
      'type': ?PlaylistItem._write_type(instance.type),
    };
