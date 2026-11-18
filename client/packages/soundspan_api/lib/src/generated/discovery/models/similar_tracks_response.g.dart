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
    disallowNullValues: const ['sourceTrackId', 'tracks'],
  );
  return SimilarTracksResponse(
    sourceFeatures: SimilarTracksResponse._read_sourceFeatures(
      json['sourceFeatures'],
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
  'sourceFeatures': SimilarTracksResponse._write_sourceFeatures(
    instance.sourceFeatures,
  ),
  'sourceTrackId': instance.sourceTrackId,
  'tracks': instance.tracks.map((e) => e.toJson()).toList(),
};
