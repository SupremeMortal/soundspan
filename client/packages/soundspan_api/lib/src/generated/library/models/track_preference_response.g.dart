// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_preference_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackPreferenceResponse _$TrackPreferenceResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const [
      'dislikedAt',
      'likedAt',
      'playbackId',
      'score',
      'signal',
      'state',
      'trackId',
      'updatedAt',
    ],
    disallowNullValues: const [
      'playbackId',
      'score',
      'signal',
      'state',
      'trackId',
    ],
  );
  return TrackPreferenceResponse(
    dislikedAt: TrackPreferenceResponse._read_dislikedAt(json['dislikedAt']),
    likedAt: TrackPreferenceResponse._read_likedAt(json['likedAt']),
    playbackId: json['playbackId'] as String,
    score: TrackPreferenceResponse._read_score(json['score']),
    signal: TrackPreferenceResponse._read_signal(json['signal']),
    state: TrackPreferenceResponse._read_state(json['state']),
    trackId: json['trackId'] as String,
    updatedAt: TrackPreferenceResponse._read_updatedAt(json['updatedAt']),
    additionalProperties:
        TrackPreferenceResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : TrackPreferenceResponse._readExtras(
            TrackPreferenceResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TrackPreferenceResponseToJson(
  TrackPreferenceResponse instance,
) => <String, dynamic>{
  'dislikedAt': TrackPreferenceResponse._write_dislikedAt(instance.dislikedAt),
  'likedAt': TrackPreferenceResponse._write_likedAt(instance.likedAt),
  'playbackId': instance.playbackId,
  'score': ?TrackPreferenceResponse._write_score(instance.score),
  'signal': ?TrackPreferenceResponse._write_signal(instance.signal),
  'state': ?TrackPreferenceResponse._write_state(instance.state),
  'trackId': instance.trackId,
  'updatedAt': TrackPreferenceResponse._write_updatedAt(instance.updatedAt),
};
