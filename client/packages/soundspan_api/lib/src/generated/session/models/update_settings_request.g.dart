// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_settings_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateSettingsRequest _$UpdateSettingsRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    disallowNullValues: const [
      'loudnessMode',
      'maxCacheSizeMb',
      'playbackQuality',
    ],
  );
  return UpdateSettingsRequest(
    loudnessMode: UpdateSettingsRequest._read_loudnessMode(
      json['loudnessMode'],
    ),
    maxCacheSizeMb: UpdateSettingsRequest._read_maxCacheSizeMb(
      json['maxCacheSizeMb'],
    ),
    playbackQuality: UpdateSettingsRequest._read_playbackQuality(
      json['playbackQuality'],
    ),
    additionalProperties:
        UpdateSettingsRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : UpdateSettingsRequest._readExtras(
            UpdateSettingsRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$UpdateSettingsRequestToJson(
  UpdateSettingsRequest instance,
) => <String, dynamic>{
  'loudnessMode': ?UpdateSettingsRequest._write_loudnessMode(
    instance.loudnessMode,
  ),
  'maxCacheSizeMb': ?UpdateSettingsRequest._write_maxCacheSizeMb(
    instance.maxCacheSizeMb,
  ),
  'playbackQuality': ?UpdateSettingsRequest._write_playbackQuality(
    instance.playbackQuality,
  ),
};
