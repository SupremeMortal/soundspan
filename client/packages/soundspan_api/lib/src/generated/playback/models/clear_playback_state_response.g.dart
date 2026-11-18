// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clear_playback_state_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClearPlaybackStateResponse _$ClearPlaybackStateResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['success'],
    disallowNullValues: const ['success'],
  );
  return ClearPlaybackStateResponse(
    success: json['success'] as bool,
    additionalProperties:
        ClearPlaybackStateResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : ClearPlaybackStateResponse._readExtras(
            ClearPlaybackStateResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ClearPlaybackStateResponseToJson(
  ClearPlaybackStateResponse instance,
) => <String, dynamic>{'success': instance.success};
