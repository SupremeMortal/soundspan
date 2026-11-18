// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_listen_group_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateListenGroupRequest _$CreateListenGroupRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    disallowNullValues: const [
      'currentTimeMs',
      'currentTrackId',
      'isPlaying',
      'name',
      'queueTrackIds',
      'queueTracks',
      'visibility',
    ],
  );
  return CreateListenGroupRequest(
    currentTimeMs: json['currentTimeMs'] as num?,
    currentTrackId: json['currentTrackId'] as String?,
    isPlaying: json['isPlaying'] as bool?,
    name: json['name'] as String?,
    queueTrackIds: (json['queueTrackIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    queueTracks: (json['queueTracks'] as List<dynamic>?)
        ?.map((e) => ListenQueueTrackInput.fromJson(e as Map<String, dynamic>))
        .toList(),
    visibility: CreateListenGroupRequest._read_visibility(json['visibility']),
    additionalProperties:
        CreateListenGroupRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : CreateListenGroupRequest._readExtras(
            CreateListenGroupRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$CreateListenGroupRequestToJson(
  CreateListenGroupRequest instance,
) => <String, dynamic>{
  'currentTimeMs': ?instance.currentTimeMs,
  'currentTrackId': ?instance.currentTrackId,
  'isPlaying': ?instance.isPlaying,
  'name': ?instance.name,
  'queueTrackIds': ?instance.queueTrackIds,
  'queueTracks': ?instance.queueTracks?.map((e) => e.toJson()).toList(),
  'visibility': ?CreateListenGroupRequest._write_visibility(
    instance.visibility,
  ),
};
