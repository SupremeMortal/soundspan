// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similar_tracks_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimilarTracksResponse _$SimilarTracksResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['sourceFeatures', 'sourceTrackId', 'tracks'],
    disallowNullValues: const ['sourceFeatures', 'sourceTrackId', 'tracks'],
  );
  return SimilarTracksResponse(
    sourceFeatures: VibeAudioFeatures.fromJson(
      json['sourceFeatures'] as Map<String, dynamic>,
    ),
    sourceTrackId: json['sourceTrackId'] as String,
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => SimilarTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        SimilarTracksResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : SimilarTracksResponse._readExtras(
            SimilarTracksResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SimilarTracksResponseToJson(
  SimilarTracksResponse instance,
) => <String, dynamic>{
  'sourceFeatures': instance.sourceFeatures.toJson(),
  'sourceTrackId': instance.sourceTrackId,
  'tracks': instance.tracks.map((e) => e.toJson()).toList(),
};
