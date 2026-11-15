// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribed_podcast_episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribedPodcastEpisode _$SubscribedPodcastEpisodeFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const [
      'coverUrl',
      'description',
      'duration',
      'id',
      'progress',
      'publishedAt',
      'title',
    ],
    disallowNullValues: const [
      'duration',
      'id',
      'progress',
      'publishedAt',
      'title',
    ],
  );
  return SubscribedPodcastEpisode(
    coverUrl: json['coverUrl'] as String?,
    description: json['description'] as String?,
    duration: SubscribedPodcastEpisode._read_duration(json['duration']),
    id: json['id'] as String,
    progress: EpisodeProgress.fromJson(
      json['progress'] as Map<String, dynamic>,
    ),
    publishedAt: SubscribedPodcastEpisode._read_publishedAt(
      json['publishedAt'],
    ),
    title: json['title'] as String,
    additionalProperties:
        SubscribedPodcastEpisode._extras(json, 'additionalProperties') == null
        ? const {}
        : SubscribedPodcastEpisode._readExtras(
            SubscribedPodcastEpisode._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SubscribedPodcastEpisodeToJson(
  SubscribedPodcastEpisode instance,
) => <String, dynamic>{
  'coverUrl': instance.coverUrl,
  'description': instance.description,
  'duration': ?SubscribedPodcastEpisode._write_duration(instance.duration),
  'id': instance.id,
  'progress': instance.progress.toJson(),
  'publishedAt': ?SubscribedPodcastEpisode._write_publishedAt(
    instance.publishedAt,
  ),
  'title': instance.title,
};
