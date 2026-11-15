// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_podcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchPodcast _$SearchPodcastFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'author',
      'description',
      'episodeCount',
      'id',
      'imageUrl',
      'title',
    ],
    disallowNullValues: const ['episodeCount', 'id', 'rank', 'title'],
  );
  return SearchPodcast(
    author: json['author'] as String?,
    description: json['description'] as String?,
    episodeCount: SearchPodcast._read_episodeCount(json['episodeCount']),
    id: json['id'] as String,
    imageUrl: json['imageUrl'] as String?,
    rank: json['rank'] as num?,
    title: json['title'] as String,
    additionalProperties:
        SearchPodcast._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchPodcast._readExtras(
            SearchPodcast._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchPodcastToJson(SearchPodcast instance) =>
    <String, dynamic>{
      'author': instance.author,
      'description': instance.description,
      'episodeCount': ?SearchPodcast._write_episodeCount(instance.episodeCount),
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'rank': ?instance.rank,
      'title': instance.title,
    };
