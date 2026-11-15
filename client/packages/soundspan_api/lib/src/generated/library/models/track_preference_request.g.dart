// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_preference_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackPreferenceRequest _$TrackPreferenceRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['playbackId', 'signal'],
    disallowNullValues: const ['metadata', 'playbackId', 'signal'],
  );
  return TrackPreferenceRequest(
    metadata: json['metadata'] == null
        ? null
        : PlaybackMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String,
    signal: TrackPreferenceRequest._read_signal(json['signal']),
    additionalProperties:
        TrackPreferenceRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : TrackPreferenceRequest._readExtras(
            TrackPreferenceRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TrackPreferenceRequestToJson(
  TrackPreferenceRequest instance,
) => <String, dynamic>{
  'metadata': ?instance.metadata?.toJson(),
  'playbackId': instance.playbackId,
  'signal': ?TrackPreferenceRequest._write_signal(instance.signal),
};
