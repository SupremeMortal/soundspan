// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_queue_item_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenQueueItemArtist _$ListenQueueItemArtistFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name'],
    disallowNullValues: const ['id', 'name'],
  );
  return ListenQueueItemArtist(
    id: json['id'] as String,
    name: json['name'] as String,
    additionalProperties:
        ListenQueueItemArtist._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenQueueItemArtist._readExtras(
            ListenQueueItemArtist._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenQueueItemArtistToJson(
  ListenQueueItemArtist instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};
