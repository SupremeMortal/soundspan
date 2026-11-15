// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribed_podcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribedPodcast _$SubscribedPodcastFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'author',
      'autoDownloadEpisodes',
      'coverUrl',
      'description',
      'episodeCount',
      'episodes',
      'id',
      'title',
    ],
    disallowNullValues: const [
      'autoDownloadEpisodes',
      'episodeCount',
      'episodes',
      'id',
      'title',
    ],
  );
  return SubscribedPodcast(
    author: json['author'] as String?,
    autoDownloadEpisodes: json['autoDownloadEpisodes'] as bool,
    coverUrl: json['coverUrl'] as String?,
    description: json['description'] as String?,
    episodeCount: SubscribedPodcast._read_episodeCount(json['episodeCount']),
    episodes: (json['episodes'] as List<dynamic>)
        .map(
          (e) => SubscribedPodcastEpisode.fromJson(e as Map<String, dynamic>),
        )
        .toList(),
    id: json['id'] as String,
    title: json['title'] as String,
    additionalProperties:
        SubscribedPodcast._extras(json, 'additionalProperties') == null
        ? const {}
        : SubscribedPodcast._readExtras(
            SubscribedPodcast._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SubscribedPodcastToJson(
  SubscribedPodcast instance,
) => <String, dynamic>{
  'author': instance.author,
  'autoDownloadEpisodes': instance.autoDownloadEpisodes,
  'coverUrl': instance.coverUrl,
  'description': instance.description,
  'episodeCount': ?SubscribedPodcast._write_episodeCount(instance.episodeCount),
  'episodes': instance.episodes.map((e) => e.toJson()).toList(),
  'id': instance.id,
  'title': instance.title,
};
