// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Podcast _$PodcastFromJson(Map<String, dynamic> json) => _Podcast(
  id: json['id'] as String,
  title: json['title'] as String,
  author: json['author'] as String?,
  description: json['description'] as String?,
  artworkRef: json['artworkRef'] as String?,
  episodeCount: (json['episodeCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$PodcastToJson(_Podcast instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'author': instance.author,
  'description': instance.description,
  'artworkRef': instance.artworkRef,
  'episodeCount': instance.episodeCount,
};

_PodcastSummary _$PodcastSummaryFromJson(Map<String, dynamic> json) =>
    _PodcastSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      artworkRef: json['artworkRef'] as String?,
      feedUrl: json['feedUrl'] as String?,
      itunesId: json['itunesId'] as String?,
    );

Map<String, dynamic> _$PodcastSummaryToJson(_PodcastSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'artworkRef': instance.artworkRef,
      'feedUrl': instance.feedUrl,
      'itunesId': instance.itunesId,
    };

_Episode _$EpisodeFromJson(Map<String, dynamic> json) => _Episode(
  id: json['id'] as String,
  podcastId: json['podcastId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  durationSec: (json['durationSec'] as num?)?.toInt(),
  publishedAt: json['publishedAt'] == null
      ? null
      : DateTime.parse(json['publishedAt'] as String),
  artworkRef: json['artworkRef'] as String?,
  progress: json['progress'] == null
      ? null
      : EpisodeProgress.fromJson(json['progress'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EpisodeToJson(_Episode instance) => <String, dynamic>{
  'id': instance.id,
  'podcastId': instance.podcastId,
  'title': instance.title,
  'description': instance.description,
  'durationSec': instance.durationSec,
  'publishedAt': instance.publishedAt?.toIso8601String(),
  'artworkRef': instance.artworkRef,
  'progress': instance.progress,
};

_EpisodeProgress _$EpisodeProgressFromJson(Map<String, dynamic> json) =>
    _EpisodeProgress(
      currentTimeSec: (json['currentTimeSec'] as num).toDouble(),
      isFinished: json['isFinished'] as bool,
    );

Map<String, dynamic> _$EpisodeProgressToJson(_EpisodeProgress instance) =>
    <String, dynamic>{
      'currentTimeSec': instance.currentTimeSec,
      'isFinished': instance.isFinished,
    };
