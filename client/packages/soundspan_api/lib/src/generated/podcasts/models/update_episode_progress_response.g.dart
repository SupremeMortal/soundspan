// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_episode_progress_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateEpisodeProgressResponse _$UpdateEpisodeProgressResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['progress', 'success'],
    disallowNullValues: const ['progress', 'success'],
  );
  return UpdateEpisodeProgressResponse(
    progress: SavedEpisodeProgress.fromJson(
      json['progress'] as Map<String, dynamic>,
    ),
    success: json['success'] as bool,
    additionalProperties:
        UpdateEpisodeProgressResponse._extras(json, 'additionalProperties') ==
            null
        ? const {}
        : UpdateEpisodeProgressResponse._readExtras(
            UpdateEpisodeProgressResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$UpdateEpisodeProgressResponseToJson(
  UpdateEpisodeProgressResponse instance,
) => <String, dynamic>{
  'progress': instance.progress.toJson(),
  'success': instance.success,
};
