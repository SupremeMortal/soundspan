// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_queue_track_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenQueueTrackInput _$ListenQueueTrackInputFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['playbackId'],
    disallowNullValues: const ['metadata', 'playbackId'],
  );
  return ListenQueueTrackInput(
    metadata: json['metadata'] == null
        ? null
        : PlaybackMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String,
    additionalProperties:
        ListenQueueTrackInput._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenQueueTrackInput._readExtras(
            ListenQueueTrackInput._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenQueueTrackInputToJson(
  ListenQueueTrackInput instance,
) => <String, dynamic>{
  'metadata': ?instance.metadata?.toJson(),
  'playbackId': instance.playbackId,
};
