// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_episode_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedEpisodeProgress _$SavedEpisodeProgressFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['currentTime', 'isFinished', 'progress'],
    disallowNullValues: const ['currentTime', 'isFinished', 'progress'],
  );
  return SavedEpisodeProgress(
    currentTime: json['currentTime'] as num,
    isFinished: json['isFinished'] as bool,
    progress: json['progress'] as num,
    additionalProperties:
        SavedEpisodeProgress._extras(json, 'additionalProperties') == null
        ? const {}
        : SavedEpisodeProgress._readExtras(
            SavedEpisodeProgress._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SavedEpisodeProgressToJson(
  SavedEpisodeProgress instance,
) => <String, dynamic>{
  'currentTime': instance.currentTime,
  'isFinished': instance.isFinished,
  'progress': instance.progress,
};
