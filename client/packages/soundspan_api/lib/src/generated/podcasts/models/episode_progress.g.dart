// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodeProgress _$EpisodeProgressFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'currentTime',
      'isFinished',
      'lastPlayedAt',
      'progress',
    ],
    disallowNullValues: const [
      'currentTime',
      'isFinished',
      'lastPlayedAt',
      'progress',
    ],
  );
  return EpisodeProgress(
    currentTime: json['currentTime'] as num,
    isFinished: json['isFinished'] as bool,
    lastPlayedAt: EpisodeProgress._read_lastPlayedAt(json['lastPlayedAt']),
    progress: json['progress'] as num,
    additionalProperties:
        EpisodeProgress._extras(json, 'additionalProperties') == null
        ? const {}
        : EpisodeProgress._readExtras(
            EpisodeProgress._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$EpisodeProgressToJson(
  EpisodeProgress instance,
) => <String, dynamic>{
  'currentTime': instance.currentTime,
  'isFinished': instance.isFinished,
  'lastPlayedAt': ?EpisodeProgress._write_lastPlayedAt(instance.lastPlayedAt),
  'progress': instance.progress,
};
