// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PodcastSummary _$PodcastSummaryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'author',
      'episodeCount',
      'genres',
      'id',
      'isExternal',
      'itunesId',
      'title',
    ],
    disallowNullValues: const [
      'author',
      'coverUrl',
      'episodeCount',
      'feedUrl',
      'genres',
      'id',
      'isExternal',
      'itunesId',
      'title',
    ],
  );
  return PodcastSummary(
    author: json['author'] as String,
    coverUrl: json['coverUrl'] as String?,
    episodeCount: PodcastSummary._read_episodeCount(json['episodeCount']),
    feedUrl: json['feedUrl'] as String?,
    genres: (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
    id: json['id'] as String,
    isExternal: json['isExternal'] as bool,
    itunesId: PodcastSummary._read_itunesId(json['itunesId']),
    title: json['title'] as String,
    additionalProperties:
        PodcastSummary._extras(json, 'additionalProperties') == null
        ? const {}
        : PodcastSummary._readExtras(
            PodcastSummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PodcastSummaryToJson(
  PodcastSummary instance,
) => <String, dynamic>{
  'author': instance.author,
  'coverUrl': ?instance.coverUrl,
  'episodeCount': ?PodcastSummary._write_episodeCount(instance.episodeCount),
  'feedUrl': ?instance.feedUrl,
  'genres': instance.genres,
  'id': instance.id,
  'isExternal': instance.isExternal,
  'itunesId': ?PodcastSummary._write_itunesId(instance.itunesId),
  'title': instance.title,
};
