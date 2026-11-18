// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_queue_item_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackQueueItemArtist _$PlaybackQueueItemArtistFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name'],
    disallowNullValues: const ['id', 'name'],
  );
  return PlaybackQueueItemArtist(
    id: json['id'] as String,
    name: json['name'] as String,
    additionalProperties:
        PlaybackQueueItemArtist._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaybackQueueItemArtist._readExtras(
            PlaybackQueueItemArtist._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaybackQueueItemArtistToJson(
  PlaybackQueueItemArtist instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};
