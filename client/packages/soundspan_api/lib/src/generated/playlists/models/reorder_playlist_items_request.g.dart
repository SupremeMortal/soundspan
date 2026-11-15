// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_playlist_items_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReorderPlaylistItemsRequest _$ReorderPlaylistItemsRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['playbackIds'],
    disallowNullValues: const ['playbackIds'],
  );
  return ReorderPlaylistItemsRequest(
    playbackIds: (json['playbackIds'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    additionalProperties:
        ReorderPlaylistItemsRequest._extras(json, 'additionalProperties') ==
            null
        ? const {}
        : ReorderPlaylistItemsRequest._readExtras(
            ReorderPlaylistItemsRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ReorderPlaylistItemsRequestToJson(
  ReorderPlaylistItemsRequest instance,
) => <String, dynamic>{'playbackIds': instance.playbackIds};
