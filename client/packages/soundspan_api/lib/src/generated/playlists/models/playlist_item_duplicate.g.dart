// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_item_duplicate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistItemDuplicate _$PlaylistItemDuplicateFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['duplicated', 'item', 'message'],
    disallowNullValues: const ['duplicated', 'item', 'message'],
  );
  return PlaylistItemDuplicate(
    duplicated: PlaylistItemDuplicate._read_duplicated(json['duplicated']),
    item: PlaylistItem.fromJson(json['item'] as Map<String, dynamic>),
    message: json['message'] as String,
    additionalProperties:
        PlaylistItemDuplicate._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistItemDuplicate._readExtras(
            PlaylistItemDuplicate._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistItemDuplicateToJson(
  PlaylistItemDuplicate instance,
) => <String, dynamic>{
  'duplicated': ?PlaylistItemDuplicate._write_duplicated(instance.duplicated),
  'item': instance.item.toJson(),
  'message': instance.message,
};
