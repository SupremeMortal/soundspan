// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_playlist_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddPlaylistItemRequest _$AddPlaylistItemRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['playbackId'],
    disallowNullValues: const ['metadata', 'playbackId'],
  );
  return AddPlaylistItemRequest(
    metadata: json['metadata'] == null
        ? null
        : PlaybackMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String,
    additionalProperties:
        AddPlaylistItemRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : AddPlaylistItemRequest._readExtras(
            AddPlaylistItemRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AddPlaylistItemRequestToJson(
  AddPlaylistItemRequest instance,
) => <String, dynamic>{
  'metadata': ?instance.metadata?.toJson(),
  'playbackId': instance.playbackId,
};
