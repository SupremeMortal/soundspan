// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_playback_state_request_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavePlaybackStateRequestQueueItem _$SavePlaybackStateRequestQueueItemFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    disallowNullValues: const [
      'coverUrl',
      'duration',
      'episodeId',
      'id',
      'itemType',
      'metadata',
      'playbackId',
      'podcastId',
      'podcastTitle',
      'title',
    ],
  );
  return SavePlaybackStateRequestQueueItem(
    coverUrl: json['coverUrl'] as String?,
    duration: json['duration'] as num?,
    episodeId: json['episodeId'] as String?,
    id: json['id'] as String?,
    itemType: SavePlaybackStateRequestQueueItem._read_itemType(
      json['itemType'],
    ),
    metadata: json['metadata'] == null
        ? null
        : PlaybackMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String?,
    podcastId: json['podcastId'] as String?,
    podcastTitle: json['podcastTitle'] as String?,
    title: json['title'] as String?,
    additionalProperties:
        SavePlaybackStateRequestQueueItem._extras(
              json,
              'additionalProperties',
            ) ==
            null
        ? const {}
        : SavePlaybackStateRequestQueueItem._readExtras(
            SavePlaybackStateRequestQueueItem._extras(
              json,
              'additionalProperties',
            ),
          ),
  );
}

Map<String, dynamic> _$SavePlaybackStateRequestQueueItemToJson(
  SavePlaybackStateRequestQueueItem instance,
) => <String, dynamic>{
  'coverUrl': ?instance.coverUrl,
  'duration': ?instance.duration,
  'episodeId': ?instance.episodeId,
  'id': ?instance.id,
  'itemType': ?SavePlaybackStateRequestQueueItem._write_itemType(
    instance.itemType,
  ),
  'metadata': ?instance.metadata?.toJson(),
  'playbackId': ?instance.playbackId,
  'podcastId': ?instance.podcastId,
  'podcastTitle': ?instance.podcastTitle,
  'title': ?instance.title,
};
