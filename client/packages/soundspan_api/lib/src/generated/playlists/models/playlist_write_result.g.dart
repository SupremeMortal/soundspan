// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_write_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistWriteResult _$PlaylistWriteResultFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['message'],
    disallowNullValues: const ['message'],
  );
  return PlaylistWriteResult(
    message: json['message'] as String,
    additionalProperties:
        PlaylistWriteResult._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistWriteResult._readExtras(
            PlaylistWriteResult._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistWriteResultToJson(
  PlaylistWriteResult instance,
) => <String, dynamic>{'message': instance.message};
