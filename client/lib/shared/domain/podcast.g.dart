// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Podcast _$PodcastFromJson(Map<String, dynamic> json) => _Podcast(
  id: json['id'] as String,
  title: json['title'] as String,
  author: json['author'] as String?,
  artworkRef: json['artworkRef'] as String?,
);

Map<String, dynamic> _$PodcastToJson(_Podcast instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'author': instance.author,
  'artworkRef': instance.artworkRef,
};

_PodcastSummary _$PodcastSummaryFromJson(Map<String, dynamic> json) =>
    _PodcastSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      artworkRef: json['artworkRef'] as String?,
    );

Map<String, dynamic> _$PodcastSummaryToJson(_PodcastSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'artworkRef': instance.artworkRef,
    };

_Episode _$EpisodeFromJson(Map<String, dynamic> json) => _Episode(
  id: json['id'] as String,
  podcastId: json['podcastId'] as String,
  title: json['title'] as String,
  durationSec: (json['durationSec'] as num?)?.toInt(),
  publishedAt: json['publishedAt'] == null
      ? null
      : DateTime.parse(json['publishedAt'] as String),
  artworkRef: json['artworkRef'] as String?,
);

Map<String, dynamic> _$EpisodeToJson(_Episode instance) => <String, dynamic>{
  'id': instance.id,
  'podcastId': instance.podcastId,
  'title': instance.title,
  'durationSec': instance.durationSec,
  'publishedAt': instance.publishedAt?.toIso8601String(),
  'artworkRef': instance.artworkRef,
};
