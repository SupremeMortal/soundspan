// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackQueueItem _$PlaybackQueueItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['duration', 'id', 'title'],
    disallowNullValues: const [
      'duration',
      'episodeId',
      'id',
      'itemType',
      'playbackId',
      'podcastId',
      'podcastTitle',
      'title',
    ],
  );
  return PlaybackQueueItem(
    album: json['album'] == null
        ? null
        : PlaybackQueueItemAlbum.fromJson(
            json['album'] as Map<String, dynamic>,
          ),
    artist: json['artist'] == null
        ? null
        : PlaybackQueueItemArtist.fromJson(
            json['artist'] as Map<String, dynamic>,
          ),
    coverUrl: json['coverUrl'] as String?,
    duration: json['duration'] as num,
    episodeId: json['episodeId'] as String?,
    id: json['id'] as String,
    itemType: PlaybackQueueItem._read_itemType(json['itemType']),
    playbackId: json['playbackId'] as String?,
    podcastId: json['podcastId'] as String?,
    podcastTitle: json['podcastTitle'] as String?,
    title: json['title'] as String,
    additionalProperties:
        PlaybackQueueItem._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaybackQueueItem._readExtras(
            PlaybackQueueItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaybackQueueItemToJson(PlaybackQueueItem instance) =>
    <String, dynamic>{
      'album': ?instance.album?.toJson(),
      'artist': ?instance.artist?.toJson(),
      'coverUrl': ?instance.coverUrl,
      'duration': instance.duration,
      'episodeId': ?instance.episodeId,
      'id': instance.id,
      'itemType': ?PlaybackQueueItem._write_itemType(instance.itemType),
      'playbackId': ?instance.playbackId,
      'podcastId': ?instance.podcastId,
      'podcastTitle': ?instance.podcastTitle,
      'title': instance.title,
    };
