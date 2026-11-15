// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_item_playback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistItemPlayback _$PlaylistItemPlaybackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['isPlayable', 'message', 'reason'],
    disallowNullValues: const ['isPlayable'],
  );
  return PlaylistItemPlayback(
    isPlayable: json['isPlayable'] as bool,
    message: json['message'] as String?,
    reason: json['reason'] as String?,
    additionalProperties:
        PlaylistItemPlayback._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistItemPlayback._readExtras(
            PlaylistItemPlayback._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistItemPlaybackToJson(
  PlaylistItemPlayback instance,
) => <String, dynamic>{
  'isPlayable': instance.isPlayable,
  'message': instance.message,
  'reason': instance.reason,
};
