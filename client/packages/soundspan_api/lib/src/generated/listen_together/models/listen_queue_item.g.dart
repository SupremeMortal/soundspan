// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenQueueItem _$ListenQueueItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['album', 'artist', 'duration', 'id', 'title'],
    disallowNullValues: const [
      'album',
      'artist',
      'duration',
      'id',
      'playbackId',
      'title',
    ],
  );
  return ListenQueueItem(
    album: ListenQueueItemAlbum.fromJson(json['album'] as Map<String, dynamic>),
    artist: ListenQueueItemArtist.fromJson(
      json['artist'] as Map<String, dynamic>,
    ),
    duration: ListenQueueItem._read_duration(json['duration']),
    id: json['id'] as String,
    playbackId: json['playbackId'] as String?,
    title: json['title'] as String,
    additionalProperties:
        ListenQueueItem._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenQueueItem._readExtras(
            ListenQueueItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenQueueItemToJson(ListenQueueItem instance) =>
    <String, dynamic>{
      'album': instance.album.toJson(),
      'artist': instance.artist.toJson(),
      'duration': ?ListenQueueItem._write_duration(instance.duration),
      'id': instance.id,
      'playbackId': ?instance.playbackId,
      'title': instance.title,
    };
