// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueContext _$QueueContextFromJson(Map<String, dynamic> json) =>
    _QueueContext(
      kind: $enumDecode(_$QueueContextKindEnumMap, json['kind']),
      id: json['id'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$QueueContextToJson(_QueueContext instance) =>
    <String, dynamic>{
      'kind': _$QueueContextKindEnumMap[instance.kind]!,
      'id': instance.id,
      'title': instance.title,
    };

const _$QueueContextKindEnumMap = {
  QueueContextKind.album: 'album',
  QueueContextKind.playlist: 'playlist',
  QueueContextKind.artist: 'artist',
  QueueContextKind.mix: 'mix',
  QueueContextKind.radio: 'radio',
  QueueContextKind.search: 'search',
  QueueContextKind.library: 'library',
  QueueContextKind.single: 'single',
};

TrackQueueItem _$TrackQueueItemFromJson(Map<String, dynamic> json) =>
    TrackQueueItem(
      queueItemId: json['queueItemId'] as String,
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
      context: QueueContext.fromJson(json['context'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$TrackQueueItemToJson(TrackQueueItem instance) =>
    <String, dynamic>{
      'queueItemId': instance.queueItemId,
      'track': instance.track,
      'context': instance.context,
      'type': instance.$type,
    };

EpisodeQueueItem _$EpisodeQueueItemFromJson(Map<String, dynamic> json) =>
    EpisodeQueueItem(
      queueItemId: json['queueItemId'] as String,
      episode: Episode.fromJson(json['episode'] as Map<String, dynamic>),
      podcast: Podcast.fromJson(json['podcast'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$EpisodeQueueItemToJson(EpisodeQueueItem instance) =>
    <String, dynamic>{
      'queueItemId': instance.queueItemId,
      'episode': instance.episode,
      'podcast': instance.podcast,
      'type': instance.$type,
    };
