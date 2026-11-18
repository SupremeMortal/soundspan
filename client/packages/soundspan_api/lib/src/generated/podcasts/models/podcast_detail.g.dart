// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PodcastDetail _$PodcastDetailFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'author',
      'autoDownloadEpisodes',
      'coverUrl',
      'description',
      'episodes',
      'feedUrl',
      'genres',
      'id',
      'isSubscribed',
      'title',
    ],
    disallowNullValues: const [
      'autoDownloadEpisodes',
      'episodes',
      'feedUrl',
      'genres',
      'id',
      'isSubscribed',
      'title',
    ],
  );
  return PodcastDetail(
    author: json['author'] as String?,
    autoDownloadEpisodes: json['autoDownloadEpisodes'] as bool,
    coverUrl: json['coverUrl'] as String?,
    description: json['description'] as String?,
    episodes: (json['episodes'] as List<dynamic>)
        .map((e) => PodcastEpisode.fromJson(e as Map<String, dynamic>))
        .toList(),
    feedUrl: json['feedUrl'] as String,
    genres: (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
    id: json['id'] as String,
    isSubscribed: json['isSubscribed'] as bool,
    title: json['title'] as String,
    additionalProperties:
        PodcastDetail._extras(json, 'additionalProperties') == null
        ? const {}
        : PodcastDetail._readExtras(
            PodcastDetail._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PodcastDetailToJson(PodcastDetail instance) =>
    <String, dynamic>{
      'author': instance.author,
      'autoDownloadEpisodes': instance.autoDownloadEpisodes,
      'coverUrl': instance.coverUrl,
      'description': instance.description,
      'episodes': instance.episodes.map((e) => e.toJson()).toList(),
      'feedUrl': instance.feedUrl,
      'genres': instance.genres,
      'id': instance.id,
      'isSubscribed': instance.isSubscribed,
      'title': instance.title,
    };
