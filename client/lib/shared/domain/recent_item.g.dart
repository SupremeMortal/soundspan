// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentArtist _$RecentArtistFromJson(Map<String, dynamic> json) => RecentArtist(
  artist: Artist.fromJson(json['artist'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$RecentArtistToJson(RecentArtist instance) =>
    <String, dynamic>{'artist': instance.artist, 'kind': instance.$type};

RecentPodcast _$RecentPodcastFromJson(Map<String, dynamic> json) =>
    RecentPodcast(
      podcast: Podcast.fromJson(json['podcast'] as Map<String, dynamic>),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$RecentPodcastToJson(RecentPodcast instance) =>
    <String, dynamic>{'podcast': instance.podcast, 'kind': instance.$type};
