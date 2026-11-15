// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast_episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PodcastEpisode _$PodcastEpisodeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'description',
      'duration',
      'episodeNumber',
      'id',
      'imageUrl',
      'isDownloaded',
      'progress',
      'publishedAt',
      'season',
      'title',
    ],
    disallowNullValues: const [
      'duration',
      'id',
      'isDownloaded',
      'progress',
      'publishedAt',
      'title',
    ],
  );
  return PodcastEpisode(
    description: json['description'] as String?,
    duration: PodcastEpisode._read_duration(json['duration']),
    episodeNumber: PodcastEpisode._read_episodeNumber(json['episodeNumber']),
    id: json['id'] as String,
    imageUrl: json['imageUrl'] as String?,
    isDownloaded: json['isDownloaded'] as bool,
    progress: EpisodeProgress.fromJson(
      json['progress'] as Map<String, dynamic>,
    ),
    publishedAt: PodcastEpisode._read_publishedAt(json['publishedAt']),
    season: PodcastEpisode._read_season(json['season']),
    title: json['title'] as String,
    additionalProperties:
        PodcastEpisode._extras(json, 'additionalProperties') == null
        ? const {}
        : PodcastEpisode._readExtras(
            PodcastEpisode._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PodcastEpisodeToJson(
  PodcastEpisode instance,
) => <String, dynamic>{
  'description': instance.description,
  'duration': ?PodcastEpisode._write_duration(instance.duration),
  'episodeNumber': PodcastEpisode._write_episodeNumber(instance.episodeNumber),
  'id': instance.id,
  'imageUrl': instance.imageUrl,
  'isDownloaded': instance.isDownloaded,
  'progress': instance.progress.toJson(),
  'publishedAt': ?PodcastEpisode._write_publishedAt(instance.publishedAt),
  'season': PodcastEpisode._write_season(instance.season),
  'title': instance.title,
};
