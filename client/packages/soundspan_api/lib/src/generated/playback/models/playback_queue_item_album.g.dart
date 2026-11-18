// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_queue_item_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackQueueItemAlbum _$PlaybackQueueItemAlbumFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['coverArt', 'id', 'title'],
    disallowNullValues: const ['id', 'title'],
  );
  return PlaybackQueueItemAlbum(
    coverArt: json['coverArt'] as String?,
    id: json['id'] as String,
    title: json['title'] as String,
    additionalProperties:
        PlaybackQueueItemAlbum._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaybackQueueItemAlbum._readExtras(
            PlaybackQueueItemAlbum._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaybackQueueItemAlbumToJson(
  PlaybackQueueItemAlbum instance,
) => <String, dynamic>{
  'coverArt': instance.coverArt,
  'id': instance.id,
  'title': instance.title,
};
