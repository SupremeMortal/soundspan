// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_episode_progress_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateEpisodeProgressRequest _$UpdateEpisodeProgressRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['currentTime', 'duration'],
    disallowNullValues: const ['currentTime', 'duration', 'isFinished'],
  );
  return UpdateEpisodeProgressRequest(
    currentTime: json['currentTime'] as num,
    duration: json['duration'] as num,
    isFinished: json['isFinished'] as bool?,
    additionalProperties:
        UpdateEpisodeProgressRequest._extras(json, 'additionalProperties') ==
            null
        ? const {}
        : UpdateEpisodeProgressRequest._readExtras(
            UpdateEpisodeProgressRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$UpdateEpisodeProgressRequestToJson(
  UpdateEpisodeProgressRequest instance,
) => <String, dynamic>{
  'currentTime': instance.currentTime,
  'duration': instance.duration,
  'isFinished': ?instance.isFinished,
};
