// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_queue_item_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenQueueItemAlbum _$ListenQueueItemAlbumFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['coverArt', 'id', 'title'],
    disallowNullValues: const ['id', 'title'],
  );
  return ListenQueueItemAlbum(
    coverArt: json['coverArt'] as String?,
    id: json['id'] as String,
    title: json['title'] as String,
    additionalProperties:
        ListenQueueItemAlbum._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenQueueItemAlbum._readExtras(
            ListenQueueItemAlbum._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenQueueItemAlbumToJson(
  ListenQueueItemAlbum instance,
) => <String, dynamic>{
  'coverArt': instance.coverArt,
  'id': instance.id,
  'title': instance.title,
};
