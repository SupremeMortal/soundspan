// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_play_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordPlayRequest _$RecordPlayRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['playbackId'],
    disallowNullValues: const [
      'listenedMs',
      'metadata',
      'playbackId',
      'playedAt',
    ],
  );
  return RecordPlayRequest(
    listenedMs: RecordPlayRequest._read_listenedMs(json['listenedMs']),
    metadata: json['metadata'] == null
        ? null
        : PlaybackMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String,
    playedAt: RecordPlayRequest._read_playedAt(json['playedAt']),
    additionalProperties:
        RecordPlayRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : RecordPlayRequest._readExtras(
            RecordPlayRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RecordPlayRequestToJson(RecordPlayRequest instance) =>
    <String, dynamic>{
      'listenedMs': ?RecordPlayRequest._write_listenedMs(instance.listenedMs),
      'metadata': ?instance.metadata?.toJson(),
      'playbackId': instance.playbackId,
      'playedAt': ?RecordPlayRequest._write_playedAt(instance.playedAt),
    };
