// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_cover_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistCoverItem _$PlaylistCoverItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'track'],
    disallowNullValues: const ['id'],
  );
  return PlaylistCoverItem(
    id: json['id'] as String,
    track: json['track'] == null
        ? null
        : PlaylistCoverItemTrack.fromJson(
            json['track'] as Map<String, dynamic>,
          ),
    additionalProperties:
        PlaylistCoverItem._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistCoverItem._readExtras(
            PlaylistCoverItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistCoverItemToJson(PlaylistCoverItem instance) =>
    <String, dynamic>{'id': instance.id, 'track': instance.track?.toJson()};
