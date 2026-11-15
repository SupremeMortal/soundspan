// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchEpisode _$SearchEpisodeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'audioUrl',
      'description',
      'duration',
      'id',
      'podcastId',
      'podcastTitle',
      'publishedAt',
      'rank',
      'title',
    ],
    disallowNullValues: const [
      'audioUrl',
      'duration',
      'id',
      'podcastId',
      'podcastTitle',
      'publishedAt',
      'rank',
      'title',
    ],
  );
  return SearchEpisode(
    audioUrl: json['audioUrl'] as String,
    description: json['description'] as String?,
    duration: SearchEpisode._read_duration(json['duration']),
    id: json['id'] as String,
    podcastId: json['podcastId'] as String,
    podcastTitle: json['podcastTitle'] as String,
    publishedAt: SearchEpisode._read_publishedAt(json['publishedAt']),
    rank: json['rank'] as num,
    title: json['title'] as String,
    additionalProperties:
        SearchEpisode._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchEpisode._readExtras(
            SearchEpisode._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchEpisodeToJson(SearchEpisode instance) =>
    <String, dynamic>{
      'audioUrl': instance.audioUrl,
      'description': instance.description,
      'duration': ?SearchEpisode._write_duration(instance.duration),
      'id': instance.id,
      'podcastId': instance.podcastId,
      'podcastTitle': instance.podcastTitle,
      'publishedAt': ?SearchEpisode._write_publishedAt(instance.publishedAt),
      'rank': instance.rank,
      'title': instance.title,
    };
